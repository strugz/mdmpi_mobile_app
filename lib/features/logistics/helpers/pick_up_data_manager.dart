
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/cancel_remarks_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/pick_up/pick_up_repository.dart';
import 'package:mdmpi_mobile_app/data/services/messaging_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pick_up_form_state.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/pick_up_mapper.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/item_category_repository.dart';

import '../../../base/utils/image_utils/image_conversion_base_64_to_string.dart';
import '../../../data/repositories/image/image_repository.dart';
import '../../personalization/controller/user_controller.dart';

/// Manages pick-up request data operations and orchestrates business logic.
/// Handles CRUD operations, status updates, form validation, and data synchronization
/// between API and local storage for pick-up requests.
class PickUpDataManager {
  final PickUpRepository _repository = Get.find<PickUpRepository>();
  final CancelRemarksRepository _cancelRemarksRepository =
      Get.find<CancelRemarksRepository>();
  final MessagingController _messageController =
      Get.find<MessagingController>();

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

  /// Fetches pick-up requests from local database or API based on storage preference.
  /// Attempts local DB first if [useLocalStorage] is true; falls back to API if empty.
  /// Applies active filters after loading data and updates the controller state.
  ///
  /// [controller] The pick-up controller to update with fetched data
  /// [useLocalStorage] If true, prefer local DB; if false, fetch directly from API
  Future<void> fetchPickUps(
      PickUpController controller, bool useLocalStorage) async {
    if (controller.isLoading.value) return;
    controller.isLoading.value = true;
    controller.errorMessage.value = null;
    try {
      List<PickUpModel> results;
      if (!useLocalStorage) {
        logDebug(
            'PickUpDataManager: Fetching from API ($useLocalStorage=false, forcing refresh)');
        results = await _repository.getAll(forceRefresh: true);
      } else {
        logDebug('PickUpDataManager: Fetching from local DB first');
        results = await _repository.getLocalPickUps();
        if (results.isEmpty) {
          logDebug('PickUpDataManager: Local DB empty, fetching from API');
          results = await _repository.getAll();
        } else {
          logDebug(
              'PickUpDataManager: Loaded ${results.length} items from local DB');
        }
      }

      controller.pickUps.assignAll(results);
      logDebug(
          'PickUpDataManager: Assigned ${results.length} pick-ups to controller');

      controller.filterManager.applyFilter(controller.pickUps.toList());
    } catch (e) {
      controller.errorMessage.value = e.toString();
      logDebug('PickUpDataManager.fetchPickUps error: $e');
      BLoaders.errorSnackBar(title: 'Error', message: e.toString());
    } finally {
      controller.isLoading.value = false;
    }
  }

  /// Creates and saves a new pick-up request from form data.
  /// Validates client selection, document references, pick-up date, and item category.
  /// Displays loading dialog during save operation and shows appropriate feedback.
  ///
  /// Validation checks:
  /// - Client must be selected
  /// - At least one document reference required
  /// - Pick-up date must be provided
  /// - Item category is normalized to ID format
  ///
  /// [controller] The pick-up controller containing form state and data
  Future<void> saveRequestFromForm(PickUpController controller) async {
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
        BFullScreenLoader.stopLoading(); // ✅ Stop loading before return
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

      final model = PickUpModel(
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
      controller.pickUps.assignAll(refreshedList);

      // Reapply filters to update the filtered view
      controller.filterManager.applyFilter(controller.pickUps.toList());

      controller.errorMessage.value = null;
    } catch (e) {
      controller.errorMessage.value = 'An error occurred: $e';
      BLoaders.errorSnackBar(
          title: 'Save Failed', message: 'An error occurred: $e');
    } finally {
      BFullScreenLoader.stopLoading();
    }
  }

  /// Inserts a new pick-up request model and refreshes the controller list.
  /// Prevents duplicate saves by checking if a save operation is already in progress.
  /// Shows success or error feedback and updates the pick-up list on completion.
  ///
  /// [model] The pick-up model to insert
  /// [controller] The pick-up controller to refresh after insertion
  Future<void> insertPickUpModel(
      PickUpModel model, PickUpController controller) async {
    if (controller.isSaving.value) return;
    controller.isSaving.value = true;
    controller.errorMessage.value = null;
    try {
      await _repository.insert(model, silent: true);
      await fetchPickUps(controller, controller.useLocalStorage.value);
      BLoaders.successSnackBar(title: 'Success', message: 'Request created');
    } catch (e) {
      controller.errorMessage.value = e.toString();
      BLoaders.errorSnackBar(
          title: 'Save Failed', message: 'An error occurred: $e');
    } finally {
      controller.isSaving.value = false;
    }
  }

  /// Updates the status of a pick-up request with automatic field population.
  /// Handles status-specific logic including timestamps, signatures, and proof images.
  ///
  /// Status transitions:
  /// - "Item Prepared": Sets itemPreparedAt timestamp and preparedBy field
  /// - "Item Packed": Sets itemPreparedEndAt timestamp and releasedBy field
  /// - "Received": Sets receivedBy, uploads signature and proof images
  ///
  /// Images and signatures are uploaded to the server if connected, otherwise saved locally.
  ///
  /// [request] The pick-up request to update
  /// [newStatus] The new status to set
  /// [controller] The pick-up controller for state management
  /// [formState] Form state containing signature and field values
  Future<void> updateRequestStatus(PickUpModel request, String newStatus,
      PickUpController controller, PickUpFormState formState) async {
    try {
      controller.isSaving.value = true;
      controller.errorMessage.value = null;
      final nowString = DateTime.now().toString();

      final updated = request.copyWith(
        status: newStatus,
        preparedBy: newStatus == BTexts.statusGettingSuppliesReady
            ? controller.userController.user.value.initial
            : request.preparedBy,
        itemPreparedAt: newStatus == BTexts.statusGettingSuppliesReady &&
                request.itemPreparedAt.isEmpty
            ? nowString
            : request.itemPreparedAt,
        itemPreparedEndAt: newStatus == BTexts.statusItemPacked &&
                request.itemPreparedEndAt.isEmpty
            ? nowString
            : request.itemPreparedEndAt,
        releasedBy:
            newStatus == BTexts.statusItemPacked && request.releasedBy.isEmpty
                ? controller.userController.user.value.initial
                : request.releasedBy,
        receivedBy:
            newStatus == BTexts.statusReceived && request.receivedBy.isEmpty
                ? controller.formState.receivedByController.text
                : request.receivedBy,
      );

      final bool signatureWasAdded = newStatus == BTexts.statusReceived &&
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

      if (newStatus == BTexts.statusReceived) {
        String? finalImageBase64 =
            await BImageHelperFunctions.getDeliveryImageAsBase64(
                newStatus, request.id);

        // ✅ Safe null check - prevents crash
        if (finalImageBase64!.isNotEmpty) {
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
              logDebug('PickUpDataManager: Image upload failed: $e');
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
              'PickUpDataManager: No image to upload (finalImageBase64 is null or empty)');
        }
      }

      final payload = PickUpMapper.toUpdateDto(updated);

      await _repository.updateWithPayload(payload.toJson(), silent: true);
      await _messageController.sendSmsMessage(newStatus, updated);

      await controller.loadPickUps();

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

  /// Cancels a pick-up request with remarks via API.
  /// Validates connectivity, calls the cancel API endpoint, and refreshes the pick-up list.
  /// Shows loading dialog during operation and displays success/error feedback.
  ///
  /// [request] The pick-up request to cancel
  /// [remarks] Cancellation remarks/reason
  /// [user] User identifier performing the cancellation
  /// [controller] The pick-up controller for state management
  Future<void> cancelRequestWithRemarks(PickUpModel request, String remarks,
      String user, PickUpController controller) async {
    BFullScreenLoader.openLoadingDialog(
        'Saving on process...', BImages.docerAnimation);

    if (!await validateConnectivity()) {
      BFullScreenLoader.stopLoading();
      return;
    }

    try {
      await _repository.cancelPickUpAPI(request.id, remarks, user,
          silent: true);
      await _messageController.sendSmsMessage(
        BTexts.statusCancelled,
        request,
        overrideCancelRemarks: remarks,
      );
      await fetchPickUps(controller, controller.useLocalStorage.value);
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
  /// [controller] The pick-up controller to populate with category data
  Future<void> loadCategories(PickUpController controller) async {
    try {
      final items = await Get.find<ItemCategoryRepository>().getAll();
      controller.formState.itemCategories.assignAll(items);

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
      logDebug('PickUpDataManager.loadCategories failed: $e');
    }
  }

  /// Fetches cancel remarks for a pick-up request from the cancel remarks repository.
  /// Uses the shared CancelRemarksRepository with pick-up module specification.
  /// Returns empty model if remarks are not found or API call fails.
  ///
  /// [requestId] The pick-up request ID to fetch remarks for
  /// Returns [CancelRemarksModel] containing remarks and date, or empty model on error
  Future<CancelRemarksModel> fetchCancelRemarks(String requestId) async {
    try {
      logDebug('🔍 PickUpDataManager: Fetching cancel remarks for: $requestId');
      final result = await _cancelRemarksRepository.getCancelRemarksByRequestId(
        requestId,
        module: RequestModule.pickUp, // Specify pick-up module
      );
      logDebug(
          '✅ PickUpDataManager: API returned remarks: "${result.remarks}" date: "${result.date}"');
      if (result.remarks.isEmpty) {
        logDebug(
            '⚠️ PickUpDataManager: Remarks are EMPTY! Check if API endpoint exists and returns data.');
      }
      return result;
    } catch (e) {
      logDebug('❌ PickUpDataManager.fetchCancelRemarks FAILED: $e');
      logDebug(
          '💡 Tip: Check if GET /api4/RequestPickUp/cancel/$requestId endpoint exists');
      return CancelRemarksModel.empty;
    }
  }
}
