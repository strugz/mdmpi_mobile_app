import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// Manages the Collection Bucket → Activity flow.
///
/// **Bucket items** have no assigned personnel — they only carry client
/// details and document details. When the user selects items from the bucket
/// they are moved into the **activity list** and assigned to the current user.
class CollectionActivityController extends GetxController {
  static CollectionActivityController get instance => Get.find();

  // ========================================================================
  // Observable state
  // ========================================================================

  /// Items available in the collection bucket (unassigned).
  final RxList<CollectionItemModel> bucketItems = <CollectionItemModel>[].obs;

  /// Items the user has claimed / is working on.
  final RxList<CollectionItemModel> activityItems = <CollectionItemModel>[].obs;

  /// IDs currently selected (multi-select) inside the bucket screen.
  final RxSet<String> selectedBucketIds = <String>{}.obs;

  /// Loading flag.
  final RxBool isLoading = false.obs;

  /// Active filter on the activity screen.
  final RxString activityFilter = 'All'.obs;

  /// Active category filter (e.g. 'Core Status', 'Delays').
  final RxString categoryFilter = 'All'.obs;

  // ========================================================================
  // Lifecycle
  // ========================================================================

  @override
  void onInit() {
    super.onInit();
    _loadSampleBucketItems();
  }

  // ========================================================================
  // Bucket selection
  // ========================================================================

  /// Toggle selection state for a single bucket item.
  void toggleBucketSelection(String id) {
    if (selectedBucketIds.contains(id)) {
      selectedBucketIds.remove(id);
    } else {
      selectedBucketIds.add(id);
    }
  }

  /// Select / deselect all bucket items.
  void toggleSelectAll() {
    if (selectedBucketIds.length == bucketItems.length) {
      selectedBucketIds.clear();
    } else {
      selectedBucketIds
        ..clear()
        ..addAll(bucketItems.map((e) => e.id));
    }
  }

  /// Whether a specific item is currently selected.
  bool isSelected(String id) => selectedBucketIds.contains(id);

  /// True when every bucket item is selected.
  bool get allSelected =>
      bucketItems.isNotEmpty &&
      selectedBucketIds.length == bucketItems.length;

  // ========================================================================
  // Move selected bucket items → activity
  // ========================================================================

  /// Claim the selected bucket items – moves them from [bucketItems] into
  /// [activityItems] with updated statuses and records the assignment time.
  void claimSelectedItems() {
    if (selectedBucketIds.isEmpty) return;

    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    for (final id in selectedBucketIds) {
      final index = bucketItems.indexWhere((e) => e.id == id);
      if (index == -1) continue;

      final item = bucketItems[index].copyWith(
        coreStatus: CollectionStatusColors.statusOngoing,
        delayStatus: CollectionStatusColors.statusOnSchedule,
        outcomeStatus: CollectionStatusColors.statusNone,
        administrativeStatus: CollectionStatusColors.statusForVerification,
        assignedAt: now,
      );
      activityItems.add(item);
      bucketItems.removeAt(index);
    }

    selectedBucketIds.clear();
    logDebug(
        '[CollectionActivityController] Claimed ${activityItems.length} items');
  }

  // ========================================================================
  // Activity helpers
  // ========================================================================

  /// Update a specific status category of an activity item.
  void updateActivityStatus(String id, String category, String newStatus) {
    final index = activityItems.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = activityItems[index];
    CollectionItemModel updatedItem;

    switch (category) {
      case CollectionStatusColors.categoryCoreFlow:
        updatedItem = item.copyWith(coreStatus: newStatus);
        break;
      case CollectionStatusColors.categoryDelays:
        updatedItem = item.copyWith(delayStatus: newStatus);
        break;
      case CollectionStatusColors.categoryOutcomes:
        updatedItem = item.copyWith(outcomeStatus: newStatus);
        break;
      case CollectionStatusColors.categoryAdministrative:
        updatedItem = item.copyWith(administrativeStatus: newStatus);
        break;
      default:
        updatedItem = item;
    }

    activityItems[index] = updatedItem;
  }

  /// Save the activity updates and move the item back to the bucket list.
  void saveActivity({
    required String id,
    required String delayStatus,
    required String outcomeStatus,
    required String administrativeStatus,
    required String remarks,
    double? totalCollected,
  }) {
    final index = activityItems.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final oldItem = activityItems[index];
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    // Update item and calculate new balance
    final double newlyCollected = totalCollected ?? 0;
    final double updatedTotalCollected = oldItem.totalCollected + newlyCollected;
    final double updatedToBeCollected = (oldItem.toBeCollected - newlyCollected).clamp(0, double.infinity);

    // Auto-update outcome status if fully collected
    String finalOutcomeStatus = outcomeStatus;
    if (updatedToBeCollected == 0) {
      finalOutcomeStatus = CollectionStatusColors.statusFullyCollected;
    } else if (newlyCollected > 0 && finalOutcomeStatus == CollectionStatusColors.statusNone) {
      // If they collected something but didn't set a status, default to partial
      finalOutcomeStatus = CollectionStatusColors.statusPartiallyCollected;
    }

    // Create history entry
    final historyEntry = CollectionHistoryModel(
      date: now,
      collectorName: oldItem.collectorName,
      coreStatus: oldItem.coreStatus,
      delayStatus: delayStatus,
      outcomeStatus: finalOutcomeStatus,
      administrativeStatus: administrativeStatus,
      remarks: remarks,
      totalCollected: newlyCollected,
    );

    final updatedItem = oldItem.copyWith(
      delayStatus: delayStatus,
      outcomeStatus: finalOutcomeStatus,
      administrativeStatus: administrativeStatus,
      remarks: remarks,
      toBeCollected: updatedToBeCollected,
      totalCollected: updatedTotalCollected,
      history: [...oldItem.history, historyEntry],
      assignedAt: 'N/A',
      collectorName: 'Unassigned',
      coreStatus: CollectionStatusColors.statusUnassigned,
    );

    // Move to bucket
    bucketItems.add(updatedItem);
    activityItems.removeAt(index);

    logDebug('[CollectionActivityController] Activity $id saved and moved to bucket');
  }

  /// Set the current filter on the activity screen.
  void setActivityFilter(String filter) => activityFilter.value = filter;

  /// Set the current category filter.
  void setCategoryFilter(String category) {
    categoryFilter.value = category;
    activityFilter.value = 'All'; // Reset sub-filter when category changes
  }

  /// Filtered view of activity items based on [activityFilter] and [categoryFilter].
  List<CollectionItemModel> get filteredActivityItems {
    Iterable<CollectionItemModel> items = activityItems;

    // First, filter by category context if specified (for the detail screens)
    if (categoryFilter.value != 'All') {
      items = items.where((e) {
        switch (categoryFilter.value) {
          case 'Core Status':
            // Show all items since everything in activity has a Core Status
            return true; 
          case 'Delays':
            // Only show if it has an active delay (not "On Schedule")
            return e.delayStatus != CollectionStatusColors.statusOnSchedule;
          case 'Completed':
            // Only show if it has an outcome (not "None")
            return e.outcomeStatus != CollectionStatusColors.statusNone;
          case 'Administrative':
            // For Administrative, we show all since they all have an admin status 
            // (default "For Verification")
            return true;
          default:
            return true;
        }
      });
    }

    // Then, filter by specific sub-status if not "All"
    if (activityFilter.value == 'All') return items.toList();

    return items.where((e) {
      // Check if the current activityFilter matches ANY of the four statuses
      return e.coreStatus == activityFilter.value ||
          e.delayStatus == activityFilter.value ||
          e.outcomeStatus == activityFilter.value ||
          e.administrativeStatus == activityFilter.value;
    }).toList();
  }

  // ========================================================================
  // Sample data (will be replaced by repository calls)
  // ========================================================================

  void _loadSampleBucketItems() {
    bucketItems.assignAll([
      CollectionItemModel(
        id: 'COL-001',
        client: ClientModel(
          id: 'C001',
          name: 'ABC Corporation',
          address: '123 Main St, Makati',
          contact: '09171234567',
          emailAddress: 'abc@corp.com',
        ),
        documentReferences: ['CHQ-001234'],
        bankName: 'BDO',
        toBeCollected: 25000,
        totalCollected: 0,
        documentDate: '2026-03-01',
        remarks: 'Post-dated cheque',
        coreStatus: CollectionStatusColors.statusUnassigned,
        delayStatus: CollectionStatusColors.statusOnSchedule,
        outcomeStatus: CollectionStatusColors.statusNone,
        administrativeStatus: CollectionStatusColors.statusForVerification,
        collectorName: 'John Doe',
        history: [
          CollectionHistoryModel(
            date: '2026-03-01 09:00',
            collectorName: 'System',
            coreStatus: CollectionStatusColors.statusUnassigned,
            remarks: 'Item created in bucket',
          ),
        ],
      ),
      CollectionItemModel(
        id: 'COL-002',
        client: ClientModel(
          id: 'C002',
          name: 'XYZ Trading',
          address: '456 Rizal Ave, Quezon City',
          contact: '09189876543',
          emailAddress: 'xyz@trading.ph',
        ),
        documentReferences: ['CHQ-005678'],
        bankName: 'Metrobank',
        toBeCollected: 18500,
        totalCollected: 0,
        documentDate: '2026-02-28',
        remarks: 'Overdue 5 days',
        coreStatus: CollectionStatusColors.statusUnassigned,
        delayStatus: CollectionStatusColors.statusBehindSchedule,
        outcomeStatus: CollectionStatusColors.statusNone,
        administrativeStatus: CollectionStatusColors.statusForVerification,
        collectorName: 'Jane Smith',
        history: [
          CollectionHistoryModel(
            date: '2026-02-28 10:00',
            collectorName: 'Admin',
            coreStatus: CollectionStatusColors.statusUnassigned,
            delayStatus: CollectionStatusColors.statusBehindSchedule,
            remarks: 'Marked as behind schedule by supervisor',
          ),
        ],
      ),
      CollectionItemModel(
        id: 'COL-003',
        client: ClientModel(
          id: 'C003',
          name: 'LMN Enterprises',
          address: '789 EDSA, Mandaluyong',
          contact: '09201112233',
          emailAddress: 'lmn@ent.com',
        ),
        documentReferences: ['CHQ-009012', 'CHQ-009013'],
        bankName: 'BPI',
        toBeCollected: 42000,
        totalCollected: 42000,
        documentDate: '2026-03-02',
        coreStatus: CollectionStatusColors.statusOngoing,
        delayStatus: CollectionStatusColors.statusOnSchedule,
        outcomeStatus: CollectionStatusColors.statusFullyCollected,
        administrativeStatus: CollectionStatusColors.statusForVerification,
        collectorName: 'John Doe',
        assignedAt: '2026-03-02 08:30',
        history: [
          CollectionHistoryModel(
            date: '2026-03-02 08:30',
            collectorName: 'John Doe',
            coreStatus: CollectionStatusColors.statusOngoing,
            remarks: 'Claimed from bucket',
          ),
          CollectionHistoryModel(
            date: '2026-03-02 14:00',
            collectorName: 'John Doe',
            coreStatus: CollectionStatusColors.statusOngoing,
            outcomeStatus: CollectionStatusColors.statusFullyCollected,
            remarks: 'Successfully collected the cheque',
          ),
        ],
      ),
      CollectionItemModel(
        id: 'COL-004',
        client: ClientModel(
          id: 'C004',
          name: 'PQR Industries',
          address: '321 Ayala Blvd, Makati',
          contact: '09334455667',
          emailAddress: 'pqr@ind.com',
        ),
        documentReferences: ['CHQ-003456'],
        bankName: 'Landbank',
        toBeCollected: 15750,
        totalCollected: 0,
        documentDate: '2026-03-03',
        remarks: 'Cash on delivery alternative',
        coreStatus: CollectionStatusColors.statusOngoing,
        delayStatus: CollectionStatusColors.statusRescheduled,
        outcomeStatus: CollectionStatusColors.statusNone,
        administrativeStatus: CollectionStatusColors.statusOnHold,
      ),
      CollectionItemModel(
        id: 'COL-005',
        client: ClientModel(
          id: 'C005',
          name: 'STU Holdings',
          address: '654 Shaw Blvd, Pasig',
          contact: '09557788990',
          emailAddress: 'stu@hold.com',
        ),
        documentReferences: ['CHQ-007890'],
        bankName: 'RCBC',
        toBeCollected: 33200,
        totalCollected: 0,
        documentDate: '2026-03-01',
        coreStatus: CollectionStatusColors.statusOngoing,
        delayStatus: CollectionStatusColors.statusOnSchedule,
        outcomeStatus: CollectionStatusColors.statusNone,
        administrativeStatus: CollectionStatusColors.statusCancelled,
      ),
    ]);
  }
}

