import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_engagement_dao.dart';
import 'package:mdmpi_mobile_app/data/services/report_export_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/team_engagement.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_reports_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/reports/collection_reports_screen.dart';

/// Settings → Reports: loading by month, the Head's team rows, and the
/// CSV going out through Save and Share.

CollectionEngagementRecord _e(String at, double amount) =>
    CollectionEngagementRecord(
      localRef: 'INVOICE|$at',
      collectorCode: 'JCA',
      kind: 'INVOICE',
      itemId: 'I-$at',
      clientId: 'NLN-115',
      clientName: 'Accusure',
      engagedAt: at,
      engagedOn: at.substring(0, 10),
      status: 'Collected',
      amount: amount,
      createdAt: at,
    );

class _Harness {
  final saved = <String, String>{};
  final shared = <String>[];
  final months = <String>[];
  Result<TeamActivityFeed> team = Result.success(const TeamActivityFeed(
      from: '',
      to: '',
      engagements: [
        TeamEngagement(
            kind: 'Engagement',
            id: 1,
            collectorCode: 'MAR',
            collectorName: 'Mar',
            clientCode: 'C1',
            status: 'Collected',
            amount: 300,
            date: '2026-09-02'),
      ]));
  Completer<void>? holdAugust;

  CollectionReportsController controller({bool head = false}) =>
      CollectionReportsController(
        loadOwn: (ym) async {
          months.add(ym);
          if (ym == '2026-08') await holdAugust?.future;
          return Result.success(ym == '2026-09'
              ? [_e('2026-09-03T10:00:00', 1000)]
              : <CollectionEngagementRecord>[]);
        },
        loadTeam: ({required from, required to, collector}) async => team,
        cases: (_) => const [],
        collectorCode: () => 'JCA',
        collectorName: () => 'Jay',
        isHead: () => head,
        now: () => DateTime(2026, 9, 28),
        exporter: ReportExportService(
          save: ({required fileName, required Uint8List bytes}) async {
            saved[fileName] = utf8.decode(bytes);
            return '/storage/$fileName';
          },
          share: ({required fileName, required Uint8List bytes}) async {
            shared.add(fileName);
            return true;
          },
        ),
      );
}

Future<void> _pump(WidgetTester tester, CollectionReportsController c,
    Widget home) async {
  Get.put(c);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GetMaterialApp(
    theme: BCollectionTheme.light,
    getPages: [
      GetPage(
          name: BRoutes.collectionReportActivity,
          page: () => const ActivityReportScreen()),
      GetPage(
          name: BRoutes.collectionReportCollectors,
          page: () => const CollectorsSummaryScreen()),
      GetPage(
          name: BRoutes.collectionReportRecon,
          page: () => const ReconDetailReportScreen()),
    ],
    home: home,
  ));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  group('controller', () {
    test('a slower load for an older month never overwrites a newer one',
        () async {
      final h = _Harness()..holdAugust = Completer<void>();
      final c = h.controller();
      c.stepMonth(-1);
      final august = c.loadActivity();
      c.stepMonth(1);
      await c.loadActivity();
      h.holdAugust!.complete();
      await august;
      expect(c.activityTable.value!.title, contains('2026-09'));
      expect(c.activityTable.value!.rows, hasLength(1));
    });

    test('the reconciliation detail rebuilds on a filter or case change',
        () {
      final changed = 0.obs;
      var builds = 0;
      final c = CollectionReportsController(
        cases: (_) {
          builds++;
          return const [];
        },
        casesChanged: changed,
        isHead: () => false,
        now: () => DateTime(2026, 9, 28),
      )..onInit();
      expect(builds, 1);
      c.reconTable.value;
      c.reconTable.value;
      expect(builds, 1, reason: 'reading does not rebuild');
      c.reconFilter.value = ReconDashboardFilter.open;
      changed.value++;
      return Future<void>.delayed(Duration.zero, () {
        expect(builds, 3);
        c.onClose();
      });
    });

    test('never steps past the current month', () {
      final c = _Harness().controller();
      c.stepMonth(1);
      expect(c.yearMonth, '2026-09');
      expect(c.canStepForward, isFalse);
      c.stepMonth(-9);
      expect(c.yearMonth, '2025-12');
    });

    test('a collector gets only their own row; no team call', () async {
      final h = _Harness();
      var teamCalls = 0;
      final c = CollectionReportsController(
        loadOwn: (_) async => Result.success([_e('2026-09-03T10:00:00', 1000)]),
        loadTeam: ({required from, required to, collector}) async {
          teamCalls++;
          return h.team;
        },
        cases: (_) => const [],
        collectorCode: () => 'JCA',
        isHead: () => false,
        now: () => DateTime(2026, 9, 28),
      );
      await c.loadCollectors();
      expect(teamCalls, 0);
      expect(c.collectorsTable.value!.rows.single[0].csv, 'JCA');
    });

    test('the Head gets the team; a feed failure keeps their own row',
        () async {
      final h = _Harness();
      final c = h.controller(head: true);
      await c.loadCollectors();
      expect(c.collectorsTable.value!.rows.map((r) => r[0].csv),
          ['JCA', 'MAR']);

      h.team = Result.failure('Could not reach the server.');
      await c.loadCollectors();
      expect(c.teamError.value, 'Could not reach the server.');
      expect(c.collectorsTable.value!.rows.single[0].csv, 'JCA');
    });
  });

  group('screens', () {
    testWidgets('the hub opens each report', (tester) async {
      await _pump(tester, _Harness().controller(),
          const CollectionReportsScreen());
      await tester.tap(find.byKey(const ValueKey('reports-activity')));
      await tester.pumpAndSettle();
      expect(find.text('Activity report'), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);
    });

    testWidgets('the activity report saves and shares its CSV',
        (tester) async {
      final h = _Harness();
      await _pump(tester, h.controller(), const ActivityReportScreen());
      expect(find.byKey(const ValueKey('report-row-0')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('report-share')));
      await tester.pumpAndSettle();
      expect(h.shared, ['mdmpi_activity_JCA_2026-09.csv']);

      await tester.tap(find.byKey(const ValueKey('report-save')));
      await tester.pumpAndSettle();
      final csv = h.saved['mdmpi_activity_JCA_2026-09.csv']!;
      expect(csv, contains('Accusure'));
      expect(csv, contains('1000.00'));
      expect(find.text('Report saved'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 4));
    });

    testWidgets('an empty month says so and exports nothing', (tester) async {
      final h = _Harness();
      await _pump(tester, h.controller(), const ActivityReportScreen());
      await tester.tap(find.byKey(const ValueKey('report-month-back')));
      await tester.pumpAndSettle();
      expect(find.text('August 2026'), findsOneWidget);
      expect(find.byKey(const ValueKey('report-empty')), findsOneWidget);
      for (final key in ['report-save', 'report-share']) {
        expect(tester.widget<ButtonStyleButton>(find.byKey(ValueKey(key))).enabled,
            isFalse);
      }
    });

    testWidgets('the Head sees a note when team figures are unavailable',
        (tester) async {
      final h = _Harness()..team = Result.failure('offline');
      await _pump(tester, h.controller(head: true),
          const CollectorsSummaryScreen());
      expect(find.byKey(const ValueKey('report-note')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-row-0')), findsOneWidget);
    });
  });
}
