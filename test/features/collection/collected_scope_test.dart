import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_actual_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_engagement_dao.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reports/collectors_summary_report.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_settings_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/total_collected_controller.dart';

/// Settings → Collected this Month: me only (the default) or all collectors.
/// What these protect: "me only" never asks the server and stays the
/// phone's own total; "all" adds the other collectors' collected amounts
/// (Settled is not part of it); a failed load leaves the own figure and says why; and a switch
/// back to "me only" drops the teammates at once.

class _Activity extends CollectionActivityController {
  // Skips the real start-up (database, downloads); nothing here needs it.
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _Repo extends CollectionRepository {
  @override
  Future<List<CollectionActualRecord>> getActualCollections(
          String yearMonth) async =>
      const [];

  @override
  Future<double?> getTarget(String yearMonth) async => null;
}

final _now = DateTime.now();

CollectionEngagementRecord _own(double amount) {
  final date = DateFormat('yyyy-MM-dd HH:mm')
      .format(DateTime(_now.year, _now.month, 1, 10));
  return CollectionEngagementRecord(
    localRef: CollectionEngagementRecord.buildLocalRef(
        kind: 'INVOICE', subjectId: 'INV-1', engagedAt: date),
    collectorCode: 'JCA',
    collectorName: 'Jay',
    kind: 'INVOICE',
    itemId: 'INV-1',
    clientId: 'C-1',
    clientName: 'Almighty Medical Supply',
    engagedAt: date,
    engagedOn: date.split(' ').first,
    status: 'Collected',
    amount: amount,
    createdAt: date,
  );
}

const _teammates = [
  CollectorSummaryRow(
      code: 'RMM',
      name: 'Romewel Magdalita',
      collected: 357632.39,
      settledInvoices: 5,
      source: CollectorSummaryRow.sourceServer),
  CollectorSummaryRow(
      code: 'ABC',
      name: 'Ana',
      collected: 1000,
      settledInvoices: 2,
      source: CollectorSummaryRow.sourceServer),
];

void main() {
  tearDown(Get.reset);

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  ({
    CollectionSettingsController settings,
    TotalCollectedController totals,
    List<String> asked,
  }) seed({
    Object? saved,
    Future<Result<List<CollectorSummaryRow>>> Function()? load,
  }) {
    final activity = _Activity()..ownEngagements.assignAll([_own(500)]);
    Get.put<CollectionActivityController>(activity);
    Get.put<CollectionRepository>(_Repo());
    final store = <String, dynamic>{
      if (saved != null) CollectionSettingsController.collectedScopeKey: saved,
    };
    final settings = Get.put(CollectionSettingsController(
      read: (k) => store[k],
      write: (k, v) async => store[k] = v,
    ));
    final asked = <String>[];
    final totals = Get.put(TotalCollectedController(
      loadOthers: (ym, _) async {
        asked.add(ym);
        return load != null ? load() : Result.success(_teammates);
      },
    ));
    return (settings: settings, totals: totals, asked: asked);
  }

  test('default is me only: own total, no server call', () async {
    final s = seed();
    await settle();

    expect(s.settings.collectedAllCollectors.value, isFalse);
    expect(s.totals.allCollectors, isFalse);
    expect(s.totals.scopedTotal, 500);
    expect(s.asked, isEmpty);
  });

  test('all collectors adds the teammates\' collected amounts', () async {
    final s = seed(saved: 'all');
    await settle();

    expect(s.totals.allCollectors, isTrue);
    expect(s.asked, [DateFormat('yyyy-MM').format(_now)]);
    expect(s.totals.scopedTotal, closeTo(500 + 357632.39 + 1000, 0.001));
  });

  test('switching in Settings applies at once and is saved', () async {
    final s = seed();
    await settle();

    await s.settings.setCollectedAllCollectors(true);
    await settle();
    expect(s.totals.scopedTotal, closeTo(358132.39 + 1000, 0.001));
    expect(
        CollectionSettingsController.readCollectedAllCollectors(
            (k) => k == CollectionSettingsController.collectedScopeKey
                ? 'all'
                : null),
        isTrue);

    await s.settings.setCollectedAllCollectors(false);
    await settle();
    expect(s.totals.scopedTotal, 500);
    expect(s.totals.otherCollectors, isEmpty);
  });

  test('a failed load keeps the own figure and says why', () async {
    final s = seed(
        saved: 'all',
        load: () async => Result.failure('Could not reach the server.'));
    await settle();

    expect(s.totals.scopedTotal, 500);
    expect(s.totals.othersError.value, 'Could not reach the server.');
    expect(s.totals.othersLoading.value, isFalse);
  });

  test('an unreadable or unknown saved value is me only', () {
    expect(
        CollectionSettingsController.readCollectedAllCollectors(
            (_) => throw Exception('no storage')),
        isFalse);
    expect(
        CollectionSettingsController.readCollectedAllCollectors((_) => 'team'),
        isFalse);
  });
}
