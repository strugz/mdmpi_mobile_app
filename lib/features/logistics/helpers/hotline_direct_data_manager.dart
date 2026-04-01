import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
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
import 'package:mdmpi_mobile_app/features/logistics/controllers/hotline_direct_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/notification_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Manager for Hotline Direct domain orchestration (save/update flows).
///
/// Responsibilities:
/// - CRUD operations for Hotline Direct requests
/// - API and local database synchronization
/// - Image and signature upload handling
/// - Category data loading
/// - Cancel remarks fetching
/// - Network connectivity validation
/// - SMS notification sending
/// - Uses StandardDeliveryRepository but filters for Hotline Direct category only
class HotlineDirectDataManager {
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

  /// Save a new Hotline Direct request from form state.
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
  Future<void> saveRequestFromForm(HotlineDirectController controller) async {
    BFullScreenLoader.openLoadingDialog(
        'Saving on process...', BImages.docerAnimation);

    if (!await validateConnectivity()) {
      BFullScreenLoader.stopLoading();
      return;
    }

    try {
      final userCtrl = Get.find<UserController>();
      final formState = controller.formState;

      // Validation
      if (formState.requestedBy.text.isEmpty) {
        BLoaders.errorSnackBar(
            title: 'Request', message: 'Please select a requested by.');
        return;
      }

      final client = formState.clientInformation.value;
      if (client == null || client.id.isEmpty) {
        BLoaders.errorSnackBar(
            title: 'Client', message: 'Please select a Client.');
        return;
      }

      final docRefs = formState.documentReferenceControllers
          .map((c) => c.text.trim())
          .toList();
      if (docRefs.isEmpty || docRefs.any((e) => e.isEmpty)) {
        BLoaders.errorSnackBar(
            title: 'Document Reference',
            message: 'Please enter at least one document reference.');
        return;
      }

      // Normalize category IDs
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
      );

      // Send notifications
      _webSocketController.sendNotificationMessage(
        NotificationModel(
            title: 'New', body: 'New Hotline Direct Request Received!'),
      );

      final managersPhoneNumber = await _dbHelper
          .getUserAndManagerPhoneNumbers(formState.requestedBy.text);

      managersPhoneNumber
          .add(await _dbHelper.getUserPhoneNumberByUsername('RLD'));

      if (newRequest.createdBy == 'MEO') {
        managersPhoneNumber
            .add(await _dbHelper.getUserPhoneNumberByUsername('LNA'));
      }

      if (newRequest.createdBy == 'AVS') {
        managersPhoneNumber
            .add(await _dbHelper.getUserPhoneNumberByUsername('RPT'));
      }

      if (newRequest.createdBy == 'RPT') {
        managersPhoneNumber
            .add(await _dbHelper.getUserPhoneNumberByUsername('AVS'));
      }

      await _messageController.sendSmsMessage(
          managersPhoneNumber, BTexts.statusNewRequest, newRequest);

      // Save to repository - include scanned items from form state
      await _repository.insertDelivery(newRequest, formState.scannedInventoryItems.toList());

      // Reload requests
      await fetchHotlineDirectRequests(
          controller, controller.useLocalStorage.value);

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
    HotlineDirectController controller,
  ) async {
    try {
      controller.isSaving.value = true;
      controller.errorMessage.value = null;
      final formState = controller.formState;
      final nowString = DateTime.now().toString();

      // Resolve mobileID
      int? resolvedMobileID;
      if (newStatus == BTexts.statusItemPrepared) {
        if (request.mobileID == null || request.mobileID == 0) {
          resolvedMobileID =
              int.tryParse(formState.mobile.text) ?? request.mobileID;
        } else {
          resolvedMobileID = request.mobileID;
        }
      } else {
        resolvedMobileID = request.mobileID;
      }

      // Get delivery image if needed
      String finalImageBase64 = request.image;
      if (newStatus == BTexts.statusDoneDelivery && request.image.isEmpty) {
        finalImageBase64 = await BImageHelperFunctions.getDeliveryImageAsBase64(
                newStatus, request.id) ??
            formState.cameraPickUpPicture.value;
      }

      // Update request with new status and status-specific fields
      final updatedRequest = request.copyWith(
        status: newStatus,
        itemPreparedBy: newStatus == BTexts.statusGettingSuppliesReady &&
                request.itemPreparedBy.isEmpty
            ? userInitial
            : request.itemPreparedBy,
        deliveredBy: newStatus == BTexts.statusItemPrepared &&
                request.deliveredBy.isEmpty
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

      print('HEY2: ${jsonEncode(updatedRequest)}');

      // Handle signature upload
      final bool signatureWasAdded = newStatus == BTexts.statusDoneDelivery &&
          request.signature.isEmpty &&
          formState.receiverSignatureBase64.value.isNotEmpty;

      if (signatureWasAdded) {
        final isConnectedForUpload =
            await NetworkManager.instance.isConnected();
        if (isConnectedForUpload) {
          await ImageRepository.instance.uploadFile(
            requestId: request.id,
            base64Image: formState.receiverSignatureBase64.string,
            type: 'Signature',
          );
        } else {
          BLoaders.warningSnackBar(
              title: 'No Internet',
              message:
                  'Signature saved locally. It will be uploaded when internet connection is available.');
        }
      }

      // Handle image proof upload
      final bool imageProofWasAdded = newStatus == BTexts.statusDoneDelivery &&
          request.image.isEmpty &&
          finalImageBase64.isNotEmpty;

      if (imageProofWasAdded) {
        final isConnectedForUpload =
            await NetworkManager.instance.isConnected();
        if (isConnectedForUpload) {
          try {
            await ImageRepository.instance.uploadFile(
              requestId: request.id,
              base64Image: finalImageBase64,
              type: 'Proof',
            );
          } catch (e) {
            BLoaders.warningSnackBar(
              title: 'Upload Failed',
              message:
                  'Image proof could not be uploaded. It will be synced when connection is available.',
            );
          }
        } else {
          BLoaders.warningSnackBar(
              title: 'No Internet',
              message:
                  'Image saved locally. It will be uploaded when internet connection is available.');
        }
      }

      if (controller.useLocalStorage.value) {
        await _dbHelper.updateRequest(requestModel: updatedRequest);
      } else {
        final isConnected = await validateConnectivity();
        if (isConnected) {
          await _repository.updateDelivery(updatedRequest, userInitial);
          await _dbHelper.updateRequest(requestModel: updatedRequest);
        } else {
          await _dbHelper.updateRequest(requestModel: updatedRequest);
          BLoaders.warningSnackBar(
            title: 'No Internet',
            message:
                'Request updated locally. Sync with server when connection returns.',
          );
        }
      }

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
        NotificationModel(
            title: 'Hotline Direct Update', body: updatedRequest.status),
      );

      final managersPhoneNumber = await _dbHelper
          .getUserAndManagerPhoneNumbers(updatedRequest.requestBy);

      managersPhoneNumber
          .add(await _dbHelper.getUserPhoneNumberByUsername('RLD'));

      if (newStatus == BTexts.statusItemPrepared &&
          request.itemPreparedBy == 'LNA') {
        managersPhoneNumber
            .add(await _dbHelper.getUserPhoneNumberByUsername('MEO'));
      }

      if (newStatus == BTexts.statusItemPrepared &&
          request.itemPreparedBy == 'RPT') {
        managersPhoneNumber
            .add(await _dbHelper.getUserPhoneNumberByUsername('AVS'));
      }

      await _messageController.sendSmsMessage(
          managersPhoneNumber, newStatus, updatedRequest);

      // Force reactive update by nullifying first, then setting the new value
      // This ensures GetX Obx widgets detect the change
      controller.currentSelectedRequest.value = null;

      // Small delay to ensure the null is registered
      await Future.delayed(const Duration(milliseconds: 10));

      // Now set the updated request - this will trigger Obx rebuild
      controller.currentSelectedRequest.value = updatedRequest;

      // Update the request in the allPendingRequests list so it reflects the new status
      final index = controller.allPendingRequests
          .indexWhere((req) => req.id == updatedRequest.id);
      if (index != -1) {
        controller.allPendingRequests[index] = updatedRequest;
        // Trigger update notification for RxList
        controller.allPendingRequests.refresh();
      }

      formState.reset();

      // Ensure filter is reapplied to update the displayed list
      controller.filterManager
          .applyFilter(controller.allPendingRequests.toList());

      BLoaders.successSnackBar(title: 'Success', message: 'Request updated');
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

  /// Cancel a Hotline Direct request with remarks.
  ///
  /// Handles both online and offline scenarios:
  /// - Online: Updates via API and local DB
  /// - Offline: Updates local DB only with sync warning
  ///
  /// Sends WebSocket notification and SMS to relevant personnel.
  Future<void> cancelRequestWithRemarks(StandardDeliveryModel request,
      String remarks, String user, HotlineDirectController controller) async {
    BFullScreenLoader.openLoadingDialog(
        'Saving on process...', BImages.docerAnimation);

    if (!await validateConnectivity()) {
      BFullScreenLoader.stopLoading();
      return;
    }

    try {
      if (!controller.useLocalStorage.value) {
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
            title: 'Hotline Direct Cancelled!', body: 'Reason: $remarks'),
      );

      List<String> managersPhoneNumber = [];

      managersPhoneNumber
          .add(await _dbHelper.getUserPhoneNumberByUsername('RLD'));

      if (request.itemPreparedBy == 'LNA') {
        managersPhoneNumber
            .add(await _dbHelper.getUserPhoneNumberByUsername('MEO'));
      }

      if (request.itemPreparedBy == 'RPT') {
        managersPhoneNumber
            .add(await _dbHelper.getUserPhoneNumberByUsername('AVS'));
      }

      await _messageController.sendSmsMessage(
          managersPhoneNumber, BTexts.statusCancelled, request);

      await fetchHotlineDirectRequests(
          controller, controller.useLocalStorage.value);

      // Ensure filter is reapplied to update the displayed list
      controller.filterManager
          .applyFilter(controller.allPendingRequests.toList());

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

  /// Fetch Hotline Direct requests and assign to the controller.
  ///
  /// Data source selection:
  /// - useLocalStorage = false: Force API fetch
  /// - useLocalStorage = true: Try local DB first, fallback to API if empty
  ///
  /// Filters for Hotline Direct category only and applies active filters after loading data.
  Future<void> fetchHotlineDirectRequests(HotlineDirectController controller,
      [bool useLocalStorage = true]) async {
    if (controller.isLoading.value) return;
    controller.isLoading.value = true;
    controller.errorMessage.value = null;
    try {
      List<StandardDeliveryModel> results;

      if (!useLocalStorage) {
        // Force API fetch
        final apiRequests = await _repository.getAllPending();
        results = apiRequests;
        await _dbHelper.insertRequests(apiRequests);
      } else {
        // Try local DB first
        results = await _dbHelper.getRequests();
        if (results.isEmpty) {
          final apiRequests = await _repository.getAllPending();
          results = apiRequests;
          await _dbHelper.insertRequests(apiRequests);
        }
      }

      // Filter for Hotline Direct category only (formCategoryID = '8')
      final hotlineDirectRequests =
          results.where((r) => r.formCategoryID == '8').toList();

      controller.allPendingRequests.assignAll(hotlineDirectRequests);

      controller.filterManager
          .applyFilter(controller.allPendingRequests.toList());

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
  /// - Form category: Prefers "hotline" or "direct" category
  /// - Item category: Prefers "reagent" category
  ///
  /// Safe to call multiple times; will not duplicate data.
  Future<void> loadCategories(HotlineDirectController controller) async {
    try {
      final items = await Get.find<ItemCategoryRepository>().getAll();
      final forms = await Get.find<FormCategoryRepository>().getAll();
      controller.formState.itemCategories.assignAll(items);
      controller.formState.formCategories.assignAll(forms);

      if (controller.formState.formCategory.text.trim().isEmpty &&
          controller.formState.formCategories.isNotEmpty) {
        final defaultForm = controller.formState.formCategories.firstWhere(
          (e) =>
              e.name.toLowerCase().contains('hotline') ||
              e.name.toLowerCase().contains('direct'),
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
      logDebug('HotlineDirectDataManager.loadCategories failed: $e');
    }
  }

  /// Fetch cancel remarks for a request.
  ///
  /// Tries local DB first, then fallback to API.
  /// Persists API results to local DB for offline access.
  Future<CancelRemarksModel> fetchCancelRemarks(String requestId) async {
    try {
      logDebug(
          '🔍 HotlineDirectDataManager: Fetching cancel remarks for: $requestId');

      // Try local DB first
      try {
        final bool exists = await _dbHelper.isRequestRemarkExisting(requestId);
        if (exists) {
          final localRemarks = await _dbHelper.getRequestRemarks(requestId);
          logDebug(
              '✅ HotlineDirectDataManager: Found local remarks: "${localRemarks.remarks}"');
          return localRemarks;
        }
      } catch (e) {
        logDebug('⚠️ HotlineDirectDataManager: Local DB read failed: $e');
      }

      // Fallback to API
      try {
        final result =
            await _cancelRemarksRepository.getCancelRemarksByRequestId(
          requestId,
          module: RequestModule.standardDelivery,
        );
        logDebug(
            '✅ HotlineDirectDataManager: API returned remarks: "${result.remarks}" date: "${result.date}"');

        if (result != CancelRemarksModel.empty) {
          // Persist to local DB
          try {
            final remarksDao = await _dbHelper.remarksDao;
            await remarksDao.insertRemark(
                requestId, result.remarks, result.date);
            logDebug(
                '💾 HotlineDirectDataManager: Persisted remarks to local DB');
          } catch (e) {
            logDebug(
                '⚠️ HotlineDirectDataManager: Failed to persist remarks: $e');
          }
          return result;
        }
        return CancelRemarksModel.empty;
      } catch (e) {
        logDebug('❌ HotlineDirectDataManager: API fetch failed: $e');
        return CancelRemarksModel.empty;
      }
    } catch (e) {
      logDebug('❌ HotlineDirectDataManager.fetchCancelRemarks FAILED: $e');
      return CancelRemarksModel.empty;
    }
  }

  /// Upload all modified Hotline Direct requests from local DB to API.
  ///
  /// Iterates through all requests in local DB and uploads any that are
  /// not in "New Request" status (i.e., have been modified).
  ///
  /// Use case: Manual sync when connectivity is restored after offline changes.
  Future<void> uploadModifiedRequest() async {
    try {
      final userCtrl = Get.find<UserController>();
      final requests = await _dbHelper.getRequests();
      // Filter for Hotline Direct category (formCategoryID = '8')
      final hotlineDirectRequests =
          requests.where((r) => r.formCategoryID == '8').toList();

      for (var request in hotlineDirectRequests) {
        if (request.status != BTexts.statusNewRequest) {
          await _repository.updateDelivery(request,userCtrl.user.value.initial);
        }
      }
      BLoaders.successSnackBar(
          title: 'Success',
          message: 'Modified Hotline Direct requests uploaded successfully');
    } catch (e) {
      BLoaders.errorSnackBar(
          title: 'Upload Failed',
          message: "Could not upload requests: ${e.toString()}");
    }
  }
}
