import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_actual_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_target_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_workspace_parser.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/total_collected_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/total_collected_month/monthly_summary_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Actual Collection and its target by area (update checklist items 3 and 5):
/// a collector with a default area sees that area's figure and target, and can
/// switch to all areas and back. Without a default area: the team, as before.

final _ym = DateFormat('yyyy-MM');
final _head = TotalCollectedController.thisMonth();

CollectionActualRecord _entry(int id, int day, double amount, String area) =>
    CollectionActualRecord(
      actualId: id,
      collectionDate: DateFormat('yyyy-MM-dd')
          .format(DateTime(_head.year, _head.month, day)),
      amount: amount,
      referenceNo: 'OR-$id',
      area: area,
    );

/// The month's entries and targets as the last download left them.
class _Repo extends CollectionRepository {
  @override
  Future<List<CollectionActualRecord>> getActualCollections(
          String yearMonth) async =>
      yearMonth == _ym.format(_head)
          ? [
              _entry(1, 3, 15000, 'NCR'),
              _entry(2, 5, 5000, 'NCR'),
              _entry(3, 7, 9000, 'VIS'),
              _entry(4, 8, 1000, ''),
            ]
          : const [];

  @override
  Future<double?> getTarget(String yearMonth) async => 100000;

  @override
  Future<double?> getAreaTarget(String yearMonth, String area) async =>
      {'NCR': 40000.0, 'VIS': 30000.0}[area];
}

class _Activity extends CollectionActivityController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

TotalCollectedController _totals(String defaultArea) {
  Get.put<CollectionActivityController>(_Activity());
  Get.put<CollectionRepository>(_Repo());
  return Get.put(TotalCollectedController(defaultArea: () => defaultArea));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  group('the download', () {
    test('reads each entry\'s area and the targets area by area', () {
      final ws = CollectionWorkspaceParser.parse({
        'Targets': [
          {'YearMonth': '2026-10', 'TargetAmount': 70000},
        ],
        'AreaTargets': [
          {'YearMonth': '2026-10', 'Area': 'ncr', 'TargetAmount': 40000},
          {'YearMonth': '2026-10', 'Area': '', 'TargetAmount': 30000},
        ],
        'ActualCollections': [
          {
            'ActualId': 7,
            'CollectionDate': '2026-10-03',
            'Amount': 1500,
            'ReferenceNo': '',
            'Area': 'vis',
          },
        ],
      });

      expect(ws.targets['2026-10'], 70000,
          reason: 'the whole team\'s, as before');
      expect(ws.hasAreaTargets, isTrue);
      expect(ws.areaTargets.map((t) => (t.area, t.amount)),
          [('NCR', 40000.0), ('', 30000.0)]);
      expect(ws.actualCollections.single.area, 'VIS');
      expect(ws.actualCollections.single.referenceNo, '');
    });

    test('an older server sends no area targets: they are left alone', () {
      final ws = CollectionWorkspaceParser.parse({'Targets': []});
      expect(ws.hasAreaTargets, isFalse);
      expect(ws.areaTargets, isEmpty);
    });
  });

  group('the phone\'s copy', () {
    late Database db;

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      db = await openDatabase(inMemoryDatabasePath,
          version: 1, onCreate: (db, _) async => ensureCollectionTables(db));
    });

    tearDown(() async => db.close());

    test('keeps the area targets, replaced on each download', () async {
      final dao = CollectionTargetDao(db);
      await dao.replaceAreas(const [
        CollectionAreaTarget(yearMonth: '2026-10', area: 'NCR', amount: 40000),
        CollectionAreaTarget(yearMonth: '2026-10', area: 'VIS', amount: 30000),
      ]);
      expect(await dao.getArea('2026-10', 'ncr'), 40000);
      expect(await dao.getArea('2026-10', 'MIN'), isNull);

      await dao.replaceAreas(const [
        CollectionAreaTarget(yearMonth: '2026-10', area: 'VIS', amount: 35000),
      ]);
      expect(await dao.getArea('2026-10', 'NCR'), isNull);
      expect(await dao.getArea('2026-10', 'VIS'), 35000);
    });

    test('keeps each entry\'s area', () async {
      final dao = CollectionActualDao(db);
      await dao.replaceAll([_entry(1, 3, 15000, 'NCR')]);
      expect((await dao.getAll()).single.area, 'NCR');
    });
  });

  group('the figure', () {
    test('with a default area: that area\'s actual and target', () async {
      final t = _totals('NCR');
      await _settle();

      expect(t.actualArea.value, 'NCR');
      expect(t.actualScopeLabel, 'NCR');
      expect(t.actualCollectionTotal, 20000);
      expect(t.postedEntries.map((e) => e.referenceNo), ['OR-2', 'OR-1']);
      expect(t.targetAmount.value, 40000);
    });

    test('switched to all areas: every entry against the whole target',
        () async {
      final t = _totals('NCR');
      await _settle();

      t.setActualArea('');
      await _settle();
      expect(t.actualScopeLabel, 'Team');
      expect(t.actualCollectionTotal, 30000);
      expect(t.targetAmount.value, 100000);

      t.setActualArea('NCR');
      await _settle();
      expect(t.actualCollectionTotal, 20000);
      expect(t.targetAmount.value, 40000);
    });

    test('an area with no target says so', () async {
      final t = _totals('MIN');
      await _settle();
      expect(t.actualCollectionTotal, 0);
      expect(t.targetAmount.value, 0);
    });

    test('without a default area: the team, as before', () async {
      final t = _totals('');
      await _settle();
      expect(t.canPickArea, isFalse);
      expect(t.actualCollectionTotal, 30000);
      expect(t.targetAmount.value, 100000);
    });
  });

  group('the Actual Collection page', () {
    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(GetMaterialApp(
        theme: BAppTheme.lightTheme,
        home: const MonthlySummaryScreen(type: 'Actual'),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('switches between the collector\'s area and all areas',
        (tester) async {
      _totals('NCR');
      await pump(tester);

      expect(find.byKey(const ValueKey('actual-area-mine')), findsOneWidget);
      expect(find.text('NCR · posted by the office'), findsOneWidget);
      expect(find.text('₱20,000.00'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('actual-area-all')));
      await tester.pumpAndSettle();
      expect(find.text('Team · posted by the office'), findsOneWidget);
      expect(find.text('₱30,000.00'), findsWidgets);
    });

    testWidgets('no default area: no switch', (tester) async {
      _totals('');
      await pump(tester);
      expect(find.byKey(const ValueKey('actual-area-mine')), findsNothing);
      expect(find.text('Team · posted by the office'), findsOneWidget);
    });
  });
}
