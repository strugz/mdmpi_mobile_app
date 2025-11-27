import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/cancel_remarks_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pick_up_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pick_up_form_state.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pick_up_data_manager.dart';

/// Controller for managing pick-up requests state and operations.
class PickUpController extends GetxController {
  /// Raw list of pick-up requests.
  final RxList<PickUpModel> pickUps = <PickUpModel>[].obs;

  /// Currently selected pick-up (for UI actions/navigation).
  final Rx<PickUpModel?> currentSelectedPickUp = Rx<PickUpModel?>(null);

  /// Loading flag for list operations.
  final RxBool isLoading = false.obs;

  /// Loading flag for save/update operations.
  final RxBool isSaving = false.obs;

  /// Last error message, if any.
  final RxnString errorMessage = RxnString();

  /// Cancel remarks data
  final Rx<CancelRemarksModel?> cancelRemarks = Rx<CancelRemarksModel?>(null);

  /// Manager for date & status filtering.
  late final PickUpFilterManager filterManager;
  late final PickUpDataManager dataManager;

  /// --- Form state and controllers ---
  late final PickUpFormState formState;

  /// User controller for accessing logged-in user data.
  late final UserController userController;

  /// CreatedBy is derived from the logged-in user and stored here (not exposed as an editable UI field).
  String createdBy = '';

  /// Load categories from repositories (safe to call repeatedly)
  Future<void> loadCategories() async {
    await dataManager.loadCategories(this);
  }

  @override
  void onInit() {
    super.onInit();
    filterManager = PickUpFilterManager();
    dataManager = PickUpDataManager();
    formState = PickUpFormState();
    formState.initializeDefaultDate();
    dataManager.loadCategories(this);
    dataManager.fetchPickUps(this);

    userController = Get.find<UserController>();
    createdBy = userController.user.value.initial;
  }

  /// Convenience access to filtered list.
  List<PickUpModel> get filteredPickUps => filterManager.filteredPickUps;

  /// Update status filter.
  void selectStatusFilter(PickUpStatusFilter statusFilter) {
    filterManager.selectStatusFilter(statusFilter, pickUps);
  }

  /// Update date filter.
  void selectDateFilter(RequestFilter filter) {
    filterManager.selectFilter(filter, pickUps);
  }

  /// Fetch all pick-up requests from repository.
  Future<void> loadPickUps() async {
    await dataManager.fetchPickUps(this);
  }

  /// Insert a new pick-up request and refresh the list.
  Future<void> addPickUp(PickUpModel model) async {
    await dataManager.insertPickUpModel(model, this);
  }

  /// Cancel a pick-up request with remarks.
  Future<void> cancelPickUp(PickUpModel request, String remarks) async {
    final user = userController.user.value.initial;
    await dataManager.cancelRequestWithRemarks(request, remarks, user, this);
  }

  /// Build a PickUpModel from the controllers and submit.
  Future<void> submitFromForm() async {
    await dataManager.saveRequestFromForm(this);
    // Do not reset here; the screen's onSave handles visual clearing to keep
    // behavior localized to the widget as requested.
  }

  /// Update status using data manager to merge UI inputs.
  Future<void> updateStatusWithInputs(
      PickUpModel request, String newStatus) async {
    await dataManager.updateRequestStatus(request, newStatus, this, formState);
  }

  void setSignature(Uint8List? signature) {
    formState.receiverSignatureBytes.value = signature;
    formState.receiverSignatureBase64.value =
        signature != null && signature.isNotEmpty
            ? base64Encode(signature)
            : "";
  }

  /// Load cancel remarks for a request ID
  Future<void> loadCancelRemarks(String requestId) async {
    try {
      final repo = Get.find<CancelRemarksRepository>();
      final result = await repo.getCancelRemarksByRequestId(
        requestId,
        module: RequestModule.pickUp,
      );

      cancelRemarks.value = result;
    } catch (e) {
      cancelRemarks.value = CancelRemarksModel.empty;
    }
  }

  @override
  void onClose() {
    try {
      formState.dispose();
    } catch (_) {}
    super.onClose();
  }
}

