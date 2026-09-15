import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/sync_manager.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_advance_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';

/// Lifecycle of the explicit "Download Bucket" action.
enum BucketDownloadPhase { idle, downloading, success, error }

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

  /// Claimed by this collector and still open → Activity; everything else →
  /// Bucket. The server only ever returns the shared pool plus *my* claims, so
  /// a non-empty `assignedAt` means mine. `'N/A'` is how the model spells null.
  static bool isClaimedOpen(CollectionItemModel item) {
    final assigned = item.assignedAt.trim();
    return assigned.isNotEmpty && assigned != 'N/A' && item.toBeCollected > 0;
  }

  /// Every known invoice exactly once. An id can transiently live in both
  /// lists; the Activity copy wins because it carries the freshest history.
  static List<CollectionItemModel> mergeUnique(
      Iterable<CollectionItemModel> bucket,
      Iterable<CollectionItemModel> activity) {
    final byId = <String, CollectionItemModel>{};
    for (final i in bucket) {
      byId[i.id] = i;
    }
    for (final i in activity) {
      byId[i.id] = i;
    }
    return byId.values.toList();
  }

  // ========================================================================
  // Cached per-client aggregates
  //
  // [allItems] and the per-account totals are read once per account while
  // building the bucket list, and again by every visible card. Recomputing
  // them meant merging and scanning all items on each call, so listing N
  // accounts over M invoices cost N x M (at 3870 invoices that stalled the
  // page transition into the bucket). They are now folded once per change
  // and served from maps.
  //
  // Invalidated by any change to bucketItems / activityItems. Every mutation
  // in this controller goes through the RxList API (assignAll, add, removeAt,
  // index assignment), so the listeners registered in onInit see them all;
  // models are replaced rather than mutated in place.
  // ========================================================================

  bool _aggregatesDirty = true;
  int _cachedSourceLength = -1;
  List<CollectionItemModel> _allItemsCache = const [];
  final Map<String, int> _invoiceCountByClient = {};
  final Map<String, double> _totalDueByClient = {};
  final Map<String, double> _totalCollectedByClient = {};

  /// Marks the cached aggregates stale. Call after changing item contents in
  /// a way that bypasses the observable lists (nothing does today).
  void invalidateAggregates() => _aggregatesDirty = true;

  /// Invalidates the cached aggregates on every change to either item list.
  /// Called from [onInit]; exposed so tests can wire a bare controller.
  @visibleForTesting
  void startAggregateTracking() {
    ever(bucketItems, (_) => invalidateAggregates());
    ever(activityItems, (_) => invalidateAggregates());
  }

  void _rebuildAggregates() {
    _allItemsCache = mergeUnique(bucketItems, activityItems);
    _invoiceCountByClient.clear();
    _totalDueByClient.clear();
    _totalCollectedByClient.clear();

    // Money spans bucket + activity, so it folds over the merged list.
    for (final item in _allItemsCache) {
      final id = item.client.id;
      _totalDueByClient[id] = (_totalDueByClient[id] ?? 0) + item.toBeCollected;
      _totalCollectedByClient[id] =
          (_totalCollectedByClient[id] ?? 0) + item.totalCollected;
    }
    // Invoice count is bucket-only and ignores fully-settled invoices,
    // matching the previous getter exactly.
    for (final item in bucketItems) {
      if (item.toBeCollected > 0) {
        final id = item.client.id;
        _invoiceCountByClient[id] = (_invoiceCountByClient[id] ?? 0) + 1;
      }
    }
    _cachedSourceLength = bucketItems.length + activityItems.length;
    _aggregatesDirty = false;
  }

  /// Serving a warm cache must still *read* both lists.
  ///
  /// An Obx subscribes to whatever observables its builder touches. Before
  /// caching, every aggregate walked bucketItems/activityItems, so any Obx
  /// reading one was automatically rebuilt when items changed. A cached read
  /// touches nothing, which both throws "improper use of a GetX" when the
  /// builder reads no other observable, and silently stops the widget
  /// updating when it reads one.
  ///
  /// Reading the lengths here re-registers both lists for the enclosing Obx.
  /// The length is also compared against the cache, so a change that somehow
  /// escaped the dirty flag still forces a rebuild.
  void _ensureAggregates() {
    final sourceLength = bucketItems.length + activityItems.length;
    if (_aggregatesDirty || sourceLength != _cachedSourceLength) {
      _rebuildAggregates();
    }
  }

  /// Bucket and Activity items merged by id (Activity wins).
  ///
  /// Returns a cached list: read it, never mutate it.
  List<CollectionItemModel> get allItems {
    _ensureAggregates();
    return _allItemsCache;
  }

  /// Replace both lists (and the account list) from a full set of items.
  void _setItems(List<CollectionItemModel> items) {
    final claimed = <CollectionItemModel>[];
    final pool = <CollectionItemModel>[];
    for (final i in items) {
      (isClaimedOpen(i) ? claimed : pool).add(i);
    }
    activityItems.assignAll(claimed);
    bucketItems.assignAll(pool);
    selectedBucketIds.removeWhere((id) => !pool.any((p) => p.id == id));

    final clientMap = <String, ClientModel>{};
    for (final item in items) {
      clientMap[item.client.id] = item.client;
    }
    masterAccountList.assignAll(clientMap.values.toList());
  }

  final RxSet<String> selectedBucketIds = <String>{}.obs;
  final RxBool isLoading = false.obs;

  /// Phase of the explicit "Download Bucket" action; drives the full-screen
  /// download transition on the Collection home screen. Separate from
  /// [isLoading] so the silent initial load never shows the overlay.
  final Rx<BucketDownloadPhase> bucketDownloadPhase =
      BucketDownloadPhase.idle.obs;

  /// Items received by the most recent successful bucket download.
  final RxInt lastDownloadedCount = 0.obs;

  /// How long the success/error result stays on screen before the overlay fades.
  static const Duration downloadResultHold = Duration(milliseconds: 1400);

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
  final RxMap<String, List<CollectionHistoryModel>> clientHistory =
      <String, List<CollectionHistoryModel>>{}.obs;

  /// Global activities (Deposit, CWT Pick-up, Reconciliation)
  final RxList<Map<String, dynamic>> globalActivities =
      <Map<String, dynamic>>[].obs;

  /// Advanced payments without an invoice yet
  final RxList<Map<String, dynamic>> unassignedAdvancedPayments =
      <Map<String, dynamic>>[].obs;

  // ========================================================================
  // Lifecycle
  // ========================================================================

  @override
  void onInit() {
    super.onInit();
    // Initialize repository and sync manager from DI
    repository = Get.find<CollectionRepository>();
    syncManager = Get.find<SyncManager>();
    // Any change to either list invalidates the cached per-client aggregates.
    // Registered before the first load so nothing can serve a stale map.
    startAggregateTracking();
    // Load data
    loadBucket();
    _loadPersistedExtras();
    // A server download replaces the local cache; mirror it in memory. Local
    // read only (no network), so this cannot loop back into a sync.
    ever(repository.localDataVersion, (_) async {
      _loadPersistedExtras();
      final items = await repository.getLocalCollectionItems();
      _setItems(items);
    });
  }

  /// Load collection bucket items from repository.
  /// Attempts to fetch from API or returns local cached data if offline.
  Future<void> loadBucket() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final items = await repository.getAll();
      _setItems(items);

      logDebug(
          '[CollectionActivityController] Loaded ${items.length} bucket items');
      isLoading.value = false;
    } catch (e) {
      logDebug('[CollectionActivityController] loadBucket error: $e');
      errorMessage.value = 'Failed to load collection items: $e';
      isLoading.value = false;
    }
  }

  /// Number of un-uploaded (queued) changes; drives the Upload All badge.
  int get pendingUploadCount => syncManager.pendingCount.value;

  /// Download a fresh bucket from the server.
  ///
  /// Guarded: refuses to overwrite the local cache while un-uploaded field work
  /// is still queued (process-flow requirement 7), since a force-refresh clears
  /// the local table.
  Future<void> downloadBucket() async {
    final pending = await syncManager.getPendingChangeCount();
    if (pending > 0) {
      Get.defaultDialog(
        title: 'Upload first',
        middleText:
            'You have $pending un-uploaded collection${pending == 1 ? '' : 's'}.\n\n'
            'Upload them before downloading a new bucket, so no field work is lost.',
        textConfirm: 'OK',
        onConfirm: () => Get.back(),
      );
      return;
    }

    if (bucketDownloadPhase.value != BucketDownloadPhase.idle) return;

    try {
      isLoading.value = true;
      errorMessage.value = null;
      bucketDownloadPhase.value = BucketDownloadPhase.downloading;

      final items = await repository.refreshFromApi();
      _setItems(items);
      lastDownloadedCount.value = items.length;

      logDebug(
          '[CollectionActivityController] Downloaded ${items.length} bucket items');
      bucketDownloadPhase.value = BucketDownloadPhase.success;
    } catch (e) {
      logDebug('[CollectionActivityController] downloadBucket error: $e');
      errorMessage.value = 'Failed to download bucket: $e';
      bucketDownloadPhase.value = BucketDownloadPhase.error;
    } finally {
      isLoading.value = false;
    }

    // Let the result (check / error) register before the overlay fades out.
    await Future<void>.delayed(downloadResultHold);
    if (!isClosed) bucketDownloadPhase.value = BucketDownloadPhase.idle;
  }

  /// Supervisor "Add to Bucket": create an invoice on the server (saved to the
  /// DB first) and add it to the local bucket on success. Returns true on success.
  Future<bool> addInvoiceToBucket({
    required String clientId,
    required String clientName,
    String clientCode = '',
    String clientAddress = '',
    String clientContact = '',
    List<String> documentReferences = const [],
    required double toBeCollected,
    String? bankName,
    String? remarks,
    String? documentDate,
    String? postingDate,
    String? dueDate,
  }) async {
    final item = await repository.createInvoice(
      clientId: clientId,
      clientName: clientName,
      clientCode: clientCode,
      clientAddress: clientAddress,
      clientContact: clientContact,
      documentReferences: documentReferences,
      toBeCollected: toBeCollected,
      bankName: bankName,
      remarks: remarks,
      documentDate: documentDate,
      postingDate: postingDate,
      dueDate: dueDate,
    );

    if (item == null) return false;

    bucketItems.add(item);
    if (!masterAccountList.any((c) => c.id == item.client.id)) {
      masterAccountList.add(item.client);
    }
    return true;
  }

  /// End-of-day "Upload All": push every queued change to the server and refresh
  /// the local bucket on success.
  Future<void> uploadAll() async {
    final result = await syncManager.uploadAll();

    if (result == null) {
      BLoaders.warningSnackBar(
        title: 'Upload',
        message:
            syncManager.syncErrorMessage.value ?? 'Upload could not complete.',
      );
      return;
    }

    if (result.hasRejections) {
      BLoaders.warningSnackBar(
        title: 'Uploaded with issues',
        message:
            'Uploaded ${result.accepted}. ${result.rejectedCount} rejected — review in the outbox.',
      );
    } else {
      BLoaders.successSnackBar(
        title: 'Uploaded',
        message:
            'Uploaded ${result.accepted} collection${result.accepted == 1 ? '' : 's'}.',
      );
      // Refresh the local bucket now that the queue is clear.
      await loadBucket();
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
      bucketItems.isNotEmpty && selectedBucketIds.length == bucketItems.length;

  /// Territory code from Filter by Area ('' = all, 'OTHERS' = unnamed prefixes).
  final RxString selectedArea = ''.obs;

  /// Case-insensitive prefix match against the selected area (see BCollectionArea).
  bool _matchesArea(String code) =>
      BCollectionArea.matches(code, selectedArea.value);

  /// Bank names this collector has already recorded, most used first.
  ///
  /// Offered as one-tap fills on the engagement form so a bank name is picked
  /// rather than retyped; collectors work the same few banks repeatedly.
  List<String> recentBankNames({int limit = 4}) {
    final counts = <String, int>{};
    final display = <String, String>{};
    for (final item in allItems) {
      for (final h in item.history) {
        final name = h.bankName?.trim() ?? '';
        if (name.isEmpty) continue;
        final key = name.toLowerCase();
        counts[key] = (counts[key] ?? 0) + 1;
        display[key] = name;
      }
    }
    final keys = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return [for (final k in keys.take(limit)) display[k]!];
  }

  /// Number of bucket accounts in [area] (a BCollectionArea code, the "Others"
  /// sentinel, or '' for every account). Ignores the other bucket filters so
  /// the Filter by Area screen shows what each choice would reveal.
  int accountCountForArea(String area) => masterAccountList
      .where((c) => BCollectionArea.matches(c.code, area))
      .length;

  /// True when any bucket-narrowing input (search, amount/invoice range, area)
  /// is active. Drives the empty-state copy and the "Clear all filters" action.
  bool get hasActiveBucketFilter =>
      bucketSearchQuery.value.trim().isNotEmpty ||
      bucketMinAmount.value > 0 ||
      bucketMaxAmount.value > 0 ||
      bucketMinInvoices.value > 0 ||
      bucketMaxInvoices.value > 0 ||
      selectedArea.value.isNotEmpty;

  /// Reset every bucket filter, including the area selection.
  void clearBucketFilters() {
    bucketSearchQuery.value = '';
    bucketMinAmount.value = 0;
    bucketMaxAmount.value = 0;
    bucketMinInvoices.value = 0;
    bucketMaxInvoices.value = 0;
    selectedArea.value = '';
  }

  List<ClientModel> get bucketAccounts {
    return masterAccountList.where((client) {
      // Territory Filter
      if (!_matchesArea(client.code)) return false;

      final invoiceCount = getAccountInvoiceCount(client.id);
      if (invoiceCount == 0) return false;

      if (bucketSearchQuery.value.isNotEmpty &&
          !client.name
              .toLowerCase()
              .contains(bucketSearchQuery.value.toLowerCase())) {
        return false;
      }
      final totalAmount = getAccountTotalDue(client.id);

      if (bucketMinAmount.value > 0 && totalAmount < bucketMinAmount.value)
        return false;
      if (bucketMaxAmount.value > 0 && totalAmount > bucketMaxAmount.value)
        return false;
      if (bucketMinInvoices.value > 0 && invoiceCount < bucketMinInvoices.value)
        return false;
      if (bucketMaxInvoices.value > 0 && invoiceCount > bucketMaxInvoices.value)
        return false;

      return true;
    }).toList();
  }

  List<CollectionItemModel> getInvoicesByAccount(String clientId) {
    final invoices = bucketItems
        .where((item) => item.client.id == clientId && item.toBeCollected > 0)
        .toList();
    // Apply search query if present
    var results = invoices;
    if (invoiceSearchQuery.value.isNotEmpty) {
      final query = invoiceSearchQuery.value.toLowerCase();
      results = results.where((item) {
        return item.id.toLowerCase().contains(query) ||
            item.documentReferences
                .any((ref) => ref.toLowerCase().contains(query));
      }).toList();
    }

    // Apply amount range filter when set (bucket-level filter used for account invoices)
    if (bucketMinAmount.value > 0 || bucketMaxAmount.value > 0) {
      results = results.where((item) {
        final minOk = bucketMinAmount.value > 0
            ? item.toBeCollected >= bucketMinAmount.value
            : true;
        final maxOk = bucketMaxAmount.value > 0
            ? item.toBeCollected <= bucketMaxAmount.value
            : true;
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
    _ensureAggregates();
    return _totalDueByClient[clientId] ?? 0.0;
  }

  double getAccountTotalCollected(String clientId) {
    _ensureAggregates();
    return _totalCollectedByClient[clientId] ?? 0.0;
  }

  int getAccountInvoiceCount(String clientId) {
    _ensureAggregates();
    return _invoiceCountByClient[clientId] ?? 0;
  }

  // ========================================================================
  // Activity helpers
  // ========================================================================

  List<ClientModel> get activityAccounts {
    final activeClientIds = activityItems
        .where((e) => e.toBeCollected > 0)
        .map((e) => e.client.id)
        .toSet();
    return masterAccountList.where((client) {
      if (!activeClientIds.contains(client.id)) return false;
      if (activitySearchQuery.value.isNotEmpty &&
          !client.name
              .toLowerCase()
              .contains(activitySearchQuery.value.toLowerCase())) {
        return false;
      }
      final totalAmount = getActivityAccountTotalDue(client.id);
      final invoiceCount = getActivityAccountInvoiceCount(client.id);

      if (activityMinAmount.value > 0 && totalAmount < activityMinAmount.value)
        return false;
      if (activityMaxAmount.value > 0 && totalAmount > activityMaxAmount.value)
        return false;
      if (activityMinInvoices.value > 0 &&
          invoiceCount < activityMinInvoices.value) return false;
      if (activityMaxInvoices.value > 0 &&
          invoiceCount > activityMaxInvoices.value) return false;

      return true;
    }).toList();
  }

  double getActivityAccountTotalDue(String clientId) => activityItems
      .where((item) => item.client.id == clientId)
      .fold(0.0, (sum, item) => sum + item.toBeCollected);

  double getActivityAccountTotalCollected(String clientId) => activityItems
      .where((item) => item.client.id == clientId)
      .fold(0.0, (sum, item) => sum + item.totalCollected);

  int getActivityAccountInvoiceCount(String clientId) => activityItems
      .where((item) => item.client.id == clientId && item.toBeCollected > 0)
      .length;

  List<CollectionItemModel> getActivityInvoicesByAccount(String clientId) {
    final invoices = activityItems
        .where((item) => item.client.id == clientId && item.toBeCollected > 0)
        .toList();
    var results = invoices;
    if (invoiceSearchQuery.value.isNotEmpty) {
      final query = invoiceSearchQuery.value.toLowerCase();
      results = results.where((item) {
        return item.id.toLowerCase().contains(query) ||
            item.documentReferences
                .any((ref) => ref.toLowerCase().contains(query));
      }).toList();
    }

    // Apply activity amount range filter when set
    if (activityMinAmount.value > 0 || activityMaxAmount.value > 0) {
      results = results.where((item) {
        final minOk = activityMinAmount.value > 0
            ? item.toBeCollected >= activityMinAmount.value
            : true;
        final maxOk = activityMaxAmount.value > 0
            ? item.toBeCollected <= activityMaxAmount.value
            : true;
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

    final allItems = this.allItems;
    final accountInvoices =
        allItems.where((item) => item.client.id == clientId).toList();

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
    final allItems = this.allItems;
    final accountItems =
        allItems.where((item) => item.client.id == clientId).toList();

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
    final allItems = this.allItems;
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
      final client = masterAccountList.firstWhere((c) => c.id == clientId,
          orElse: () => ClientModel.empty());
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
    final allItems = this.allItems;
    return allItems.where((item) {
      if (item.toBeCollected != 0) return false;
      if (!_matchesArea(item.bpCode)) return false;
      return true;
    }).toList();
  }

  /// Due Date: invoices past their due date, filtered by area
  List<CollectionItemModel> get overdueItems {
    final allItems = this.allItems;
    final now = DateTime.now();
    return allItems.where((item) {
      if (!_matchesArea(item.bpCode)) return false;
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
    return masterAccountList
        .where((c) => settledInvoiceIds.contains(c.id))
        .toList();
  }

  /// Returns accounts that have overdue invoices
  List<ClientModel> get overdueAccounts {
    final overdueInvoiceIds = overdueItems.map((e) => e.client.id).toSet();
    return masterAccountList
        .where((c) => overdueInvoiceIds.contains(c.id))
        .toList();
  }

  /// Returns settled invoices for a specific account
  List<CollectionItemModel> getSettledInvoicesByAccount(String clientId) {
    return completedItems.where((item) => item.client.id == clientId).toList();
  }

  /// Returns overdue invoices for a specific account
  List<CollectionItemModel> getOverdueInvoicesByAccount(String clientId) {
    return overdueItems.where((item) => item.client.id == clientId).toList();
  }

  /// Reconciliation: invoices marked for reconciliation, filtered by area
  List<CollectionItemModel> get reconciliationItems {
    final allItems = this.allItems;
    return allItems.where((item) {
      if (item.status != 'Reconciliation') return false;
      if (item.toBeCollected <= 0) return false;
      if (!_matchesArea(item.bpCode)) return false;
      return true;
    }).toList();
  }

  /// Advanced Payment: unassigned payments, filtered by area (based on client code)
  List<Map<String, dynamic>> get filteredUnassignedAdvancedPayments {
    return unassignedAdvancedPayments.where((entry) {
      final clientId = entry['clientId'];
      final client = masterAccountList.firstWhere((c) => c.id == clientId,
          orElse: () => ClientModel.empty());
      if (!_matchesArea(client.code)) return false;
      return true;
    }).toList();
  }

  /// Returns accounts that have reconciliation invoices
  List<ClientModel> get reconciliationAccounts {
    // Only show accounts that have reconciliation invoices currently in the bucket
    final clientIds = reconciliationItems
        .where((item) => bucketItems.any((b) => b.id == item.id))
        .map((e) => e.client.id)
        .toSet();
    return masterAccountList.where((c) => clientIds.contains(c.id)).toList();
  }

  /// Returns accounts that have unassigned advanced payments
  List<ClientModel> get advancedPaymentAccounts {
    final clientIds =
        unassignedAdvancedPayments.map((e) => e['clientId'] as String).toSet();
    return masterAccountList.where((c) => clientIds.contains(c.id)).toList();
  }

  /// Number of assigned advanced payments (invoices created from advanced payments)
  int get assignedAdvancedPaymentCount {
    final fromBucket = bucketItems
        .where((item) =>
            item.toBeCollected > 0 &&
            item.history.any((h) => h.status == 'Advanced Payment Applied'))
        .map((i) => i.id);
    final fromActivity = activityItems
        .where((item) =>
            item.toBeCollected > 0 &&
            item.history.any((h) => h.status == 'Advanced Payment Applied'))
        .map((i) => i.id);
    final assignedIds = {...fromBucket, ...fromActivity};
    return assignedIds.length;
  }

  /// Total advanced payments: assigned (invoices created and still unpaid) + unassigned payments
  int get advancedPaymentsCount =>
      assignedAdvancedPaymentCount + unassignedAdvancedPayments.length;

  /// Returns reconciliation invoices for a specific account
  List<CollectionItemModel> getReconciliationInvoicesByAccount(
      String clientId) {
    return reconciliationItems
        .where((item) => item.client.id == clientId)
        .toList();
  }

  // ========================================================================
  // Process Logic
  // ========================================================================

  Future<void> markInvoicesForReconciliation(
      String clientId, List<String> invoiceIds, String remarks) async {
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final collectorInitials = UserController.instance.user.value.initials;
    final updated = <CollectionItemModel>[];

    CollectionItemModel mark(CollectionItemModel item) => item.copyWith(
          status: 'Reconciliation',
          history: [
            ...item.history,
            CollectionHistoryModel(
              date: now,
              collectorName: collectorInitials,
              status: 'Reconciliation',
              remarks: remarks,
            )
          ],
        );

    for (final id in invoiceIds) {
      // Find in bucket or activity
      int idx = bucketItems.indexWhere((e) => e.id == id);
      if (idx != -1) {
        bucketItems[idx] = mark(bucketItems[idx]);
        updated.add(bucketItems[idx]);
        continue;
      }

      idx = activityItems.indexWhere((e) => e.id == id);
      if (idx != -1) {
        activityItems[idx] = mark(activityItems[idx]);
        updated.add(activityItems[idx]);
      }
    }

    // Persist the marked invoices and queue the office activity for upload.
    await repository.saveOfficeActivity(
      type: 'Reconciliation',
      clientId: clientId,
      clientName: _clientNameFor(clientId),
      remarks: remarks,
      documentIds: invoiceIds,
      updatedInvoices: updated,
    );
    logDebug(
        '[CollectionActivityController] Marked ${invoiceIds.length} invoices for Reconciliation');
  }

  Future<void> saveAdvancedPayment({
    required String clientId,
    required double amount,
    required String remarks,
  }) async {
    // Persisted + queued (ADVANCED_PAYMENT) so it survives a restart and uploads.
    final record = await repository.saveAdvance(
      clientId: clientId,
      clientName: _clientNameFor(clientId),
      amount: amount,
      remarks: remarks,
    );
    if (record == null) {
      errorMessage.value = 'Failed to save advanced payment';
      return;
    }

    unassignedAdvancedPayments.add(_advanceToMap(record));
    logDebug(
        '[CollectionActivityController] Saved Advanced Payment ${record.externalRef} for $clientId: ₱$amount');
  }

  Future<void> assignInvoiceToPayment({
    required String paymentId,
    required String invoiceNumber,
    required double amountDue,
    required String dueDate,
  }) async {
    final paymentIdx =
        unassignedAdvancedPayments.indexWhere((e) => e['id'] == paymentId);
    if (paymentIdx == -1) return;

    final payment = unassignedAdvancedPayments[paymentIdx];
    final clientId = payment['clientId'] as String;
    final paidAmount = payment['amount'] as double;
    final client = masterAccountList.firstWhere((c) => c.id == clientId,
        orElse: () => ClientModel.empty());

    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final collectorInitials =
        payment['collectorName'] ?? UserController.instance.user.value.initials;

    final remainingDue = (amountDue - paidAmount).clamp(0.0, double.infinity);
    final isFullyPaid = remainingDue == 0;

    final historyEntry = CollectionHistoryModel(
      date: now,
      collectorName: collectorInitials,
      status: 'Advanced Payment Applied',
      remarks: 'Applied from advanced payment: ${payment['remarks']}',
      totalCollected: paidAmount > amountDue ? amountDue : paidAmount,
    );

    final newItem = CollectionItemModel(
      id: invoiceNumber,
      client: client,
      bpCode: client.code,
      toBeCollected: remainingDue,
      totalCollected: paidAmount > amountDue ? amountDue : paidAmount,
      dueDate: dueDate,
      status: isFullyPaid ? 'Collected' : '',
      history: [historyEntry],
    );

    // Persist locally and queue ASSIGN_ADVANCE (the server creates the invoice if
    // new and allocates the advance to it).
    await repository.assignAdvance(
      advance: CollectionAdvanceRecord(
        externalRef: paymentId,
        clientId: clientId,
        clientName: client.name,
        amount: paidAmount,
        date: (payment['date'] ?? now).toString(),
        remarks: (payment['remarks'] ?? '').toString(),
        collectorName: collectorInitials.toString(),
      ),
      newInvoice: newItem,
      amountDue: amountDue,
      dueDate: dueDate,
    );

    // Add to bucket (if fully paid it shows in settled, if not it waits for next collection)
    bucketItems.add(newItem);

    // Remove from unassigned (use removeWhere to be robust against id type mismatches or duplicates)
    unassignedAdvancedPayments.removeWhere((e) => e['id'] == paymentId);

    logDebug(
        '[CollectionActivityController] Assigned invoice $invoiceNumber to payment. Fully paid: $isFullyPaid');
  }

  // ========================================================================
  // Claims
  // ========================================================================

  Future<void> unclaimAccount(String clientId) async {
    final invoices =
        activityItems.where((item) => item.client.id == clientId).toList();
    if (invoices.isEmpty) return;

    final released = <CollectionItemModel>[];
    for (final inv in invoices) {
      final index = activityItems.indexWhere((e) => e.id == inv.id);
      if (index != -1) {
        final item = activityItems[index];
        final restored = item.copyWith(
          assignedAt: '',
          status: item.status == 'Reconciliation' ? 'Reconciliation' : '',
        );
        bucketItems.add(restored);
        activityItems.removeAt(index);
        released.add(restored);
      }
    }

    // Clear Engagement: release locally + queue CLEAR (no reason/history).
    await repository.releaseInvoices(
        clientId: clientId, releasedInvoices: released);
    logDebug(
        '[CollectionActivityController] Account $clientId unclaimed (${invoices.length} invoices)');
  }

  Future<void> unclaimWithReason(
      String clientId, String reason, String remarks) async {
    // 1. Move all invoices back to bucket without adding history to them
    final invoices =
        activityItems.where((item) => item.client.id == clientId).toList();
    if (invoices.isEmpty) return;

    final released = <CollectionItemModel>[];
    for (final inv in invoices) {
      final index = activityItems.indexWhere((e) => e.id == inv.id);
      if (index != -1) {
        final item = activityItems[index];
        final restored = item.copyWith(
          assignedAt: '',
          status: item.status == 'Reconciliation' ? 'Reconciliation' : '',
        );
        bucketItems.add(restored);
        activityItems.removeAt(index);
        released.add(restored);
      }
    }

    // 2. Deferred Engagement: persist the release, record the reason once for the
    //    account, and queue DEFER (the server keeps one entry per account).
    final record = await repository.releaseInvoices(
      clientId: clientId,
      releasedInvoices: released,
      reason: reason,
      remarks: remarks,
    );

    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final collectorInitials = UserController.instance.user.value.initials;
    final historyEntry = CollectionHistoryModel(
      date: record?.date ?? now,
      collectorName: record?.collectorName ?? collectorInitials,
      status: reason,
      remarks: remarks,
      totalCollected: 0,
    );

    final historyList = clientHistory[clientId] ?? [];
    clientHistory[clientId] = [...historyList, historyEntry];

    logDebug(
        '[CollectionActivityController] Account $clientId unclaimed with account-level reason: $reason');
  }

  void claimAccount(String clientId) {
    // Prefer claiming reconciliation-marked invoices that are still in the bucket.
    final reconInvoices = getReconciliationInvoicesByAccount(clientId);
    final bucketReconIds = reconInvoices
        .where((i) => bucketItems.any((b) => b.id == i.id))
        .map((i) => i.id)
        .toList();

    if (bucketReconIds.isNotEmpty) {
      claimItemsByIds(bucketReconIds);
      logDebug(
          '[CollectionActivityController] Account $clientId claimed (${bucketReconIds.length} reconciliation invoices)');
      return;
    }

    // Fallback: claim all bucket items (legacy behavior)
    final invoices =
        bucketItems.where((item) => item.client.id == clientId).toList();
    if (invoices.isEmpty) return;

    final ids = invoices.map((e) => e.id).toList();
    claimItemsByIds(ids);
    logDebug(
        '[CollectionActivityController] Account $clientId claimed (${invoices.length} invoices)');
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
        final item = bucketItems[index];
        final moved = item.copyWith(
          status: item.status == 'Reconciliation' ? 'Reconciliation' : '',
          assignedAt: now,
        );
        activityItems.add(moved);
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
      final double updatedTotalCollected =
          oldItem.totalCollected + newlyCollected;
      final double updatedToBeCollected =
          (oldItem.toBeCollected - newlyCollected).clamp(0, double.infinity);

      final bool isFullyPaid = updatedToBeCollected == 0;
      final bool wasReconciliation =
          oldItem.status == CollectionStatusColors.statusReconciliation;
      final String finalStatus = isFullyPaid
          ? CollectionStatusColors.statusCollected
          : (wasReconciliation
              ? CollectionStatusColors.statusReconciliation
              : '');

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

      logDebug(
          '[CollectionActivityController] Activity $id saved. Move to bucket: $isFullyPaid');
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
      final selectedItems =
          activityItems.where((item) => ids.contains(item.id)).toList();
      final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

      for (var item in selectedItems) {
        final double manualAmount = amounts[item.id] ?? 0;
        final String itemRemarks = remarks[item.id] ?? 'Batch Recording';

        final double updatedTotalCollected = item.totalCollected + manualAmount;
        final double updatedToBeCollected =
            (item.toBeCollected - manualAmount).clamp(0, double.infinity);

        final bool isFullyPaid = updatedToBeCollected == 0;
        final bool wasReconciliation =
            item.status == CollectionStatusColors.statusReconciliation;

        final String itemStatus = statuses[item.id] ??
            (isFullyPaid
                ? CollectionStatusColors.statusCollected
                : (wasReconciliation
                    ? CollectionStatusColors.statusReconciliation
                    : ''));

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
          status: isFullyPaid
              ? CollectionStatusColors.statusCollected
              : (wasReconciliation
                  ? CollectionStatusColors.statusReconciliation
                  : ''),
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
      logDebug(
          '[CollectionActivityController] Batch activity saved for ${ids.length} items');
    } catch (e) {
      logDebug('[CollectionActivityController] saveBatchActivity error: $e');
      errorMessage.value = 'Failed to save batch activity: $e';
    }
  }

  Future<void> saveGlobalActivity({
    required String type,
    required String accountName,
    required String remarks,
    double totalCollected = 0,
    String? bankName,
    String? checkNumber,
    String? clientId,
    List<String> documentIds = const [],
  }) async {
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final collectorInitials = UserController.instance.user.value.initials;

    // Persist + queue (DEPOSIT / CWT_PICKUP). Forms that only know the account
    // name (CWT) get the id resolved from the loaded account list.
    final resolvedClientId = (clientId != null && clientId.isNotEmpty)
        ? clientId
        : _clientIdFor(accountName);
    await repository.saveOfficeActivity(
      type: type,
      clientId: resolvedClientId,
      clientName: accountName,
      amount: totalCollected,
      bankName: bankName,
      checkNumber: checkNumber,
      remarks: remarks,
      documentIds: documentIds,
    );

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
  // Persisted account-level concepts (Stage C2)
  // ========================================================================

  /// Rebuild the in-memory lists from SQLite so activities, advances and
  /// account history survive an app restart.
  Future<void> _loadPersistedExtras() async {
    try {
      final activities = await repository.loadOfficeActivities();
      globalActivities.assignAll(activities
          // Reconciliation is shown through invoice status, not as an activity card.
          .where((a) => a.type != 'Reconciliation')
          .map((a) => {
                'history': CollectionHistoryModel(
                  date: a.date,
                  collectorName: a.collectorName,
                  status: a.type,
                  remarks: a.remarks,
                  totalCollected: a.amount,
                  bankName: a.bankName,
                  checkNumber: a.checkNumber,
                ),
                'accountName': a.clientName,
                'invoiceId': null,
                'item': null,
              })
          .toList());

      final advances = await repository.loadUnassignedAdvances();
      unassignedAdvancedPayments
          .assignAll(advances.map(_advanceToMap).toList());

      final history = await repository.loadAccountHistory();
      final grouped = <String, List<CollectionHistoryModel>>{};
      for (final h in history) {
        grouped.putIfAbsent(h.clientId, () => []).add(CollectionHistoryModel(
              date: h.date,
              collectorName: h.collectorName,
              status: h.reason,
              remarks: h.remarks,
              totalCollected: 0,
            ));
      }
      clientHistory.assignAll(grouped);

      logDebug(
          '[CollectionActivityController] Loaded ${activities.length} activities, '
          '${advances.length} advances, ${history.length} account history entries');
    } catch (e) {
      logDebug('[CollectionActivityController] _loadPersistedExtras error: $e');
    }
  }

  Map<String, dynamic> _advanceToMap(CollectionAdvanceRecord r) => {
        'id': r.externalRef,
        'clientId': r.clientId,
        'amount': r.amount,
        'remarks': r.remarks,
        'date': r.date,
        'collectorName': r.collectorName,
      };

  String _clientNameFor(String clientId) {
    final c = masterAccountList.firstWhereOrNull((c) => c.id == clientId);
    return c?.name ?? clientId;
  }

  String _clientIdFor(String accountName) {
    final c = masterAccountList.firstWhereOrNull(
        (c) => c.name.trim().toLowerCase() == accountName.trim().toLowerCase());
    return c?.id ?? '';
  }
}
