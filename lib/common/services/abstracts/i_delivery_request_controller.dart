import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_form_state.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Abstract interface for delivery request controllers (StandardDelivery, HotlineD Direct).
///
/// This interface defines the contract that all delivery request controllers must implement.
/// It ensures type safety and allows widgets to work with any delivery request controller
/// without being tightly coupled to a specific implementation.
///
/// Both StandardDeliveryController and HotlineDirectController implement this interface,
/// differing only in their data filtering logic (by form category).
abstract class IDeliveryRequestController {
  // ========================================================================
  // STATE PROPERTIES
  // ========================================================================

  /// Complete list of delivery requests loaded from repository (unfiltered source data).
  RxList<StandardDeliveryModel> get allPendingRequests;

  /// Currently selected delivery request for detail view or editing.
  Rx<StandardDeliveryModel?> get currentSelectedRequest;

  /// Indicates whether a fetch/load operation is in progress.
  RxBool get isLoading;

  /// Indicates whether a save/update/delete operation is in progress.
  RxBool get isSaving;

  /// Storage preference flag for data source selection (local DB vs API).
  RxBool get useLocalStorage;

  /// Most recent error message from failed operations.
  RxnString get errorMessage;

  /// Cancellation remarks for the currently viewed delivery request.
  Rx<CancelRemarksModel?> get cancelRemarks;

  /// Request count statistics by status.
  RxInt get totalRequest;
  RxInt get gettingSuppliesReady;
  RxInt get itemPrepared;
  RxInt get forDelivery;
  RxInt get delivered;

  /// Identity of the user who created the current request.
  String get createdBy;

  /// Encapsulates all form-related state (text controllers, categories, dates, signatures).
  StandardDeliveryFormState get formState;

  /// Reference to user controller for accessing logged-in user information.
  UserController get userController;

  // ========================================================================
  // COMPUTED PROPERTIES
  // ========================================================================

  /// Returns the currently filtered list of delivery requests.
  List<StandardDeliveryModel> get filteredRequests;

  // ========================================================================
  // DATA LOADING & FETCHING
  // ========================================================================

  /// Fetches all delivery requests from the configured data source.
  /// Uses local database if [useLocalStorage] is true, otherwise fetches from API.
  Future<void> loadRequests();

  /// Loads item categories from the repository and populates form state.
  Future<void> loadCategories();

  /// Fetches cancellation remarks for a specific delivery request.
  Future<void> loadCancelRemarks(String requestId);

  /// Refresh requests by clearing local database and fetching from API.
  Future<void> refreshRequests();

  // ========================================================================
  // REQUEST COUNT TRACKING
  // ========================================================================

  /// Update request counts by status for dashboard statistics.
  void updateRequestCounts();

  // ========================================================================
  // FILTERING OPERATIONS
  // ========================================================================

  /// Updates the active status filter and reapplies filtering.
  void selectStatusFilter(StandardDeliveryStatusFilter statusFilter);

  /// Updates the active date range filter and reapplies filtering.
  void selectFilter(RequestFilter filter);

  // ========================================================================
  // CRUD OPERATIONS
  // ========================================================================

  /// Creates a new delivery request from the current form state.
  Future<void> saveRequest();

  /// Updates the status of a delivery request with automatic field population.
  Future<void> updateRequestStatus(StandardDeliveryModel requestModel,
      String newStatus, String userInitial);

  /// Cancels a delivery request with mandatory remarks explaining the reason.
  Future<void> updateRequestForCancellation(
      StandardDeliveryModel requestModel, String remarks,
      {bool showLoader = true});

  // ========================================================================
  // FORM STATE MANAGEMENT
  // ========================================================================

  /// Adds a new empty document reference field to the form.
  void addDocumentReferenceField();

  /// Removes a specific document reference field from the form.
  void removeDocumentReferenceField(TextEditingController controller);

  /// Updates the client information in the form state.
  void updateRequestClientInformation(ClientModel clientDetails);

  /// Sets the receiver's signature for delivery confirmation.
  void setSignature(Uint8List? signature);

  // ========================================================================
  // SETTINGS & PREFERENCES
  // ========================================================================

  /// Toggles the data source preference between local database and API.
  void toggleStoragePreference(bool value);
}
