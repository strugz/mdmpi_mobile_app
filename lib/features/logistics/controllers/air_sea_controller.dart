import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/cancel_remarks_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/air_sea_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/air_sea_form_state.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/air_sea_data_manager.dart';

/// Controller for managing Air/Sea requests lifecycle, state, and business operations.
///
/// Responsibilities:
/// - Manages Air/Sea request data (list, selection, CRUD operations)
/// - Handles filtering by status and date range
/// - Coordinates form state for create/update operations
/// - Manages local DB and API synchronization
/// - Handles signature capture and image proof uploads
class AirSeaController extends GetxController {
  // ========================================================================
  // STATE PROPERTIES
  // ========================================================================

  /// Complete list of Air/Sea requests loaded from repository.
  /// This is the unfiltered source data.
  final RxList<AirSeaModel> airSeaRequests = <AirSeaModel>[].obs;

  /// Currently selected Air/Sea request for detail view or editing.
  /// Null when no request is selected.
  final Rx<AirSeaModel?> currentSelectedAirSea = Rx<AirSeaModel?>(null);

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

  /// Cancellation remarks data for the currently viewed Air/Sea request.
  /// Contains remarks and cancellation date when a request is cancelled.
  final Rx<CancelRemarksModel?> cancelRemarks = Rx<CancelRemarksModel?>(null);

  /// Identity of the user who created the current request.
  /// Automatically populated from logged-in user's initials.
  String createdBy = '';

  // ========================================================================
  // MANAGERS & DEPENDENCIES
  // ========================================================================

  /// Manages filtering logic for Air/Sea requests (by status and date).
  late final AirSeaFilterManager filterManager;

  /// Handles data operations including CRUD, validation, and API calls.
  late final AirSeaDataManager dataManager;

  /// Encapsulates all form-related state (text controllers, categories, dates, signatures).
  late final AirSeaFormState formState;

  /// Reference to user controller for accessing logged-in user information.
  late final UserController userController;

  // ========================================================================
  // LIFECYCLE METHODS
  // ========================================================================

  @override
  void onInit() {
    super.onInit();

    // Initialize managers
    filterManager = AirSeaFilterManager();
    dataManager = AirSeaDataManager();

    // Initialize form state with default values
    formState = AirSeaFormState();
    formState.initializeDefaultDate();

    // Load initial data
    dataManager.loadCategories(this);
    dataManager.fetchAirSeaRequests(this, useLocalStorage.value);

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

  /// Returns the currently filtered list of Air/Sea requests.
  /// Applies active status and date filters from the filter manager.
  List<AirSeaModel> get filteredAirSeaRequests => filterManager.filteredAirSeaRequests;

  // ========================================================================
  // DATA LOADING & FETCHING
  // ========================================================================

  /// Fetches all Air/Sea requests from the configured data source.
  /// Uses local database if [useLocalStorage] is true, otherwise fetches from API.
  /// Automatically updates the [airSeaRequests] list and applies active filters.
  Future<void> loadAirSeaRequests() async {
    await dataManager.fetchAirSeaRequests(this, useLocalStorage.value);
  }

  /// Loads item categories from the repository and populates form state.
  /// Safe to call multiple times; will not duplicate data.
  /// Sets default category selection (prefers 'reagent' if available).
  Future<void> loadCategories() async {
    await dataManager.loadCategories(this);
  }

  /// Fetches cancellation remarks for a specific Air/Sea request.
  /// Updates [cancelRemarks] with the retrieved data or empty model on failure.
  ///
  /// [requestId] The unique identifier of the Air/Sea request
  Future<void> loadCancelRemarks(String requestId) async {
    try {
      final repo = Get.find<CancelRemarksRepository>();
      final result = await repo.getCancelRemarksByRequestId(
        requestId,
        module: RequestModule.airSea,
      );
      cancelRemarks.value = result;
    } catch (e) {
      cancelRemarks.value = CancelRemarksModel.empty;
    }
  }

  // ========================================================================
  // FILTERING OPERATIONS
  // ========================================================================

  /// Updates the active status filter and reapplies filtering to the Air/Sea list.
  ///
  /// Available status filters:
  /// - All: Shows all Air/Sea requests
  /// - New Request: Shows only newly created requests
  /// - Item Prepared: Shows requests with prepared items
  /// - Item Packed: Shows packed and ready-to-ship requests
  /// - Received: Shows completed/received requests
  ///
  /// [statusFilter] The status filter to apply
  void selectStatusFilter(AirSeaStatusFilter statusFilter) {
    filterManager.selectStatusFilter(statusFilter, airSeaRequests);
  }

  /// Updates the active date range filter and reapplies filtering to the Air/Sea list.
  ///
  /// Available date filters:
  /// - Today: Shows requests from current date
  /// - This Week: Shows requests from the current week
  /// - This Month: Shows requests from the current month
  /// - Custom Range: Shows requests within a user-defined date range
  ///
  /// [filter] The date filter to apply
  void selectDateFilter(RequestFilter filter) {
    filterManager.selectFilter(filter, airSeaRequests);
  }

  // ========================================================================
  // CRUD OPERATIONS
  // ========================================================================

  /// Creates a new Air/Sea request from the current form state.
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

  /// Inserts a pre-constructed Air/Sea model into the repository.
  /// Prevents duplicate submissions by checking [isSaving] flag.
  /// Refreshes the Air/Sea list after successful insertion.
  ///
  /// [model] The Air/Sea request model to insert
  Future<void> addAirSea(AirSeaModel model) async {
    await dataManager.insertAirSeaModel(model, this);
  }

  /// Updates the status of an Air/Sea request with automatic field population.
  /// Handles status-specific business logic:
  ///
  /// - "Item Prepared": Records preparation timestamp and preparer's name
  /// - "Item Packed": Records packing completion time
  /// - "Received": Records rider's name, captures signature, uploads proof images
  ///
  /// For "Received" status, uploads signature and proof images to server if connected,
  /// otherwise saves locally for later synchronization.
  ///
  /// [request] The Air/Sea request to update
  /// [newStatus] The new status to set (must be a valid status string)
  Future<void> updateStatusWithInputs(
      AirSeaModel request, String newStatus) async {
    await dataManager.updateRequestStatus(request, newStatus, this, formState);
  }

  /// Cancels an Air/Sea request with mandatory remarks explaining the reason.
  /// Validates network connectivity before submission.
  /// Refreshes the Air/Sea list after successful cancellation.
  ///
  /// The cancellation is recorded with:
  /// - Requesting user's identifier
  /// - Cancellation remarks/reason
  /// - Current timestamp
  ///
  /// [request] The Air/Sea request to cancel
  /// [remarks] Explanation for the cancellation (required)
  Future<void> cancelAirSea(AirSeaModel request, String remarks) async {
    final user = userController.user.value.initial;
    await dataManager.cancelRequestWithRemarks(request, remarks, user, this);
  }

  /// Endorses an Air/Sea request to an authorized guard or personnel.
  /// Captures guard information and signature when items need to be handed
  /// off to security or other authorized personnel who don't have app access.
  ///
  /// This method:
  /// - Validates required fields (guard name, signature)
  /// - Uploads signature to server if online
  /// - Updates request status to "Endorsed to Guard"
  /// - Records endorsement timestamp and endorsing user
  /// - Refreshes the Air/Sea list on success
  ///
  /// [requestId] The unique identifier of the Air/Sea request
  /// [endorsedTo] Full name of the guard/authorized person receiving the items
  /// [signatureBase64] Base64 encoded signature image of the guard
  /// [remarks] Optional notes about the endorsement
  Future<void> endorseToGuard({
    required String requestId,
    required String endorsedTo,
    required String signatureBase64,
    String? remarks,
  }) async {
    try {
      isSaving.value = true;
      errorMessage.value = null;

      final success = await dataManager.airSeaRepo.endorseToGuard(
        requestId: requestId,
        endorsedTo: endorsedTo,
        signatureBase64: signatureBase64,
        remarks: remarks,
        silent: false,
      );

      if (success) {
        // Refresh data to show updated status
        await dataManager.fetchAirSeaRequests(this, useLocalStorage.value, forceRefresh: true);
      } else {
        errorMessage.value = 'Failed to endorse item to guard';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isSaving.value = false;
    }
  }

  /// Marks an Air/Sea request as received with waybill tracking information.
  /// Records the final receipt of items with mandatory waybill number and
  /// optional receiver signature.
  ///
  /// This method:
  /// - Validates waybill number format
  /// - Optionally uploads receiver signature to server
  /// - Updates request status to "Received"
  /// - Records receipt timestamp and receiving user
  /// - Refreshes the Air/Sea list on success
  ///
  /// [requestId] The unique identifier of the Air/Sea request
  /// [waybillNumber] Waybill/tracking number for the shipment (required)
  /// [signatureBase64] Optional base64 encoded signature of the final receiver
  /// [remarks] Optional notes about the receipt
  Future<void> receiveRequest({
    required String requestId,
    required String waybillNumber,
    String? signatureBase64,
    String? remarks,
  }) async {
    try {
      isSaving.value = true;
      errorMessage.value = null;

      final success = await dataManager.airSeaRepo.receiveRequest(
        requestId: requestId,
        waybillNumber: waybillNumber,
        signatureBase64: signatureBase64,
        remarks: remarks,
        silent: false,
      );

      if (success) {
        // Refresh data to show updated status
        await dataManager.fetchAirSeaRequests(this, useLocalStorage.value, forceRefresh: true);
      } else {
        errorMessage.value = 'Failed to mark request as received';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isSaving.value = false;
    }
  }

  // ========================================================================
  // CONFIGURATION & SETTINGS
  // ========================================================================

  /// Toggles the data source preference between local database and API.
  /// Automatically reloads Air/Sea data using the newly selected source.
  ///
  /// Use cases:
  /// - Enable local storage for offline mode or faster loading
  /// - Disable local storage to force fresh data from server
  ///
  /// [value] True to use local storage, false to use API directly
  void toggleStoragePreference(bool value) {
    useLocalStorage.value = value;
    loadAirSeaRequests();
  }
}

