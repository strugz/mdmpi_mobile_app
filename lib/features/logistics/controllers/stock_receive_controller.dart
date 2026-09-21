import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_pull_out_request_controller.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/cancel_remarks_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/stock_receive_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_form_state.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/stock_receive_data_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/request_date_scope.dart';

/// Controller for managing Stock Receive requests state and operations.
///
/// Responsibilities:
/// - Manages Stock Receive request data (list, selection, CRUD operations)
/// - Handles filtering by status and date range
/// - Coordinates form state for create/update operations
/// - Manages local DB and API synchronization
/// - Handles signature capture and image proof uploads
/// - Filters data by Stock Receive form category only
class StockReceiveController extends GetxController
    implements IPullOutRequestController {
  /// Raw list of Stock Receive requests.
  final RxList<PullOutModel> stockReceives = <PullOutModel>[].obs;

  /// Currently selected Stock Receive (for UI actions/navigation).
  final Rx<PullOutModel?> currentSelectedStockReceive = Rx<PullOutModel?>(null);

  /// Loading flag for list operations.
  final RxBool isLoading = false.obs;

  /// Loading flag for save/update operations.
  final RxBool isSaving = false.obs;

  /// Storage preference flag for data source selection.
  /// - true: Use local database (offline-first approach)
  /// - false: Fetch directly from API/server (default)
  final RxBool useLocalStorage = false.obs;

  /// Wire date scope the in-memory list was last loaded with.
  RequestDateScope? loadedDateScope;

  /// Wire scope required by the currently selected date filter.
  RequestDateScope get activeScope =>
      RequestDateScope.fromFilter(filterManager.selectedFilter.value);

  /// Last error message, if any.
  final RxnString errorMessage = RxnString();

  /// Cancel remarks data
  @override
  final Rx<CancelRemarksModel?> cancelRemarks = Rx<CancelRemarksModel?>(null);

  /// Manager for date & status filtering.
  late final StockReceiveFilterManager filterManager;
  late final StockReceiveDataManager dataManager;

  /// --- Form state and controllers ---
  @override
  late final PullOutFormState formState;

  /// User controller for accessing logged-in user data.
  late final UserController userController;

  /// CreatedBy is derived from the logged-in user and stored here.
  String createdBy = '';

  /// Load categories from repositories (safe to call repeatedly)
  Future<void> loadCategories() async {
    await dataManager.loadCategories(this);
  }

  @override
  void onInit() {
    super.onInit();
    filterManager = StockReceiveFilterManager();
    dataManager = StockReceiveDataManager();
    formState = PullOutFormState();
    formState.initializeDefaultDate();
    dataManager.loadCategories(this);
    // Deliberately no fetch here. Whoever shows this tab drives the load:
    // the Request screen loads the selected date filter only, and the Home
    // dashboard loads the full history it needs for its year/month counts.
    // Fetching here as well would race those two through the isLoading guard.

    userController = Get.find<UserController>();
    createdBy = userController.user.value.initial;
  }

  /// Convenience access to filtered list.
  List<PullOutModel> get filteredStockReceives =>
      filterManager.filteredStockReceives;

  /// Update status filter.
  void selectStatusFilter(PullOutStatusFilter statusFilter) {
    filterManager.selectStatusFilter(statusFilter, stockReceives);
  }

  /// Applies [filter] immediately, then re-fetches only when the new filter
  /// needs a wider date range than what is currently loaded (e.g. Today ->
  /// All). Narrowing (All -> Today) needs no network call.
  void selectDateFilter(RequestFilter filter) {
    filterManager.selectFilter(filter, stockReceives);
    if (!shouldRefetch(loadedDateScope, filter)) return;
    unawaited(loadStockReceives().then(
        (_) => filterManager.applyFilter(stockReceives.toList())));
  }

  void selectDateFrom(DateTime? date) {
    filterManager.selectDateFrom(date, stockReceives);
  }

  void selectDateTo(DateTime? date) {
    filterManager.selectDateTo(date, stockReceives);
  }

  void selectItemCategoryId(String categoryId) {
    filterManager.selectItemCategoryId(categoryId, stockReceives);
  }

  void setClientNameQuery(String query) {
    filterManager.setClientNameQuery(query, stockReceives);
  }

  void setDocumentReferenceQuery(String query) {
    filterManager.setDocumentReferenceQuery(query, stockReceives);
  }

  /// Loads stock receives for the currently selected date filter.
  Future<void> loadStockReceives() async {
    await loadForScope(activeScope);
  }

  /// Loads stock receives for an explicit [scope], bypassing the selected
  /// filter.
  ///
  /// Used by the Home dashboard, which needs the full history for its
  /// year/month counts regardless of what this tab is filtered to.
  Future<void> loadForScope(RequestDateScope scope) async {
    await dataManager.fetchStockReceives(this, useLocalStorage.value, scope);
  }

  Future<void> hardResetStockReceives() async {
    await dataManager.hardResetStockReceives(this);
  }

  /// Insert a new Stock Receive request and refresh the list.
  Future<void> addStockReceive(PullOutModel model) async {
    await dataManager.insertStockReceiveModel(model, this);
  }

  /// Cancel a Stock Receive request with remarks.
  Future<void> cancelStockReceive(PullOutModel request, String remarks) async {
    final user = userController.user.value.initial;
    await dataManager.cancelRequestWithRemarks(request, remarks, user, this);
  }

  /// Build a PullOutModel from the controllers and submit.
  Future<void> submitFromForm() async {
    await dataManager.saveRequestFromForm(this);
  }

  /// Update status using data manager to merge UI inputs.
  @override
  Future<void> updateStatusWithInputs(
      PullOutModel request, String newStatus) async {
    await dataManager.updateRequestStatus(request, newStatus, this, formState);
  }

  @override
  void setSignature(Uint8List? signature) {
    formState.receiverSignatureBytes.value = signature;
    formState.receiverSignatureBase64.value =
        signature != null && signature.isNotEmpty
            ? base64Encode(signature)
            : "";
  }

  /// Load cancel remarks for a request ID
  @override
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
  /// Automatically reloads Stock Receive data using the newly selected source.
  ///
  /// Use cases:
  /// - Enable local storage for offline mode or faster loading
  /// - Disable local storage to force fresh data from server
  ///
  /// [value] True to use local storage, false to use API directly
  void toggleStoragePreference(bool value) {
    if (useLocalStorage.value == value) {
      return;
    }
    useLocalStorage.value = value;
    loadStockReceives();
  }

  @override
  void onClose() {
    try {
      formState.dispose();
    } catch (_) {}
    super.onClose();
  }
}
