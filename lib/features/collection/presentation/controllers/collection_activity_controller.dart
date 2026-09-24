import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/sync_manager.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_advance_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_engagement_dao.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation_fold.dart';
import 'package:mdmpi_mobile_app/features/collection/models/bank_model.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/bank_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/models/activity_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/models/invoice_filter.dart';

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

  /// Distinct customer P.O.s per account, bucket-only like the invoice count.
  /// Case-insensitive: SAP hands us `ADC-1` and `adc-1` for the same order.
  final Map<String, int> _poCountByClient = {};

  /// Marks the cached aggregates stale. Call after changing item contents in
  /// a way that bypasses the observable lists (nothing does today).
  void invalidateAggregates() => _aggregatesDirty = true;

  /// Invalidates the cached aggregates on every change to either item list.
  /// Called from [onInit]; exposed so tests can wire a bare controller.
  @visibleForTesting
  void startAggregateTracking() {
    ever(bucketItems, (_) => invalidateAggregates());
    ever(activityItems, (_) => invalidateAggregates());
    // The calendar's grouping resolves each engagement's invoice out of
    // allItems, so it goes stale with the item lists as well as with the
    // archive itself.
    ever(bucketItems, (_) => _byDateDirty = true);
    ever(activityItems, (_) => _byDateDirty = true);
    ever(ownEngagements, (_) => _byDateDirty = true);
  }

  void _rebuildAggregates() {
    _allItemsCache = mergeUnique(bucketItems, activityItems);
    _invoiceCountByClient.clear();
    _totalDueByClient.clear();
    _totalCollectedByClient.clear();
    _poCountByClient.clear();

    // Money spans bucket + activity, so it folds over the merged list.
    for (final item in _allItemsCache) {
      final id = item.client.id;
      _totalDueByClient[id] = (_totalDueByClient[id] ?? 0) + item.toBeCollected;
      _totalCollectedByClient[id] =
          (_totalCollectedByClient[id] ?? 0) + item.totalCollected;
    }
    // Invoice count is bucket-only and ignores fully-settled invoices,
    // matching the previous getter exactly.
    final posByClient = <String, Set<String>>{};
    for (final item in bucketItems) {
      if (item.toBeCollected > 0) {
        final id = item.client.id;
        _invoiceCountByClient[id] = (_invoiceCountByClient[id] ?? 0) + 1;
        if (item.hasPoNumber) {
          (posByClient[id] ??= <String>{})
              .add(item.poNumber.trim().toUpperCase());
        }
      }
    }
    for (final e in posByClient.entries) {
      _poCountByClient[e.key] = e.value.length;
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

  /// True once the first [loadBucket] has finished, success or failure.
  /// Until then the home screen shows a skeleton instead of empty figures,
  /// because "₱0.00" and "No items in bucket" during a server fetch read as
  /// an empty account rather than a loading one.
  final RxBool hasLoadedOnce = false.obs;

  /// The initial load is still running and nothing has been shown yet.
  bool get isFirstLoad => isLoading.value && !hasLoadedOnce.value;

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

  /// Filter and sort for the bucket, the same value the engagement list
  /// uses. The bucket is a catalogue, so it defaults to alphabetical, and
  /// its area lives on [selectedArea] because the toolbar's own chip owns it.
  final Rx<ActivityFilter> bucketFilterSpec =
      const ActivityFilter(sort: ActivitySort.name).obs;

  static const ActivityFilter _bucketFilterDefault =
      ActivityFilter(sort: ActivitySort.name);

  /// How many accounts [spec] would leave in the bucket, with the current
  /// search and area. Drives the live count on the filter sheet's button.
  int countBucketAccounts(ActivityFilter spec) =>
      _bucketAccountsFor(spec).length;

  final RxString activitySearchQuery = ''.obs;

  /// Filter and sort for the Field Engagement list and each account's
  /// invoice list. One value, replaced whole; see [ActivityFilter].
  final Rx<ActivityFilter> activityFilterSpec = ActivityFilter.none.obs;

  bool get hasActiveActivityFilter => activityFilterSpec.value.isActive;

  /// Territory codes with at least one engaged invoice, in the order
  /// [BCollectionArea] lists them. The filter never offers an empty area.
  List<String> get activityAreas {
    final present = <String>{};
    for (final item in activityItems) {
      if (item.toBeCollected <= 0) continue;
      final prefix = BCollectionArea.prefixOf(item.client.code);
      present.add(BCollectionArea.knownPrefixes.contains(prefix)
          ? prefix
          : BCollectionArea.others);
    }
    return BCollectionArea.names.keys.where(present.contains).toList();
  }

  void clearActivityFilters() => activityFilterSpec.value = ActivityFilter.none;

  /// How many accounts [spec] would leave on the engagement list, with the
  /// current search. Drives the live count on the filter sheet's button.
  int countActivityAccounts(ActivityFilter spec) =>
      _activityAccountsFor(spec).length;

  final RxString activityFilter = 'All'.obs;

  final RxString invoiceSearchQuery = ''.obs;

  /// Filter and sort for one account's invoice list. Its own value, not the
  /// engagement list's: once an account is open, the questions worth asking
  /// are about its invoices. See [InvoiceFilter]. Reset on leaving the
  /// screen, like [invoiceSearchQuery], so it never follows you into the
  /// next account.
  final Rx<InvoiceFilter> invoiceFilterSpec = InvoiceFilter.none.obs;

  bool get hasActiveInvoiceFilter => invoiceFilterSpec.value.isActive;

  void clearInvoiceFilters() => invoiceFilterSpec.value = InvoiceFilter.none;

  /// How many of [clientId]'s engaged invoices [spec] would show, with the
  /// current search. Drives the live count on the filter sheet's button.
  int countActivityInvoices(String clientId, InvoiceFilter spec) =>
      _activityInvoicesFor(clientId, spec).length;

  final RxList<ClientModel> masterAccountList = <ClientModel>[].obs;

  // Multi-select Account state
  final RxBool isSelectionMode = false.obs;
  final RxSet<String> selectedAccountIds = <String>{}.obs;

  /// [selectedAccountIds] in tick order. What is ticked rides at the head of
  /// the bucket list, so a pick spread over a 261-account catalogue is always
  /// together and always countable.
  ///
  /// Tick order, not list order: the account just ticked goes to the top, so
  /// the row that moves is the row the collector is looking at. A card only
  /// ever leaves a slot *above* the thumb — rows below the ticked one hold
  /// still, which is where the next target is.
  final RxList<String> selectionOrder = <String>[].obs;

  /// The account that moved on the last tick, and a counter that changes with
  /// it, so the list can play that one row's arrival instead of hard-cutting
  /// it into place. Only the moved row animates; the rest just close the gap.
  final RxString lastMovedAccountId = ''.obs;
  final RxInt selectionGeneration = 0.obs;

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
    // Reference data for the check fields. Independent of the bucket, and
    // nothing waits on it.
    loadBanks();
    // A server download replaces the local cache; mirror it in memory. Local
    // read only (no network), so this cannot loop back into a sync.
    ever(repository.localDataVersion, (_) async {
      _loadPersistedExtras();
      final items = await repository.getLocalCollectionItems();
      _setItems(items);
    });
    // One wire for all seven save paths, rather than a re-read at each of
    // them: the repository bumps this whenever it archives an engagement, so
    // a path added later cannot forget to refresh the calendar.
    ever(repository.ownEngagementVersion, (_) => reloadOwnEngagements());
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
    } catch (e) {
      logDebug('[CollectionActivityController] loadBucket error: $e');
      errorMessage.value = 'Failed to load collection items: $e';
    } finally {
      isLoading.value = false;
      hasLoadedOnce.value = true;
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
    String? poNumber,
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
      poNumber: poNumber,
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
  // ── Bank list ───────────────────────────────────────────────────────────

  /// The company bank list, for the check fields.
  final RxList<BankModel> banks = <BankModel>[].obs;

  /// Load the cached bank list and refresh it behind the collector.
  ///
  /// Never blocks anything: a failure here leaves the picker on whatever was
  /// cached, and an empty picker leaves the bank field as plain text.
  Future<void> loadBanks() async {
    if (!Get.isRegistered<BankRepository>()) return;
    final repository = Get.find<BankRepository>();
    banks.assignAll(await repository.cached());
    final result = await repository.refresh();
    if (result.isSuccess) banks.assignAll(result.value);
  }

  /// The company's own name for whatever was recorded against a collection.
  ///
  /// History predates the picker, so the same bank sits in it as "BPI" and as
  /// "Bank of the Philippine Islands". Resolving both onto the code means one
  /// chip instead of two, and a chip that writes what the picker would.
  String canonicalBankName(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final lower = value.toLowerCase();
    for (final bank in banks) {
      if (bank.code.toLowerCase() == lower ||
          bank.name.toLowerCase() == lower) {
        return bank.label;
      }
    }
    // Not on the company list: a bank typed before this existed, or one the
    // list has since dropped. Better offered as it was recorded than lost.
    return value;
  }

  List<String> recentBankNames({int limit = 4}) {
    final counts = <String, int>{};
    final display = <String, String>{};
    for (final item in allItems) {
      for (final h in item.history) {
        final name = canonicalBankName(h.bankName ?? '');
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

  /// Number of bucket accounts [area] would show (a BCollectionArea code, the
  /// "Others" sentinel, or '' for every account).
  ///
  /// Exactly what picking that area produces: the same population and the same
  /// filters as [bucketAccounts], with only the territory swapped. Counting
  /// the master account list instead reported accounts the bucket can never
  /// show — ones already claimed into an engagement, or settled to a zero
  /// balance — so the picker offered 45 and the list then held 44.
  int accountCountForArea(String area) =>
      _bucketAccountsFor(bucketFilterSpec.value, area: area).length;

  /// True when any bucket-narrowing input (search, amount/invoice range, area)
  /// is active. Drives the empty-state copy and the "Clear all filters" action.
  bool get hasActiveBucketFilter =>
      bucketSearchQuery.value.trim().isNotEmpty ||
      bucketFilterSpec.value.isActive ||
      selectedArea.value.isNotEmpty;

  /// Reset every bucket filter, including the area selection.
  void clearBucketFilters() {
    bucketSearchQuery.value = '';
    bucketFilterSpec.value = _bucketFilterDefault;
    selectedArea.value = '';
  }

  /// Order two accounts by how many invoices they hold under [spec].
  ///
  /// The count is a property of the account, so it cannot come through the
  /// invoice comparator. Only the invoices that passed the filter are
  /// counted, so the order agrees with the number printed on the card.
  int _byInvoiceCount(
    ActivityFilter spec,
    Map<String, List<CollectionItemModel>> matching,
    ClientModel a,
    ClientModel b,
  ) {
    final an = matching[a.id]?.length ?? 0;
    final bn = matching[b.id]?.length ?? 0;
    return spec.sort == ActivitySort.mostInvoices
        ? bn.compareTo(an)
        : an.compareTo(bn);
  }

  List<ClientModel> get bucketAccounts =>
      _selectedFirst(_bucketAccountsFor(bucketFilterSpec.value));

  /// The ticked accounts, in tick order, ahead of everything else.
  ///
  /// A ticked account the filters or the search have since dropped simply is
  /// not there — this promotes a row, it does not resurrect one.
  List<ClientModel> _selectedFirst(List<ClientModel> accounts) {
    if (selectionOrder.isEmpty) return accounts;
    final slot = <String, int>{
      for (var i = 0; i < selectionOrder.length; i++) selectionOrder[i]: i
    };
    final picked = List<ClientModel?>.filled(selectionOrder.length, null);
    final rest = <ClientModel>[];
    for (final client in accounts) {
      final i = slot[client.id];
      if (i == null) {
        rest.add(client);
      } else {
        picked[i] = client;
      }
    }
    return [...picked.whereType<ClientModel>(), ...rest];
  }

  /// How many rows at the head of [bucketAccounts] are ticked ones, so the
  /// list can rule a line under the group.
  int get selectedVisibleCount {
    if (selectionOrder.isEmpty) return 0;
    final visible =
        _bucketAccountsFor(bucketFilterSpec.value).map((c) => c.id).toSet();
    return selectionOrder.where(visible.contains).length;
  }

  /// Accounts with at least one bucket invoice that passes [spec], the area
  /// and the search. An account is judged by its best invoice, so filtering
  /// for "late 30+" keeps every account holding such an invoice.
  ///
  /// [area] overrides the selected territory, which is how the area picker
  /// asks what each choice would actually show.
  List<ClientModel> _bucketAccountsFor(ActivityFilter spec, {String? area}) {
    final query = bucketSearchQuery.value.toLowerCase();
    final inArea = area ?? selectedArea.value;
    final matching = <String, List<CollectionItemModel>>{};
    for (final item in bucketItems) {
      if (item.toBeCollected <= 0 || !spec.matches(item)) continue;
      matching.putIfAbsent(item.client.id, () => []).add(item);
    }
    final accounts = masterAccountList.where((client) {
      if (!BCollectionArea.matches(client.code, inArea)) return false;
      if (!matching.containsKey(client.id)) return false;
      return query.isEmpty || client.name.toLowerCase().contains(query);
    }).toList();

    // A catalogue, so alphabetical by default: collectors find accounts here
    // by name. The master list is a map's values in whatever order invoices
    // arrived from the server, which is no order at all. Any other sort comes
    // from the spec, placing each account by its leading invoice.
    CollectionItemModel leading(ClientModel c) =>
        (matching[c.id]!..sort(spec.compare)).first;
    if (spec.sort == ActivitySort.name) {
      accounts
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (spec.sort.isAccountLevel) {
      accounts.sort((a, b) {
        final byCount = _byInvoiceCount(spec, matching, a, b);
        return byCount != 0 ? byCount : a.name.compareTo(b.name);
      });
    } else if (spec.sort.isByAmount) {
      // The figure on the card, which is the account's whole balance. Ordering
      // by the leading invoice instead put an account holding one small
      // invoice among thirty-eight at the top of "amount low to high".
      accounts.sort((a, b) {
        final due = _byAccountTotal(
            spec, getAccountTotalDue(a.id), getAccountTotalDue(b.id));
        return due != 0 ? due : a.name.compareTo(b.name);
      });
    } else {
      accounts.sort((a, b) {
        final byLead = spec.compare(leading(a), leading(b));
        return byLead != 0 ? byLead : a.name.compareTo(b.name);
      });
    }
    return accounts;
  }

  /// Order two account totals by [spec]'s direction.
  int _byAccountTotal(ActivityFilter spec, double a, double b) =>
      spec.sort.isDescending ? b.compareTo(a) : a.compareTo(b);

  /// How many of this account's bucket invoices are past due — the strongest
  /// signal for which accounts to pick up today.
  int getBucketAccountOverdueCount(String clientId) => bucketItems
      .where((item) =>
          item.client.id == clientId &&
          item.toBeCollected > 0 &&
          item.isOverdue)
      .length;

  /// Everything currently in view, and everything currently ticked.
  ///
  /// Both read off [bucketAccounts] so a filter that empties the list also
  /// zeroes the count, and the acquire bar's total is the sum of exactly the
  /// rows the collector can see are ticked.
  ({int accounts, double due}) get bucketSummary {
    var due = 0.0;
    final accounts = bucketAccounts;
    for (final client in accounts) {
      due += getAccountTotalDue(client.id);
    }
    return (accounts: accounts.length, due: due);
  }

  ({int accounts, double due}) get selectionSummary {
    var due = 0.0;
    for (final id in selectedAccountIds) {
      due += getAccountTotalDue(id);
    }
    return (accounts: selectedAccountIds.length, due: due);
  }

  /// Tick every account the current filters leave visible — "take the whole
  /// area" in one tap.
  void selectAllVisibleAccounts() {
    // Read in the order shown, so taking the lot leaves every row exactly
    // where it already was. Ticking all of them must not shuffle the screen.
    final ids = bucketAccounts.map((c) => c.id).toList();
    if (ids.isEmpty) return;
    selectedAccountIds.addAll(ids);
    selectionOrder.assignAll([
      ...ids,
      // Anything ticked but filtered out of view keeps its place in the order.
      ...selectionOrder.where((id) => !ids.contains(id)),
    ]);
    lastMovedAccountId.value = '';
    selectionGeneration.value++;
    isSelectionMode.value = true;
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
            item.poNumber.toLowerCase().contains(query) ||
            item.documentReferences
                .any((ref) => ref.toLowerCase().contains(query));
      }).toList();
    }

    // The same filter the bucket list uses, so opening an account shows the
    // invoices that put it on the list and nothing else.
    final spec = bucketFilterSpec.value;
    results = results.where(spec.matches).toList()
      ..sort(spec.sort == ActivitySort.name
          // Inside one account every invoice shares the name, so the
          // catalogue's default has nothing to order by: oldest due first.
          ? (a, b) => a.daysPastDue.compareTo(b.daysPastDue) * -1
          : spec.compare);

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

  /// The account's open bucket invoices, unfiltered: what its card counts.
  /// The breakdown on the card reads this, so the lines under "3 P.O.s ·
  /// 7 invoices" are exactly those seven.
  List<CollectionItemModel> getBucketOpenInvoices(String clientId) => bucketItems
      .where((item) => item.client.id == clientId && item.toBeCollected > 0)
      .toList();

  /// How many distinct customer P.O.s the account's open invoices fall under.
  /// Zero when none of them carries one.
  int getAccountPoCount(String clientId) {
    _ensureAggregates();
    return _poCountByClient[clientId] ?? 0;
  }

  // ========================================================================
  // Activity helpers
  // ========================================================================

  List<ClientModel> get activityAccounts =>
      _activityAccountsFor(activityFilterSpec.value);

  /// Accounts with at least one engaged invoice that passes [spec] and the
  /// search, ordered by the spec's sort. An account is judged by its best
  /// invoice: if any invoice matches, the account stays, so a filter for
  /// "Refused to Pay" shows every account with such an invoice.
  List<ClientModel> _activityAccountsFor(ActivityFilter spec) {
    final query = activitySearchQuery.value.toLowerCase();
    final matching = <String, List<CollectionItemModel>>{};
    for (final item in activityItems) {
      if (item.toBeCollected <= 0 || !spec.matches(item)) continue;
      matching.putIfAbsent(item.client.id, () => []).add(item);
    }
    final accounts = masterAccountList.where((client) {
      if (!matching.containsKey(client.id)) return false;
      return query.isEmpty || client.name.toLowerCase().contains(query);
    }).toList();

    // A work queue, so it is ordered like one. The default is most overdue
    // first, then worth most; the other sorts follow the spec. Each account
    // is placed by its leading invoice under that same sort, and the name
    // breaks ties so the order never shuffles between rebuilds.
    CollectionItemModel leading(ClientModel c) =>
        (matching[c.id]!..sort(spec.compare)).first;
    accounts.sort((a, b) {
      if (spec.sort == ActivitySort.name) return a.name.compareTo(b.name);
      if (spec.sort.isAccountLevel) {
        final byCount = _byInvoiceCount(spec, matching, a, b);
        return byCount != 0 ? byCount : a.name.compareTo(b.name);
      }
      if (spec.sort == ActivitySort.mostOverdue) {
        final overdue = getActivityAccountOverdueCount(b.id)
            .compareTo(getActivityAccountOverdueCount(a.id));
        if (overdue != 0) return overdue;
        final due = getActivityAccountTotalDue(b.id)
            .compareTo(getActivityAccountTotalDue(a.id));
        if (due != 0) return due;
        return a.name.compareTo(b.name);
      }
      if (spec.sort.isByAmount) {
        // The figure on the card: the account's whole balance, not one of
        // its invoices.
        final due = _byAccountTotal(spec, getActivityAccountTotalDue(a.id),
            getActivityAccountTotalDue(b.id));
        if (due != 0) return due;
        return a.name.compareTo(b.name);
      }
      final byLead = spec.compare(leading(a), leading(b));
      return byLead != 0 ? byLead : a.name.compareTo(b.name);
    });
    return accounts;
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

  /// The account's open engaged invoices, unfiltered: what its Activity card
  /// counts, and what the card's P.O. breakdown lists.
  List<CollectionItemModel> getActivityOpenInvoices(String clientId) =>
      activityItems
          .where((item) => item.client.id == clientId && item.toBeCollected > 0)
          .toList();

  /// Distinct customer P.O.s across this account's engaged invoices.
  int getActivityAccountPoCount(String clientId) => activityItems
      .where((item) =>
          item.client.id == clientId &&
          item.toBeCollected > 0 &&
          item.hasPoNumber)
      .map((item) => item.poNumber.trim().toUpperCase())
      .toSet()
      .length;

  /// How many of this account's engaged invoices are past their due date.
  int getActivityAccountOverdueCount(String clientId) => activityItems
      .where((item) =>
          item.client.id == clientId &&
          item.toBeCollected > 0 &&
          item.isOverdue)
      .length;

  /// The day at a glance: what is on the collector's plate right now.
  ///
  /// Read off [activityAccounts] rather than the raw list so it always agrees
  /// with the cards underneath it, including while a filter is applied.
  ({int accounts, int invoices, int overdue, double due, double collected})
      get activitySummary {
    var invoices = 0;
    var overdue = 0;
    var due = 0.0;
    var collected = 0.0;
    for (final client in activityAccounts) {
      invoices += getActivityAccountInvoiceCount(client.id);
      overdue += getActivityAccountOverdueCount(client.id);
      due += getActivityAccountTotalDue(client.id);
      collected += getActivityAccountTotalCollected(client.id);
    }
    return (
      accounts: activityAccounts.length,
      invoices: invoices,
      overdue: overdue,
      due: due,
      collected: collected,
    );
  }

  List<CollectionItemModel> getActivityInvoicesByAccount(String clientId) =>
      _activityInvoicesFor(clientId, invoiceFilterSpec.value);

  /// This account's engaged invoices under [spec] and the current search.
  ///
  /// The engagement filter is deliberately not applied here. It picks which
  /// accounts are worth a visit; once one is open the collector is recording
  /// against whatever that account owes, and an invoice hidden by a filter
  /// set two screens ago — with no way to clear it from here — is an invoice
  /// that cannot be paid.
  List<CollectionItemModel> _activityInvoicesFor(
      String clientId, InvoiceFilter spec) {
    var results = activityItems
        .where((item) => item.client.id == clientId && item.toBeCollected > 0)
        .toList();

    if (invoiceSearchQuery.value.isNotEmpty) {
      final query = invoiceSearchQuery.value.toLowerCase();
      results = results.where((item) {
        return item.id.toLowerCase().contains(query) ||
            item.poNumber.toLowerCase().contains(query) ||
            item.documentReferences
                .any((ref) => ref.toLowerCase().contains(query));
      }).toList();
    }

    return results.where(spec.matches).toList()..sort(spec.compare);
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

    // 1. Add invoice-level history. A reconciliation an outcome has since
    //    finished folds into that outcome, as in [allRecentHistory], so the
    //    list never shows "Reconciliation" and then "Collected" as two events.
    for (var item in accountItems) {
      for (final entry in foldFinishedReconciliations(item.history)) {
        combined.add({
          'history': entry.history,
          'invoiceId': item.id,
          'item': item,
          'reconciledOn': entry.reconciledOn,
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

    // 1. Add invoice-level history. A reconciliation an outcome has since
    //    finished folds into that outcome; see [reconciliationMerge].
    final allItems = this.allItems;
    for (var item in allItems) {
      for (final entry in foldFinishedReconciliations(item.history)) {
        combined.add({
          'history': entry.history,
          'accountName': item.client.name,
          'invoiceId': item.id,
          'item': item,
          'reconciledOn': entry.reconciledOn,
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

  // ========================================================================
  // The calendar's grouping
  // ========================================================================

  /// This collector's own engagements, read from the archive.
  ///
  /// Not derived from [allRecentHistory]: that is built out of the invoices
  /// currently in the bucket and the activity list, both of which are a cache
  /// of what the server says today. An invoice that settles stops coming back
  /// and takes its history with it, and the history table itself is truncated
  /// on every download — so a calendar built on it went blank shortly after
  /// the collector uploaded the work it was showing.
  final RxList<CollectionEngagementRecord> ownEngagements =
      <CollectionEngagementRecord>[].obs;

  bool _byDateDirty = true;
  int _byDateSourceLength = -1;
  Map<DateTime, List<Map<String, dynamic>>> _byDateCache = const {};

  /// Engagements grouped by the day they happened, for the calendar.
  ///
  /// Memoised. `table_calendar` asks once per visible cell through its event
  /// loader and again in each day builder, so regrouping on every call meant
  /// rebuilding the whole of the collector's history fifty to ninety times a
  /// frame.
  ///
  /// Keyed to the list rather than to the calendar day, unlike the days-past
  /// memo in BFormatter: which day an engagement belongs to was settled when
  /// it was recorded and does not go stale at midnight, only when the data
  /// changes.
  Map<DateTime, List<Map<String, dynamic>>> get activitiesByDate {
    // Reading the length is not decorative: it re-registers ownEngagements
    // with the enclosing Obx, which a cached read would otherwise touch
    // nothing to subscribe to. See [_ensureAggregates] for the same trap.
    final sourceLength = ownEngagements.length;
    if (_byDateDirty || sourceLength != _byDateSourceLength) {
      _rebuildByDate();
    }
    return _byDateCache;
  }

  void _rebuildByDate() {
    final grouped = <DateTime, List<Map<String, dynamic>>>{};
    final itemsById = {for (final i in allItems) i.id: i};
    var unplaceable = 0;

    // Some archive rows do not name their account: a deferral copied from
    // the server (the history table has no name column), or a deferral
    // recorded when the account had no invoice left in the bucket to copy
    // the name from. The card then had a blank headline and the day's
    // account filter had no chip for it. The name is known elsewhere: on the
    // client's invoices, in the master account list, or on another archive
    // row of the same client.
    final namesByClient = <String, String>{};
    for (final i in allItems) {
      if (i.client.name.isNotEmpty) {
        namesByClient.putIfAbsent(i.client.id, () => i.client.name);
      }
    }
    for (final c in masterAccountList) {
      if (c.name.isNotEmpty) namesByClient.putIfAbsent(c.id, () => c.name);
    }
    for (final e in ownEngagements) {
      if (e.clientName.isNotEmpty) {
        namesByClient.putIfAbsent(e.clientId, () => e.clientName);
      }
    }

    // A reconciliation and the outcome that finished it are one story, told
    // once. A Reconciliation row followed by an outcome on the same invoice
    // (or by a deferral of its account) folds into that outcome, which is
    // then labelled "Reconciliation Collected", "Reconciliation Refused to
    // Pay", and so on; a reconciliation nothing has finished yet stands on
    // its own. Read from the archive rather than the cached invoice: once
    // the invoice settles it leaves the cache, and the archive is what is
    // left.
    final merge = reconciliationMerge(ownEngagements);

    for (final e in ownEngagements) {
      // Reconciliation reads through invoice status, not as an engagement —
      // the same rule _loadPersistedExtras applies to the activity list.
      if (e.kind == 'OFFICE' && e.status == 'Reconciliation') continue;
      // A reconciliation an outcome has since finished: shown as part of
      // that outcome, not as a row of its own.
      if (merge.finished.contains(e.localRef)) continue;

      final day = BFormatter.parseLocal(e.engagedOn);
      if (day == null) {
        unplaceable++;
        continue;
      }
      final key = DateTime(day.year, day.month, day.day);

      // The same map shape ActivityHistoryCard already consumes, so nothing
      // downstream changes. 'item' is simply null once the invoice has
      // settled and left the bucket — the card already allows that.
      grouped.putIfAbsent(key, () => []).add({
        'history': CollectionHistoryModel(
          date: e.engagedAt,
          collectorName: e.collectorName,
          status: e.status,
          remarks: e.remarks,
          totalCollected: e.amount,
          bankName: e.bankName,
          checkNumber: e.checkNumber,
          checkDate: e.checkDate,
          purposeOfVisit: e.purposeOfVisit,
        ),
        'accountName': e.clientName.isNotEmpty
            ? e.clientName
            : (namesByClient[e.clientId] ?? ''),
        'invoiceId': e.itemId.isEmpty ? null : e.itemId,
        // The archive's kind, so the calendar can tell an advance's AP
        // reference from an invoice number and float from a collection.
        'kind': e.kind,
        'item': itemsById[e.itemId],
        'reconciledOn': merge.reconciledOn[e.localRef],
        // An account-level outcome covers several invoices; the card says
        // how many in place of the one invoice it does not have.
        'invoiceCount': e.kind == 'ACCOUNT' && e.documentIds.isNotEmpty
            ? e.documentIds.length
            : null,
      });
    }

    for (final entries in grouped.values) {
      entries.sort((a, b) => (b['history'] as CollectionHistoryModel)
          .date
          .compareTo((a['history'] as CollectionHistoryModel).date));
    }

    if (unplaceable > 0) {
      logDebug('[CollectionActivityController] $unplaceable engagement(s) '
          'had no readable date and are not on the calendar');
    }

    _byDateCache = grouped;
    _byDateSourceLength = ownEngagements.length;
    _byDateDirty = false;
  }

  /// Which reconciliations an outcome has finished, and which outcome.
  ///
  /// Returns the localRefs of every INVOICE Reconciliation row that a later
  /// engagement has finished, and for each finishing outcome the date of the
  /// latest reconciliation it finished. The outcome then shows as one entry
  /// labelled with both, and the reconciliation row is not shown again. A
  /// reconciliation with no outcome after it is in neither map: it is still
  /// open and shows on its own.
  ///
  /// Two kinds of outcome finish a reconciliation:
  ///  * an INVOICE engagement on the same invoice (Collected, Partially
  ///    Collected, ...);
  ///  * an ACCOUNT engagement of the same client (a deferral: Refused to
  ///    Pay, Customer Unavailable, ...). A deferral is recorded once per
  ///    account and lists the invoices it released in [documentIds]; it
  ///    finishes the open reconciliations of exactly those. Rows copied from
  ///    the server carry no document ids and fall back to every open
  ///    reconciliation of the client.
  ///
  /// Chronology is per client, so a deferral only reaches reconciliations
  /// recorded before it.
  @visibleForTesting
  static ReconciliationMerge reconciliationMerge(
      Iterable<CollectionEngagementRecord> engagements) {
    final finished = <String>{};
    final reconciledOn = <String, String>{};

    final byClient = <String, List<(DateTime, CollectionEngagementRecord)>>{};
    for (final r in engagements) {
      if (r.kind != 'INVOICE' && r.kind != 'ACCOUNT') continue;
      if (r.kind == 'INVOICE' && r.itemId.isEmpty) continue;
      if (r.kind == 'ACCOUNT' && r.status.isEmpty) continue;
      final at = BFormatter.parseLocal(r.engagedAt);
      if (at == null) continue;
      byClient.putIfAbsent(r.clientId, () => []).add((at, r));
    }

    for (final timeline in byClient.values) {
      timeline.sort((a, b) => a.$1.compareTo(b.$1));

      // invoice id -> the reconciliation still waiting for an outcome
      final open = <String, CollectionEngagementRecord>{};

      for (final (_, r) in timeline) {
        if (r.kind == 'INVOICE') {
          if (r.status == 'Reconciliation') {
            open[r.itemId] = r;
            continue;
          }
          final rec = open.remove(r.itemId);
          if (rec != null) {
            finished.add(rec.localRef);
            reconciledOn[r.localRef] = rec.engagedAt;
          }
          continue;
        }

        // ACCOUNT: finish the open reconciliations this deferral covered.
        final covered = r.documentIds.isEmpty
            ? open.keys.toList()
            : open.keys.where(r.documentIds.contains).toList();
        String? latest;
        DateTime? latestAt;
        for (final id in covered) {
          final rec = open.remove(id)!;
          finished.add(rec.localRef);
          final at = BFormatter.parseLocal(rec.engagedAt);
          if (at != null && (latestAt == null || at.isAfter(latestAt))) {
            latestAt = at;
            latest = rec.engagedAt;
          }
        }
        if (latest != null) reconciledOn[r.localRef] = latest;
      }
    }
    return ReconciliationMerge(finished: finished, reconciledOn: reconciledOn);
  }

  /// Re-read the archive. Cheap: one indexed query over the collector's own
  /// rows, and nothing else in the app writes to that table.
  Future<void> reloadOwnEngagements() async {
    final result = await repository.loadOwnEngagements();
    result.fold(
      onSuccess: ownEngagements.assignAll,
      onFailure: (e) =>
          logDebug('[CollectionActivityController] reloadOwnEngagements: $e'),
    );
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
    final now = DateTime.now().toIso8601String();
    final collectorLabel = repository.collectorName;
    final updated = <CollectionItemModel>[];

    CollectionItemModel mark(CollectionItemModel item) => item.copyWith(
          status: 'Reconciliation',
          history: [
            ...item.history,
            CollectionHistoryModel(
              date: now,
              collectorName: collectorLabel,
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

  /// The engagement stamp for a collection the collector dated themselves:
  /// the day from [day], the time of day from [clock]. ISO, like every other
  /// archive stamp, so it files under [day] in its month.
  @visibleForTesting
  static String collectionStamp(DateTime day, DateTime clock) => DateTime(
        day.year,
        day.month,
        day.day,
        clock.hour,
        clock.minute,
        clock.second,
        clock.millisecond,
      ).toIso8601String();

  /// Apply an Advanced Payment to an invoice, as a collection on
  /// [collectionDate].
  ///
  /// The advance is float until this moment and counts toward no month. The
  /// collector picks the date, and so the month whose Collected this Month it
  /// lands in; only the day is taken from [collectionDate], with the current
  /// time of day so two applications on one day keep their order and their
  /// archive keys apart.
  ///
  /// Returns the float left over: an advance larger than the invoice keeps
  /// the excess under Advanced Payment for the next invoice (0 when spent).
  Future<double> assignInvoiceToPayment({
    required String paymentId,
    required String invoiceNumber,
    required double amountDue,
    required String dueDate,
    required DateTime collectionDate,
  }) async {
    final paymentIdx =
        unassignedAdvancedPayments.indexWhere((e) => e['id'] == paymentId);
    if (paymentIdx == -1) return 0;

    final payment = unassignedAdvancedPayments[paymentIdx];
    final clientId = payment['clientId'] as String;
    final paidAmount = payment['amount'] as double;
    final client = masterAccountList.firstWhere((c) => c.id == clientId,
        orElse: () => ClientModel.empty());

    final appliedAt = collectionStamp(collectionDate, DateTime.now());
    final collectorLabel = payment['collectorName'] ?? repository.collectorName;

    final remainingDue = (amountDue - paidAmount).clamp(0.0, double.infinity);
    final isFullyPaid = remainingDue == 0;
    final appliedAmount = paidAmount > amountDue ? amountDue : paidAmount;

    final historyEntry = CollectionHistoryModel(
      date: appliedAt,
      collectorName: collectorLabel,
      status: 'Advanced Payment Applied',
      remarks: 'Applied from advanced payment: ${payment['remarks']}',
      totalCollected: appliedAmount,
    );

    final newItem = CollectionItemModel(
      id: invoiceNumber,
      client: client,
      bpCode: client.code,
      toBeCollected: remainingDue,
      totalCollected: appliedAmount,
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
        date: (payment['date'] ?? appliedAt).toString(),
        remarks: (payment['remarks'] ?? '').toString(),
        collectorName: collectorLabel.toString(),
      ),
      newInvoice: newItem,
      amountDue: amountDue,
      dueDate: dueDate,
      appliedAt: appliedAt,
      appliedAmount: appliedAmount,
    );

    // Add to bucket (if fully paid it shows in settled, if not it waits for next collection)
    bucketItems.add(newItem);

    // What the invoice did not need stays float, on the same advance, for the
    // next invoice; the repository keeps the same remainder in SQLite. Spent
    // in full, the advance leaves the list (removeWhere, robust against id
    // type mismatches or duplicates).
    final excess = paidAmount - appliedAmount;
    if (excess > 0.005) {
      unassignedAdvancedPayments[paymentIdx] = {...payment, 'amount': excess};
    } else {
      unassignedAdvancedPayments.removeWhere((e) => e['id'] == paymentId);
    }

    logDebug(
        '[CollectionActivityController] Assigned invoice $invoiceNumber to payment. '
        'Fully paid: $isFullyPaid. Float left: ₱$excess');
    return excess > 0.005 ? excess : 0;
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

    final now = DateTime.now().toIso8601String();
    final collectorLabel = repository.collectorName;
    final historyEntry = CollectionHistoryModel(
      date: record?.date ?? now,
      collectorName: record?.collectorName ?? collectorLabel,
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
  ///
  /// One pass, two notifications. It used to search the bucket for each id in
  /// turn and add/remove one invoice at a time, so acquiring an account of
  /// 1,095 invoices did a million comparisons and fired 2,190 list changes,
  /// each waking every Obx on the screen. That was 400ms of frozen UI.
  Future<void> claimItemsByIds(List<String> ids) async {
    if (ids.isEmpty) return;

    try {
      final wanted = ids.toSet();
      final now = DateTime.now().toIso8601String();

      final keep = <CollectionItemModel>[];
      final moved = <CollectionItemModel>[];
      for (final item in bucketItems) {
        if (wanted.contains(item.id)) {
          moved.add(item.copyWith(
            status: item.status == 'Reconciliation' ? 'Reconciliation' : '',
            assignedAt: now,
          ));
        } else {
          keep.add(item);
        }
      }
      if (moved.isEmpty) return;

      // Assign whole lists rather than mutating per item: two notifications
      // instead of two per invoice.
      activityItems.addAll(moved);
      bucketItems.assignAll(keep);
      selectedBucketIds.removeWhere(wanted.contains);

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
      // Untick returns the row to where the sort says it belongs, which is
      // the same rule in reverse. The head of the list is exactly the pick.
      selectionOrder.remove(clientId);
      lastMovedAccountId.value = '';
      selectionGeneration.value++;
      if (selectedAccountIds.isEmpty) isSelectionMode.value = false;
    } else {
      isSelectionMode.value = true;
      selectedAccountIds.add(clientId);
      // Newest tick leads, so the row that moves is the row being looked at.
      selectionOrder.insert(0, clientId);
      lastMovedAccountId.value = clientId;
      selectionGeneration.value++;
    }
  }

  void enterSelectionMode(String clientId) {
    if (selectedAccountIds.contains(clientId)) return;
    toggleAccountSelection(clientId);
  }

  void exitSelectionMode() {
    isSelectionMode.value = false;
    selectedAccountIds.clear();
    selectionOrder.clear();
    lastMovedAccountId.value = '';
  }

  /// True while an acquire is writing. Drives the overlay that covers the
  /// bucket, so a long write reads as work rather than as a frozen list.
  final RxBool isAcquiring = false.obs;

  /// What the running acquire is moving, for the overlay's copy. Set before
  /// the selection is cleared, so the figures do not fall to zero mid-write.
  final RxInt acquiringInvoices = 0.obs;
  final RxInt acquiringAccounts = 0.obs;

  /// Move every invoice of every ticked account into Field Engagement.
  ///
  /// Gathers the ids in one pass and claims them once, rather than calling
  /// [claimAccount] per account: that rescanned the whole bucket for each of
  /// them and made a separate repository round trip each time, so ticking 265
  /// accounts meant 265 scans and 265 writes.
  Future<void> claimSelectedAccounts() async {
    if (selectedAccountIds.isEmpty) return;

    final wantedClients = selectedAccountIds.toSet();
    // An account marked for reconciliation contributes only those invoices,
    // matching what claimAccount does for a single account.
    final reconByClient = <String, List<String>>{};
    final allByClient = <String, List<String>>{};
    for (final item in bucketItems) {
      if (!wantedClients.contains(item.client.id)) continue;
      allByClient.putIfAbsent(item.client.id, () => []).add(item.id);
      if (item.status == 'Reconciliation') {
        reconByClient.putIfAbsent(item.client.id, () => []).add(item.id);
      }
    }

    final ids = <String>[];
    for (final clientId in wantedClients) {
      final recon = reconByClient[clientId];
      ids.addAll(recon ?? allByClient[clientId] ?? const []);
    }
    if (ids.isEmpty) {
      exitSelectionMode();
      return;
    }

    acquiringInvoices.value = ids.length;
    acquiringAccounts.value = wantedClients.length;
    exitSelectionMode();
    isAcquiring.value = true;
    try {
      await claimItemsByIds(ids);
      logDebug('[CollectionActivityController] Claimed ${ids.length} invoices '
          'across ${wantedClients.length} accounts');
    } finally {
      // In a finally so a failed write cannot leave the bucket covered.
      isAcquiring.value = false;
    }
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
      final now = DateTime.now().toIso8601String();
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
        collectorName: repository.collectorName,
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
      final now = DateTime.now().toIso8601String();

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
          collectorName: repository.collectorName,
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
    final now = DateTime.now().toIso8601String();
    final collectorLabel = repository.collectorName;

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
      collectorName: collectorLabel,
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

      // Before the first read, so an upgrading collector does not open a blank
      // calendar. It also drops the copies it made last time and takes them
      // again from the cache that was just refreshed, which is how collection
      // data deleted on the server stops being reported here.
      await repository.backfillOwnEngagements();
      await reloadOwnEngagements();

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
        // Carried so a card can name the account even when it is not in the
        // downloaded account list, instead of printing "N/A".
        'clientName': r.clientName,
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
