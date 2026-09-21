import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/standard_delivery/standard_delivery_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A Standard Delivery / Hotline Direct hard reset must not destroy work that
/// belongs to other modules.
///
/// The signature, image, image-outbox and document-reference tables are keyed
/// by `RequestID` with no module column and are written by Pick Up and
/// Air / Sea too. Clearing them from the Standard Delivery reset discarded
/// every module's un-uploaded proof photos and signatures.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath,
        version: 1, onCreate: (db, v) async => createAllTables(db));

    await db.insert('a_tblRequest', {'RequestID': 1});
    await db.insert('a_tblRequestImageOutbox', {
      'RequestID': '77',
      'ImageType': 'Proof',
      'ImageLookupKey': 'k',
      'RequestImage': 'pickup-photo',
      'ApiStatus': 'Pending',
    });
    await db.insert('a_tblRequestReceiverSignature', {
      'RequestID': 77,
      'RequestReceiverSignature': 'pickup-signature',
      'ApiStatus': 'Pending',
    });
    await db.insert('a_tblRequestImage', {
      'RequestID': 77,
      'RequestImage': 'airsea-photo',
    });
    await db.insert('a_tblRequestDocumentReference', {
      'RequestID': 77,
      'Reference': 'DR-77',
    });
  });

  tearDown(() async => db.close());

  test('RequestDao.deleteAll clears requests but keeps shared tables',
      () async {
    await RequestDao(db).deleteAll();

    expect(await db.query('a_tblRequest'), isEmpty);
    expect(await db.query('a_tblRequestImageOutbox'), hasLength(1));
    expect(await db.query('a_tblRequestReceiverSignature'), hasLength(1));
    expect(await db.query('a_tblRequestImage'), hasLength(1));
    expect(await db.query('a_tblRequestDocumentReference'), hasLength(1));
  });
}
