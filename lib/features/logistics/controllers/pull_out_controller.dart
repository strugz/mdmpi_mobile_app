import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/cancel_remarks_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';
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

  /// Storage preference flag for data source selection.
  /// - true: Use local database (offline-first approach)
  /// - false: Fetch directly from API/server (default)
  final RxBool useLocalStorage = false.obs;

  /// Last error message, if any.
  final RxnString errorMessage = RxnString();

  /// Cancel remarks data
  final Rx<CancelRemarksModel?> cancelRemarks = Rx<CancelRemarksModel?>(null);

  /// Manager for date & status filtering.
  late final PullOutFilterManager filterManager;
  late final PullOutDataManager dataManager;

  /// --- Form state and controllers ---
  late final PullOutFormState formState;

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
    filterManager = PullOutFilterManager();
    dataManager = PullOutDataManager();
    formState = PullOutFormState();
    formState.initializeDefaultDate();
    dataManager.loadCategories(this);
    dataManager.fetchPullOuts(this);

    userController = Get.find<UserController>();
    createdBy = userController.user.value.initial;
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

  void selectDateFrom(DateTime? date) {
    filterManager.selectDateFrom(date, pullOuts);
  }

  void selectDateTo(DateTime? date) {
    filterManager.selectDateTo(date, pullOuts);
  }

  void selectItemCategoryId(String categoryId) {
    filterManager.selectItemCategoryId(categoryId, pullOuts);
  }

  void setClientNameQuery(String query) {
    filterManager.setClientNameQuery(query, pullOuts);
  }


  void setDocumentReferenceQuery(String query) {
    filterManager.setDocumentReferenceQuery(query,pullOuts);
  }
  /// Fetch all pull-out requests from repository.
  Future<void> loadPullOuts() async {
    await dataManager.fetchPullOuts(this, useLocalStorage.value);
  }

  /// Insert a new pull-out request and refresh the list.
  Future<void> addPullOut(PullOutModel model) async {
    await dataManager.insertPullOutModel(model, this);
  }

  /// Cancel a pull-out request with remarks.
  Future<void> cancelPullOut(PullOutModel request, String remarks) async {
    final user = userController.user.value.initial;
    await dataManager.cancelRequestWithRemarks(request, remarks, user, this);
  }

  /// Build a PullOutModel from the controllers and submit.
  Future<void> submitFromForm() async {
    await dataManager.saveRequestFromForm(this);
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

  /// Load cancel remarks for a request ID
  Future<void> loadCancelRemarks(String requestId) async {
    try {
      final repo = Get.find<CancelRemarksRepository>();
      final result = await repo.getCancelRemarksByRequestId(
        requestId,
        module: RequestModule.pullOut,
      );

      cancelRemarks.value = result;
    } catch (e) {
      cancelRemarks.value = CancelRemarksModel.empty;
    }
  }

  /// Toggles the data source preference between local database and API.
  /// Automatically reloads pull-out data using the newly selected source.
  ///
  /// Use cases:
  /// - Enable local storage for offline mode or faster loading
  /// - Disable local storage to force fresh data from server
  ///
  /// [value] True to use local storage, false to use API directly
  void toggleStoragePreference(bool value) {
    useLocalStorage.value = value;
    loadPullOuts();
  }

  @override
  void onClose() {
    try {
      formState.dispose();
    } catch (_) {}
    super.onClose();
  }
}
