import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
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
  /// [activityItems] with status `'Pending'` and records the assignment time.
  void claimSelectedItems() {
    if (selectedBucketIds.isEmpty) return;

    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    for (final id in selectedBucketIds) {
      final index = bucketItems.indexWhere((e) => e.id == id);
      if (index == -1) continue;

      final item = bucketItems[index].copyWith(
        status: CollectionStatusColors.statusPending,
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

  /// Update the status of an activity item.
  void updateActivityStatus(String id, String newStatus) {
    final index = activityItems.indexWhere((e) => e.id == id);
    if (index == -1) return;
    activityItems[index] = activityItems[index].copyWith(status: newStatus);
  }

  /// Set the current filter on the activity screen.
  void setActivityFilter(String filter) => activityFilter.value = filter;

  /// Filtered view of activity items based on [activityFilter].
  List<CollectionItemModel> get filteredActivityItems {
    if (activityFilter.value == 'All') return activityItems;
    return activityItems
        .where((e) => e.status == activityFilter.value)
        .toList();
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
        amount: 25000,
        documentDate: '2026-03-01',
        remarks: 'Post-dated cheque',
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
        amount: 18500,
        documentDate: '2026-02-28',
        remarks: 'Overdue 5 days',
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
        amount: 42000,
        documentDate: '2026-03-02',
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
        amount: 15750,
        documentDate: '2026-03-03',
        remarks: 'Cash on delivery alternative',
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
        amount: 33200,
        documentDate: '2026-03-01',
      ),
    ]);
  }
}

