// ...existing code...

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/cancel_remarks_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/air_sea/air_sea_repository.dart';
import 'package:mdmpi_mobile_app/data/services/messaging_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/air_sea_form_state.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/proof_image_outbox_uploader.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_status_stages_model.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/air_sea_mapper.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/item_category_repository.dart';

import '../../../base/utils/image_utils/image_conversion_base_64_to_string.dart';
import '../../../data/models/realtime_location_model.dart';
import '../../../data/repositories/image/image_repository.dart';

/// Manages Air/Sea request data operations and orchestrates business logic.
/// Handles CRUD operations, status updates, form validation, and data synchronization
/// between API and local storage for Air/Sea requests.
class AirSeaDataManager {
  static const String _latestRealtimeLocationKey =
      'realtime_location_saver_latest';

  final AirSeaRepository _repository = Get.find<AirSeaRepository>();
  final CancelRemarksRepository _cancelRemarksRepository =
      Get.find<CancelRemarksRepository>();
  final MessagingController _messageController =
      Get.find<MessagingController>();

  /// Public getter for repository access (used by controller for direct operations)
  AirSeaRepository get airSeaRepo => _repository;

  // ========================================================================
  // VALIDATION METHODS
  // ========================================================================

  /// Validates network connectivity before performing operations.
  /// Shows a warning snackbar if no internet connection is available.
  /// Returns true if connected, false otherwise.
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

  // ========================================================================
  // CRUD OPERATIONS
  // ========================================================================

  /// Fetches Air/Sea requests from local database or API based on storage preference.
  /// Attempts local DB first if [useLocalStorage] is true; falls back to API if empty.
  /// Applies active filters after loading data and updates the controller state.
  ///
  /// [controller] The Air/Sea controller to update with fetched data
  /// [useLocalStorage] If true, prefer local DB; if false, fetch directly from API
  /// [forceRefresh] If true, forces fetching from API regardless of useLocalStorage
  Future<void> fetchAirSeaRequests(
      AirSeaController controller, bool useLocalStorage) async {
    if (controller.isLoading.value) return;
    controller.isLoading.value = true;
    controller.errorMessage.value = null;
    try {
      List<AirSeaModel> results;
      if (!useLocalStorage) {
        results = await _repository.getAll(forceRefresh: true);
      } else {
        results = await _repository.getLocalAirSeaRequests();
        if (results.isEmpty) {
          results = await _repository.getAll();
        } else {
          logDebug(
              'AirSeaDataManager: Loaded ${results.length} items from local DB');
        }
      }

      controller.airSeaRequests.assignAll(results);

      controller.filterManager.applyFilter(controller.airSeaRequests.toList());
    } catch (e) {
      controller.errorMessage.value = e.toString();
      logDebug('AirSeaDataManager.fetchAirSeaRequests failed: $e');
    } finally {
      controller.isLoading.value = false;
    }
  }

  /// Hard reset Air/Sea data by clearing local cache and forcing a fresh API load.
  Future<void> hardResetAirSeaRequests(AirSeaController controller) async {
    if (controller.isLoading.value) return;

    if (!await validateConnectivity()) {
      return;
    }

    controller.isLoading.value = true;
    controller.errorMessage.value = null;

    try {
      await _repository.clearLocalData();
      final results = await _repository.getAll(
        forceRefresh: true,
        allowLocalFallback: false,
      );

      controller.airSeaRequests.assignAll(results);
      controller.filterManager.applyFilter(controller.airSeaRequests.toList());

      BLoaders.successSnackBar(
        title: 'Success',
        message: 'Air/Sea data refreshed successfully',
      );
    } catch (e) {
      controller.errorMessage.value = e.toString();
      BLoaders.errorSnackBar(title: 'Error', message: e.toString());
    } finally {
      controller.isLoading.value = false;
    }
  }

  /// Creates and saves a new Air/Sea request from form data.
  /// Validates client selection, document references, pick-up date, and item category.
  /// Displays loading dialog during save operation and shows appropriate feedback.
  ///
  /// Validation checks:
  /// - Client must be selected
  /// - At least one document reference required
  /// - Pick-up date must be provided
  /// - Item category is normalized to ID format
  ///
  /// [controller] The Air/Sea controller containing form state and data
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

      final client = stdController.formState.clientInformation.value;
      if (client == null || client.id.isEmpty) {
        controller.errorMessage.value = 'Please select a Client.';
        BLoaders.errorSnackBar(
            title: 'Client', message: 'Please select a Client.');
        BFullScreenLoader.stopLoading();
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
        BFullScreenLoader.stopLoading();
        return;
      }

      if (controller.formState.datePickUpController.text.trim().isEmpty) {
        controller.errorMessage.value = 'Please pick a pick-up date.';
        BLoaders.errorSnackBar(
            title: 'Pick-Up Date', message: 'Please pick a pick-up date.');
        BFullScreenLoader.stopLoading();
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

      final normalizedItemCategory = ensureCategoryId(
          controller.formState.itemCategoryController,
          controller.formState.itemCategories);

      final userCtrl = Get.find<UserController>();

      final model = AirSeaModel(
        clientId: client.id,
        client: client,
        itemCategoryId: normalizedItemCategory,
        datePickUp: controller.formState.datePickUpController.text,
        status: 'New Request',
        createdBy: userCtrl.user.value.initial,
        documentReference: docRefs,
      );

      // Insert via API (also saves to local DB)
      await _repository.insert(model, silent: true);
      await _messageController.sendSmsMessage(BTexts.statusNewRequest, model);

      // Force refresh from API to ensure we have the latest data with proper IDs
      final refreshedList = await _repository.refreshFromApi();

      // Update controller's list
      controller.airSeaRequests.clear();
      controller.airSeaRequests.addAll(refreshedList);

      // Reapply filters to update the filtered view
      controller.filterManager.applyFilter(controller.airSeaRequests.toList());

      controller.errorMessage.value = null;
    } catch (e) {
      controller.errorMessage.value = 'An error occurred: $e';
      BLoaders.errorSnackBar(
          title: 'Save Failed', message: 'An error occurred: $e');
    } finally {
      BFullScreenLoader.stopLoading();
    }
  }

  /// Inserts a new Air/Sea request model and refreshes the controller list.
  /// Prevents duplicate saves by checking if a save operation is already in progress.
  /// Shows success or error feedback and updates the Air/Sea list on completion.
  ///
  /// [model] The Air/Sea model to insert
  /// [controller] The Air/Sea controller to refresh after insertion
  Future<void> insertAirSeaModel(AirSeaModel model, dynamic controller) async {
    if (controller.isSaving.value) return;
    controller.isSaving.value = true;
    controller.errorMessage.value = null;
    try {
      await _repository.insert(model, silent: true);
      await fetchAirSeaRequests(controller, controller.useLocalStorage.value);
      BLoaders.successSnackBar(title: 'Success', message: 'Request created');
    } catch (e) {
      controller.errorMessage.value = e.toString();
      BLoaders.errorSnackBar(
          title: 'Save Failed', message: 'An error occurred: $e');
    } finally {
      controller.isSaving.value = false;
    }
  }

  /// Updates the status of an Air/Sea request with automatic field population.
  /// Handles status-specific logic including timestamps, signatures, and proof images.
  ///
  /// Status transitions:
  /// - "Item Prepared": Sets itemPreparedAt timestamp and preparedBy field
  /// - "Item Packed": Sets itemPreparedEndAt timestamp
  /// - "Received": Uploads signature and proof images
  ///
  /// Images and signatures are uploaded to the server if connected, otherwise saved locally.
  ///
  /// [request] The Air/Sea request to update
  /// [newStatus] The new status to set
  /// [controller] The Air/Sea controller for state management
  /// [formState] Form state containing signature and field values
  Future<void> updateRequestStatus(AirSeaModel request, String newStatus,
      dynamic controller, AirSeaFormState formState) async {
    if (!await _validateRequiredUpdateFields(
      request: request,
      newStatus: newStatus,
      formState: formState,
    )) {
      return;
    }

    try {
      controller.isSaving.value = true;
      controller.errorMessage.value = null;
      final nowString = DateTime.now().toString();
      final userInitial = controller.userController.user.value.initial;

      final RealtimeLocationModel? latestRealtimeLocation =
          _readLatestRealtimeLocation();

      if (newStatus == BTexts.statusProvincialInTransit &&
          latestRealtimeLocation == null) {
        controller.errorMessage.value =
            'No realtime location found. Please enable realtime location saver and wait for a location update before starting transit.';
        BLoaders.errorSnackBar(
          title: 'Validation Error',
          message: controller.errorMessage.value!,
        );
        return;
      }

      final updated = request.copyWith(
        status: newStatus,
        preparedBy: newStatus == BTexts.statusGettingSuppliesReady
            ? userInitial
            : request.preparedBy,
        itemPreparedAt: newStatus == BTexts.statusGettingSuppliesReady &&
                request.itemPreparedAt.isEmpty
            ? nowString
            : request.itemPreparedAt,
        itemPreparedEndAt: newStatus == BTexts.statusItemPacked &&
                request.itemPreparedEndAt.isEmpty
            ? nowString
            : request.itemPreparedEndAt,
        receivedBy: ((newStatus == BTexts.statusReceived ||
                    newStatus == BTexts.statusEndorsedToGuard) &&
                formState.receivedByController.text.isNotEmpty)
            ? formState.receivedByController.text
            : (request.receivedBy.isEmpty ? userInitial : request.receivedBy),
        waybillNumber: newStatus == BTexts.statusReceived &&
                formState.waybillNumberController.text.isNotEmpty
            ? formState.waybillNumberController.text
            : request.waybillNumber,
        receivedAt:
            newStatus == BTexts.statusReceived && request.receivedAt.isEmpty
                ? nowString
                : request.receivedAt,
        tripTicketNumber: newStatus == BTexts.statusForDispatch &&
                formState.tripTicketController.text.isNotEmpty
            ? formState.tripTicketController.text
            : request.tripTicketNumber,
        driver: newStatus == BTexts.statusForDispatch &&
                formState.driverController.text.isNotEmpty
            ? formState.driverController.text
            : request.driver,
        helper: newStatus == BTexts.statusForDispatch &&
                formState.helperController.text.isNotEmpty
            ? formState.helperController.text
            : request.helper,
        mobileId: newStatus == BTexts.statusForDispatch &&
                formState.vehicleController.text.isNotEmpty
            ? int.tryParse(formState.vehicleController.text)
            : request.mobileId,
        dispatchedAt:
            newStatus == BTexts.statusDispatch && request.dispatchedAt.isEmpty
                ? nowString
                : request.dispatchedAt,
        dropOffAt:
            newStatus == BTexts.statusDropOff && request.dropOffAt.isEmpty
                ? nowString
                : request.dropOffAt,
        provincialReceiverName: newStatus == BTexts.statusProvincialDelivered &&
                formState.provincialDeliveredToController.text.isNotEmpty
            ? formState.provincialDeliveredToController.text.trim()
            : request.provincialReceiverName,
        provincialPickUpBy: newStatus == BTexts.statusProvincialPickUp
            ? userInitial
            : request.provincialPickUpBy,
        provincialPickUpAt: newStatus == BTexts.statusProvincialPickUp
            ? nowString
            : request.provincialPickUpAt,
        provincialInTransitAt: newStatus == BTexts.statusProvincialInTransit
            ? nowString
            : request.provincialInTransitAt,
        provincialInTransitLocation: newStatus ==
                BTexts.statusProvincialInTransit
            ? (latestRealtimeLocation != null
                ? '${latestRealtimeLocation.latitude},${latestRealtimeLocation.longitude}'
                : request.provincialInTransitLocation)
            : request.provincialInTransitLocation,
        provincialDeliveredEndAt: newStatus == BTexts.statusProvincialDelivered
            ? nowString
            : request.provincialDeliveredEndAt,
        provincialDeliveredLocation: newStatus ==
                BTexts.statusProvincialDelivered
            ? (latestRealtimeLocation != null
                ? '${latestRealtimeLocation.latitude},${latestRealtimeLocation.longitude}'
                : request.provincialDeliveredLocation)
            : request.provincialDeliveredLocation,
      );

      await _handleStatusUploads(
        request: request,
        newStatus: newStatus,
        formState: formState,
      );

      final payload = AirSeaMapper.toUpdateDto(updated, userInitial);

      await _repository.updateWithPayload(payload.toJson(), silent: true);
      await _messageController.sendSmsMessage(newStatus, updated);

      await controller.loadAirSeaRequests();

      BLoaders.successSnackBar(title: 'Success', message: 'Request updated');
    } catch (e) {
      controller.errorMessage.value = e.toString();
      BLoaders.errorSnackBar(
          title: 'Error',
          message: controller.errorMessage.value ?? 'Failed to update');
    } finally {
      formState.reset();
      controller.isSaving.value = false;
    }
  }

  Future<void> _handleStatusUploads({
    required AirSeaModel request,
    required String newStatus,
    required AirSeaFormState formState,
  }) async {
    final signatureBase64 = formState.receiverSignatureBase64.value;

    await _uploadSignatureIfNeeded(
      shouldUpload: _shouldUploadStandardSignature(
        newStatus: newStatus,
        signatureBase64: signatureBase64,
      ),
      requestId: request.id,
      signatureBase64: signatureBase64,
      type: 'Signature',
    );

    final shouldUploadProof = _shouldUploadStandardProof(
      currentStatus: request.status,
      newStatus: newStatus,
    );

    if (shouldUploadProof) {
      await _uploadProofImageIfNeeded(
        requestId: request.id,
        newStatus: newStatus,
        imageLookupKey: request.id,
        type: 'Proof',
        uploadFailureMessage:
            'Image proof could not be uploaded. It will be synced when connection is available.',
        offlineMessage:
            'Image saved locally. It will be uploaded when internet connection is available.',
        emptyImageLogMessage:
            'AirSeaDataManager: No image to upload (finalImageBase64 is null or empty) for status: $newStatus',
      );
    } else {
      logDebug(
          'AirSeaDataManager: Skipping proof image upload - already uploaded during previous status transition (current: ${request.status} → new: $newStatus)');
    }

    await _uploadProvincialProofIfNeeded(
      requestId: request.id,
      newStatus: newStatus,
    );

    await _uploadSignatureIfNeeded(
      shouldUpload: newStatus == BTexts.statusProvincialDelivered &&
          signatureBase64.isNotEmpty,
      requestId: request.id,
      signatureBase64: signatureBase64,
      type: 'Provincial_Signature',
    );
  }

  bool _shouldUploadStandardSignature({
    required String newStatus,
    required String signatureBase64,
  }) {
    if (signatureBase64.isEmpty) {
      return false;
    }

    return newStatus == BTexts.statusEndorsedToGuard ||
        newStatus == BTexts.statusReceived ||
        newStatus == BTexts.statusDropOff;
  }

  bool _shouldUploadStandardProof({
    required String currentStatus,
    required String newStatus,
  }) {
    return newStatus == BTexts.statusEndorsedToGuard ||
        newStatus == BTexts.statusReceived ||
        (newStatus == BTexts.statusDropOff &&
            currentStatus != BTexts.statusEndorsedToGuard);
  }

  Future<void> _uploadProvincialProofIfNeeded({
    required String requestId,
    required String newStatus,
  }) async {
    if (newStatus == BTexts.statusProvincialPickUp) {
      await _uploadProofImageIfNeeded(
        requestId: requestId,
        newStatus: newStatus,
        imageLookupKey: '${requestId}_provincial_pick_up',
        type: 'Provincial_PickUp_Proof',
        uploadFailureMessage:
            'Provincial pick-up proof image could not be uploaded. It will be synced when connection is available.',
        showOfflineWarning: false,
      );
    }

    if (newStatus == BTexts.statusProvincialDelivered) {
      await _uploadProofImageIfNeeded(
        requestId: requestId,
        newStatus: newStatus,
        imageLookupKey: '${requestId}_provincial_delivery',
        type: 'Provincial_Delivery_Proof',
        uploadFailureMessage:
            'Provincial delivery proof image could not be uploaded. It will be synced when connection is available.',
        showOfflineWarning: false,
      );
    }
  }

  Future<void> _uploadSignatureIfNeeded({
    required bool shouldUpload,
    required String requestId,
    required String signatureBase64,
    required String type,
  }) async {
    if (!shouldUpload) {
      return;
    }

    final isConnectedForUpload = await NetworkManager.instance.isConnected();
    if (isConnectedForUpload) {
      await ImageRepository.instance.uploadFile(
        requestId: requestId,
        base64Image: signatureBase64,
        type: type,
      );
      return;
    }

    BLoaders.warningSnackBar(
      title: 'No Internet',
      message:
          'Signature saved locally. It will be uploaded when internet connection is available.',
    );
  }

  Future<void> _uploadProofImageIfNeeded({
    required String requestId,
    required String newStatus,
    required String imageLookupKey,
    required String type,
    required String uploadFailureMessage,
    String? offlineMessage,
    String? emptyImageLogMessage,
    bool showOfflineWarning = true,
  }) async {
    final imageBase64 = await BImageHelperFunctions.getDeliveryImageAsBase64(
      newStatus,
      imageLookupKey,
    );

    if (imageBase64 == null || imageBase64.isEmpty) {
      if (emptyImageLogMessage != null) {
        logDebug(emptyImageLogMessage);
      }
      return;
    }

    await ProofImageOutboxUploader.instance.uploadOrQueue(
      requestId: requestId,
      imageLookupKey: imageLookupKey,
      base64Image: imageBase64,
      type: type,
      uploadFailureMessage: uploadFailureMessage,
      offlineMessage: offlineMessage ??
          'Image saved locally. It will be uploaded when internet connection is available.',
      showOfflineWarning: showOfflineWarning,
    );
  }

  /// Cancels an Air/Sea request with remarks via API.
  /// Validates connectivity, calls the cancel API endpoint, and refreshes the Air/Sea list.
  /// Shows loading dialog during operation and displays success/error feedback.
  ///
  /// [request] The Air/Sea request to cancel
  /// [remarks] Cancellation remarks/reason
  /// [user] User identifier performing the cancellation
  /// [controller] The Air/Sea controller for state management
  Future<void> cancelRequestWithRemarks(AirSeaModel request, String remarks,
      String user, dynamic controller) async {
    BFullScreenLoader.openLoadingDialog(
        'Saving on process...', BImages.docerAnimation);

    if (!await validateConnectivity()) {
      BFullScreenLoader.stopLoading();
      return;
    }

    try {
      await _repository.cancelAirSeaAPI(request.id, remarks, user,
          silent: true);
      await _messageController.sendSmsMessage(
        BTexts.statusCancelled,
        request,
        overrideCancelRemarks: remarks,
      );
      await fetchAirSeaRequests(controller, controller.useLocalStorage.value);
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

  // ========================================================================
  // DATA LOADING & UTILITY METHODS
  // ========================================================================

  /// Loads item categories from repository and populates the controller caches.
  /// Sets a default category (preferring 'reagent' if available) when no category is selected.
  /// Stores category ID in the controller for use with BDropDownDynamicList.
  ///
  /// [controller] The Air/Sea controller to populate with category data
  Future<void> loadCategories(dynamic controller) async {
    try {
      final items = await Get.find<ItemCategoryRepository>().getAll();
      controller.formState.itemCategories.clear();
      controller.formState.itemCategories.addAll(items);

      if (controller.formState.itemCategoryController.text.trim().isEmpty &&
          controller.formState.itemCategories.isNotEmpty) {
        final defaultItem = controller.formState.itemCategories.firstWhere(
          (e) => e.name.toLowerCase().contains('reagent'),
          orElse: () => controller.formState.itemCategories.first,
        );
        // Store the ID in the controller; BDropDownDynamicList stores IDs.
        controller.formState.itemCategoryController.text = defaultItem.id;
      }
    } catch (e) {
      logDebug('AirSeaDataManager.loadCategories failed: $e');
    }
  }

  /// Fetches cancel remarks for an Air/Sea request from the cancel remarks repository.
  /// Uses the shared CancelRemarksRepository with Air/Sea module specification.
  /// Returns empty model if remarks are not found or API call fails.
  ///
  /// [requestId] The Air/Sea request ID to fetch remarks for
  /// Returns [CancelRemarksModel] containing remarks and date, or empty model on error
  Future<CancelRemarksModel> fetchCancelRemarks(String requestId) async {
    try {
      logDebug('🔍 AirSeaDataManager: Fetching cancel remarks for: $requestId');
      final result = await _cancelRemarksRepository.getCancelRemarksByRequestId(
        requestId,
        module: RequestModule.airSea, // Specify Air/Sea module
      );
      logDebug(
          '✅ AirSeaDataManager: API returned remarks: "${result.remarks}" date: "${result.date}"');
      if (result.remarks.isEmpty) {
        logDebug(
            '⚠️ AirSeaDataManager: Remarks are EMPTY! Check if API endpoint exists and returns data.');
      }
      return result;
    } catch (e) {
      logDebug('❌ AirSeaDataManager.fetchCancelRemarks FAILED: $e');
      logDebug(
          '💡 Tip: Check if GET /api4/RequestAirSea/cancel/$requestId endpoint exists');
      return CancelRemarksModel.empty;
    }
  }

  Future<bool> _validateRequiredUpdateFields({
    required AirSeaModel request,
    required String newStatus,
    required AirSeaFormState formState,
  }) async {
    if (newStatus == BTexts.statusEndorsedToGuard) {
      return _validateNamedSignature(
        name: request.receivedBy.trim().isNotEmpty
            ? request.receivedBy
            : formState.receivedByController.text,
        nameMessage: 'Please enter Guard Name',
        signatureMessage: 'Please capture Guard Signature',
        formState: formState,
      );
    }

    if (newStatus == BTexts.statusReceived) {
      // if (!_validateNamedSignature(
      //   name: request.receivedBy.trim().isNotEmpty
      //       ? request.receivedBy
      //       : formState.receivedByController.text,
      //   nameMessage: 'Please enter Receiver Name',
      //   signatureMessage: 'Please capture Receiver Signature',
      //   formState: formState,
      // )) {
      //   return false;
      // }
      final waybill = request.waybillNumber.trim().isNotEmpty
          ? request.waybillNumber
          : formState.waybillNumberController.text;
      if (waybill.trim().isEmpty) {
        BLoaders.errorSnackBar(
          title: 'Validation Error',
          message: 'Please enter Waybill Number',
        );
        return false;
      }
      return true;
    }

    if (newStatus == BTexts.statusForDispatch) {
      return _validateDispatchInfo(request, formState);
    }

    if (newStatus == BTexts.statusDropOff) {
      if (!_validateNamedSignature(
        name: request.receivedBy.trim().isNotEmpty
            ? request.receivedBy
            : formState.receivedByController.text,
        nameMessage: 'Please enter Receiver Name',
        signatureMessage: 'Please capture Receiver Signature',
        formState: formState,
      )) {
        return false;
      }
      return _validateProofImage(
        newStatus: newStatus,
        imageLookupKey: request.id,
        formImagePath: formState.cameraDropOffPicture.value,
        message: 'Please capture proof image for drop off',
      );
    }

    if (newStatus == BTexts.statusProvincialPickUp) {
      return _validateProofImage(
        newStatus: newStatus,
        imageLookupKey: '${request.id}_provincial_pick_up',
        formImagePath: formState.cameraPickUpPicture.value,
        message: 'Please capture or attach pick-up proof image',
      );
    }

    if (newStatus == BTexts.statusProvincialInTransit) {
      return _validateLatestRealtimeLocation();
    }

    if (newStatus == BTexts.statusProvincialDelivered) {
      if (formState.provincialDeliveredToController.text.trim().isEmpty &&
          request.provincialReceiverName.trim().isEmpty) {
        BLoaders.errorSnackBar(
          title: 'Validation Error',
          message: 'Please enter the client contact person name',
        );
        return false;
      }
      if (!_hasSignature(formState)) {
        BLoaders.errorSnackBar(
          title: 'Validation Error',
          message: 'Please capture recipient signature',
        );
        return false;
      }
      if (!await _validateProofImage(
        newStatus: newStatus,
        imageLookupKey: '${request.id}_provincial_delivery',
        formImagePath: formState.cameraDropOffPicture.value,
        message: 'Please capture proof image for delivery',
      )) {
        return false;
      }
      return _validateLatestRealtimeLocation();
    }

    return true;
  }

  bool _validateNamedSignature({
    required String name,
    required String nameMessage,
    required String signatureMessage,
    required AirSeaFormState formState,
  }) {
    if (name.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: nameMessage,
      );
      return false;
    }
    if (!_hasSignature(formState)) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: signatureMessage,
      );
      return false;
    }
    return true;
  }

  bool _validateDispatchInfo(
    AirSeaModel request,
    AirSeaFormState formState,
  ) {
    final tripTicket = request.tripTicketNumber.trim().isNotEmpty
        ? request.tripTicketNumber
        : formState.tripTicketController.text;
    final driver = request.driver.trim().isNotEmpty
        ? request.driver
        : formState.driverController.text;
    final helper = request.helper.trim().isNotEmpty
        ? request.helper
        : formState.helperController.text;
    final hasVehicle = (request.mobileId != null && request.mobileId != 0) ||
        formState.vehicleController.text.trim().isNotEmpty;

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
    if (helper.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please select Helper',
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

  Future<bool> _validateProofImage({
    required String newStatus,
    required String imageLookupKey,
    required String formImagePath,
    required String message,
  }) async {
    final proofImage = await BImageHelperFunctions.getDeliveryImageAsBase64(
          newStatus,
          imageLookupKey,
        ) ??
        formImagePath;

    if (proofImage.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: message,
      );
      return false;
    }
    return true;
  }

  bool _validateLatestRealtimeLocation() {
    if (_readLatestRealtimeLocation() != null) {
      return true;
    }
    BLoaders.errorSnackBar(
      title: 'Validation Error',
      message:
          'No realtime location found. Please enable realtime location saver and wait for a location update before starting transit.',
    );
    return false;
  }

  bool _hasSignature(AirSeaFormState formState) {
    return formState.receiverSignatureBase64.value.trim().isNotEmpty ||
        (formState.receiverSignatureBytes.value?.isNotEmpty ?? false);
  }

  /// Fetches status/history stages for a specific Air/Sea request.
  /// Returns an empty list on error and logs warnings. This method delegates
  /// to `AirSeaRepository.fetchHistoryByRequestId` and keeps behavior consistent
  /// with other fetch helpers in this manager.
  Future<List<AirSeaStatusStagesModel>> fetchHistory(String requestId,
      {bool silent = false}) async {
    try {
      logDebug('🔍 AirSeaDataManager: Fetching history for: $requestId');
      final result =
          await _repository.fetchHistoryByRequestId(requestId, silent: silent);
      logDebug(
          '✅ AirSeaDataManager: Retrieved ${result.length} history items for $requestId');
      return result;
    } catch (e) {
      logDebug('❌ AirSeaDataManager.fetchHistory FAILED: $e');
      return <AirSeaStatusStagesModel>[];
    }
  }

  /// Reads and validates the latest realtime location sample from local storage.
  RealtimeLocationModel? _readLatestRealtimeLocation() {
    final dynamic latestRaw = GetStorage().read(_latestRealtimeLocationKey);
    if (latestRaw is! Map) {
      return null;
    }

    final latestMap = Map<String, dynamic>.from(latestRaw);
    final latitude = _tryParseCoordinate(latestMap['latitude']);
    final longitude = _tryParseCoordinate(latestMap['longitude']);

    if (latitude == null || longitude == null) {
      return null;
    }

    if (latitude < -90 || latitude > 90) {
      return null;
    }

    if (longitude < -180 || longitude > 180) {
      return null;
    }

    return RealtimeLocationModel.fromJson(latestMap);
  }

  /// Safely parses a coordinate value from dynamic storage data.
  double? _tryParseCoordinate(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
