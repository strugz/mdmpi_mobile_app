import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/backload_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/hotline_direct_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/backload_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';

/// Controller for the BackLoad workflow.
///
/// Manages:
/// - Selected remarks reason (dropdown)
/// - Editable delivery date for the reprocessed request
/// - Saving a new BackLoad record (API-first; local DB only on API success)
/// - Loading existing BackLoad entries for a request
/// - Reprocessing a Back Load transaction (resetting the workflow)
/// - Observable state for the UI
class BackLoadController extends GetxController {
  static BackLoadController get instance => Get.find();

  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final BackLoadRepository _repository = Get.find<BackLoadRepository>();

  // ---------------------------------------------------------------------------
  // Fixed dropdown options
  // ---------------------------------------------------------------------------

  /// The allowed remarks values for back-load.
  static const List<String> remarksOptions = [
    'Wrong item',
    'Time constraint',
    'Unavailable customer',
    'Refused delivery',
    'Reroute',
    'Expiry not Accepted',
  ];

  // ---------------------------------------------------------------------------
  // Observable state
  // ---------------------------------------------------------------------------

  /// Currently selected reason from the dropdown.
  final RxnString selectedRemarks = RxnString();

  /// Delivery date the user edits before submitting the back-load.
  final Rx<DateTime?> selectedDeliveryDate = Rx<DateTime?>(null);

  /// True while an API call is in progress.
  final RxBool isSaving = false.obs;

  /// True while loading existing BackLoad data.
  final RxBool isLoading = false.obs;

  /// Error message shown in UI (nullable — null means no error).
  final RxnString errorMessage = RxnString();

  /// All BackLoad entries loaded for the current request.
  final RxList<BackLoadModel> backLoadEntries = <BackLoadModel>[].obs;

  /// The latest BackLoad entry for the current request (for modal display).
  final Rxn<BackLoadModel> latestBackLoad = Rxn<BackLoadModel>();

  // ---------------------------------------------------------------------------
  // Delivery date controller (text field)
  // ---------------------------------------------------------------------------

  final TextEditingController deliveryDateController = TextEditingController();

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Load all BackLoad entries for [requestId] from local DB.
  ///
  /// The local table is only populated when the transaction already has
  /// BackLoad history (from API sync), so this returns entries only for
  /// transactions that have been back-loaded before.
  Future<void> loadBackLoadEntries(String requestId) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final entries = await _repository.getLocalByRequestId(requestId);
      backLoadEntries.assignAll(entries);
      latestBackLoad.value = entries.isNotEmpty ? entries.first : null;
    } catch (e) {
      logDebug('❌ BackLoadController.loadBackLoadEntries: $e');
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Convenience alias used by the Standard Delivery modal / page to
  /// preload BackLoad remarks before building the remarks section.
  Future<void> loadBackLoadRemarks(String requestId) =>
      loadBackLoadEntries(requestId);

  /// Submit a new BackLoad record for the given request.
  ///
  /// **API-first:** the record is sent to the API first. If the API call
  /// fails, nothing is saved to the local BackLoad table. After API success
  /// the local history is updated and delivery lists are refreshed.
  Future<bool> submitBackLoad(StandardDeliveryModel request) async {
    if (selectedRemarks.value == null || selectedRemarks.value!.isEmpty) {
      BLoaders.errorSnackBar(
          title: 'Validation', message: 'Please select a reason');
      return false;
    }

    try {
      isSaving.value = true;
      errorMessage.value = null;

      final result = await _repository.addBackLoad(
        requestId: request.id,
        remarks: selectedRemarks.value!,
        deliveryDate: deliveryDateController.value.text,
      );

      if (result.isFailure) {
        errorMessage.value = result.error;
        BLoaders.errorSnackBar(
            title: 'Error', message: 'Failed to submit back load');
        return false;
      }

      // On success, repository already persists the saved BackLoad to local DB.
      // Update controller-local state so UI reflects the newly created entry
      // immediately without waiting for a later reload.
      try {
        final saved = result.value;

        // Avoid inserting duplicates if the item already exists
        final exists =
            backLoadEntries.any((e) => e.backLoadId == saved.backLoadId);
        if (!exists) {
          backLoadEntries.insert(0, saved);
        } else {
          // Replace the existing item with the new one (if you want to refresh)
          final idx = backLoadEntries
              .indexWhere((e) => e.backLoadId == saved.backLoadId);
          if (idx != -1) backLoadEntries[idx] = saved;
        }

        latestBackLoad.value = saved;
      } catch (e) {
        logDebug(
            '? BackLoadController: failed to update in-memory state after save: $e');
      }

      // Refresh delivery lists so status reflects 'Back Load'
      try {
        final sdController = Get.find<StandardDeliveryController>();
        await sdController.loadRequests();
      } catch (e) {
        logDebug('BackLoadController: could not refresh Standard Delivery: $e');
      }

      try {
        final hotlineController = Get.find<HotlineDirectController>();
        await hotlineController.loadRequests();
      } catch (e) {
        logDebug('BackLoadController: could not refresh Hotline Direct: $e');
      }

      BLoaders.successSnackBar(
          title: 'Back Load', message: 'Request marked as Back Load');
      return true;
    } catch (e) {
      logDebug('❌ BackLoadController.submitBackLoad: $e');
      errorMessage.value = e.toString();
      BLoaders.errorSnackBar(
          title: 'Error', message: 'Failed to submit back load');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Reprocess a Back Load transaction.
  ///
  /// Resets the transaction workflow state so it re-enters the standard
  /// delivery flow from the beginning. The original transaction ID is
  /// preserved. All BackLoad history rows remain linked to the request.
  Future<bool> reprocessRequest(StandardDeliveryModel request) async {
    try {
      isSaving.value = true;
      errorMessage.value = null;

      final sdController = Get.find<StandardDeliveryController>();
      final userInitial = sdController.userController.user.value.initial;

      // Reset status to New Request, preserving the transaction ID
      await sdController.updateRequestStatus(
        request,
        BTexts.statusNewRequest,
        userInitial,
      );

      // Refresh the list
      await sdController.loadRequests();

      BLoaders.successSnackBar(
          title: 'Reprocess', message: 'Transaction reprocessed successfully');
      return true;
    } catch (e) {
      logDebug('❌ BackLoadController.reprocessRequest: $e');
      errorMessage.value = e.toString();
      BLoaders.errorSnackBar(
          title: 'Error', message: 'Failed to reprocess transaction');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Fetch all BackLoad records from the API and sync to local DB.
  /// Intended to be called during app initialization.
  Future<void> syncFromApi() async {
    try {
      await _repository.fetchAllFromApi();
    } catch (e) {
      logDebug('❌ BackLoadController.syncFromApi: $e');
    }
  }

  /// Reset form state for a new back-load flow.
  void resetForm() {
    selectedRemarks.value = null;
    selectedDeliveryDate.value = null;
    deliveryDateController.clear();
    errorMessage.value = null;
  }

  /// Initialize form state for the given request.
  ///
  /// Resets previous state and pre-populates the delivery date from [request].
  /// Call this **before** navigating to `BackLoadTransactionPage`.
  void initForRequest(StandardDeliveryModel request) {
    resetForm();
    if (request.deliveryDate.isNotEmpty) {
      deliveryDateController.text = request.deliveryDate;
      try {
        selectedDeliveryDate.value =
            DateFormat('yyyy-MM-dd').parse(request.deliveryDate);
      } catch (_) {
        // ignore parse errors
      }
    }
  }

  @override
  void onClose() {
    deliveryDateController.dispose();
    super.onClose();
  }
}
