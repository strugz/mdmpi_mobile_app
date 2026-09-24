import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_activity_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_advance_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_account_history_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_target_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Stage C2: the concepts that used to live only in memory now persist.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Stage C2 collection tables', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async => ensureCollectionTables(db),
      );
    });

    tearDown(() async => db.close());

    test('creates the four Stage C2 tables', () async {
      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'a_tblCollection%'",
      );
      final names = rows.map((r) => r['name'] as String).toSet();
      expect(
        names,
        containsAll(<String>{
          'a_tblCollectionActivity',
          'a_tblCollectionAdvance',
          'a_tblCollectionAccountHistory',
          'a_tblCollectionTarget',
        }),
      );
    });

    test('office activity round-trips including the invoice list', () async {
      final dao = CollectionActivityDao(db);
      await dao.insert(const CollectionActivityRecord(
        type: 'Deposit',
        clientId: 'NCR-300',
        clientName: 'Metro Globe',
        date: '2026-09-15 10:00',
        amount: 900,
        bankName: 'BDO',
        checkNumber: 'C-900',
        remarks: 'Cheque deposit',
        documentIds: ['DP1', 'DP2'],
        collectorName: 'Juan',
        localRef: 'ACT-1',
      ));

      final all = await dao.getAll();
      final a = all.single;
      expect(a.type, 'Deposit');
      expect(a.documentIds, ['DP1', 'DP2']);
      expect(a.amount, 900);
      expect(a.localRef, 'ACT-1');
    });

    test('advance is unassigned until marked, then disappears from getUnassigned', () async {
      final dao = CollectionAdvanceDao(db);
      await dao.upsert(const CollectionAdvanceRecord(
        externalRef: 'AP-1',
        clientId: 'VIS-777',
        clientName: 'Cebu Clinic',
        amount: 5000,
        date: '2026-09-15 09:00',
        collectorName: 'Juan',
      ));

      expect((await dao.getUnassigned()).single.isUnassigned, isTrue);

      await dao.markAssigned('AP-1', 'SI-OCT-1');
      expect(await dao.getUnassigned(), isEmpty);
      expect((await dao.getAll()).single.assignedDocumentId, 'SI-OCT-1');
    });

    // An advance larger than its invoice keeps the excess as float for the
    // next invoice: same advance, still unassigned, only the remainder.
    test('an excess stays float on the same advance', () async {
      final dao = CollectionAdvanceDao(db);
      await dao.upsert(const CollectionAdvanceRecord(
        externalRef: 'AP-1',
        clientId: 'VIS-777',
        clientName: 'Cebu Clinic',
        amount: 750000,
        date: '2026-09-15 09:00',
        collectorName: 'Juan',
      ));

      await dao.keepRemainder('AP-1', 250000);

      final left = (await dao.getUnassigned()).single;
      expect(left.externalRef, 'AP-1',
          reason: 'the server spreads one payment across invoices');
      expect(left.amount, 250000);
      expect(left.isUnassigned, isTrue);
      expect(left.clientName, 'Cebu Clinic');
    });

    test('account history and target persist', () async {
      final hist = CollectionAccountHistoryDao(db);
      await hist.insert(const CollectionAccountHistoryRecord(
        clientId: 'SLN-150',
        date: '2026-09-15 11:00',
        reason: 'Customer Unavailable',
        remarks: 'Closed today',
        collectorName: 'Juan',
      ));
      expect((await hist.getAll()).single.reason, 'Customer Unavailable');

      final target = CollectionTargetDao(db);
      await target.set('2026-09', 100000);
      await target.set('2026-09', 150000); // corrected later: upsert, one row
      expect(await target.get('2026-09'), 150000);
      expect((await target.getAll()).length, 1);
      expect(await target.get('2026-10'), isNull);
    });
  });
}
