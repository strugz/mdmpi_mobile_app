import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_notification_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/notification_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';

import '../helpers/request_data_manager.dart';
import '../helpers/request_filter_manager.dart';
import '../helpers/request_form_state.dart';

enum RequestFilter {
  today('Today'),
  yesterday('Yesterday'),
  tomorrow('Tomorrow'),
  fiveDaysAgo('5 Days Ago'),
  thirtyDaysAgo('30 Days Ago'),
  all('All');

  const RequestFilter(this.displayName);
  final String displayName;
}

enum RequestStatusFilter {
  statusNewRequest('New Request'),
  statusGettingSuppliesReady('Getting supplies ready'),
  statusItemPrepared('Item Prepared'),
  statusForDelivery('For Delivery'),
  statusDoneDelivery('Delivered'),
  statusCancelled('Cancelled'),
  all('All');

  const RequestStatusFilter(this.displayName);
  final String displayName;
}

class StandardDeliveryController extends GetxController {
  static StandardDeliveryController get instance => Get.find();

  // State
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isFetchingRequests = false.obs;
  final useLocalStorage = true.obs;
  final totalRequest = 0.obs;
  final gettingSuppliesReady = 0.obs;
  final itemPrepared = 0.obs;
  final forDelivery = 0.obs;
  final delivered = 0.obs;
  final allPendingRequests = <StandardDeliveryModel>[].obs;
  final currentSelectedRequest = Rx<StandardDeliveryModel?>(null);
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  /// Cache of cancel remarks keyed by request ID
  final RxMap<String, CancelRemarksModel> cancelRemarksCache = <String, CancelRemarksModel>{}.obs;
  /// Loading flags per request id to avoid duplicate fetches
  final RxMap<String, bool> cancelRemarksLoading = <String, bool>{}.obs;
  // Managers
  late final RequestFormState formState;
  late final RequestDataManager dataManager;
  late final RequestFilterManager filterManager;
  late final WebSocketNotificationController _webSocketController;

  @override
  Future<void> onInit() async {
    super.onInit();
    formState = RequestFormState();
    dataManager = RequestDataManager();
    filterManager = RequestFilterManager();
    _webSocketController = Get.find<WebSocketNotificationController>();

    formState.initializeDefaultDate();

    if (await _dbHelper.isRequestTableNotEmpty()) {
      await dataManager.loadDataFromSqfLite(allPendingRequests, filterManager);
      updateRequestCounts();
    } else {
      loadRequests();
    }

    _webSocketController.registerNotificationListener(_handleNotification);
  }

  @override
  void onClose() {
    formState.dispose();
    super.onClose();
  }

  void updateRequestCounts() {
    totalRequest.value = allPendingRequests.length;
    gettingSuppliesReady.value = allPendingRequests
        .where((r) => r.status == BTexts.statusGettingSuppliesReady)
        .length;
    itemPrepared.value = allPendingRequests
        .where((r) => r.status == BTexts.statusItemPrepared)
        .length;
    forDelivery.value = allPendingRequests
        .where((r) => r.status == BTexts.statusForDelivery)
        .length;
    delivered.value = allPendingRequests
        .where((r) => r.status == BTexts.statusDoneDelivery)
        .length;
  }

  Future<void> _handleNotification(NotificationModel notification) async {
    if (notification.title == 'New' || notification.title == 'Update') {
      await loadRequests();
    }
  }

  Future<void> loadRequests() async {
    try {
      isLoading.value = true;
      if (useLocalStorage.value) {
        await dataManager.fetchPendingRequestsAPI(
            allPendingRequests, filterManager);
      } else {
        await dataManager.loadDataFromSqfLite(
            allPendingRequests, filterManager);
      }
      updateRequestCounts();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshRequests() async {
    await DatabaseHelper.instance.deleteRequest();
    if (await dataManager.validateConnectivity()) {
      await dataManager.fetchPendingRequestsAPI(
          allPendingRequests, filterManager);
    }
  }

  void addDocumentReferenceField() {
    formState.documentReferenceControllers.add(TextEditingController());
  }

  void removeDocumentReferenceField(TextEditingController controller) {
    controller.dispose();
    formState.documentReferenceControllers.remove(controller);
  }

  void updateRequestClientInformation(ClientModel clientDetails) {
    formState.clientInformation.value = clientDetails;
  }

  void setSignature(Uint8List? signature) {
    formState.receiverSignatureBytes.value = signature;
    formState.receiverSignatureBase64.value =
        signature != null && signature.isNotEmpty
            ? base64Encode(signature)
            : "";
  }

  Future<void> saveRequest() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await dataManager.saveRequest(formState);
      await loadRequests();
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> updateRequestStatus(
      StandardDeliveryModel requestModel, String newStatus, String userInitial) async {
    await dataManager.updateRequestStatus(
      requestModel,
      newStatus,
      userInitial,
      formState,
      currentSelectedRequest,
      useLocalStorage.value,
    );
    await loadRequests();
  }

  Future<void> updateRequestForCancellation(
      StandardDeliveryModel requestModel, String remarks,
      {bool showLoader = true}) async {
    await dataManager.cancelRequestWithRemarks(
        requestModel, remarks, useLocalStorage.value && showLoader);
    await loadRequests();
  }

  void toggleStoragePreference(bool value) {
    useLocalStorage.value = value;
    loadRequests();
  }

  void selectFilter(RequestFilter filter) {
    filterManager.selectFilter(filter, allPendingRequests);
  }

  void selectStatusFilter(RequestStatusFilter statusFilter) {
    filterManager.selectStatusFilter(statusFilter, allPendingRequests);
  }

  /// Fetch cancel remarks for a request ID. Prefer local DB; if missing call API.
  /// Stores the result in [cancelRemarksCache] and persists API results to local DB when available.
  Future<CancelRemarksModel> fetchCancelRemarks(String requestId) async {
    // Avoid duplicate fetches
    if (cancelRemarksCache.containsKey(requestId)) return cancelRemarksCache[requestId]!;
    if (cancelRemarksLoading[requestId] == true) {
      // Wait until loading finishes
      while (cancelRemarksLoading[requestId] == true) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return cancelRemarksCache[requestId] ?? CancelRemarksModel.empty;
    }

    cancelRemarksLoading[requestId] = true;
    try {
      final result = await dataManager.fetchCancelRemarks(requestId);
      cancelRemarksCache[requestId] = result;
      return result;
    } catch (_) {
      cancelRemarksCache[requestId] = CancelRemarksModel.empty;
      return CancelRemarksModel.empty;
    } finally {
      cancelRemarksLoading.remove(requestId);
    }
  }
}
