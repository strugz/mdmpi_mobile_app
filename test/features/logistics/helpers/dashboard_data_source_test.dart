import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_ids.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_data_source.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The Home dashboard reads its counts from the SQLite cache instead of the
/// network. These tests pin the module split and the staleness gate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('loadFromCache', () {
    late Database db;
    late DashboardDataSource source;

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath,
          version: 1, onCreate: (db, v) async => createAllTables(db));
      source = DashboardDataSource(
        database: () async => db,
        readLastSync: () => null,
        writeLastSync: (_) {},
      );
    });

    tearDown(() async => db.close());

    test('splits every shared table into its two modules', () async {
      await db.insert('a_tblRequest', {
        'RequestID': 1,
        'FormCategoryID': FormCategoryIds.standardDelivery,
        'RequestStatus': 'New Request',
        'RequestDeliveryDate': '2026-03-10',
      });
      await db.insert('a_tblRequest', {
        'RequestID': 2,
        'FormCategoryID': FormCategoryIds.hotlineDirect,
        'RequestStatus': 'Delivered',
        'RequestDeliveryDate': '2026-03-11',
      });
      await db.insert('a_tblRequestPullOutReturnPickUp', {
        'RequestID': 3,
        'FormCategoryID': FormCategoryIds.pullOutReturn,
        'RequestStatus': 'New Request',
        'PullOutDate': '2026-04-01',
      });
      await db.insert('a_tblRequestPullOutReturnPickUp', {
        'RequestID': 4,
        'FormCategoryID': FormCategoryIds.stockReceive,
        'RequestStatus': 'New Request',
        'PullOutDate': '2026-04-02',
      });
      await db.insert('a_tblRequestPickUp', {
        'RequestID': 5,
        'Status': 'Received',
        'DatePickUp': '2026-05-01',
      });
      await db.insert('a_tblRequestAirSea', {
        'RequestID': 6,
        'Status': 'New Request',
        'DatePickUp': '2026-06-01',
      });
      await db.insert('a_tblRequestAirSea', {
        'RequestID': 7,
        'FormCategoryID': FormCategoryIds.airSeaHd,
        'Status': 'New Request',
        'DatePickUp': '2026-06-02',
      });

      final entries = await source.loadFromCache();
      final byModule = <FormCategoryType, int>{};
      for (final e in entries) {
        byModule[e.module] = (byModule[e.module] ?? 0) + 1;
      }

      expect(byModule[FormCategoryType.standardDelivery], 1);
      expect(byModule[FormCategoryType.hotlineDirect], 1);
      expect(byModule[FormCategoryType.pullOutReturn], 1);
      expect(byModule[FormCategoryType.stockReceive], 1);
      expect(byModule[FormCategoryType.pickUp], 1);
      expect(byModule[FormCategoryType.airSea], 1);
      expect(byModule[FormCategoryType.airSeaHd], 1);
      expect(entries, hasLength(7));
    });

    test('falls back to createdAt when the module date is missing', () async {
      await db.insert('a_tblRequestPickUp', {
        'RequestID': 1,
        'Status': 'New Request',
        'DatePickUp': '',
        'CreatedAt': '2026-02-20T08:00:00Z',
      });

      final entries = await source.loadFromCache();

      expect(entries.single.date?.year, 2026);
      expect(entries.single.date?.month, 2);
    });

    test('an empty cache yields no entries, not an error', () async {
      expect(await source.loadFromCache(), isEmpty);
    });
  });

  group('staleness gate', () {
    DateTime? stored;
    final clock = DateTime(2026, 9, 18, 12, 0);

    DashboardDataSource build() => DashboardDataSource(
          database: () async => throw StateError('not needed'),
          readLastSync: () => stored,
          writeLastSync: (v) => stored = v,
          now: () => clock,
          staleAfter: const Duration(minutes: 15),
        );

    setUp(() => stored = null);

    test('never synced is stale', () {
      expect(build().isStale, isTrue);
    });

    test('synced 10 minutes ago is fresh', () {
      stored = clock.subtract(const Duration(minutes: 10));
      expect(build().isStale, isFalse);
    });

    test('synced 16 minutes ago is stale', () {
      stored = clock.subtract(const Duration(minutes: 16));
      expect(build().isStale, isTrue);
    });

    test('syncIfStale skips a fresh cache and does not touch the network',
        () async {
      stored = clock.subtract(const Duration(minutes: 1));
      var calls = 0;

      final ran = await build().syncIfStale(() async => calls++);

      expect(ran, isFalse);
      expect(calls, 0);
    });

    test('syncIfStale runs on a stale cache and stamps the time', () async {
      var calls = 0;

      final ran = await build().syncIfStale(() async => calls++);

      expect(ran, isTrue);
      expect(calls, 1);
      expect(stored, clock);
    });

    test('force runs even when fresh', () async {
      stored = clock;
      var calls = 0;

      final ran = await build().syncIfStale(() async => calls++, force: true);

      expect(ran, isTrue);
      expect(calls, 1);
    });
  });
}
