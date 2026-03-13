import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/cancel_remarks_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/inventory/inventory_item_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_form_state.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_data_manager.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:iconsax/iconsax.dart';

/// Controller for managing Standard Delivery requests lifecycle, state, and business operations.
///
/// Responsibilities:
/// - Manages Standard Delivery request data (list, selection, CRUD operations)
/// - Handles filtering by status and date range
/// - Coordinates form state for create/update operations
/// - Manages local DB and API synchronization
/// - Handles signature capture and image proof uploads
/// - Tracks request counts by status
class StandardDeliveryController extends GetxController
    implements IDeliveryRequestController {
  static StandardDeliveryController get instance => Get.find();

  // ========================================================================
  // STATE PROPERTIES
  // ========================================================================

  /// Complete list of Standard Delivery requests loaded from repository.
  /// This is the unfiltered source data.
  @override
  final RxList<StandardDeliveryModel> allPendingRequests =
      <StandardDeliveryModel>[].obs;

  /// Currently selected Standard Delivery request for detail view or editing.
  /// Null when no request is selected.
  @override
  final Rx<StandardDeliveryModel?> currentSelectedRequest =
      Rx<StandardDeliveryModel?>(null);

  /// Indicates whether a fetch/load operation is in progress.
  /// Used to show loading indicators in the UI.
  @override
  final RxBool isLoading = false.obs;

  /// Indicates whether a save/update/delete operation is in progress.
  /// Prevents duplicate submissions during async operations.
  @override
  final RxBool isSaving = false.obs;

  /// Storage preference flag for data source selection.
  /// - true: Use local database (offline-first approach)
  /// - false: Fetch directly from API/server (default)
  @override
  final RxBool useLocalStorage = false.obs;

  /// Stores the most recent error message from failed operations.
  /// Null when no error has occurred.
  @override
  final RxnString errorMessage = RxnString();

  /// Cancellation remarks data for the currently viewed Standard Delivery request.
  /// Contains remarks and cancellation date when a request is cancelled.
  @override
  final Rx<CancelRemarksModel?> cancelRemarks = Rx<CancelRemarksModel?>(null);

  /// Request count by status for dashboard/statistics display.
  @override
  final RxInt totalRequest = 0.obs;
  @override
  final RxInt gettingSuppliesReady = 0.obs;
  @override
  final RxInt itemPrepared = 0.obs;
  @override
  final RxInt forDelivery = 0.obs;
  @override
  final RxInt delivered = 0.obs;

  /// Identity of the user who created the current request.
  /// Automatically populated from logged-in user's initials.
  @override
  String createdBy = '';

  // ========================================================================
  // INVENTORY OCR STATE
  // ========================================================================

  /// Whether an analyze-file request is currently in flight.
  final RxBool isAnalyzingFile = false.obs;

  /// Last error from an analyze-file attempt. Null when no error.
  final RxnString analyzeError = RxnString();

  // ========================================================================
  // MANAGERS & DEPENDENCIES
  // ========================================================================

  /// Manages filtering logic for Standard Delivery requests (by status and date).
  late final StandardDeliveryFilterManager filterManager;

  /// Handles data operations including CRUD, validation, and API calls.
  late final StandardDeliveryDataManager dataManager;

  /// Encapsulates all form-related state (text controllers, categories, dates, signatures).
  @override
  late final StandardDeliveryFormState formState;

  /// Reference to user controller for accessing logged-in user information.
  @override
  late final UserController userController;

  // ========================================================================
  // LIFECYCLE METHODS
  // ========================================================================

  @override
  Future<void> onInit() async {
    super.onInit();

    // Initialize managers
    filterManager = StandardDeliveryFilterManager();
    dataManager = StandardDeliveryDataManager();

    // Initialize form state with default values
    formState = StandardDeliveryFormState();
    formState.initializeDefaultDate();

    // Load initial data
    await dataManager.loadCategories(this);
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

  /// Returns the currently filtered list of Standard Delivery requests.
  /// Applies active status and date filters from the filter manager.
  @override
  List<StandardDeliveryModel> get filteredRequests =>
      filterManager.filteredRequests;

  // ========================================================================
  // DATA LOADING & FETCHING
  // ========================================================================

  /// Fetches all Standard Delivery requests from the configured data source.
  /// Uses local database if [useLocalStorage] is true, otherwise fetches from API.
  /// Automatically updates the [allPendingRequests] list and applies active filters.
  @override
  Future<void> loadRequests() async {
    await dataManager.fetchStandardDeliveryRequests(
        this, useLocalStorage.value);
  }

  /// Loads item categories from the repository and populates form state.
  /// Safe to call multiple times; will not duplicate data.
  /// Sets default category selection (prefers 'reagent' if available).
  @override
  Future<void> loadCategories() async {
    await dataManager.loadCategories(this);
  }

  /// Fetches cancellation remarks for a specific Standard Delivery request.
  /// Updates [cancelRemarks] with the retrieved data or empty model on failure.
  ///
  /// [requestId] The unique identifier of the Standard Delivery request
  @override
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
  @override
  Future<void> refreshRequests() async {
    await dataManager.fetchStandardDeliveryRequests(this, false);
  }

  // ========================================================================
  // REQUEST COUNT TRACKING
  // ========================================================================

  /// Update request counts by status for dashboard statistics.
  /// Counts requests in each status category from the unfiltered list.
  @override
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

  /// Updates the active status filter and reapplies filtering to the Standard Delivery list.
  ///
  /// Available status filters:
  /// - All: Shows all Standard Delivery requests
  /// - New Request: Shows only newly created requests
  /// - Getting Supplies Ready: Shows requests being prepared
  /// - Item Prepared: Shows requests with prepared items
  /// - For Delivery: Shows requests out for delivery
  /// - Delivered: Shows completed deliveries
  ///
  /// [statusFilter] The status filter to apply
  @override
  void selectStatusFilter(StandardDeliveryStatusFilter statusFilter) {
    filterManager.selectStatusFilter(statusFilter, allPendingRequests);
  }

  /// Updates the active date range filter and reapplies filtering to the Standard Delivery list.
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
  @override
  void selectFilter(RequestFilter filter) {
    filterManager.selectFilter(filter, allPendingRequests);
  }

  // ========================================================================
  // CRUD OPERATIONS
  // ========================================================================

  /// Creates a new Standard Delivery request from the current form state.
  /// Validates all required fields (client, document references, delivery date).
  /// Shows loading dialog during submission and displays success/error feedback.
  ///
  /// Validation includes:
  /// - Client selection is required
  /// - At least one document reference must be provided
  /// - Requested by must be selected
  ///
  /// Note: Form reset is handled by the data manager after successful save.
  @override
  Future<void> saveRequest() async {
    await dataManager.saveRequestFromForm(this);
  }

  /// Updates the status of a Standard Delivery request with automatic field population.
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
  /// [requestModel] The Standard Delivery request to update
  /// [newStatus] The new status to set (must be a valid status string)
  /// [userInitial] The initial of the user performing the status update
  @override
  Future<void> updateRequestStatus(StandardDeliveryModel requestModel,
      String newStatus, String userInitial) async {
    await dataManager.updateRequestStatus(
      requestModel,
      newStatus,
      userInitial,
      this,
    );
  }

  /// Cancels a Standard Delivery request with mandatory remarks explaining the reason.
  /// Validates network connectivity before submission.
  /// Refreshes the Standard Delivery list after successful cancellation.
  ///
  /// The cancellation is recorded with:
  /// - Requesting user's identifier
  /// - Cancellation remarks/reason
  /// - Current timestamp
  ///
  /// [requestModel] The Standard Delivery request to cancel
  /// [remarks] Explanation for the cancellation (required)
  /// [showLoader] Whether to show loading dialog (default: true)
  @override
  Future<void> updateRequestForCancellation(
      StandardDeliveryModel requestModel, String remarks,
      {bool showLoader = true}) async {
    final user = userController.user.value.initial;
    await dataManager.cancelRequestWithRemarks(
        requestModel, remarks, user, this, useLocalStorage.value);
  }

  // ========================================================================
  // FORM STATE MANAGEMENT
  // ========================================================================

  /// Adds a new empty document reference field to the form.
  /// Creates a new TextEditingController and adds it to the reactive list.
  @override
  void addDocumentReferenceField() {
    formState.documentReferenceControllers.add(TextEditingController());
  }

  /// Removes a specific document reference field from the form.
  /// Disposes the controller to prevent memory leaks.
  ///
  /// [controller] The TextEditingController to remove and dispose
  @override
  void removeDocumentReferenceField(TextEditingController controller) {
    controller.dispose();
    formState.documentReferenceControllers.remove(controller);
  }

  /// Updates the client information in the form state.
  /// Triggers reactive updates in the UI.
  ///
  /// [clientDetails] The new client information to set
  @override
  void updateRequestClientInformation(ClientModel clientDetails) {
    formState.clientInformation.value = clientDetails;
  }

  /// Sets the receiver's signature for delivery confirmation.
  /// Converts the signature bytes to Base64 for storage and transmission.
  ///
  /// [signature] The signature image bytes, or null to clear
  @override
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
  /// Automatically reloads Standard Delivery data using the newly selected source.
  ///
  /// Use cases:
  /// - Enable local storage for offline mode or faster loading
  /// - Disable local storage to force fresh data from server
  ///
  /// [value] True to use local storage, false to use API directly
  @override
  void toggleStoragePreference(bool value) {
    useLocalStorage.value = value;
    loadRequests();
  }

  // ========================================================================
  // INVENTORY OCR OPERATIONS
  // ========================================================================

  /// Sends [file] (picture or PDF) to the Gemini analyze-file endpoint via
  /// [InventoryItemRepository] and populates [scannedInventoryItems] with the
  /// parsed results.
  ///
  /// Sets [isAnalyzingFile] while the request is in flight and updates
  /// [analyzeError] on failure.
  Future<void> analyzeFileForInventory(File file) async {
    try {
      isAnalyzingFile.value = true;
      analyzeError.value = null;

      final repo = Get.find<InventoryItemRepository>();
      final result = await repo.analyzeFile(file);

      if (result.isSuccess) {
        // store scanned items in the form state so UI/widgets bound to the form
        // will react accordingly
        formState.scannedInventoryItems.addAll(result.value);
        logDebug(
            'StandardDeliveryController: Parsed ${result.value.length} inventory items');
      } else {
        analyzeError.value = result.error;
        logDebug(
            'StandardDeliveryController: analyzeFile failed – ${result.error}');
      }
    } catch (e) {
      analyzeError.value = e.toString();
      logDebug(
          'StandardDeliveryController: analyzeFileForInventory error – $e');
    } finally {
      isAnalyzingFile.value = false;
    }
  }

  /// Opens the device camera (or camera UI) and forwards the captured image
  /// file to [analyzeFileForInventory]. This method centralizes permission and
  /// platform handling so the UI widget stays pure.
  Future<void> pickAndAnalyzeFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? picked =
          await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (picked == null) return;
      final file = File(picked.path);
      await analyzeFileWithAiToolkit(file);
      return;
    } catch (e, st) {
      analyzeError.value = 'Camera error: ${e.toString()}';
      try {
        logDebug('pickAndAnalyzeFromCamera error: $e\n$st');
      } catch (_) {}
    }
  }

  /// Presents a gallery/file chooser and forwards the selected file to
  /// [analyzeFileForInventory]. Handles bytes-only platforms by writing a
  /// temporary file when necessary.
  Future<void> pickAndAnalyzeFromFile() async {
    try {
      final context =
          Get.context ?? Get.rootDelegate.navigatorKey.currentContext;
      if (context == null) {
        analyzeError.value = 'Unable to access context for file picker.';
        return;
      }

      final choice = await showModalBottomSheet<String?>(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Iconsax.image),
                  title: const Text('Pick image from gallery'),
                  onTap: () => Navigator.of(ctx).pop('gallery'),
                ),
                ListTile(
                  leading: const Icon(Iconsax.folder_2),
                  title: const Text('Pick any file'),
                  onTap: () => Navigator.of(ctx).pop('file'),
                ),
                ListTile(
                  leading: const Icon(Iconsax.close_circle),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.of(ctx).pop(null),
                ),
              ],
            ),
          );
        },
      );

      if (choice == null) return;

      if (choice == 'gallery') {
        final picker = ImagePicker();
        final XFile? picked = await picker.pickImage(
            source: ImageSource.gallery, imageQuality: 85);
        if (picked == null) return;
        final file = File(picked.path);
        await analyzeFileWithAiToolkit(file);
        return;
      }

      if (choice == 'file') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowMultiple: false,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
          withData: true,
        );

        if (result == null || result.files.isEmpty) return;
        final picked = result.files.single;

        String? path = picked.path;
        if (path == null && picked.bytes != null) {
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/${picked.name}');
          await tempFile.writeAsBytes(picked.bytes!);
          path = tempFile.path;
        }

        if (path == null) {
          analyzeError.value = 'Unable to resolve selected file path.';
          return;
        }

        final file = File(path);
        if (!await file.exists()) {
          analyzeError.value = 'Selected file does not exist.';
          return;
        }

        await analyzeFileWithAiToolkit(file);
        return;
      }
    } catch (e, st) {
      analyzeError.value = 'File picker error: ${e.toString()}';
      try {
        logDebug('pickAndAnalyzeFromFile error: $e\n$st');
      } catch (_) {}
    }
  }

  /// Removes a single scanned inventory item at [index].
  void removeScannedItem(int index) {
    final items = formState.scannedInventoryItems;
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  /// Clears all scanned inventory items.
  void clearScannedItems() {
    formState.scannedInventoryItems.clear();
    analyzeError.value = null;
  }

  /// Analyze [file] using Google Generative Language (gemini) by sending the
  /// file bytes and prompt in the `contents` -> `parts` -> `inlineData` + `text`
  /// request body and extracting the first candidate content text from the
  /// response. This is a minimal, direct implementation (no retries/fallbacks).
  Future<void> analyzeFileWithAiToolkit(File file, {String? prompt}) async {
    isAnalyzingFile.value = true;
    analyzeError.value = null;
    try {
      final repo = Get.find<InventoryItemRepository>();
      final result = await repo.analyzeFileWithGemini(file, prompt: prompt);

      if (result.isSuccess) {
        formState.scannedInventoryItems.addAll(result.value);
        logDebug('analyzeFileWithAiToolkit: Parsed ${result.value.length} inventory items via repository');
      } else {
        analyzeError.value = result.error;
        logDebug('analyzeFileWithAiToolkit: repository error – ${result.error}');
      }
    } catch (e, st) {
      analyzeError.value = e.toString();
      logDebug('analyzeFileWithAiToolkit error – $e\n$st');
    } finally {
      isAnalyzingFile.value = false;
    }
  }

}
