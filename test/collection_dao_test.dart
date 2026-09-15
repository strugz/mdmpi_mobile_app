import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_pending_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ensureCollectionTables + Collection DAOs', () {
    late Database db;
    late CollectionDao dao;
    late CollectionPendingDao pendingDao;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await ensureCollectionTables(db);
        },
      );
      dao = CollectionDao(db);
      pendingDao = CollectionPendingDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('creates the three collection tables', () async {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'a_tblCollection%'",
      );
      final names = tables.map((r) => r['name'] as String).toSet();
      expect(
        names,
        containsAll(<String>{
          'a_tblCollectionItems',
          'a_tblCollectionHistory',
          'a_tblCollectionPending',
        }),
      );
    });

    test('insert item with history round-trips through the DAO', () async {
      final item = CollectionItemModel(
        id: 'INV-1',
        client: ClientModel(
          id: 'C1',
          code: 'C1',
          name: 'Acme',
          address: 'Manila',
          contact: '0900',
          emailAddress: 'a@a.com',
        ),
        documentReferences: const ['SI-1', 'SI-2'],
        toBeCollected: 1000,
        history: const [
          CollectionHistoryModel(
            date: '2026-09-14',
            collectorName: 'Juan',
            status: 'Partially Collected',
            totalCollected: 250,
            checkNumber: '123',
          ),
        ],
      );

      await dao.insertCollectionItem(item);

      final loaded = await dao.getCollectionItemById('INV-1');
      expect(loaded, isNotNull);
      expect(loaded!.client.name, 'Acme');
      expect(loaded.documentReferences, ['SI-1', 'SI-2']);
      expect(loaded.toBeCollected, 1000);
      expect(loaded.history.length, 1);
      expect(loaded.history.first.checkNumber, '123');
    });

    test('pending queue add / count / remove', () async {
      final id = await pendingDao.addPendingChange(PendingChange(
        operation: 'SAVE_ACTIVITY',
        payload: '{"amount":250}',
        itemId: 'INV-1',
        createdAt: '2026-09-14T10:00:00Z',
      ));

      expect(await pendingDao.getPendingChangeCount(), 1);

      await pendingDao.removePendingChange(id);
      expect(await pendingDao.hasPendingChanges(), isFalse);
    });
  });
}
