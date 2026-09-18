import 'dart:async';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_hd_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/hotline_direct_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/stock_receive_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_aggregator.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_data_source.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_bucket_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_date_filter.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/request_date_scope.dart';

/// Controller for the Home activity dashboard, aggregating all six request
/// modules (Standard Delivery, Pull Out, Pick Up, Air/Sea, Hotline Direct,
/// Stock Receive) into filterable counts.
///
/// Architecture:
/// - Reads its numbers from the local SQLite cache via [DashboardDataSource],
///   so opening Home costs no network calls while the cache is fresh. A full
///   server snapshot is fetched only when the cache is older than
///   [DashboardDataSource.staleAfter] or on pull-to-refresh.
/// - Watches whichever module controllers are already alive and re-reads the
///   cache when their lists change, so a status update on a tab shows on Home
///   without a fetch. It never instantiates a controller just to watch it.
/// - Normalizes every request into [DashboardEntry]; all counting/filtering
///   is delegated to the pure [DashboardAggregator].
class DashboardController extends GetxController {
  static DashboardController get instance => Get.find();

  // ========================================================================
  // SOURCE CONTROLLERS (nullable — missing modules render as empty)
  // ========================================================================

  StandardDeliveryController? _standardDelivery;
  HotlineDirectController? _hotlineDirect;
  PullOutController? _pullOut;
  PickUpController? _pickUp;
  AirSeaController? _airSea;
  AirSeaHdController? _airSeaHd;
  StockReceiveController? _stockReceive;

  final List<Worker> _workers = [];
  final Set<Type> _watched = <Type>{};
  final DashboardDataSource _source = DashboardDataSource();

  // ========================================================================
  // FILTER STATE
  // ========================================================================

  /// Selected module, or null for the "All Requests" view.
  final Rxn<FormCategoryType> selectedModule = Rxn<FormCategoryType>();

  /// Selected year, or null for all time.
  final Rxn<int> selectedYear = Rxn<int>();

  /// Selected month (1-12) within [selectedYear], or null for the whole year.
  final Rxn<int> selectedMonth = Rxn<int>();

  /// All requests across the six modules, normalized for counting.
  final RxList<DashboardEntry> entries = <DashboardEntry>[].obs;

  final RxBool isRefreshing = false.obs;

  /// True until the first cache read completes, so Home can show a skeleton
  /// instead of a misleading zero.
  final RxBool isLoading = true.obs;

  // ========================================================================
  // COMPUTED PROPERTIES
  // ========================================================================

  DashboardDateFilter get dateFilter => DashboardDateFilter(
        year: selectedYear.value,
        month: selectedMonth.value,
      );

  /// Entries matching the active date filter across all modules.
  List<DashboardEntry> get dateFilteredEntries =>
      DashboardAggregator.applyFilter(entries, dateFilter);

  /// Entries matching the active date filter and selected module.
  List<DashboardEntry> get filteredEntries => DashboardAggregator.applyFilter(
        entries,
        dateFilter,
        module: selectedModule.value,
      );

  /// Grand total for the current filter selection.
  int get totalCount => filteredEntries.length;

  /// Per-module counts under the active date filter (All Requests view).
  Map<FormCategoryType, int> get moduleCounts =>
      DashboardAggregator.countByModule(dateFilteredEntries);

  /// Status buckets for the selected module (empty in All Requests view).
  List<DashboardBucket> get buckets => selectedModule.value == null
      ? const []
      : DashboardBucketConfig.bucketsFor(selectedModule.value!);

  /// Per-bucket counts for the selected module under the active date filter.
  Map<String, int> get bucketCounts =>
      DashboardAggregator.countByBucket(filteredEntries, buckets);

  /// Years offered by the year dropdown: years present in the data plus the
  /// current year, newest first.
  List<int> get yearOptions {
    final years = DashboardAggregator.availableYears(entries);
    final current = DateTime.now().year;
    if (!years.contains(current)) {
      years
        ..add(current)
        ..sort((a, b) => b.compareTo(a));
    }
    return years;
  }

  // ========================================================================
  // LIFECYCLE
  // ========================================================================

  @override
  void onInit() {
    super.onInit();
    _bindLiveSources();
    unawaited(_start());
  }

  Future<void> _start() async {
    // Cache first: Home renders instantly and costs no network while fresh.
    try {
      await _reloadFromCache();
    } finally {
      isLoading.value = false;
    }
    // Then a full snapshot, but only if the cache has gone stale.
    final synced = await _source.syncIfStale(_loadFullHistory);
    if (synced) {
      _bindLiveSources();
      await _reloadFromCache();
    }
  }

  /// Watch every module controller that is already alive, once each.
  ///
  /// Uses `Get.isRegistered`, never `Get.find`, so the dashboard does not
  /// instantiate seven controllers (and their fetches) just to observe them.
  /// Called again after a full sync, which does instantiate them.
  void _bindLiveSources() {
    _standardDelivery ??= _tryFind<StandardDeliveryController>();
    _hotlineDirect ??= _tryFind<HotlineDirectController>();
    _pullOut ??= _tryFind<PullOutController>();
    _pickUp ??= _tryFind<PickUpController>();
    _airSea ??= _tryFind<AirSeaController>();
    _airSeaHd ??= _tryFind<AirSeaHdController>();
    _stockReceive ??= _tryFind<StockReceiveController>();

    _watch(StandardDeliveryController, _standardDelivery?.allPendingRequests);
    _watch(HotlineDirectController, _hotlineDirect?.allPendingRequests);
    _watch(PullOutController, _pullOut?.pullOuts);
    _watch(PickUpController, _pickUp?.pickUps);
    _watch(AirSeaController, _airSea?.airSeaRequests);
    _watch(AirSeaHdController, _airSeaHd?.airSeaRequests);
    _watch(StockReceiveController, _stockReceive?.stockReceives);
  }

  @override
  void onClose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    _workers.clear();
    super.onClose();
  }

  /// The controller if it already exists; never creates one.
  T? _tryFind<T>() {
    if (!Get.isRegistered<T>()) return null;
    try {
      return Get.find<T>();
    } catch (e) {
      logDebug('DashboardController: $T unavailable: $e');
      return null;
    }
  }

  /// Resolve-or-create, used only by the full sync which needs every module.
  T? _findOrCreate<T>() {
    try {
      return Get.find<T>();
    } catch (e) {
      logDebug('DashboardController: $T unavailable, module shows empty: $e');
      return null;
    }
  }

  void _watch<T>(Type owner, RxList<T>? source) {
    if (source == null || _watched.contains(owner)) return;
    _watched.add(owner);
    // Every write path updates SQLite before it patches its Rx list, so
    // re-reading the cache here sees the change.
    _workers.add(ever<List<T>>(source, (_) => unawaited(_reloadFromCache())));
  }

  // ========================================================================
  // FILTER ACTIONS
  // ========================================================================

  /// Select a module, or null for the All Requests view.
  void selectModule(FormCategoryType? module) {
    selectedModule.value = module;
  }

  /// Select a year (null = all time). Changing year resets the month.
  void selectYear(int? year) {
    selectedYear.value = year;
    selectedMonth.value = null;
  }

  /// Select a month within the selected year (null = whole year).
  void selectMonth(int? month) {
    selectedMonth.value = month;
  }

  // ========================================================================
  // DATA
  // ========================================================================

  /// Pull-to-refresh: force a full snapshot, then re-read the cache.
  Future<void> refreshDashboard() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      await _source.syncIfStale(_loadFullHistory, force: true);
      _bindLiveSources();
    } finally {
      isRefreshing.value = false;
      await _reloadFromCache();
    }
  }

  /// Load every module's full history through its controller, so each
  /// repository refreshes the SQLite cache the dashboard reads.
  ///
  /// This is the one place the dashboard instantiates controllers. It counts
  /// by year and month, so it always needs the full history, never a tab's
  /// scoped (e.g. Today-only) load. Each tab's own client-side filter still
  /// narrows what it displays.
  Future<void> _loadFullHistory() async {
    _standardDelivery ??= _findOrCreate<StandardDeliveryController>();
    _hotlineDirect ??= _findOrCreate<HotlineDirectController>();
    _pullOut ??= _findOrCreate<PullOutController>();
    _pickUp ??= _findOrCreate<PickUpController>();
    _airSea ??= _findOrCreate<AirSeaController>();
    _airSeaHd ??= _findOrCreate<AirSeaHdController>();
    _stockReceive ??= _findOrCreate<StockReceiveController>();

    {
      const scope = RequestDateScope.all;
      await Future.wait([
        _guarded('standardDelivery',
            () => _standardDelivery?.loadForScope(scope) ?? Future.value()),
        _guarded('hotlineDirect',
            () => _hotlineDirect?.loadForScope(scope) ?? Future.value()),
        _guarded(
            'pullOut', () => _pullOut?.loadForScope(scope) ?? Future.value()),
        _guarded(
            'pickUp', () => _pickUp?.loadForScope(scope) ?? Future.value()),
        _guarded(
            'airSea', () => _airSea?.loadForScope(scope) ?? Future.value()),
        _guarded('airSeaHd',
            () => _airSeaHd?.loadForScope(scope) ?? Future.value()),
        _guarded('stockReceive',
            () => _stockReceive?.loadForScope(scope) ?? Future.value()),
      ]);
    }
  }

  Future<void> _guarded(String name, Future<void> Function()? load) async {
    if (load == null) return;
    try {
      await load();
    } catch (e) {
      logDebug('DashboardController: refresh of $name failed: $e');
    }
  }

  /// Re-read every cached request and rebuild the normalized entry list.
  Future<void> _reloadFromCache() async {
    try {
      entries.assignAll(await _source.loadFromCache());
    } catch (e) {
      logDebug('DashboardController: cache read failed: $e');
    }
  }
}
