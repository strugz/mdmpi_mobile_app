import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/cancel_remarks_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/pull_out/pull_out_repository.dart';
import 'package:mdmpi_mobile_app/data/services/messaging_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/proof_image_outbox_uploader.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_form_state.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/pull_out_mapper.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/item_category_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/form_category_repository.dart';

import '../../../base/utils/image_utils/image_conversion_base_64_to_string.dart';
import '../../../data/repositories/image/image_repository.dart';

/// Manager for Stock Receive domain orchestration (save/update flows).
///
/// Responsibilities:
/// - CRUD operations for Stock Receive requests
/// - API and local database synchronization
/// - Image and signature upload handling
/// - Category data loading
/// - Cancel remarks fetching
/// - Network connectivity validation
/// - Uses PullOutRepository but filters for Stock Receive category only
class StockReceiveDataManager {
  final PullOutRepository _repository = Get.find<PullOutRepository>();
  final CancelRemarksRepository _cancelRemarksRepository =
      Get.find<CancelRemarksRepository>();
  final MessagingController _messageController =
      Get.find<MessagingController>();

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

  /// Save a new Stock Receive request using values from controllers and shared form state.
  Future<void> saveRequestFromForm(dynamic controller) async {
    BFullScreenLoader.openLoadingDialog(
        'Saving on process...', BImages.docerAnimation);

    if (!await validateConnectivity()) {
      controller.errorMessage.value = 'No Internet connection';
      BFullScreenLoader.stopLoading();
      return;
    }

    try {
      final stdController = Get.find<StandardDeliveryController>();
      final userCtrl = Get.find<UserController>();

      final client = stdController.formState.clientInformation.value;
      if (client == null || client.id.isEmpty) {
        controller.errorMessage.value = 'Please select a Client.';
        BLoaders.errorSnackBar(
            title: 'Client', message: 'Please select a Client.');
        return;
      }

      final docRefs = stdController.formState.documentReferenceControllers
          .map((c) => c.text.trim())
          .toList();
      if (docRefs.isEmpty || docRefs.any((e) => e.isEmpty)) {
        controller.errorMessage.value =
            'Please enter at least one document reference.';
        BLoaders.errorSnackBar(
            title: 'Document Reference',
            message: 'Please enter at least one document reference.');
        return;
      }

      if (controller.formState.pullOutDateController.text.trim().isEmpty) {
        controller.errorMessage.value = 'Please pick a stock receive date.';
        BLoaders.errorSnackBar(
            title: 'Stock Receive Date',
            message: 'Please pick a stock receive date.');
        return;
      }

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

      final normalizedFormCategory = ensureCategoryId(
          controller.formState.formCategoryController,
          controller.formState.formCategories);
      final normalizedItemCategory = ensureCategoryId(
          controller.formState.itemCategoryController,
          controller.formState.itemCategories);

      final model = PullOutModel(
        clientId: client.id,
        client: client,
        clientContactPerson:
            controller.formState.clientContactPersonController.text,
        createdBy: userCtrl.user.value.initial,
        requestStatus: 'New Request',
        formCategoryId: normalizedFormCategory,
        itemCategoryId: normalizedItemCategory,
        irrfNumber: controller.formState.irrfNumberController.text,
        irrfDate: controller.formState.irrfDateController.text,
        reasonForReturn: controller.formState.reasonController.text,
        releasedBy: controller.formState.releasedByController.text,
        pullOutDate: controller.formState.pullOutDateController.text,
        pullOutDateStartAt: controller.formState.pullOutStartController.text,
        pullOutDateEndAt: controller.formState.pullOutEndController.text,
        tripTicketNumber: controller.formState.tripTicketController.text,
        driver: controller.formState.driverController.text,
        helper: controller.formState.helperController.text,
        requestedBy: userCtrl.user.value.initial,
        documentReference: docRefs,
      );
      await _repository.insert(model, silent: true);
      await _messageController.sendSmsMessage(BTexts.statusNewRequest, model);

      await controller.loadStockReceives();

      // Mark as success
      controller.errorMessage.value = null;
    } catch (e) {
      controller.errorMessage.value = 'An error occurred: $e';
      BLoaders.errorSnackBar(
          title: 'Save Failed', message: 'An error occurred: $e');
    } finally {
      BFullScreenLoader.stopLoading();
    }
  }

  /// Update request status and merge interactive header inputs (trip ticket,
  /// driver, helper) from the controller if provided.
  Future<void> updateRequestStatus(
    PullOutModel request,
    String newStatus,
    dynamic controller,
    PullOutFormState formState,
  ) async {
    try {
      controller.isSaving.value = true;
      controller.errorMessage.value = null;
      final nowString = DateTime.now().toString();

      final updated = request.copyWith(
        requestStatus: newStatus,
        tripTicketNumber:
            controller.formState.tripTicketController.text.isNotEmpty
                ? controller.formState.tripTicketController.text
                : request.tripTicketNumber,
        driver: controller.formState.driverController.text.isNotEmpty
            ? controller.formState.driverController.text
            : request.driver,
        helper: controller.formState.helperController.text.isNotEmpty
            ? controller.formState.helperController.text
            : request.helper,
        pullOutDateStartAt: newStatus == BTexts.statusInTransit &&
                request.pullOutDateStartAt.isEmpty
            ? nowString
            : request.pullOutDateStartAt,
        pullOutDateEndAt: newStatus == BTexts.statusTakenOut &&
                request.pullOutDateEndAt.isEmpty
            ? nowString
            : request.pullOutDateEndAt,
        mobileID:
            newStatus == BTexts.statusInTransit && request.mobileID == null
                ? (int.tryParse(controller.formState.mobile.text) ??
                    request.mobileID)
                : request.mobileID,
        releasedBy:
            newStatus == BTexts.statusTakenOut && request.releasedBy.isEmpty
                ? controller.formState.releasedByController.text
                : request.releasedBy,
      );

      final bool signatureWasAdded = newStatus == BTexts.statusTakenOut &&
          formState.receiverSignatureBase64.value.isNotEmpty;

      if (signatureWasAdded) {
        final isConnectedForUpload =
            await NetworkManager.instance.isConnected();
        if (isConnectedForUpload) {
          await ImageRepository.instance.uploadFile(
            requestId: request.id,
            base64Image: formState.receiverSignatureBase64.value,
            type: 'Signature',
          );
        } else {
          BLoaders.warningSnackBar(
              title: 'No Internet',
              message:
                  'Signature saved locally. It will be uploaded when internet connection is available.');
        }
      }

      if (newStatus == BTexts.statusTakenOut) {
        String? finalImageBase64 =
            await BImageHelperFunctions.getDeliveryImageAsBase64(
                newStatus, request.id);

        if (finalImageBase64 != null && finalImageBase64.isNotEmpty) {
          await ProofImageOutboxUploader.instance.uploadOrQueue(
            requestId: request.id,
            imageLookupKey: request.id,
            base64Image: finalImageBase64,
            type: 'Proof',
          );
        }
      }

      final payload = PullOutMapper.toUpdateDto(updated);

      await _repository.updateWithPayload(payload, silent: true);
      await _messageController.sendSmsMessage(newStatus, updated);

      await controller.loadStockReceives();

      BLoaders.successSnackBar(title: 'Success', message: 'Request updated');
    } catch (e) {
      controller.errorMessage.value = e.toString();
      BLoaders.errorSnackBar(
          title: 'Error',
          message: controller.errorMessage.value ?? 'Failed to update');
    } finally {
      formState.reset();
      controller.isSaving.value = false;
      BFullScreenLoader.stopLoading();
    }
  }

  /// Cancel a Stock Receive request with remarks via API.
  Future<void> cancelRequestWithRemarks(PullOutModel request, String remarks,
      String user, dynamic controller) async {
    BFullScreenLoader.openLoadingDialog(
        'Saving on process...', BImages.docerAnimation);

    if (!await validateConnectivity()) {
      BFullScreenLoader.stopLoading();
      return;
    }

    try {
      await _repository.cancelPullOutAPI(request.id, remarks, user,
          silent: true);
      await _messageController.sendSmsMessage(
        BTexts.statusCancelled,
        request,
        overrideCancelRemarks: remarks,
      );
      await fetchStockReceives(controller);
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

  /// Fetch Stock Receive requests and assign to the provided controller.
  /// Attempts local DB first if [useLocalStorage] is true; falls back to API if empty.
  /// Filters for Stock Receive category only (formCategoryId = '7').
  /// Applies active filters after loading data and updates the controller state.
  ///
  /// [controller] The Stock Receive controller to update with fetched data
  /// [useLocalStorage] If true, prefer local DB; if false, fetch directly from API
  Future<void> fetchStockReceives(dynamic controller,
      [bool useLocalStorage = true]) async {
    if (controller.isLoading.value) return;
    controller.isLoading.value = true;
    controller.errorMessage.value = null;
    try {
      List<PullOutModel> results;

      if (!useLocalStorage) {
        // Force API fetch by passing forceRefresh: true
        logDebug(
            'StockReceiveDataManager: Fetching from API (useLocalStorage=false, forcing refresh)');
        results = await _repository.getAll(forceRefresh: true);
      } else {
        logDebug('StockReceiveDataManager: Fetching from local DB first');
        results = await _repository.getLocalPullOuts();
        if (results.isEmpty) {
          logDebug(
              'StockReceiveDataManager: Local DB empty, fetching from API');
          results = await _repository.getAll();
        } else {
          logDebug(
              'StockReceiveDataManager: Loaded ${results.length} items from local DB');
        }
      }

      // Filter for Stock Receive category only (formCategoryId = '7')
      final stockReceiveRequests =
          results.where((r) => r.formCategoryId == '9').toList();

      (controller.stockReceives as RxList<PullOutModel>)
          .assignAll(stockReceiveRequests);
      logDebug(
          'StockReceiveDataManager: Assigned ${stockReceiveRequests.length} Stock Receive requests to controller');

      controller.filterManager.applyFilter(controller.stockReceives.toList());
    } catch (e) {
      controller.errorMessage.value = e.toString();
      logDebug('StockReceiveDataManager.fetchStockReceives error: $e');
      BLoaders.errorSnackBar(title: 'Error', message: e.toString());
    } finally {
      controller.isLoading.value = false;
    }
  }

  /// Hard reset Stock Receive data by forcing a fresh API load and replacing the controller cache.
  Future<void> hardResetStockReceives(dynamic controller) async {
    if (controller.isLoading.value) return;

    if (!await validateConnectivity()) {
      return;
    }

    controller.isLoading.value = true;
    controller.errorMessage.value = null;

    try {
      final results = await _repository.getAll(forceRefresh: true);
      final stockReceiveRequests =
          results.where((r) => r.formCategoryId == '9').toList();

      (controller.stockReceives as RxList<PullOutModel>)
          .assignAll(stockReceiveRequests);
      controller.filterManager.applyFilter(controller.stockReceives.toList());

      BLoaders.successSnackBar(
        title: 'Success',
        message: 'Stock Receive data refreshed successfully',
      );
    } catch (e) {
      controller.errorMessage.value = e.toString();
      BLoaders.errorSnackBar(title: 'Error', message: e.toString());
    } finally {
      controller.isLoading.value = false;
    }
  }

  /// Insert a Stock Receive model and refresh controller list.
  Future<void> insertStockReceiveModel(
      PullOutModel model, dynamic controller) async {
    if (controller.isSaving.value) return;
    controller.isSaving.value = true;
    controller.errorMessage.value = null;
    try {
      await _repository.insert(model, silent: true);
      await fetchStockReceives(controller);
      BLoaders.successSnackBar(title: 'Success', message: 'Request created');
    } catch (e) {
      controller.errorMessage.value = e.toString();
      BLoaders.errorSnackBar(
          title: 'Save Failed', message: 'An error occurred: $e');
    } finally {
      controller.isSaving.value = false;
    }
  }

  /// Load item and form categories and populate the controller caches.
  /// Sets default category selections to Stock Receive.
  Future<void> loadCategories(dynamic controller) async {
    try {
      final items = await Get.find<ItemCategoryRepository>().getAll();
      final forms = await Get.find<FormCategoryRepository>().getAll();
      (controller.formState.itemCategories as RxList).assignAll(items);
      (controller.formState.formCategories as RxList).assignAll(forms);

      if (controller.formState.formCategoryController.text.trim().isEmpty &&
          controller.formState.formCategories.isNotEmpty) {
        final defaultForm = controller.formState.formCategories.firstWhere(
          (e) =>
              e.name.toLowerCase().contains('stock') ||
              e.name.toLowerCase().contains('receive'),
          orElse: () => controller.formState.formCategories.first,
        );
        controller.formState.formCategoryController.text = defaultForm.id;
      }

      if (controller.formState.itemCategoryController.text.trim().isEmpty &&
          controller.formState.itemCategories.isNotEmpty) {
        final defaultItem = controller.formState.itemCategories.firstWhere(
          (e) => e.name.toLowerCase().contains('reagent'),
          orElse: () => controller.formState.itemCategories.first,
        );
        controller.formState.itemCategoryController.text = defaultItem.id;
      }
    } catch (e) {
      logDebug('StockReceiveDataManager.loadCategories failed: $e');
    }
  }

  /// Fetch cancel remarks for a Stock Receive request from CancelRemarksRepository.
  Future<CancelRemarksModel> fetchCancelRemarks(String requestId) async {
    try {
      logDebug(
          '🔍 StockReceiveDataManager: Fetching cancel remarks for: $requestId');
      final result = await _cancelRemarksRepository.getCancelRemarksByRequestId(
        requestId,
        module: RequestModule.pullOut,
      );
      logDebug(
          '✅ StockReceiveDataManager: API returned remarks: "${result.remarks}" date: "${result.date}"');
      return result;
    } catch (e) {
      logDebug('❌ StockReceiveDataManager.fetchCancelRemarks FAILED: $e');
      return CancelRemarksModel.empty;
    }
  }
}
