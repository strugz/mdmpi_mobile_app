import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/offline_data_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/image_utils/image_conversion_base_64_to_string.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/repositories/standard_delivery/standard_delivery_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/image/image_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/cancel_remarks_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/item_category_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/form_category_repository.dart';
import 'package:mdmpi_mobile_app/data/services/messaging_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_notification_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_form_state.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/proof_image_outbox_uploader.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/hotline_direct_controller.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/notification_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Manager for Standard Delivery domain orchestration (save/update flows).
///
/// Responsibilities:
/// - CRUD operations for Standard Delivery requests
/// - API and local database synchronization
/// - Image and signature upload handling
/// - Category data loading
/// - Cancel remarks fetching
/// - Network connectivity validation
/// - SMS notification sending
class StandardDeliveryDataManager {
  final StandardDeliveryRepository _repository =
      Get.find<StandardDeliveryRepository>();
  final CancelRemarksRepository _cancelRemarksRepository =
      Get.find<CancelRemarksRepository>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final MessagingController _messageController =
      Get.find<MessagingController>();
  final WebSocketNotificationController _webSocketController =
      Get.find<WebSocketNotificationController>();

  /// Validate internet connectivity and show warning if offline.
  Future<bool> validateConnectivity() async {
    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) {
      BLoaders.warningSnackBar(
        title: 'No Internet',
        message: 'Please check your internet connection.',
      );
      return false;
    }
    return true;
  }

  /// Save a new Standard Delivery request from form state.
  ///
  /// Validation includes:
  /// - Requested by must be selected
  /// - Client must be selected
  /// - At least one document reference required
  ///
  /// On success:
  /// - Sends WebSocket notification
  /// - Sends SMS to managers
  /// - Resets form state
  Future<void> saveRequestFromForm(
      IDeliveryRequestController controller) async {
    BFullScreenLoader.openLoadingDialog(
        'Saving on process...', BImages.docerAnimation);

    if (!await validateConnectivity()) {
      BFullScreenLoader.stopLoading();
      return;
    }

    try {
      final userCtrl = Get.find<UserController>();
      final formState = controller.formState;

      // Note: Input validation is now handled by UI form validators
      // Only business logic and data transformation remain here

      final client =
          formState.clientInformation.value!; // Safe due to UI validation

      final docRefs = formState.documentReferenceControllers
          .map((c) => c.text.trim())
          .toList();

      // Normalize category IDs (data transformation logic)
      String ensureCategoryId(TextEditingController ctrl, List<dynamic> list) {
        final v = ctrl.text.trim();
        if (v.isEmpty) return '';
        if (list.any((e) => e.id == v)) return v;
        try {
          final found = list.firstWhere(
              (e) => (e.name).toString().toLowerCase() == v.toLowerCase());
          ctrl.text = found.id;
          return found.id;
        } catch (_) {
          return v;
        }
      }

      final normalizedFormCategory =
          ensureCategoryId(formState.formCategory, formState.formCategories);
      final normalizedItemCategory =
          ensureCategoryId(formState.itemCategory, formState.itemCategories);

      // Create request model
      final newRequest = StandardDeliveryModel.fromFormInputs(
        clientId: client.id,
        shippingMethod: formState.shippingMethod.text,
        deliveryTerms: formState.deliveryTerms.text,
        deliveryDate: formState.targetDate.text,
        requestBy: formState.requestedBy.text,
        documentReference: docRefs,
        preference: formState.preference.text,
        client: client,
        createdBy: userCtrl.user.value.initial,
        itemCategoryID: normalizedItemCategory,
        formCategoryID: normalizedFormCategory,
        recipientContactDetails: formState.recipientContactDetails.text.trim(),
        recipientName: formState.recipientName.text.trim(),
      );

      // Save to repository - include scanned items from form state
      await _repository.insertDelivery(
          newRequest, formState.scannedInventoryItems.toList());

      // Send notifications
      _webSocketController.sendNotificationMessage(
        NotificationModel(title: 'New', body: 'New Request Received!'),
      );

      await _messageController.sendSmsMessage(
          BTexts.statusNewRequest, newRequest,
          inventoryItems: formState.scannedInventoryItems.toList());

      // Reload requests based on form category
      // If it's Hotline Direct (form category ID '8'), refresh HotlineDirectController
      // Otherwise, refresh StandardDeliveryController
      if (normalizedFormCategory == '8') {
        try {
          final hotlineDirectController = Get.find<HotlineDirectController>();
          await hotlineDirectController.dataManager.fetchHotlineDirectRequests(
              hotlineDirectController,
              hotlineDirectController.useLocalStorage.value);
          hotlineDirectController.filterManager
              .applyFilter(hotlineDirectController.allPendingRequests.toList());
        } catch (e) {
          logDebug('⚠️ Could not refresh Hotline Direct list: $e');
        }
      } else {
        // Refresh Standard Delivery list
        await fetchStandardDeliveryRequests(
            controller, controller.useLocalStorage.value);
      }

      // Reset form
      formState.reset();

      controller.errorMessage.value = null;
    } catch (e) {
      controller.errorMessage.value = 'An error occurred: $e';
      BLoaders.errorSnackBar(
          title: 'Save Failed', message: 'An error occurred: $e');
    } finally {
      BFullScreenLoader.stopLoading();
    }
  }

  /// Update request status with automatic field population based on status.
  ///
  /// Status-specific logic:
  /// - "Getting supplies ready": Records preparer's name and timestamp
  /// - "Item Prepared": Records driver, helper, mobile, trip ticket, and end timestamp
  /// - "For Delivery": Records delivery start timestamp and location
  /// - "Delivered": Records delivery end timestamp, location, receiver, signature, and proof image
  ///
  /// Handles signature and image uploads with offline fallback.
  Future<void> updateRequestStatus(
    StandardDeliveryModel request,
    String newStatus,
    String userInitial,
    IDeliveryRequestController controller,
  ) async {
    if (!await _validateRequiredUpdateFields(
      request: request,
      newStatus: newStatus,
      formState: controller.formState,
    )) {
      return;
    }

    try {
      controller.isSaving.value = true;
      controller.errorMessage.value = null;
      final formState = controller.formState;
      final nowString = DateTime.now().toString();
      final resolvedMobileID =
          _resolveMobileId(request, newStatus, formState.mobile.text);
      final finalImageBase64 =
          await _resolveDeliveryProofImage(request, newStatus, formState);
      final updatedRequest = _buildUpdatedRequest(
        request: request,
        newStatus: newStatus,
        userInitial: userInitial,
        formState: formState,
        nowString: nowString,
        resolvedMobileID: resolvedMobileID,
      );

      await _handleStatusMediaUploads(
        request: request,
        newStatus: newStatus,
        formState: formState,
        finalImageBase64: finalImageBase64,
      );
      await _persistUpdatedRequest(
        request: updatedRequest,
        userInitial: userInitial,
        useLocalStorage: controller.useLocalStorage.value,
      );

      // Save media to local DB
      await _dbHelper.saveRequestMedia(
        requestID: request.id,
        signature: formState.receiverSignatureBase64.value.isNotEmpty
            ? formState.receiverSignatureBase64.value
            : null,
        image: finalImageBase64.isNotEmpty ? finalImageBase64 : null,
      );

      // Send notifications
      _webSocketController.sendNotificationMessage(
        NotificationModel(title: 'Update', body: updatedRequest.status),
      );

      await _messageController.sendSmsMessage(newStatus, updatedRequest);
      _applyReactiveRequestUpdate(controller, updatedRequest);

      formState.reset();
    } catch (e) {
      controller.errorMessage.value = e.toString();
      BLoaders.errorSnackBar(
          title: 'Error',
          message: controller.errorMessage.value ?? 'Failed to update');
    } finally {
      controller.isSaving.value = false;
      if (newStatus != BTexts.statusForDelivery) {
        BFullScreenLoader.stopLoading();
      }
    }
  }

  int? _resolveMobileId(
    StandardDeliveryModel request,
    String newStatus,
    String mobileText,
  ) {
    if (newStatus != BTexts.statusItemPrepared) {
      return request.mobileID;
    }
    if (request.mobileID == null || request.mobileID == 0) {
      return int.tryParse(mobileText) ?? request.mobileID;
    }
    return request.mobileID;
  }

  Future<String> _resolveDeliveryProofImage(
    StandardDeliveryModel request,
    String newStatus,
    StandardDeliveryFormState formState,
  ) async {
    if (newStatus == BTexts.statusDoneDelivery && request.image.isEmpty) {
      return await BImageHelperFunctions.getDeliveryImageAsBase64(
              newStatus, request.id) ??
          formState.cameraPickUpPicture.value;
    }
    return request.image;
  }

  StandardDeliveryModel _buildUpdatedRequest({
    required StandardDeliveryModel request,
    required String newStatus,
    required String userInitial,
    required StandardDeliveryFormState formState,
    required String nowString,
    required int? resolvedMobileID,
  }) {
    return request.copyWith(
      status: newStatus,
      itemPreparedBy: newStatus == BTexts.statusGettingSuppliesReady &&
              request.itemPreparedBy.isEmpty
          ? userInitial
          : request.itemPreparedBy,
      deliveredBy:
          newStatus == BTexts.statusItemPrepared && request.deliveredBy.isEmpty
              ? formState.selectedDriver.text
              : request.deliveredBy,
      itemPreparedAt: newStatus == BTexts.statusGettingSuppliesReady &&
              request.itemPreparedAt.isEmpty
          ? nowString
          : request.itemPreparedAt,
      itemPreparedEndAt: newStatus == BTexts.statusItemPrepared &&
              request.itemPreparedEndAt.isEmpty
          ? nowString
          : request.itemPreparedEndAt,
      deliveredAt:
          newStatus == BTexts.statusForDelivery && request.deliveredAt.isEmpty
              ? nowString
              : request.deliveredAt,
      deliveredEndAt: newStatus == BTexts.statusDoneDelivery &&
              request.deliveredEndAt.isEmpty
          ? nowString
          : request.deliveredEndAt,
      locationStartedAt: newStatus == BTexts.statusForDelivery &&
              request.locationStartedAt.isEmpty
          ? nowString
          : request.locationStartedAt,
      locationEndAt: newStatus == BTexts.statusDoneDelivery &&
              request.locationEndAt.isEmpty
          ? nowString
          : request.locationEndAt,
      helper: newStatus == BTexts.statusItemPrepared && request.helper.isEmpty
          ? formState.selectedHelper.text
          : request.helper,
      receiver:
          newStatus == BTexts.statusDoneDelivery && request.receiver.isEmpty
              ? formState.receiver.text
              : request.receiver,
      mobileID: resolvedMobileID,
      tripTicketNumber: newStatus == BTexts.statusItemPrepared &&
              request.tripTicketNumber.isEmpty
          ? formState.tripTicketNumber.text
          : request.tripTicketNumber,
    );
  }

  Future<void> _handleStatusMediaUploads({
    required StandardDeliveryModel request,
    required String newStatus,
    required StandardDeliveryFormState formState,
    required String finalImageBase64,
  }) async {
    final bool signatureWasAdded = newStatus == BTexts.statusDoneDelivery &&
        request.signature.isEmpty &&
        formState.receiverSignatureBase64.value.isNotEmpty;
    final bool imageProofWasAdded = newStatus == BTexts.statusDoneDelivery &&
        request.image.isEmpty &&
        finalImageBase64.isNotEmpty;

    // Extra proof photos (slots 2-3) upload as their own image types
    // (Proof_2, Proof_3) through the same endpoint and outbox.
    final Map<int, String> extraProofImages =
        newStatus == BTexts.statusDoneDelivery && imageProofWasAdded
            ? await BImageHelperFunctions.getExtraDeliveryImagesAsBase64(
                request.id)
            : const {};

    if (!signatureWasAdded && !imageProofWasAdded) return;

    final isConnectedForUpload = await NetworkManager.instance.isConnected();
    if (!isConnectedForUpload) {
      if (imageProofWasAdded) {
        await ProofImageOutboxUploader.instance.queueOnly(
          requestId: request.id,
          imageLookupKey: request.id,
          base64Image: finalImageBase64,
          type: 'Proof',
          apiStatus: 'Pending',
        );
        for (final entry in extraProofImages.entries) {
          await ProofImageOutboxUploader.instance.queueOnly(
            requestId: request.id,
            imageLookupKey: request.id,
            base64Image: entry.value,
            type: 'Proof_${entry.key}',
            apiStatus: 'Pending',
          );
        }
      }
      BLoaders.warningSnackBar(
        title: 'No Internet',
        message:
            'Media saved locally. It will be uploaded when internet connection is available.',
      );
      return;
    }

    if (signatureWasAdded) {
      final validation = await ImageRepository.instance.uploadFile(
        requestId: request.id,
        base64Image: formState.receiverSignatureBase64.string,
        type: 'Signature',
      );

      if (validation.isFailure) {
        await _dbHelper.insertReceiverSignature(
          requestID: request.id,
          signature: formState.receiverSignatureBase64.string,
          apiStatus: 'Pending',
        );
      }
    }

    if (imageProofWasAdded) {
      await ProofImageOutboxUploader.instance.uploadOrQueue(
        requestId: request.id,
        imageLookupKey: request.id,
        base64Image: finalImageBase64,
        type: 'Proof',
      );
      for (final entry in extraProofImages.entries) {
        await ProofImageOutboxUploader.instance.uploadOrQueue(
          requestId: request.id,
          imageLookupKey: request.id,
          base64Image: entry.value,
          type: 'Proof_${entry.key}',
        );
      }
    }
  }

  Future<void> _persistUpdatedRequest({
    required StandardDeliveryModel request,
    required String userInitial,
    required bool useLocalStorage,
  }) async {
    BFullScreenLoader.openLoadingDialog(
      'Please wait saving update...',
      BImages.docerAnimation,
    );

    try {
      if (useLocalStorage) {
        await _dbHelper.updateRequest(requestModel: request);
        return;
      }

      final isConnected = await validateConnectivity();
      if (isConnected) {
        await _repository.updateDelivery(
          request,
          userInitial,
          showSuccessSnackBar: false,
        );
        await _dbHelper.updateRequest(requestModel: request);
        return;
      }

      await _dbHelper.updateRequest(requestModel: request);
      BLoaders.warningSnackBar(
        title: 'No Internet',
        message:
            'Request updated locally. Sync with server when connection returns.',
      );
    } finally {
      BFullScreenLoader.stopLoading();
    }
  }

  void _applyReactiveRequestUpdate(
    IDeliveryRequestController controller,
    StandardDeliveryModel updatedRequest,
  ) {
    controller.currentSelectedRequest.value = updatedRequest;
    final index = controller.allPendingRequests
        .indexWhere((req) => req.id == updatedRequest.id);
    if (index != -1) {
      controller.allPendingRequests[index] = updatedRequest;
      controller.allPendingRequests.refresh();
    }

    if (controller is StandardDeliveryController) {
      controller.filterManager
          .applyFilter(controller.allPendingRequests.toList());
    }
  }

  /// Cancel a Standard Delivery request with remarks.
  ///
  /// Handles both online and offline scenarios:
  /// - Online: Updates via API and local DB
  /// - Offline: Updates local DB only with sync warning
  ///
  /// Sends WebSocket notification and SMS to relevant personnel.
  Future<void> cancelRequestWithRemarks(StandardDeliveryModel request,
      String remarks, String user, IDeliveryRequestController controller,
      [bool useLocalStorage = true]) async {
    BFullScreenLoader.openLoadingDialog(
        'Saving on process...', BImages.docerAnimation);

    if (!await validateConnectivity()) {
      BFullScreenLoader.stopLoading();
      return;
    }

    try {
      if (useLocalStorage) {
        await _dbHelper.cancelRequestWithRemarks(
            requestID: request.id,
            remarks: remarks,
            newStatus: BTexts.statusCancelled);
      } else {
        final isConnected = await validateConnectivity();
        if (isConnected) {
          await _repository.cancelDelivery(request.id, remarks, user);
          await _dbHelper.cancelRequestWithRemarks(
              requestID: request.id,
              remarks: remarks,
              newStatus: BTexts.statusCancelled);
        } else {
          await _dbHelper.cancelRequestWithRemarks(
              requestID: request.id,
              remarks: remarks,
              newStatus: BTexts.statusCancelled);
          BLoaders.warningSnackBar(
            title: 'No Internet',
            message:
                'Request updated locally. Sync with server when connection returns.',
          );
        }
      }

      _webSocketController.sendNotificationMessage(
        NotificationModel(
            title: 'Request Cancelled!', body: 'Reason: $remarks'),
      );

      await _messageController.sendSmsMessage(BTexts.statusCancelled, request);

      await fetchStandardDeliveryRequests(
          controller, controller.useLocalStorage.value);

      BLoaders.successSnackBar(
          title: 'Cancelled', message: 'Request cancelled');
    } catch (e) {
      controller.errorMessage.value = e.toString();
      BLoaders.errorSnackBar(
          title: 'Save Failed', message: 'An error occurred: $e');
    } finally {
      BFullScreenLoader.stopLoading();
    }
  }

  /// Fetch Standard Delivery requests and assign to the controller.
  ///
  /// Data source selection:
  /// - useLocalStorage = false: Force API fetch
  /// - useLocalStorage = true: Try local DB first, fallback to API if empty
  ///
  /// Applies active filters after loading data.
  Future<void> fetchStandardDeliveryRequests(
      IDeliveryRequestController controller,
      [bool useLocalStorage = true]) async {
    if (controller.isLoading.value) return;
    controller.isLoading.value = true;
    controller.errorMessage.value = null;
    try {
      List<StandardDeliveryModel> results;

      results = await OfflineDataLoader.loadLocalThenRemoteIfOnline(
        loadLocal: _dbHelper.getRequests,
        loadRemote: _repository.getAllPending,
        cacheRemote: _dbHelper.insertRequests,
        sourceName: 'StandardDeliveryDataManager.fetchStandardDeliveryRequests',
        forceRemote: !useLocalStorage,
      );

      // Filter for Standard Delivery category only (formCategoryID = '6')
      final standardDeliveryRequests =
          results.where((r) => r.formCategoryID == '6').toList();

      controller.allPendingRequests.assignAll(standardDeliveryRequests);

      // Only apply filter if controller has filterManager (StandardDeliveryController)
      try {
        if (controller is StandardDeliveryController) {
          controller.filterManager
              .applyFilter(controller.allPendingRequests.toList());
        }
      } catch (e) {
        logDebug('⚠️ Could not apply filterManager: $e');
      }

      controller.updateRequestCounts();
    } catch (e) {
      controller.errorMessage.value = e.toString();
      logDebug(
          'StandardDeliveryDataManager.fetchStandardDeliveryRequests failed: $e');
    } finally {
      controller.isLoading.value = false;
    }
  }

  /// Hard reset the Standard Delivery cache by fetching from the API,
  /// clearing local request tables, and repopulating the local database.
  Future<void> hardResetRequests(IDeliveryRequestController controller) async {
    if (controller.isLoading.value) return;

    if (!await validateConnectivity()) {
      return;
    }

    controller.isLoading.value = true;
    controller.errorMessage.value = null;

    try {
      final apiRequests =
          await _repository.getAllPending(allowLocalFallback: false);

      await _dbHelper.deleteRequest();
      await _dbHelper.insertRequests(apiRequests);

      final standardDeliveryRequests =
          apiRequests.where((r) => r.formCategoryID == '6').toList();

      controller.allPendingRequests.assignAll(standardDeliveryRequests);

      try {
        if (controller is StandardDeliveryController) {
          controller.filterManager
              .applyFilter(controller.allPendingRequests.toList());
        }
      } catch (e) {
        logDebug('⚠️ Could not apply filterManager during hard reset: $e');
      }

      controller.updateRequestCounts();
    } catch (e) {
      controller.errorMessage.value = e.toString();
      BLoaders.errorSnackBar(title: 'Error', message: e.toString());
    } finally {
      controller.isLoading.value = false;
    }
  }

  /// Load item and form categories and populate the controller form state.
  ///
  /// Sets default category selections:
  /// - Form category: Prefers "standard" category
  /// - Item category: Prefers "reagent" category
  ///
  /// Safe to call multiple times; will not duplicate data.
  Future<void> loadCategories(IDeliveryRequestController controller) async {
    try {
      final items = await Get.find<ItemCategoryRepository>().getAll();
      final forms = await Get.find<FormCategoryRepository>().getAll();
      controller.formState.itemCategories.assignAll(items);
      controller.formState.formCategories.assignAll(forms);

      if (controller.formState.formCategory.text.trim().isEmpty &&
          controller.formState.formCategories.isNotEmpty) {
        final defaultForm = controller.formState.formCategories.firstWhere(
          (e) => e.name.toLowerCase().contains('standard'),
          orElse: () => controller.formState.formCategories.first,
        );
        controller.formState.formCategory.text = defaultForm.id;
      }

      if (controller.formState.itemCategory.text.trim().isEmpty &&
          controller.formState.itemCategories.isNotEmpty) {
        final defaultItem = controller.formState.itemCategories.firstWhere(
          (e) => e.name.toLowerCase().contains('reagent'),
          orElse: () => controller.formState.itemCategories.first,
        );
        controller.formState.itemCategory.text = defaultItem.id;
      }
    } catch (e) {
      logDebug('StandardDeliveryDataManager.loadCategories failed: $e');
    }
  }

  /// Fetch cancel remarks for a request.
  ///
  /// Tries local DB first, then fallback to API.
  /// Persists API results to local DB for offline access.
  Future<CancelRemarksModel> fetchCancelRemarks(String requestId) async {
    try {
      try {
        final bool exists = await _dbHelper.isRequestRemarkExisting(requestId);
        if (exists) {
          final localRemarks = await _dbHelper.getRequestRemarks(requestId);
          return localRemarks;
        }
      } catch (e) {
        logDebug('⚠️ StandardDeliveryDataManager: Local DB read failed: $e');
      }

      // Fallback to API
      try {
        final result =
            await _cancelRemarksRepository.getCancelRemarksByRequestId(
          requestId,
          module: RequestModule.standardDelivery,
        );
        if (result != CancelRemarksModel.empty) {
          // Persist to local DB
          try {
            final remarksDao = await _dbHelper.remarksDao;
            await remarksDao.insertRemark(
                requestId, result.remarks, result.date);
          } catch (e) {
            logDebug(
                '⚠️ StandardDeliveryDataManager: Failed to persist remarks: $e');
          }
          return result;
        }
        return CancelRemarksModel.empty;
      } catch (e) {
        return CancelRemarksModel.empty;
      }
    } catch (e) {
      return CancelRemarksModel.empty;
    }
  }

  /// Upload all modified requests from local DB to API.
  ///
  /// Iterates through all requests in local DB and uploads any that are
  /// not in "New Request" status (i.e., have been modified).
  ///
  /// Use case: Manual sync when connectivity is restored after offline changes.
  Future<void> uploadModifiedRequest() async {
    try {
      final requests = await _dbHelper.getRequests();
      final userCtrl = Get.find<UserController>();
      for (var request in requests) {
        if (request.status != BTexts.statusNewRequest) {
          await _repository.updateDelivery(
              request, userCtrl.user.value.initial);
        }
      }
      BLoaders.successSnackBar(
          title: 'Success', message: 'Modified requests uploaded successfully');
    } catch (e) {
      BLoaders.errorSnackBar(
          title: 'Upload Failed',
          message: "Could not upload requests: ${e.toString()}");
    }
  }

  // ========================================================================
  // VALIDATION HELPERS
  // ========================================================================

  static Future<bool> _validateRequiredUpdateFields({
    required StandardDeliveryModel request,
    required String newStatus,
    required StandardDeliveryFormState formState,
  }) async {
    if (newStatus == BTexts.statusItemPrepared) {
      return _validateDeliveryInfoForUpdate(request, formState);
    }

    if (newStatus == BTexts.statusDoneDelivery) {
      return _validateCompletionInfo(request, newStatus, formState);
    }

    return true;
  }

  static bool _validateDeliveryInfoForUpdate(
    StandardDeliveryModel request,
    StandardDeliveryFormState formState,
  ) {
    final tripTicket = request.tripTicketNumber.trim().isNotEmpty
        ? request.tripTicketNumber
        : formState.tripTicketNumber.text;
    final driver = request.deliveredBy.trim().isNotEmpty
        ? request.deliveredBy
        : formState.selectedDriver.text;
    final hasVehicle = (request.mobileID != null && request.mobileID != 0) ||
        formState.mobile.text.trim().isNotEmpty;

    if (tripTicket.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please enter Trip Ticket Number',
      );
      return false;
    }
    if (driver.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please select Driver',
      );
      return false;
    }
    if (!hasVehicle) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please select Vehicle',
      );
      return false;
    }
    return true;
  }

  static Future<bool> _validateCompletionInfo(
    StandardDeliveryModel request,
    String newStatus,
    StandardDeliveryFormState formState,
  ) async {
    final receiver = request.receiver.trim().isNotEmpty
        ? request.receiver
        : formState.receiver.text;
    final hasSignature = request.signature.trim().isNotEmpty ||
        formState.receiverSignatureBase64.value.trim().isNotEmpty ||
        (formState.receiverSignatureBytes.value?.isNotEmpty ?? false);
    final proofImage = request.image.trim().isNotEmpty
        ? request.image
        : await BImageHelperFunctions.getDeliveryImageAsBase64(
              newStatus,
              request.id,
            ) ??
            formState.cameraPickUpPicture.value;

    if (receiver.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: "Please enter the receiver's name.",
      );
      return false;
    }
    if (!hasSignature) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: "Please capture the receiver's signature.",
      );
      return false;
    }
    if (proofImage.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please capture the delivery proof image.',
      );
      return false;
    }
    return true;
  }

  /// Validates trip ticket, driver, helper, and vehicle fields
  /// before transitioning to Item Prepared.
  ///
  /// Mirrors [PullOutModalConfig._validateDeliveryInfo] adapted for
  /// Standard Delivery field names.
  // ignore: unused_element
  static bool _validateDeliveryInfo(StandardDeliveryFormState formState) {
    if (formState.tripTicketNumber.text.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please enter Trip Ticket Number',
      );
      return false;
    }
    if (formState.selectedDriver.text.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please select Driver',
      );
      return false;
    }
    // Helper is optional for Standard Delivery — no validation required.
    if (formState.mobile.text.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please select Vehicle',
      );
      return false;
    }
    return true;
  }
}
