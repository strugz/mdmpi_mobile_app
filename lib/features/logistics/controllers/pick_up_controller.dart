import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/cancel_remarks_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pick_up_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pick_up_form_state.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pick_up_data_manager.dart';

/// Controller for managing pick-up requests lifecycle, state, and business operations.
///
/// Responsibilities:
/// - Manages pick-up request data (list, selection, CRUD operations)
/// - Handles filtering by status and date range
/// - Coordinates form state for create/update operations
/// - Manages local DB and API synchronization
/// - Handles signature capture and image proof uploads
class PickUpController extends GetxController {
  // ========================================================================
  // STATE PROPERTIES
  // ========================================================================

  /// Complete list of pick-up requests loaded from repository.
  /// This is the unfiltered source data.
  final RxList<PickUpModel> pickUps = <PickUpModel>[].obs;

  /// Currently selected pick-up request for detail view or editing.
  /// Null when no pick-up is selected.
  final Rx<PickUpModel?> currentSelectedPickUp = Rx<PickUpModel?>(null);

  /// Indicates whether a fetch/load operation is in progress.
  /// Used to show loading indicators in the UI.
  final RxBool isLoading = false.obs;

  /// Indicates whether a save/update/delete operation is in progress.
  /// Prevents duplicate submissions during async operations.
  final RxBool isSaving = false.obs;

  /// Storage preference flag for data source selection.
  /// - true: Use local database (offline-first approach)
  /// - false: Fetch directly from API/server (default)
  final RxBool useLocalStorage = false.obs;

  /// Stores the most recent error message from failed operations.
  /// Null when no error has occurred.
  final RxnString errorMessage = RxnString();

  /// Cancellation remarks data for the currently viewed pick-up request.
  /// Contains remarks and cancellation date when a request is cancelled.
  final Rx<CancelRemarksModel?> cancelRemarks = Rx<CancelRemarksModel?>(null);

  /// Identity of the user who created the current request.
  /// Automatically populated from logged-in user's initials.
  String createdBy = '';

  // ========================================================================
  // MANAGERS & DEPENDENCIES
  // ========================================================================

  /// Manages filtering logic for pick-up requests (by status and date).
  late final PickUpFilterManager filterManager;

  /// Handles data operations including CRUD, validation, and API calls.
  late final PickUpDataManager dataManager;

  /// Encapsulates all form-related state (text controllers, categories, dates, signatures).
  late final PickUpFormState formState;

  /// Reference to user controller for accessing logged-in user information.
  late final UserController userController;

  // ========================================================================
  // LIFECYCLE METHODS
  // ========================================================================

  @override
  void onInit() {
    super.onInit();

    // Initialize managers
    filterManager = PickUpFilterManager();
    dataManager = PickUpDataManager();

    // Initialize form state with default values
    formState = PickUpFormState();
    formState.initializeDefaultDate();

    // Load initial data
    dataManager.loadCategories(this);
    dataManager.fetchPickUps(this, useLocalStorage.value);

    // Set up user context
    userController = Get.find<UserController>();
    createdBy = userController.user.value.initial;
  }

  @override
  void onClose() {
    try {
      formState.dispose();
    } catch (_) {
      // Silently handle disposal errors
    }
    super.onClose();
  }

  // ========================================================================
  // COMPUTED PROPERTIES
  // ========================================================================

  /// Returns the currently filtered list of pick-up requests.
  /// Applies active status and date filters from the filter manager.
  List<PickUpModel> get filteredPickUps => filterManager.filteredPickUps;

  // ========================================================================
  // DATA LOADING & FETCHING
  // ========================================================================

  /// Fetches all pick-up requests from the configured data source.
  /// Uses local database if [useLocalStorage] is true, otherwise fetches from API.
  /// Automatically updates the [pickUps] list and applies active filters.
  Future<void> loadPickUps() async {
    await dataManager.fetchPickUps(this, useLocalStorage.value);
  }

  Future<void> hardResetPickUps() async {
    await dataManager.hardResetPickUps(this);
  }

  /// Loads item categories from the repository and populates form state.
  /// Safe to call multiple times; will not duplicate data.
  /// Sets default category selection (prefers 'reagent' if available).
  Future<void> loadCategories() async {
    await dataManager.loadCategories(this);
  }

  /// Fetches cancellation remarks for a specific pick-up request.
  /// Updates [cancelRemarks] with the retrieved data or empty model on failure.
  ///
  /// [requestId] The unique identifier of the pick-up request
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

  // ========================================================================
  // FILTERING OPERATIONS
  // ========================================================================

  /// Updates the active status filter and reapplies filtering to the pick-up list.
  ///
  /// Available status filters:
  /// - All: Shows all pick-up requests
  /// - New Request: Shows only newly created requests
  /// - Item Prepared: Shows requests with prepared items
  /// - Item Packed: Shows packed and ready-to-ship requests
  /// - Received: Shows completed/received requests
  ///
  /// [statusFilter] The status filter to apply
  void selectStatusFilter(PickUpStatusFilter statusFilter) {
    filterManager.selectStatusFilter(statusFilter, pickUps);
  }

  /// Updates the active date range filter and reapplies filtering to the pick-up list.
  ///
  /// Available date filters:
  /// - Today: Shows requests from current date
  /// - This Week: Shows requests from the current week
  /// - This Month: Shows requests from the current month
  /// - Custom Range: Shows requests within a user-defined date range
  ///
  /// [filter] The date filter to apply
  void selectDateFilter(RequestFilter filter) {
    filterManager.selectFilter(filter, pickUps);
  }

  void selectDateFrom(DateTime? date) {
    filterManager.selectDateFrom(date, pickUps);
  }

  void selectDateTo(DateTime? date) {
    filterManager.selectDateTo(date, pickUps);
  }

  void selectItemCategoryId(String categoryId) {
    filterManager.selectItemCategoryId(categoryId, pickUps);
  }

  void setClientNameQuery(String query) {
    filterManager.setClientNameQuery(query, pickUps);
  }

  void setDocumentReferenceQuery(String query) {
    filterManager.setDocumentReferenceQuery(query, pickUps);
  }
  // ========================================================================
  // CRUD OPERATIONS
  // ========================================================================

  /// Creates a new pick-up request from the current form state.
  /// Validates all required fields (client, document references, pick-up date, category).
  /// Shows loading dialog during submission and displays success/error feedback.
  ///
  /// Validation includes:
  /// - Client selection is required
  /// - At least one document reference must be provided
  /// - Pick-up date must be selected
  /// - Item category must be valid
  ///
  /// Note: Form reset is handled by the calling screen, not by this method.
  Future<void> submitFromForm() async {
    await dataManager.saveRequestFromForm(this);
  }

  /// Inserts a pre-constructed pick-up model into the repository.
  /// Prevents duplicate submissions by checking [isSaving] flag.
  /// Refreshes the pick-up list after successful insertion.
  ///
  /// [model] The pick-up request model to insert
  Future<void> addPickUp(PickUpModel model) async {
    await dataManager.insertPickUpModel(model, this);
  }

  /// Updates the status of a pick-up request with automatic field population.
  /// Handles status-specific business logic:
  ///
  /// - "Item Prepared": Records preparation timestamp and preparer's name
  /// - "Item Packed": Records packing completion time and releaser's name
  /// - "Received": Records receiver's name, captures signature, uploads proof images
  ///
  /// For "Received" status, uploads signature and proof images to server if connected,
  /// otherwise saves locally for later synchronization.
  ///
  /// [request] The pick-up request to update
  /// [newStatus] The new status to set (must be a valid status string)
  Future<void> updateStatusWithInputs(
      PickUpModel request, String newStatus) async {
    await dataManager.updateRequestStatus(request, newStatus, this, formState);
  }

  /// Cancels a pick-up request with mandatory remarks explaining the reason.
  /// Validates network connectivity before submission.
  /// Refreshes the pick-up list after successful cancellation.
  ///
  /// The cancellation is recorded with:
  /// - Requesting user's identifier
  /// - Cancellation remarks/reason
  /// - Current timestamp
  ///
  /// [request] The pick-up request to cancel
  /// [remarks] Explanation for the cancellation (required)
  Future<void> cancelPickUp(PickUpModel request, String remarks) async {
    final user = userController.user.value.initial;
    await dataManager.cancelRequestWithRemarks(request, remarks, user, this);
  }

  // ========================================================================
  // CONFIGURATION & SETTINGS
  // ========================================================================

  /// Toggles the data source preference between local database and API.
  /// Automatically reloads pick-up data using the newly selected source.
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
    loadPickUps();
  }
}
