import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/cancel_remarks_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/hotline_direct_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_form_state.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/hotline_direct_data_manager.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Controller for managing Hotline Direct requests lifecycle, state, and business operations.
///
/// Responsibilities:
/// - Manages Hotline Direct request data (list, selection, CRUD operations)
/// - Handles filtering by status and date range
/// - Coordinates form state for create/update operations
/// - Manages local DB and API synchronization
/// - Handles signature capture and image proof uploads
/// - Tracks request counts by status
/// - Filters data by Hotline Direct form category only
class HotlineDirectController extends GetxController {
  static HotlineDirectController get instance => Get.find();

  // ========================================================================
  // STATE PROPERTIES
  // ========================================================================

  /// Complete list of Hotline Direct requests loaded from repository.
  /// This is the unfiltered source data.
  final RxList<StandardDeliveryModel> allPendingRequests = <StandardDeliveryModel>[].obs;

  /// Currently selected Hotline Direct request for detail view or editing.
  /// Null when no request is selected.
  final Rx<StandardDeliveryModel?> currentSelectedRequest = Rx<StandardDeliveryModel?>(null);

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

  /// Cancellation remarks data for the currently viewed Hotline Direct request.
  /// Contains remarks and cancellation date when a request is cancelled.
  final Rx<CancelRemarksModel?> cancelRemarks = Rx<CancelRemarksModel?>(null);

  /// Request count by status for dashboard/statistics display.
  final RxInt totalRequest = 0.obs;
  final RxInt gettingSuppliesReady = 0.obs;
  final RxInt itemPrepared = 0.obs;
  final RxInt forDelivery = 0.obs;
  final RxInt delivered = 0.obs;

  /// Identity of the user who created the current request.
  /// Automatically populated from logged-in user's initials.
  String createdBy = '';

  // ========================================================================
  // MANAGERS & DEPENDENCIES
  // ========================================================================

  /// Manages filtering logic for Hotline Direct requests (by status and date).
  late final HotlineDirectFilterManager filterManager;

  /// Handles data operations including CRUD, validation, and API calls.
  late final HotlineDirectDataManager dataManager;

  /// Encapsulates all form-related state (text controllers, categories, dates, signatures).
  late final StandardDeliveryFormState formState;

  /// Reference to user controller for accessing logged-in user information.
  late final UserController userController;

  // ========================================================================
  // LIFECYCLE METHODS
  // ========================================================================

  @override
  Future<void> onInit() async {
    super.onInit();

    // Initialize managers
    filterManager = HotlineDirectFilterManager();
    dataManager = HotlineDirectDataManager();

    // Initialize form state with default values
    formState = StandardDeliveryFormState();
    formState.initializeDefaultDate();

    // Load initial data
    dataManager.loadCategories(this);
    await loadRequests();

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

  /// Returns the currently filtered list of Hotline Direct requests.
  /// Applies active status and date filters from the filter manager.
  List<StandardDeliveryModel> get filteredRequests => filterManager.filteredRequests;

  // ========================================================================
  // DATA LOADING & FETCHING
  // ========================================================================

  /// Fetches all Hotline Direct requests from the configured data source.
  /// Uses local database if [useLocalStorage] is true, otherwise fetches from API.
  /// Automatically updates the [allPendingRequests] list and applies active filters.
  /// NOTE: Uses HotlineDirectDataManager which filters for Hotline Direct category only.
  Future<void> loadRequests() async {
    // The dataManager.fetchHotlineDirectRequests will:
    // 1. Fetch data from repository (API or local DB)
    // 2. Filter for Hotline Direct category only
    // 3. Populate this.allPendingRequests with Hotline Direct requests
    // 4. Call this.filterManager.applyFilter() to filter the data
    // 5. Call this.updateRequestCounts() to update statistics
    await dataManager.fetchHotlineDirectRequests(this, useLocalStorage.value);
  }

  /// Loads item categories from the repository and populates form state.
  /// Safe to call multiple times; will not duplicate data.
  /// Sets default category selection (prefers 'hotline' or 'direct' if available).
  Future<void> loadCategories() async {
    await dataManager.loadCategories(this);
  }

  /// Fetches cancellation remarks for a specific Hotline Direct request.
  /// Updates [cancelRemarks] with the retrieved data or empty model on failure.
  ///
  /// [requestId] The unique identifier of the Hotline Direct request
  Future<void> loadCancelRemarks(String requestId) async {
    try {
      final repo = Get.find<CancelRemarksRepository>();
      final result = await repo.getCancelRemarksByRequestId(
        requestId,
        module: RequestModule.standardDelivery,
      );
      cancelRemarks.value = result;
    } catch (e) {
      cancelRemarks.value = CancelRemarksModel.empty;
    }
  }

  /// Refresh requests by clearing local database and fetching from API.
  /// Forces a fresh data load from the server.
  Future<void> refreshRequests() async {
    // Force fetch from API (useLocalStorage = false)
    // This will update allPendingRequests and apply filters automatically
    await dataManager.fetchHotlineDirectRequests(this, false);
  }

  // ========================================================================
  // REQUEST COUNT TRACKING
  // ========================================================================

  /// Update request counts by status for dashboard statistics.
  /// Counts requests in each status category from the unfiltered list.
  void updateRequestCounts() {
    totalRequest.value = allPendingRequests.length;
    gettingSuppliesReady.value = allPendingRequests
        .where((r) => r.status == BTexts.statusGettingSuppliesReady)
        .length;
    itemPrepared.value = allPendingRequests
        .where((r) => r.status == BTexts.statusItemPrepared)
        .length;
    forDelivery.value = allPendingRequests
        .where((r) => r.status == BTexts.statusForDelivery)
        .length;
    delivered.value = allPendingRequests
        .where((r) => r.status == BTexts.statusDoneDelivery)
        .length;
  }

  // ========================================================================
  // FILTERING OPERATIONS
  // ========================================================================

  /// Updates the active status filter and reapplies filtering to the Hotline Direct list.
  ///
  /// Available status filters:
  /// - All: Shows all Hotline Direct requests
  /// - New Request: Shows only newly created requests
  /// - Getting Supplies Ready: Shows requests being prepared
  /// - Item Prepared: Shows requests with prepared items
  /// - For Delivery: Shows requests out for delivery
  /// - Delivered: Shows completed deliveries
  ///
  /// [statusFilter] The status filter to apply
  void selectStatusFilter(StandardDeliveryStatusFilter statusFilter) {
    filterManager.selectStatusFilter(statusFilter, allPendingRequests);
  }

  /// Updates the active date range filter and reapplies filtering to the Hotline Direct list.
  ///
  /// Available date filters:
  /// - Today: Shows requests from current date
  /// - Yesterday: Shows requests from previous day
  /// - Tomorrow: Shows requests for next day
  /// - Last 5 Days: Shows requests from the last 5 days
  /// - Last 30 Days: Shows requests from the last 30 days
  /// - All: Shows all requests regardless of date
  ///
  /// [filter] The date filter to apply
  void selectFilter(RequestFilter filter) {
    filterManager.selectFilter(filter, allPendingRequests);
  }

  // ========================================================================
  // CRUD OPERATIONS
  // ========================================================================

  /// Creates a new Hotline Direct request from the current form state.
  /// Validates all required fields (client, document references, delivery date).
  /// Shows loading dialog during submission and displays success/error feedback.
  ///
  /// Validation includes:
  /// - Client selection is required
  /// - At least one document reference must be provided
  /// - Requested by must be selected
  ///
  /// Note: Form reset is handled by the data manager after successful save.
  Future<void> saveRequest() async {
    await dataManager.saveRequestFromForm(this);
  }

  /// Updates the status of a Hotline Direct request with automatic field population.
  /// Handles status-specific business logic:
  ///
  /// - "Getting supplies ready": Records preparation start timestamp and preparer's name
  /// - "Item Prepared": Records driver, helper, mobile, trip ticket, and end timestamp
  /// - "For Delivery": Records delivery start timestamp and location
  /// - "Delivered": Records delivery end time, location, receiver, signature, and proof images
  ///
  /// For "Delivered" status, uploads signature and proof images to server if connected,
  /// otherwise saves locally for later synchronization.
  ///
  /// [requestModel] The Hotline Direct request to update
  /// [newStatus] The new status to set (must be a valid status string)
  /// [userInitial] The initial of the user performing the status update
  Future<void> updateRequestStatus(StandardDeliveryModel requestModel,
      String newStatus, String userInitial) async {
    await dataManager.updateRequestStatus(
      requestModel,
      newStatus,
      userInitial,
      this,
    );
  }

  /// Cancels a Hotline Direct request with mandatory remarks explaining the reason.
  /// Validates network connectivity before submission.
  /// Refreshes the Hotline Direct list after successful cancellation.
  ///
  /// The cancellation is recorded with:
  /// - Requesting user's identifier
  /// - Cancellation remarks/reason
  /// - Current timestamp
  ///
  /// [requestModel] The Hotline Direct request to cancel
  /// [remarks] Explanation for the cancellation (required)
  /// [showLoader] Whether to show loading dialog (default: true)
  Future<void> updateRequestForCancellation(
      StandardDeliveryModel requestModel, String remarks,
      {bool showLoader = true}) async {
    final user = userController.user.value.initial;
    await dataManager.cancelRequestWithRemarks(requestModel, remarks, user, this);
  }

  // ========================================================================
  // FORM STATE MANAGEMENT
  // ========================================================================

  /// Adds a new empty document reference field to the form.
  /// Creates a new TextEditingController and adds it to the reactive list.
  void addDocumentReferenceField() {
    formState.documentReferenceControllers.add(TextEditingController());
  }

  /// Removes a specific document reference field from the form.
  /// Disposes the controller to prevent memory leaks.
  ///
  /// [controller] The TextEditingController to remove and dispose
  void removeDocumentReferenceField(TextEditingController controller) {
    controller.dispose();
    formState.documentReferenceControllers.remove(controller);
  }

  /// Updates the client information in the form state.
  /// Triggers reactive updates in the UI.
  ///
  /// [clientDetails] The new client information to set
  void updateRequestClientInformation(ClientModel clientDetails) {
    formState.clientInformation.value = clientDetails;
  }

  /// Sets the receiver's signature for delivery confirmation.
  /// Converts the signature bytes to Base64 for storage and transmission.
  ///
  /// [signature] The signature image bytes, or null to clear
  void setSignature(Uint8List? signature) {
    formState.receiverSignatureBytes.value = signature;
    formState.receiverSignatureBase64.value =
        signature != null && signature.isNotEmpty
            ? base64Encode(signature)
            : "";
  }

  // ========================================================================
  // SETTINGS & PREFERENCES
  // ========================================================================

  /// Toggles the data source preference between local database and API.
  /// Automatically reloads Hotline Direct data using the newly selected source.
  ///
  /// Use cases:
  /// - Enable local storage for offline mode or faster loading
  /// - Disable local storage to force fresh data from server
  ///
  /// [value] True to use local storage, false to use API directly
  void toggleStoragePreference(bool value) {
    useLocalStorage.value = value;
    loadRequests();
  }
}

