import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/local/dao/air_sea/air_sea_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/pick_up/pick_up_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/pull_out/pull_out_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/standard_delivery/standard_delivery_dao.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_ids.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_aggregator.dart';
import 'package:sqflite/sqflite.dart';

/// Where the Home dashboard gets its numbers.
///
/// The dashboard counts by year and month, so it needs the full history of
/// every module. Reading that from the network on each Home visit was the
/// single biggest source of GET traffic in the app. Instead it now reads the
/// local SQLite cache, which every repository already keeps current, and only
/// asks the server for a full snapshot when that cache is older than
/// [staleAfter] or the user pulls to refresh.
///
/// [loadFromCache] mirrors the module split the tabs use: Standard Delivery
/// and Hotline Direct share `a_tblRequest` split by `FormCategoryID`; Pull Out
/// and Stock Receive share `a_tblRequestPullOutReturnPickUp`; Air / Sea and
/// Air / Sea HD share `a_tblRequestAirSea` split by [AirSeaCategoryScope].
class DashboardDataSource {
  DashboardDataSource({
    Future<Database> Function()? database,
    DateTime? Function()? readLastSync,
    void Function(DateTime)? writeLastSync,
    DateTime Function()? now,
    this.staleAfter = const Duration(minutes: 15),
  })  : _database = database ?? (() => DatabaseHelper.instance.database),
        _readLastSync = readLastSync ?? _readLastSyncFromStorage,
        _writeLastSync = writeLastSync ?? _writeLastSyncToStorage,
        _now = now ?? DateTime.now;

  /// GetStorage key holding the ISO-8601 time of the last full sync.
  static const String lastFullSyncKey = 'dashboard_last_full_sync';

  final Future<Database> Function() _database;
  final DateTime? Function() _readLastSync;
  final void Function(DateTime) _writeLastSync;
  final DateTime Function() _now;

  /// How old the cache may be before a Home visit triggers a full sync.
  final Duration staleAfter;

  static DateTime? _readLastSyncFromStorage() {
    final raw = GetStorage().read<String>(lastFullSyncKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static void _writeLastSyncToStorage(DateTime value) {
    GetStorage().write(lastFullSyncKey, value.toIso8601String());
  }

  /// When the cache was last replaced by a full server snapshot, or null.
  DateTime? get lastFullSyncAt => _readLastSync();

  /// True when no full sync has happened within [staleAfter].
  bool get isStale {
    final last = lastFullSyncAt;
    return last == null || _now().difference(last) > staleAfter;
  }

  /// Records that a full sync just completed.
  void markSynced() => _writeLastSync(_now());

  /// Runs [fullSync] only when the cache is stale (or [force]).
  ///
  /// Returns true when a sync ran. [fullSync] is the caller's — it decides
  /// what "load everything" means for it — so this class stays free of
  /// controller wiring and stays testable.
  Future<bool> syncIfStale(
    Future<void> Function() fullSync, {
    bool force = false,
  }) async {
    if (!force && !isStale) {
      logDebug('DashboardDataSource: cache fresh, skipping full sync');
      return false;
    }
    await fullSync();
    markSynced();
    return true;
  }

  /// Every cached request, normalized for counting.
  Future<List<DashboardEntry>> loadFromCache() async {
    final db = await _database();
    final result = <DashboardEntry>[];

    for (final request in await RequestDao(db).getRequests()) {
      final module = request.formCategoryID == FormCategoryIds.hotlineDirect
          ? FormCategoryType.hotlineDirect
          : FormCategoryType.standardDelivery;
      result.add(DashboardEntry(
        module: module,
        status: request.status,
        date: DashboardAggregator.tryParseDate(request.deliveryDate) ??
            DashboardAggregator.tryParseDate(request.createdAt),
      ));
    }

    for (final request in await PullOutDao(db).getPullOutRequests()) {
      final module = request.formCategoryId == FormCategoryIds.stockReceive
          ? FormCategoryType.stockReceive
          : FormCategoryType.pullOutReturn;
      result.add(DashboardEntry(
        module: module,
        status: request.requestStatus,
        date: DashboardAggregator.tryParseDate(request.pullOutDate) ??
            DashboardAggregator.tryParseDate(request.createdAt),
      ));
    }

    for (final request in await PickUpDao(db).getPickUps()) {
      result.add(DashboardEntry(
        module: FormCategoryType.pickUp,
        status: request.status,
        date: DashboardAggregator.tryParseDate(request.datePickUp) ??
            DashboardAggregator.tryParseDate(request.createdAt),
      ));
    }

    for (final request in await AirSeaDao(db).getAirSeaRequests()) {
      final module =
          AirSeaCategoryScope.hotlineDirect.matches(request.formCategoryID)
              ? FormCategoryType.airSeaHd
              : FormCategoryType.airSea;
      result.add(DashboardEntry(
        module: module,
        status: request.status,
        date: DashboardAggregator.tryParseDate(request.datePickUp) ??
            DashboardAggregator.tryParseDate(request.createdAt),
      ));
    }

    return result;
  }

  /// Exposed so tests can pin the clock.
  @visibleForTesting
  DateTime get clock => _now();
}
