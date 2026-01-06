import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/cancel_remarks_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/air_sea/air_sea_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/air_sea_form_state.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/air_sea_mapper.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/item_category_repository.dart';

import '../../../base/utils/image_utils/image_conversion_base_64_to_string.dart';
import '../../../data/repositories/image/image_repository.dart';

/// Manages Air/Sea request data operations and orchestrates business logic.
/// Handles CRUD operations, status updates, form validation, and data synchronization
/// between API and local storage for Air/Sea requests.
class AirSeaDataManager {
  final AirSeaRepository _repository = Get.find<AirSeaRepository>();
  final CancelRemarksRepository _cancelRemarksRepository =
      Get.find<CancelRemarksRepository>();

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
        logDebug(
            'AirSeaDataManager: Fetching from API (useLocalStorage=$useLocalStorage,  forcing refresh)');
        results = await _repository.getAll(forceRefresh: true);
      } else {
        logDebug('AirSeaDataManager: Fetching from local DB first');
        results = await _repository.getLocalAirSeaRequests();
        if (results.isEmpty) {
          logDebug('AirSeaDataManager: Local DB empty, fetching from API');
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
    try {
      controller.isSaving.value = true;
      controller.errorMessage.value = null;
      final nowString = DateTime.now().toString();
      final userInitial = controller.userController.user.value.initial;

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
        receivedBy: newStatus == BTexts.statusReceived ||
                newStatus == BTexts.statusEndorsedToGuard &&
                    formState.receivedByController.text.isNotEmpty
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
        tripTicketNumber: newStatus == BTexts.statusDispatch &&
                formState.tripTicketController.text.isNotEmpty
            ? formState.tripTicketController.text
            : request.tripTicketNumber,
        driver: newStatus == BTexts.statusDispatch &&
                formState.driverController.text.isNotEmpty
            ? formState.driverController.text
            : request.driver,
        helper: newStatus == BTexts.statusDispatch &&
                formState.helperController.text.isNotEmpty
            ? formState.helperController.text
            : request.helper,
        mobileId: newStatus == BTexts.statusDispatch &&
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
      );

      // Handle signature upload for both "Endorsed to Guard" and "Received" statuses
      final bool signatureWasAdded =
          (newStatus == BTexts.statusEndorsedToGuard ||
                  newStatus == BTexts.statusReceived ||
                  newStatus == BTexts.statusDropOff) &&
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

      // Handle proof image upload for "Endorsed to Guard" or "Received" status
      // Upload only once: either during endorsement OR when going directly to received
      // Skip if transitioning from "Endorsed to Guard" → "Received" (already uploaded)
      final shouldUploadProof = newStatus == BTexts.statusEndorsedToGuard ||
          (newStatus == BTexts.statusReceived ||
              newStatus == BTexts.statusDropOff &&
                  request.status != BTexts.statusEndorsedToGuard);

      if (shouldUploadProof) {
        String? finalImageBase64 =
            await BImageHelperFunctions.getDeliveryImageAsBase64(
                newStatus, request.id);

        if (finalImageBase64 != null && finalImageBase64.isNotEmpty) {
          final isConnectedForUpload =
              await NetworkManager.instance.isConnected();

          if (isConnectedForUpload) {
            try {
              await ImageRepository.instance.uploadFile(
                requestId: request.id,
                base64Image: finalImageBase64,
                type: 'Proof',
              );
              logDebug(
                  'AirSeaDataManager: Proof image uploaded successfully for status: $newStatus (previous: ${request.status})');
            } catch (e) {
              logDebug('AirSeaDataManager: Image upload failed: $e');
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
        } else {
          logDebug(
              'AirSeaDataManager: No image to upload (finalImageBase64 is null or empty) for status: $newStatus');
        }
      } else {
        logDebug(
            'AirSeaDataManager: Skipping proof image upload - already uploaded during previous status transition (current: ${request.status} → new: $newStatus)');
      }

      final payload = AirSeaMapper.toUpdateDto(updated);

      await _repository.updateWithPayload(payload.toJson(), silent: true);

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
      BFullScreenLoader.stopLoading();
    }
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
}
