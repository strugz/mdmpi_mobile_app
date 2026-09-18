import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/data/local/dao/pick_up/pick_up_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A list refresh must not rewind a status this device already advanced.
///
/// The single-row update path has always been guarded, but the bulk insert
/// used `ConflictAlgorithm.replace` and overwrote unconditionally — so pulling
/// a stale server snapshot silently lost local progress.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('PickUpDao.insertPickUps status guard', () {
    late Database db;
    late PickUpDao dao;

    PickUpModel model(String id, String status) =>
        PickUpModel(id: id, status: status, clientId: '1');

    Future<String?> storedStatus(String id) async {
      final rows = await db.query('a_tblRequestPickUp',
          columns: ['Status'], where: 'RequestID = ?', whereArgs: [id]);
      return rows.isEmpty ? null : rows.first['Status'] as String?;
    }

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath,
          version: 1, onCreate: (db, v) async => createAllTables(db));
      dao = PickUpDao(db);
    });

    tearDown(() async => db.close());

    test('a stale snapshot cannot rewind an advanced status', () async {
      await dao.insertPickUps([model('1', BTexts.statusReceived)]);

      // Server has not caught up yet.
      await dao.insertPickUps([model('1', BTexts.statusNewRequest)]);

      expect(await storedStatus('1'), BTexts.statusReceived);
    });

    test('a forward status still applies', () async {
      await dao.insertPickUps([model('1', BTexts.statusNewRequest)]);
      await dao.insertPickUps([model('1', BTexts.statusItemPacked)]);

      expect(await storedStatus('1'), BTexts.statusItemPacked);
    });

    test('a cancel from the server still applies', () async {
      await dao.insertPickUps([model('1', BTexts.statusReceived)]);
      await dao.insertPickUps([model('1', BTexts.statusCancelled)]);

      expect(await storedStatus('1'), BTexts.statusCancelled);
    });

    test('the guard survives the BTexts casing drift', () async {
      await dao.insertPickUps([model('1', BTexts.statusItemPacked)]);
      await dao.insertPickUps([model('1', BTexts.statusGettingSuppliesReady)]);

      expect(await storedStatus('1'), BTexts.statusItemPacked,
          reason: '"Getting supplies ready" ranks below "Item Packed"');
    });

    test('rows the device has never seen are inserted normally', () async {
      await dao.insertPickUps([
        model('1', BTexts.statusNewRequest),
        model('2', BTexts.statusReceived),
      ]);

      expect(await storedStatus('1'), BTexts.statusNewRequest);
      expect(await storedStatus('2'), BTexts.statusReceived);
    });
  });
}
