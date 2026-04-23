import 'dart:math';

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

  /// Search query for the bucket screen.
  final RxString bucketSearchQuery = ''.obs;
  final RxDouble bucketMinAmount = 0.0.obs;
  final RxDouble bucketMaxAmount = 0.0.obs;
  final RxInt bucketMinInvoices = 0.obs;
  final RxInt bucketMaxInvoices = 0.obs;

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

  /// Filtered view of bucket items based on [bucketSearchQuery].
  List<CollectionItemModel> get filteredBucketItems {
    if (bucketSearchQuery.value.isEmpty) return bucketItems;

    final query = bucketSearchQuery.value.toLowerCase();
    return bucketItems.where((item) {
      return item.client.name.toLowerCase().contains(query) ||
          item.id.toLowerCase().contains(query) ||
          item.bankName.toLowerCase().contains(query) ||
          item.documentReferences.any((ref) => ref.toLowerCase().contains(query));
    }).toList();
  }

  // ========================================================================
  // Move selected bucket items → activity
  // ========================================================================

  // ========================================================================
  // Account Grouping Helpers (Bucket)
  // ========================================================================

  /// List of all unique clients (Accounts) that we want to track in the bucket.
  /// This is used as the master list so accounts stay visible even with 0 items.
  final RxList<ClientModel> masterAccountList = <ClientModel>[].obs;

  /// Returns a list of clients (Accounts) currently in the bucket, filtered by UI criteria.
  List<ClientModel> get bucketAccounts {
    return masterAccountList.where((client) {
      // 1. Filter by Search Query (Account Name)
      if (bucketSearchQuery.value.isNotEmpty &&
          !client.name.toLowerCase().contains(bucketSearchQuery.value.toLowerCase())) {
        return false;
      }

      // 2. Calculate thresholds
      final totalAmount = getAccountTotalDue(client.id);
      final invoiceCount = getAccountInvoiceCount(client.id);

      // 3. Filter by Amount Range
      if (bucketMinAmount.value > 0 && totalAmount < bucketMinAmount.value) return false;
      if (bucketMaxAmount.value > 0 && totalAmount > bucketMaxAmount.value) return false;

      // 4. Filter by Invoice Count Range
      if (bucketMinInvoices.value > 0 && invoiceCount < bucketMinInvoices.value) return false;
      if (bucketMaxInvoices.value > 0 && invoiceCount > bucketMaxInvoices.value) return false;

      return true;
    }).toList();
  }

  /// Get all bucket items for a specific client.
  List<CollectionItemModel> getInvoicesByAccount(String clientId) {
    return bucketItems.where((item) => item.client.id == clientId).toList();
  }

  /// Get total amount due for a specific client in the bucket.
  double getAccountTotalDue(String clientId) {
    return bucketItems
        .where((item) => item.client.id == clientId)
        .fold(0.0, (sum, item) => sum + item.toBeCollected);
  }

  /// Get total number of invoices for a specific client in the bucket.
  int getAccountInvoiceCount(String clientId) {
    return bucketItems.where((item) => item.client.id == clientId).length;
  }

  /// Claims items by a list of IDs.
  void claimItemsByIds(List<String> ids) {
    if (ids.isEmpty) return;

    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    for (final id in ids) {
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
    
    // Clear selection if any of these were in the global selectedBucketIds
    selectedBucketIds.removeWhere((id) => ids.contains(id));
    
    logDebug('[CollectionActivityController] Claimed ${ids.length} items');
  }

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
    final List<ClientModel> clients = [
      ClientModel(id: 'C001', code: 'MD-C001', name: 'ABC Corporation', address: '123 Main St, Makati', contact: '09171234567', emailAddress: 'abc@corp.com'),
      ClientModel(id: 'C002', code: 'MD-C002', name: 'XYZ Trading', address: '456 Rizal Ave, Quezon City', contact: '09189876543', emailAddress: 'xyz@trading.ph'),
      ClientModel(id: 'C003', code: 'MD-C003', name: 'LMN Enterprises', address: '789 EDSA, Mandaluyong', contact: '09201112233', emailAddress: 'lmn@ent.com'),
      ClientModel(id: 'C004', code: 'MD-C004', name: 'PQR Industries', address: '321 Ayala Blvd, Makati', contact: '09334455667', emailAddress: 'pqr@ind.com'),
      ClientModel(id: 'C005', code: 'MD-C005', name: 'STU Holdings', address: '654 Shaw Blvd, Pasig', contact: '09557788990', emailAddress: 'stu@hold.com'),
      ClientModel(id: 'C006', code: 'MD-C006', name: 'VWX Solutions', address: '987 Aurora Blvd, Cubao', contact: '09664433221', emailAddress: 'vwx@sol.com'),
      ClientModel(id: 'C007', code: 'MD-C007', name: 'Global Logistics Inc.', address: '555 Port Area, Manila', contact: '09771230000', emailAddress: 'global@logistics.com'),
      ClientModel(id: 'C008', code: 'MD-C008', name: 'Prime Manufacturing', address: '222 Industrial Ave, Cavite', contact: '09885551234', emailAddress: 'prime@mfg.com'),
    ];

    masterAccountList.assignAll(clients);

    final List<CollectionItemModel> generatedItems = [];
    final random = Random();

    for (var client in clients) {
      // Generate 5-15 invoices per account
      final invoiceCount = 5 + random.nextInt(11);
      
      for (int i = 1; i <= invoiceCount; i++) {
        final amount = 1000.0 + random.nextInt(49001); // 1,000 to 50,000
        final id = 'INV-${client.id}-${100 + i}';
        
        // Generate sample dates
        final postingDate = '2026-01-${10 + random.nextInt(15)}';
        
        // Generate diverse Due Dates for monitoring
        String dueDate;
        final dateType = random.nextInt(10); 
        if (dateType < 3) {
          // 30% Overdue (Past)
          dueDate = '2026-02-${10 + random.nextInt(15)}';
        } else if (dateType < 8) {
          // 50% On Schedule (Next 3-4 months)
          final month = 4 + random.nextInt(3); // April to June
          dueDate = '2026-0$month-${10 + random.nextInt(15)}';
        } else {
          // 20% Long Term (Next Year)
          dueDate = '2027-0${1 + random.nextInt(3)}-${10 + random.nextInt(15)}';
        }

        generatedItems.add(CollectionItemModel(
          id: id,
          client: client,
          bpCode: client.code,
          postingDate: postingDate,
          dueDate: dueDate,
          documentReferences: ['REF-$id'],
          bankName: ['BDO', 'BPI', 'Metrobank', 'RCBC', 'Landbank'][random.nextInt(5)],
          toBeCollected: amount,
          totalCollected: 0,
          documentDate: postingDate, // Using posting date as document date for consistency
          remarks: [
            'Post-dated cheque', 
            'Regular collection', 
            'Urgent collection', 
            'Partial payment pending', 
            'Verification needed'
          ][random.nextInt(5)],
          coreStatus: CollectionStatusColors.statusUnassigned,
          delayStatus: CollectionStatusColors.statusOnSchedule,
          outcomeStatus: CollectionStatusColors.statusNone,
          administrativeStatus: CollectionStatusColors.statusForVerification,
          collectorName: 'Unassigned',
          history: [
            CollectionHistoryModel(
              date: '2026-03-01 08:00',
              collectorName: 'System',
              coreStatus: CollectionStatusColors.statusUnassigned,
              remarks: 'Invoice generated in system',
            ),
          ],
        ));
      }
    }

    bucketItems.assignAll(generatedItems);
    
    // Original sample activity items for other screens
    activityItems.assignAll([
      CollectionItemModel(
        id: 'COL-ACT-001',
        client: clients[0],
        bpCode: clients[0].code,
        postingDate: '2026-02-15',
        dueDate: '2026-03-10',
        documentReferences: ['CHQ-PREV-1'],
        bankName: 'BDO',
        toBeCollected: 5000,
        totalCollected: 0,
        documentDate: '2026-02-20',
        coreStatus: CollectionStatusColors.statusOngoing,
        delayStatus: CollectionStatusColors.statusOnSchedule,
        outcomeStatus: CollectionStatusColors.statusNone,
        administrativeStatus: CollectionStatusColors.statusForVerification,
        collectorName: 'John Doe',
        assignedAt: '2026-03-01 09:00',
      )
    ]);
  }
}

