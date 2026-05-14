import 'dart:math';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Manages the Collection Bucket → Activity flow with a simplified status model.
class CollectionActivityController extends GetxController {
  static CollectionActivityController get instance => Get.find();

  // ========================================================================
  // Observable state
  // ========================================================================

  final RxList<CollectionItemModel> bucketItems = <CollectionItemModel>[].obs;
  final RxList<CollectionItemModel> activityItems = <CollectionItemModel>[].obs;
  final RxSet<String> selectedBucketIds = <String>{}.obs;
  final RxBool isLoading = false.obs;

  /// Search and Filter state
  final RxString bucketSearchQuery = ''.obs;
  final RxDouble bucketMinAmount = 0.0.obs;
  final RxDouble bucketMaxAmount = 0.0.obs;
  final RxInt bucketMinInvoices = 0.obs;
  final RxInt bucketMaxInvoices = 0.obs;

  final RxString activitySearchQuery = ''.obs;
  final RxDouble activityMinAmount = 0.0.obs;
  final RxDouble activityMaxAmount = 0.0.obs;
  final RxInt activityMinInvoices = 0.obs;
  final RxInt activityMaxInvoices = 0.obs;

  final RxString activityFilter = 'All'.obs;

  final RxString invoiceSearchQuery = ''.obs;

  final RxList<ClientModel> masterAccountList = <ClientModel>[].obs;

  // ========================================================================
  // Lifecycle
  // ========================================================================

  @override
  void onInit() {
    super.onInit();
    _loadSampleBucketItems();
  }

  // ========================================================================
  // Bucket helpers
  // ========================================================================

  void toggleBucketSelection(String id) {
    if (selectedBucketIds.contains(id)) {
      selectedBucketIds.remove(id);
    } else {
      selectedBucketIds.add(id);
    }
  }

  void toggleSelectAll() {
    if (selectedBucketIds.length == bucketItems.length) {
      selectedBucketIds.clear();
    } else {
      selectedBucketIds
        ..clear()
        ..addAll(bucketItems.map((e) => e.id));
    }
  }

  bool isSelected(String id) => selectedBucketIds.contains(id);

  bool get allSelected =>
      bucketItems.isNotEmpty &&
      selectedBucketIds.length == bucketItems.length;

  List<ClientModel> get bucketAccounts {
    return masterAccountList.where((client) {
      final invoiceCount = getAccountInvoiceCount(client.id);
      if (invoiceCount == 0) return false;

      if (bucketSearchQuery.value.isNotEmpty &&
          !client.name.toLowerCase().contains(bucketSearchQuery.value.toLowerCase())) {
        return false;
      }
      final totalAmount = getAccountTotalDue(client.id);

      if (bucketMinAmount.value > 0 && totalAmount < bucketMinAmount.value) return false;
      if (bucketMaxAmount.value > 0 && totalAmount > bucketMaxAmount.value) return false;
      if (bucketMinInvoices.value > 0 && invoiceCount < bucketMinInvoices.value) return false;
      if (bucketMaxInvoices.value > 0 && invoiceCount > bucketMaxInvoices.value) return false;

      return true;
    }).toList();
  }

  List<CollectionItemModel> getInvoicesByAccount(String clientId) {
    final invoices = bucketItems.where((item) => item.client.id == clientId && item.toBeCollected > 0).toList();
    // Apply search query if present
    var results = invoices;
    if (invoiceSearchQuery.value.isNotEmpty) {
      final query = invoiceSearchQuery.value.toLowerCase();
      results = results.where((item) {
        return item.id.toLowerCase().contains(query) ||
            item.documentReferences.any((ref) => ref.toLowerCase().contains(query));
      }).toList();
    }

    // Apply amount range filter when set (bucket-level filter used for account invoices)
    if (bucketMinAmount.value > 0 || bucketMaxAmount.value > 0) {
      results = results.where((item) {
        final minOk = bucketMinAmount.value > 0 ? item.toBeCollected >= bucketMinAmount.value : true;
        final maxOk = bucketMaxAmount.value > 0 ? item.toBeCollected <= bucketMaxAmount.value : true;
        return minOk && maxOk;
      }).toList();
    }

    // Sort by due date (ascending: oldest first)
    results.sort((a, b) {
      if (a.dueDate == 'N/A') return 1;
      if (b.dueDate == 'N/A') return -1;
      return a.dueDate.compareTo(b.dueDate);
    });

    return results;
  }

  double getAccountTotalDue(String clientId) {
    final allItems = [...bucketItems, ...activityItems];
    return allItems
        .where((item) => item.client.id == clientId)
        .fold(0.0, (sum, item) => sum + item.toBeCollected);
  }

  double getAccountTotalCollected(String clientId) {
    final allItems = [...bucketItems, ...activityItems];
    return allItems
        .where((item) => item.client.id == clientId)
        .fold(0.0, (sum, item) => sum + item.totalCollected);
  }

  int getAccountInvoiceCount(String clientId) => 
      bucketItems.where((item) => item.client.id == clientId && item.toBeCollected > 0).length;

  // ========================================================================
  // Activity helpers
  // ========================================================================

  List<ClientModel> get activityAccounts {
    final activeClientIds = activityItems.where((e) => e.toBeCollected > 0).map((e) => e.client.id).toSet();
    return masterAccountList.where((client) {
      if (!activeClientIds.contains(client.id)) return false;
      if (activitySearchQuery.value.isNotEmpty &&
          !client.name.toLowerCase().contains(activitySearchQuery.value.toLowerCase())) {
        return false;
      }
      final totalAmount = getActivityAccountTotalDue(client.id);
      final invoiceCount = getActivityAccountInvoiceCount(client.id);

      if (activityMinAmount.value > 0 && totalAmount < activityMinAmount.value) return false;
      if (activityMaxAmount.value > 0 && totalAmount > activityMaxAmount.value) return false;
      if (activityMinInvoices.value > 0 && invoiceCount < activityMinInvoices.value) return false;
      if (activityMaxInvoices.value > 0 && invoiceCount > activityMaxInvoices.value) return false;

      return true;
    }).toList();
  }

  double getActivityAccountTotalDue(String clientId) => activityItems
      .where((item) => item.client.id == clientId)
      .fold(0.0, (sum, item) => sum + item.toBeCollected);

  double getActivityAccountTotalCollected(String clientId) => activityItems
      .where((item) => item.client.id == clientId)
      .fold(0.0, (sum, item) => sum + item.totalCollected);

  int getActivityAccountInvoiceCount(String clientId) => 
      activityItems.where((item) => item.client.id == clientId && item.toBeCollected > 0).length;

  List<CollectionItemModel> getActivityInvoicesByAccount(String clientId) {
    final invoices = activityItems.where((item) => item.client.id == clientId && item.toBeCollected > 0).toList();
    var results = invoices;
    if (invoiceSearchQuery.value.isNotEmpty) {
      final query = invoiceSearchQuery.value.toLowerCase();
      results = results.where((item) {
        return item.id.toLowerCase().contains(query) ||
            item.documentReferences.any((ref) => ref.toLowerCase().contains(query));
      }).toList();
    }

    // Apply activity amount range filter when set
    if (activityMinAmount.value > 0 || activityMaxAmount.value > 0) {
      results = results.where((item) {
        final minOk = activityMinAmount.value > 0 ? item.toBeCollected >= activityMinAmount.value : true;
        final maxOk = activityMaxAmount.value > 0 ? item.toBeCollected <= activityMaxAmount.value : true;
        return minOk && maxOk;
      }).toList();
    }

    // Sort by due date (ascending: oldest first)
    results.sort((a, b) {
      if (a.dueDate == 'N/A') return 1;
      if (b.dueDate == 'N/A') return -1;
      return a.dueDate.compareTo(b.dueDate);
    });

    return results;
  }

  // ========================================================================
  // Account Information Details
  // ========================================================================

  /// Returns detailed financial stats for an account
  Map<String, dynamic> getAccountFinancialStats(String clientId) {
    final now = DateTime.now();
    final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
    
    final allItems = [...bucketItems, ...activityItems];
    final accountInvoices = allItems.where((item) => item.client.id == clientId).toList();
    
    double totalPastDue = 0;
    int pastDueCount = 0;
    double totalCurrentDue = 0;
    int currentDueCount = 0;

    for (final inv in accountInvoices) {
      try {
        final dueDate = DateTime.parse(inv.dueDate);
        if (dueDate.isBefore(firstDayOfCurrentMonth)) {
          totalPastDue += inv.toBeCollected;
          pastDueCount++;
        } else if (dueDate.year == now.year && dueDate.month == now.month) {
          totalCurrentDue += inv.toBeCollected;
          currentDueCount++;
        }
      } catch (e) {
        // Fallback or ignore unparseable dates
      }
    }

    return {
      'totalPastDue': totalPastDue,
      'pastDueCount': pastDueCount,
      'totalCurrentDue': totalCurrentDue,
      'currentDueCount': currentDueCount,
    };
  }

  /// Returns combined history for all invoices of a specific account (both bucket and activity)
  /// Now returns a list of maps containing the history model and the full invoice item.
  List<Map<String, dynamic>> getAccountHistory(String clientId) {
    final allItems = [...bucketItems, ...activityItems];
    final accountItems = allItems.where((item) => item.client.id == clientId).toList();

    final List<Map<String, dynamic>> combined = [];
    for (var item in accountItems) {
      for (var history in item.history) {
        combined.add({
          'history': history,
          'item': item,
        });
      }
    }

    // Sort newest first
    combined.sort((a, b) => b['history'].date.compareTo(a['history'].date));

    return combined;
  }

  /// Returns combined history for all invoices in the system, sorted by date (newest first).
  List<Map<String, dynamic>> get allRecentHistory {
    final List<Map<String, dynamic>> combined = [];
    
    final allItems = [...bucketItems, ...activityItems];
    for (var item in allItems) {
      for (var history in item.history) {
        // We only want to show user activities, or at least identify the account
        combined.add({
          'history': history,
          'accountName': item.client.name,
          'invoiceId': item.id,
          'item': item,
        });
      }
    }

    // Sort by date (Assuming yyyy-MM-dd HH:mm format)
    combined.sort((a, b) => b['history'].date.compareTo(a['history'].date));

    return combined;
  }

  void setActivityFilter(String filter) => activityFilter.value = filter;

  List<CollectionItemModel> get filteredActivityItems {
    Iterable<CollectionItemModel> items = activityItems;
    if (activityFilter.value == 'All') return items.toList();
    return items.where((e) => e.status == activityFilter.value).toList();
  }

  // ========================================================================
  // Dashboard Getters
  // ========================================================================

  // Core and Outcomes summary getters removed per UI requirements.

  /// Completed: invoice reach 0 total amount due
  List<CollectionItemModel> get completedItems {
    final allItems = [...bucketItems, ...activityItems];
    return allItems.where((item) => item.toBeCollected == 0).toList();
  }

  /// Due Date: invoices past their due date
  List<CollectionItemModel> get overdueItems {
    final allItems = [...bucketItems, ...activityItems];
    final now = DateTime.now();
    return allItems.where((item) {
      try {
        final dueDate = DateTime.parse(item.dueDate);
        return dueDate.isBefore(now);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // ========================================================================
  // Claims
  // ========================================================================

  void unclaimAccount(String clientId) {
    final invoices = activityItems.where((item) => item.client.id == clientId).toList();
    if (invoices.isEmpty) return;

    for (final inv in invoices) {
      final index = activityItems.indexWhere((e) => e.id == inv.id);
      if (index != -1) {
        final item = activityItems[index].copyWith(assignedAt: '');
        bucketItems.add(item);
        activityItems.removeAt(index);
      }
    }
    logDebug('[CollectionActivityController] Account $clientId unclaimed (${invoices.length} invoices)');
  }

  void claimAccount(String clientId) {
    final invoices = bucketItems.where((item) => item.client.id == clientId).toList();
    if (invoices.isEmpty) return;

    final ids = invoices.map((e) => e.id).toList();
    claimItemsByIds(ids);
    logDebug('[CollectionActivityController] Account $clientId claimed (${invoices.length} invoices)');
  }

  void claimItemsByIds(List<String> ids) {
    if (ids.isEmpty) return;
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    for (final id in ids) {
      final index = bucketItems.indexWhere((e) => e.id == id);
      if (index == -1) continue;
      // Do not assign a system-managed 'On-going' status; keep status empty and set assignedAt.
      final item = bucketItems[index].copyWith(
        status: '',
        assignedAt: now,
      );
      activityItems.add(item);
      bucketItems.removeAt(index);
    }
    selectedBucketIds.removeWhere((id) => ids.contains(id));
    logDebug('[CollectionActivityController] Claimed ${ids.length} items');
  }

  void saveActivity({
    required String id,
    required String status,
    required String remarks,
    double? totalCollected,
    String? bankName,
    String? checkNumber,
    String? checkDate,
    String? purposeOfVisit,
  }) {
    final index = activityItems.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final oldItem = activityItems[index];
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final double newlyCollected = totalCollected ?? 0;
    final double updatedTotalCollected = oldItem.totalCollected + newlyCollected;
    final double updatedToBeCollected = (oldItem.toBeCollected - newlyCollected).clamp(0, double.infinity);

    // If fully paid, status is Collected. 
    // If not fully paid, status is Pending (moving back to bucket) but with the outcome recorded.
    final bool isFullyPaid = updatedToBeCollected == 0;
    // When not fully paid, avoid reintroducing the removed 'Pending' status. Use empty status and rely on lastOutcome.
    final String finalStatus = isFullyPaid ? CollectionStatusColors.statusCollected : '';

    final historyEntry = CollectionHistoryModel(
      date: now,
      collectorName: UserController.instance.user.value.initials,
      status: status,
      remarks: remarks,
      totalCollected: newlyCollected,
      bankName: bankName,
      checkNumber: checkNumber,
      checkDate: checkDate,
      purposeOfVisit: purposeOfVisit,
    );

    final updatedItem = oldItem.copyWith(
      status: finalStatus,
      lastOutcome: status, // Always store the selected status as the last outcome
      remarks: remarks,
      toBeCollected: updatedToBeCollected,
      totalCollected: updatedTotalCollected,
      history: [...oldItem.history, historyEntry],
      assignedAt: '',
      collectorName: 'Unassigned',
    );

    bucketItems.add(updatedItem);
    activityItems.removeAt(index);
    logDebug('[CollectionActivityController] Activity $id saved');
  }

  // ========================================================================
  // Sample Data
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
      final invoiceCount = 3 + random.nextInt(5);
      for (int i = 1; i <= invoiceCount; i++) {
        final amount = 5000.0 + random.nextInt(20000);
        final id = 'INV-${client.id}-${100 + i}';
        final now = DateTime.now();
        // Create a variety of due dates: some past (overdue), some today, some future
        final possibleOffsets = [-60, -45, -20, -5, 0, 5, 15, 40];
        final offset = possibleOffsets[random.nextInt(possibleOffsets.length)];
        final postingDate = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: 60 + random.nextInt(50))));
        final dueDate = DateFormat('yyyy-MM-dd').format(now.add(Duration(days: offset)));

        generatedItems.add(CollectionItemModel(
          id: id,
          client: client,
          bpCode: client.code,
          postingDate: postingDate,
          dueDate: dueDate,
          documentReferences: ['REF-$id'],
          bankName: ['BDO', 'BPI', 'Metrobank'][random.nextInt(3)],
          toBeCollected: amount,
          // Start with an empty/unknown status (remove 'Pending')
          status: '',
          history: [
            CollectionHistoryModel(
              date: '2026-02-01 08:00',
              collectorName: 'System',
              status: '',
              remarks: 'Invoice #$id Created',
            ),
          ],
        ));
      }
    }
    bucketItems.assignAll(generatedItems);
    activityItems.clear();
  }
}
