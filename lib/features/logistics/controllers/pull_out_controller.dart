import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_form_state.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_data_manager.dart';

/// Controller for managing pull-out requests state and operations.
class PullOutController extends GetxController {
  /// Raw list of pull-out requests.
  final RxList<PullOutModel> pullOuts = <PullOutModel>[].obs;

  /// Currently selected pull-out (for UI actions/navigation).
  final Rx<PullOutModel?> currentSelectedPullOut = Rx<PullOutModel?>(null);

  /// Loading flag for list operations.
  final RxBool isLoading = false.obs;

  /// Loading flag for save/update operations.
  final RxBool isSaving = false.obs;

  /// Last error message, if any.
  final RxnString errorMessage = RxnString();

  /// Manager for date & status filtering.
  late final PullOutFilterManager filterManager;
  late final PullOutDataManager dataManager;

  /// --- Form state and controllers ---
  late final PullOutFormState formState;

  /// CreatedBy is derived from the logged-in user and stored here (not exposed as an editable UI field).
  String createdBy = '';

  /// Load categories from repositories (safe to call repeatedly)
  Future<void> loadCategories() async {
    await dataManager.loadCategories(this);
  }

  @override
  void onInit() {
    super.onInit();
    filterManager = PullOutFilterManager();
    dataManager = PullOutDataManager();
    formState = PullOutFormState();
    formState.initializeDefaultDate();
    dataManager.loadCategories(this);
    dataManager.fetchPullOuts(this);

    final userCtrl = Get.find<UserController>();
    createdBy = userCtrl.user.value.initial;
  }

  /// Convenience access to filtered list.
  List<PullOutModel> get filteredPullOuts => filterManager.filteredPullOuts;

  /// Update status filter.
  void selectStatusFilter(PullOutStatusFilter statusFilter) {
    filterManager.selectStatusFilter(statusFilter, pullOuts);
  }

  /// Update date filter.
  void selectDateFilter(RequestFilter filter) {
    filterManager.selectFilter(filter, pullOuts);
  }

  /// Fetch all pull-out requests from repository.
  Future<void> loadPullOuts() async {
    await dataManager.fetchPullOuts(this);
  }

  /// Insert a new pull-out request and refresh the list.
  Future<void> addPullOut(PullOutModel model) async {
    await dataManager.insertPullOutModel(model, this);
  }

  /// Cancel a pull-out request with remarks.
  Future<void> cancelPullOut(String requestId, String remarks) async {
    await dataManager.cancelPullOutById(requestId, remarks, this);
  }

  /// Build a PullOutModel from the controllers and submit.
  Future<void> submitFromForm() async {
    await dataManager.saveRequestFromForm(this);
    // Do not reset here; the screen's onSave handles visual clearing to keep
    // behavior localized to the widget as requested.
  }

  /// Update status using data manager to merge UI inputs.
  Future<void> updateStatusWithInputs(
      PullOutModel request, String newStatus) async {
    await dataManager.updateRequestStatus(request, newStatus, this, formState);
  }

  void setSignature(Uint8List? signature) {
    formState.receiverSignatureBytes.value = signature;
    formState.receiverSignatureBase64.value =
        signature != null && signature.isNotEmpty
            ? base64Encode(signature)
            : "";
  }

  @override
  void onClose() {
    try {
      formState.dispose();
    } catch (_) {}
    super.onClose();
  }
}
