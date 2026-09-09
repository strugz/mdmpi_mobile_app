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
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_bucket_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_date_filter.dart';

/// Controller for the Home activity dashboard, aggregating all six request
/// modules (Standard Delivery, Pull Out, Pick Up, Air/Sea, Hotline Direct,
/// Stock Receive) into filterable counts.
///
/// Architecture:
/// - Sources data from the existing module controllers (which own caching and
///   local-DB-first loading); a controller that cannot be resolved (e.g.
///   desktop without Firebase-backed repositories) is treated as an empty
///   module instead of crashing.
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
    _standardDelivery = _tryFind<StandardDeliveryController>();
    _hotlineDirect = _tryFind<HotlineDirectController>();
    _pullOut = _tryFind<PullOutController>();
    _pickUp = _tryFind<PickUpController>();
    _airSea = _tryFind<AirSeaController>();
    _airSeaHd = _tryFind<AirSeaHdController>();
    _stockReceive = _tryFind<StockReceiveController>();

    _watch(_standardDelivery?.allPendingRequests);
    _watch(_hotlineDirect?.allPendingRequests);
    _watch(_pullOut?.pullOuts);
    _watch(_pickUp?.pickUps);
    _watch(_airSea?.airSeaRequests);
    _watch(_airSeaHd?.airSeaRequests);
    _watch(_stockReceive?.stockReceives);

    _rebuildEntries();
  }

  @override
  void onClose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    _workers.clear();
    super.onClose();
  }

  T? _tryFind<T>() {
    try {
      return Get.find<T>();
    } catch (e) {
      logDebug('DashboardController: $T unavailable, module shows empty: $e');
      return null;
    }
  }

  void _watch<T>(RxList<T>? source) {
    if (source == null) return;
    _workers.add(ever<List<T>>(source, (_) => _rebuildEntries()));
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

  /// Re-fetch every module's requests (e.g. pull-to-refresh).
  Future<void> refreshDashboard() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      await Future.wait([
        _guarded('standardDelivery', _standardDelivery?.loadRequests),
        _guarded('hotlineDirect', _hotlineDirect?.loadRequests),
        _guarded('pullOut', _pullOut?.loadPullOuts),
        _guarded('pickUp', _pickUp?.loadPickUps),
        _guarded('airSea', _airSea?.loadAirSeaRequests),
        _guarded('airSeaHd', _airSeaHd?.loadAirSeaRequests),
        _guarded('stockReceive', _stockReceive?.loadStockReceives),
      ]);
    } finally {
      isRefreshing.value = false;
      _rebuildEntries();
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

  /// Rebuild the normalized entry list from all resolved source controllers.
  void _rebuildEntries() {
    final result = <DashboardEntry>[];

    for (final request
        in _standardDelivery?.allPendingRequests ?? const <StandardDeliveryModel>[]) {
      result.add(DashboardEntry(
        module: FormCategoryType.standardDelivery,
        status: request.status,
        date: DashboardAggregator.tryParseDate(request.deliveryDate) ??
            DashboardAggregator.tryParseDate(request.createdAt),
      ));
    }
    for (final request
        in _hotlineDirect?.allPendingRequests ?? const <StandardDeliveryModel>[]) {
      result.add(DashboardEntry(
        module: FormCategoryType.hotlineDirect,
        status: request.status,
        date: DashboardAggregator.tryParseDate(request.deliveryDate) ??
            DashboardAggregator.tryParseDate(request.createdAt),
      ));
    }
    for (final request in _pullOut?.pullOuts ?? const <PullOutModel>[]) {
      result.add(DashboardEntry(
        module: FormCategoryType.pullOutReturn,
        status: request.requestStatus,
        date: DashboardAggregator.tryParseDate(request.pullOutDate) ??
            DashboardAggregator.tryParseDate(request.createdAt),
      ));
    }
    for (final request in _pickUp?.pickUps ?? const <PickUpModel>[]) {
      result.add(DashboardEntry(
        module: FormCategoryType.pickUp,
        status: request.status,
        date: DashboardAggregator.tryParseDate(request.datePickUp) ??
            DashboardAggregator.tryParseDate(request.createdAt),
      ));
    }
    for (final request in _airSea?.airSeaRequests ?? const <AirSeaModel>[]) {
      result.add(DashboardEntry(
        module: FormCategoryType.airSea,
        status: request.status,
        date: DashboardAggregator.tryParseDate(request.datePickUp) ??
            DashboardAggregator.tryParseDate(request.createdAt),
      ));
    }
    for (final request in _airSeaHd?.airSeaRequests ?? const <AirSeaModel>[]) {
      result.add(DashboardEntry(
        module: FormCategoryType.airSeaHd,
        status: request.status,
        date: DashboardAggregator.tryParseDate(request.datePickUp) ??
            DashboardAggregator.tryParseDate(request.createdAt),
      ));
    }
    for (final request in _stockReceive?.stockReceives ?? const <PullOutModel>[]) {
      result.add(DashboardEntry(
        module: FormCategoryType.stockReceive,
        status: request.requestStatus,
        date: DashboardAggregator.tryParseDate(request.pullOutDate) ??
            DashboardAggregator.tryParseDate(request.createdAt),
      ));
    }

    entries.assignAll(result);
  }
}
