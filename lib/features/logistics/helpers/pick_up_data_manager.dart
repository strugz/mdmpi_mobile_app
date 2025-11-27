import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/cancel_remarks_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/pick_up/pick_up_repository.dart';
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

/// Manager for Pick-Up domain orchestration (save/update flows).
class PickUpDataManager {
  final PickUpRepository _repository = Get.find<PickUpRepository>();
  final CancelRemarksRepository _cancelRemarksRepository = Get.find<CancelRemarksRepository>();

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

  /// Save a new pick-up request using values from controllers and shared form state.
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

      if (controller.formState.datePickUpController.text.trim().isEmpty) {
        controller.errorMessage.value = 'Please pick a pick-up date.';
        BLoaders.errorSnackBar(
            title: 'Pick-Up Date', message: 'Please pick a pick-up date.');
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
        documentReference: docRefs,
      );
      await _repository.insert(model, silent: true);

      await controller.loadPickUps();

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

  /// Update request status and merge interactive header inputs from the controller if provided.
  Future<void> updateRequestStatus(
    PickUpModel request,
    String newStatus,
    PickUpController controller,
    PickUpFormState formState,
  ) async {
    try {
      controller.isSaving.value = true;
      controller.errorMessage.value = null;
      final nowString = DateTime.now().toString();

      final updated = request.copyWith(
        status: newStatus,
        preparedBy: controller.formState.preparedByController.text.isNotEmpty
            ? controller.formState.preparedByController.text
            : request.preparedBy,
        itemPreparedAt: newStatus == BTexts.statusItemPrepared &&
                request.itemPreparedAt.isEmpty
            ? nowString
            : request.itemPreparedAt,
        itemPreparedEndAt: newStatus == BTexts.statusForDelivery &&
                request.itemPreparedEndAt.isEmpty
            ? nowString
            : request.itemPreparedEndAt,
        releasedBy: newStatus == BTexts.statusInTransit &&
                request.releasedBy.isEmpty
            ? controller.formState.releasedByController.text
            : request.releasedBy,
        receivedBy: newStatus == BTexts.statusTakenOut &&
                request.receivedBy.isEmpty
            ? controller.formState.receivedByController.text
            : request.receivedBy,
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
      }

      final payload = PickUpMapper.toUpdateDto(updated);

      await _repository.updateWithPayload(payload.toJson(), silent: true);

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

  /// Cancel a pick-up request with remarks via API.
  Future<void> cancelRequestWithRemarks(
      PickUpModel request, String remarks, String user, PickUpController controller) async {
    BFullScreenLoader.openLoadingDialog(
        'Saving on process...', BImages.docerAnimation);

    if (!await validateConnectivity()) {
      BFullScreenLoader.stopLoading();
      return;
    }

    try {
      await _repository.cancelPickUpAPI(request.id, remarks, user, silent: true);
      await fetchPickUps(controller);
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

  /// Fetch pick-ups and assign to the provided controller.
  Future<void> fetchPickUps(PickUpController controller) async {
    if (controller.isLoading.value) return;
    controller.isLoading.value = true;
    controller.errorMessage.value = null;
    try {
      final results = await _repository.getAll();
      controller.pickUps.assignAll(results);
      controller.filterManager.applyFilter(controller.pickUps.toList());
    } catch (e) {
      controller.errorMessage.value = e.toString();
      BLoaders.errorSnackBar(title: 'Error', message: e.toString());
    } finally {
      controller.isLoading.value = false;
    }
  }

  /// Insert a PickUpModel and refresh controller list.
  Future<void> insertPickUpModel(
      PickUpModel model, PickUpController controller) async {
    if (controller.isSaving.value) return;
    controller.isSaving.value = true;
    controller.errorMessage.value = null;
    try {
      await _repository.insert(model, silent: true);
      await fetchPickUps(controller);
      BLoaders.successSnackBar(title: 'Success', message: 'Request created');
    } catch (e) {
      controller.errorMessage.value = e.toString();
      BLoaders.errorSnackBar(
          title: 'Save Failed', message: 'An error occurred: $e');
    } finally {
      controller.isSaving.value = false;
    }
  }

  /// Load item categories and populate the controller caches.
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

  /// Fetch cancel remarks for a pick-up request from CancelRemarksRepository.
  /// Uses the same shared repository as standard delivery.
  Future<CancelRemarksModel> fetchCancelRemarks(String requestId) async {
    try {
      logDebug('🔍 PickUpDataManager: Fetching cancel remarks for: $requestId');
      final result = await _cancelRemarksRepository.getCancelRemarksByRequestId(
        requestId,
        module: RequestModule.pickUp, // Specify pick-up module
      );
      logDebug('✅ PickUpDataManager: API returned remarks: "${result.remarks}" date: "${result.date}"');
      if (result.remarks.isEmpty) {
        logDebug('⚠️ PickUpDataManager: Remarks are EMPTY! Check if API endpoint exists and returns data.');
      }
      return result;
    } catch (e) {
      logDebug('❌ PickUpDataManager.fetchCancelRemarks FAILED: $e');
      logDebug('💡 Tip: Check if GET /api4/RequestPickUp/cancel/$requestId endpoint exists');
      return CancelRemarksModel.empty;
    }
  }
}

