import 'dart:math';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/sync_manager.dart';

  /// Manages the Collection Bucket → Activity flow with a simplified status model.
class CollectionActivityController extends GetxController {
  static CollectionActivityController get instance => Get.find();

  // ========================================================================
  // Dependencies
  // ========================================================================
  late final CollectionRepository repository;
  late final SyncManager syncManager;

  // ========================================================================
  // Observable state
  // ========================================================================

  final RxList<CollectionItemModel> bucketItems = <CollectionItemModel>[].obs;
  final RxList<CollectionItemModel> activityItems = <CollectionItemModel>[].obs;
  final RxSet<String> selectedBucketIds = <String>{}.obs;
  final RxBool isLoading = false.obs;

  /// Error message observable for UI feedback
  final RxnString errorMessage = RxnString();

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

  // Multi-select Account state
  final RxBool isSelectionMode = false.obs;
  final RxSet<String> selectedAccountIds = <String>{}.obs;

  // Multi-select Activity Invoice state
  final RxBool isActivitySelectionMode = false.obs;
  final RxSet<String> selectedActivityInvoiceIds = <String>{}.obs;

  /// Account-level history (for unclaiming/no collection)
  final RxMap<String, List<CollectionHistoryModel>> clientHistory = <String, List<CollectionHistoryModel>>{}.obs;

  /// Global activities (Deposit, CWT Pick-up, Reconciliation)
  final RxList<Map<String, dynamic>> globalActivities = <Map<String, dynamic>>[].obs;

  // ========================================================================
  // Lifecycle
  // ========================================================================

  @override
  void onInit() {
    super.onInit();
    // Initialize repository and sync manager from DI
    repository = Get.find<CollectionRepository>();
    syncManager = Get.find<SyncManager>();
    // Load data
    loadBucket();
  }

  /// Load collection bucket items from repository.
  /// Attempts to fetch from API or returns local cached data if offline.
  Future<void> loadBucket() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final items = await repository.getAll();
      bucketItems.assignAll(items);

      // Extract unique clients for account list
      final clientMap = <String, ClientModel>{};
      for (final item in items) {
        clientMap[item.client.id] = item.client;
      }
      masterAccountList.assignAll(clientMap.values.toList());

      logDebug('[CollectionActivityController] Loaded ${items.length} bucket items');
      isLoading.value = false;
    } catch (e) {
      logDebug('[CollectionActivityController] loadBucket error: $e');
      errorMessage.value = 'Failed to load collection items: $e';
      isLoading.value = false;

      // Fallback to sample data if available, or empty list
      _loadSampleBucketItemsAsFallback();
    }
  }

  /// Fallback to sample data if real data fails to load.
  /// This is only for development/demo purposes.
  void _loadSampleBucketItemsAsFallback() {
    try {
      logDebug('[CollectionActivityController] Loading sample data as fallback...');
      _loadSampleBucketItems();
    } catch (e) {
      logDebug('[CollectionActivityController] Fallback also failed: $e');
    }
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

  final RxString selectedArea = ''.obs;

  List<ClientModel> get bucketAccounts {
    return masterAccountList.where((client) {
      // Territory Filter
      if (selectedArea.value.isNotEmpty) {
        if (!client.code.startsWith(selectedArea.value)) return false;
      }

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
    
    // 1. Add invoice-level history
    for (var item in accountItems) {
      for (var history in item.history) {
        combined.add({
          'history': history,
          'item': item,
        });
      }
    }

    // 2. Add account-level history
    if (clientHistory.containsKey(clientId)) {
      for (var history in clientHistory[clientId]!) {
        combined.add({
          'history': history,
          'item': null,
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
    
    // 1. Add invoice-level history
    final allItems = [...bucketItems, ...activityItems];
    for (var item in allItems) {
      for (var history in item.history) {
        combined.add({
          'history': history,
          'accountName': item.client.name,
          'invoiceId': item.id,
          'item': item,
        });
      }
    }

    // 2. Add account-level history
    clientHistory.forEach((clientId, historyEntries) {
      final client = masterAccountList.firstWhere((c) => c.id == clientId, orElse: () => ClientModel.empty());
      for (var history in historyEntries) {
        combined.add({
          'history': history,
          'accountName': client.name,
          'invoiceId': null,
          'item': null,
        });
      }
    });

    // 3. Add global activities
    combined.addAll(globalActivities);

    // Sort by date (Assuming yyyy-MM-dd HH:mm format)
    combined.sort((a, b) => b['history'].date.compareTo(a['history'].date));

    return combined;
  }

  /// Returns activities grouped by date for the calendar
  Map<DateTime, List<Map<String, dynamic>>> get activitiesByDate {
    final Map<DateTime, List<Map<String, dynamic>>> grouped = {};

    for (var entry in allRecentHistory) {
      final history = entry['history'] as CollectionHistoryModel;
      try {
        // Parse yyyy-MM-dd HH:mm to get just the date part
        final datePart = history.date.split(' ')[0];
        final date = DateTime.parse(datePart);
        final normalizedDate = DateTime(date.year, date.month, date.day);
        
        if (!grouped.containsKey(normalizedDate)) {
          grouped[normalizedDate] = [];
        }
        grouped[normalizedDate]!.add(entry);
      } catch (e) {
        // Skip unparseable dates
      }
    }
    return grouped;
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

  /// Completed: invoices that reach 0 total amount due, filtered by area
  List<CollectionItemModel> get completedItems {
    final allItems = [...bucketItems, ...activityItems];
    return allItems.where((item) {
      if (item.toBeCollected != 0) return false;
      if (selectedArea.value.isNotEmpty && !item.bpCode.startsWith(selectedArea.value)) return false;
      return true;
    }).toList();
  }

  /// Due Date: invoices past their due date, filtered by area
  List<CollectionItemModel> get overdueItems {
    final allItems = [...bucketItems, ...activityItems];
    final now = DateTime.now();
    return allItems.where((item) {
      if (selectedArea.value.isNotEmpty && !item.bpCode.startsWith(selectedArea.value)) return false;
      try {
        final dueDate = DateTime.parse(item.dueDate);
        return dueDate.isBefore(now);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Returns accounts that have settled invoices
  List<ClientModel> get settledAccounts {
    final settledInvoiceIds = completedItems.map((e) => e.client.id).toSet();
    return masterAccountList.where((c) => settledInvoiceIds.contains(c.id)).toList();
  }

  /// Returns accounts that have overdue invoices
  List<ClientModel> get overdueAccounts {
    final overdueInvoiceIds = overdueItems.map((e) => e.client.id).toSet();
    return masterAccountList.where((c) => overdueInvoiceIds.contains(c.id)).toList();
  }

  /// Returns settled invoices for a specific account
  List<CollectionItemModel> getSettledInvoicesByAccount(String clientId) {
    return completedItems.where((item) => item.client.id == clientId).toList();
  }

  /// Returns overdue invoices for a specific account
  List<CollectionItemModel> getOverdueInvoicesByAccount(String clientId) {
    return overdueItems.where((item) => item.client.id == clientId).toList();
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

  void unclaimWithReason(String clientId, String reason, String remarks) {
    // 1. Move all invoices back to bucket without adding history to them
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

    // 2. Add a single account-level history entry
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final collectorInitials = UserController.instance.user.value.initials;

    final historyEntry = CollectionHistoryModel(
      date: now,
      collectorName: collectorInitials,
      status: reason,
      remarks: remarks,
      totalCollected: 0,
    );

    final historyList = clientHistory[clientId] ?? [];
    clientHistory[clientId] = [...historyList, historyEntry];

    logDebug('[CollectionActivityController] Account $clientId unclaimed with account-level reason: $reason');
  }

   void claimAccount(String clientId) {
     final invoices = bucketItems.where((item) => item.client.id == clientId).toList();
     if (invoices.isEmpty) return;

     final ids = invoices.map((e) => e.id).toList();
     claimItemsByIds(ids);
     logDebug('[CollectionActivityController] Account $clientId claimed (${invoices.length} invoices)');
   }

   /// Claim items by IDs (move to activity).
   /// Updates both UI and calls repository for persistence.
   Future<void> claimItemsByIds(List<String> ids) async {
     if (ids.isEmpty) return;

     try {
       // Update UI optimistically
       final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
       for (final id in ids) {
         final index = bucketItems.indexWhere((e) => e.id == id);
         if (index == -1) continue;
         final item = bucketItems[index].copyWith(
           status: '',
           assignedAt: now,
         );
         activityItems.add(item);
         bucketItems.removeAt(index);
       }
       selectedBucketIds.removeWhere((id) => ids.contains(id));

       // Persist to repository
       await repository.claimItemsByIds(ids, silent: true);
       logDebug('[CollectionActivityController] Claimed ${ids.length} items');
     } catch (e) {
       logDebug('[CollectionActivityController] claimItemsByIds error: $e');
       errorMessage.value = 'Failed to claim items: $e';
     }
   }

  // ========================================================================
  // Multi-select Account logic
  // ========================================================================

  void toggleAccountSelection(String clientId) {
    if (selectedAccountIds.contains(clientId)) {
      selectedAccountIds.remove(clientId);
      if (selectedAccountIds.isEmpty) {
        isSelectionMode.value = false;
      }
    } else {
      isSelectionMode.value = true;
      selectedAccountIds.add(clientId);
    }
  }

  void enterSelectionMode(String clientId) {
    isSelectionMode.value = true;
    selectedAccountIds.add(clientId);
  }

  void exitSelectionMode() {
    isSelectionMode.value = false;
    selectedAccountIds.clear();
  }

  void claimSelectedAccounts() {
    if (selectedAccountIds.isEmpty) return;
    
    final idsToClaim = selectedAccountIds.toList();
    for (final clientId in idsToClaim) {
      claimAccount(clientId);
    }
    
    exitSelectionMode();
  }

   /// Save activity for an invoice item.
   /// Updates UI optimistically and persists to repository.
   Future<void> saveActivity({
     required String id,
     required String status,
     required String remarks,
     double? totalCollected,
     String? bankName,
     String? checkNumber,
     String? checkDate,
     String? purposeOfVisit,
   }) async {
     try {
       final index = activityItems.indexWhere((e) => e.id == id);
       if (index == -1) {
         errorMessage.value = 'Item not found';
         return;
       }

       final oldItem = activityItems[index];
       final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
       final double newlyCollected = totalCollected ?? 0;
       final double updatedTotalCollected = oldItem.totalCollected + newlyCollected;
       final double updatedToBeCollected = (oldItem.toBeCollected - newlyCollected).clamp(0, double.infinity);

       final bool isFullyPaid = updatedToBeCollected == 0;
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
         lastOutcome: status,
         remarks: remarks,
         toBeCollected: updatedToBeCollected,
         totalCollected: updatedTotalCollected,
         history: [...oldItem.history, historyEntry],
         assignedAt: isFullyPaid ? '' : oldItem.assignedAt,
         collectorName: isFullyPaid ? 'Unassigned' : oldItem.collectorName,
       );

       // Update UI optimistically
       if (isFullyPaid) {
         bucketItems.add(updatedItem);
         activityItems.removeAt(index);
       } else {
         activityItems[index] = updatedItem;
       }

       // Persist to repository
       await repository.saveActivity(
         id: id,
         status: status,
         remarks: remarks,
         totalCollected: totalCollected,
         bankName: bankName,
         checkNumber: checkNumber,
         checkDate: checkDate,
         purposeOfVisit: purposeOfVisit,
         silent: true,
       );

       logDebug('[CollectionActivityController] Activity $id saved. Move to bucket: $isFullyPaid');
     } catch (e) {
       logDebug('[CollectionActivityController] saveActivity error: $e');
       errorMessage.value = 'Failed to save activity: $e';
     }
   }

  // ========================================================================
  // Multi-select Activity Invoice logic
  // ========================================================================

  void toggleActivityInvoiceSelection(String id) {
    if (selectedActivityInvoiceIds.contains(id)) {
      selectedActivityInvoiceIds.remove(id);
      if (selectedActivityInvoiceIds.isEmpty) {
        isActivitySelectionMode.value = false;
      }
    } else {
      isActivitySelectionMode.value = true;
      selectedActivityInvoiceIds.add(id);
    }
  }

  void exitActivitySelectionMode() {
    isActivitySelectionMode.value = false;
    selectedActivityInvoiceIds.clear();
  }

   /// Save batch activity for multiple items.
   /// Updates UI optimistically and persists to repository.
   Future<void> saveBatchActivity({
     required List<String> ids,
     required Map<String, String> statuses,
     required Map<String, String> remarks,
     required Map<String, double> amounts,
     required double totalAmountReceived,
     String? bankName,
     String? checkNumber,
     String? checkDate,
     String? purposeOfVisit,
   }) async {
     try {
       final selectedItems = activityItems.where((item) => ids.contains(item.id)).toList();
       final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

       for (var item in selectedItems) {
         final double manualAmount = amounts[item.id] ?? 0;
         final String itemRemarks = remarks[item.id] ?? 'Batch Recording';

         final double updatedTotalCollected = item.totalCollected + manualAmount;
         final double updatedToBeCollected = (item.toBeCollected - manualAmount).clamp(0, double.infinity);

         final bool isFullyPaid = updatedToBeCollected == 0;

         final String itemStatus = statuses[item.id] ?? (isFullyPaid ? CollectionStatusColors.statusCollected : '');

         final historyEntry = CollectionHistoryModel(
           date: now,
           collectorName: UserController.instance.user.value.initials,
           status: itemStatus,
           remarks: itemRemarks,
           totalCollected: manualAmount,
           bankName: bankName,
           checkNumber: checkNumber,
           checkDate: checkDate,
           purposeOfVisit: purposeOfVisit,
         );

         final updatedItem = item.copyWith(
           status: isFullyPaid ? CollectionStatusColors.statusCollected : '',
           lastOutcome: itemStatus,
           remarks: itemRemarks,
           toBeCollected: updatedToBeCollected,
           totalCollected: updatedTotalCollected,
           history: [...item.history, historyEntry],
           assignedAt: isFullyPaid ? '' : item.assignedAt,
           collectorName: isFullyPaid ? 'Unassigned' : item.collectorName,
         );

         // Update in lists
         final idx = activityItems.indexWhere((e) => e.id == item.id);
         if (idx != -1) {
           if (isFullyPaid) {
             activityItems.removeAt(idx);
             bucketItems.add(updatedItem);
           } else {
             activityItems[idx] = updatedItem;
           }
         }
       }

       // Persist to repository
       await repository.saveBatchActivity(
         ids: ids,
         statuses: statuses,
         remarks: remarks,
         amounts: amounts,
         totalAmountReceived: totalAmountReceived,
         bankName: bankName,
         checkNumber: checkNumber,
         checkDate: checkDate,
         purposeOfVisit: purposeOfVisit,
         silent: true,
       );

       exitActivitySelectionMode();
       logDebug('[CollectionActivityController] Batch activity saved for ${ids.length} items');
     } catch (e) {
       logDebug('[CollectionActivityController] saveBatchActivity error: $e');
       errorMessage.value = 'Failed to save batch activity: $e';
     }
   }

  void saveGlobalActivity({
    required String type,
    required String accountName,
    required String remarks,
    double totalCollected = 0,
    String? bankName,
    String? checkNumber,
  }) {
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final collectorInitials = UserController.instance.user.value.initials;

    final historyEntry = CollectionHistoryModel(
      date: now,
      collectorName: collectorInitials,
      status: type,
      remarks: remarks,
      totalCollected: totalCollected,
      bankName: bankName,
      checkNumber: checkNumber,
    );

    globalActivities.add({
      'history': historyEntry,
      'accountName': accountName,
      'invoiceId': null,
      'item': null,
    });
    
    globalActivities.refresh();
    logDebug('[CollectionActivityController] Global activity saved: $type');
  }

  // ========================================================================
  // Sample Data
  // ========================================================================

  void _loadSampleBucketItems() {
    final List<ClientModel> clients = [
      ClientModel(id: 'C001', code: 'NLN-001', name: 'ABC Corporation (North)', address: '123 Main St, Laoag', contact: '09171234567', emailAddress: 'abc@corp.com'),
      ClientModel(id: 'C002', code: 'SLN-001', name: 'XYZ Trading (South)', address: '456 Rizal Ave, Batangas', contact: '09189876543', emailAddress: 'xyz@trading.ph'),
      ClientModel(id: 'C003', code: 'CLN-001', name: 'LMN Enterprises (Central)', address: '789 EDSA, Pampanga', contact: '09201112233', emailAddress: 'lmn@ent.com'),
      ClientModel(id: 'C004', code: 'VIS-001', name: 'PQR Industries (Visayas)', address: '321 Ayala Blvd, Cebu', contact: '09334455667', emailAddress: 'pqr@ind.com'),
      ClientModel(id: 'C005', code: 'MIN-001', name: 'STU Holdings (Mindanao)', address: '654 Shaw Blvd, Davao', contact: '09557788990', emailAddress: 'stu@hold.com'),
      ClientModel(id: 'C006', code: 'RAD-001', name: 'VWX Solutions (Medical)', address: '987 Aurora Blvd, QC', contact: '09664433221', emailAddress: 'vwx@sol.com'),
      ClientModel(id: 'C007', code: 'NLN-002', name: 'Global Logistics Inc. (North)', address: '555 Port Area, Manila', contact: '09771230000', emailAddress: 'global@logistics.com'),
      ClientModel(id: 'C008', code: 'VIS-002', name: 'Prime Manufacturing (Visayas)', address: '222 Industrial Ave, Iloilo', contact: '09885551234', emailAddress: 'prime@mfg.com'),
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
