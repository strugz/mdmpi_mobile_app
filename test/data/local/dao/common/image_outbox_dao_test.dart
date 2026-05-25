import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/image_outbox_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late ImageOutboxDao dao;

  setUp(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE a_tblRequestImageOutbox (
        RequestID TEXT NOT NULL,
        ImageType TEXT NOT NULL,
        ImageLookupKey TEXT NOT NULL,
        RequestImage TEXT,
        ApiStatus TEXT DEFAULT 'Pending',
        CapturedAt TEXT,
        UNIQUE(RequestID, ImageType, ImageLookupKey)
      )
    ''');
    dao = ImageOutboxDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('inserts, lists, and deletes an image outbox row', () async {
    await dao.insertImageOutboxItem(
      requestId: '101',
      imageType: 'Proof',
      imageLookupKey: '101',
      imageBase64: 'base64',
      apiStatus: 'Failed',
      capturedAt: '2026-04-30T08:30:00.000Z',
    );

    final rows = await dao.getPendingImageOutboxItems();

    expect(rows, hasLength(1));
    expect(rows.first['RequestID'], '101');
    expect(rows.first['ImageType'], 'Proof');
    expect(rows.first['ApiStatus'], 'Failed');

    final deleted = await dao.deleteImageOutboxItem(
      requestId: '101',
      imageType: 'Proof',
      imageLookupKey: '101',
    );

    expect(deleted, 1);
    expect(await dao.getPendingImageOutboxItems(), isEmpty);
  });

  test('keeps multiple image types for the same request separately', () async {
    await dao.insertImageOutboxItem(
      requestId: '202',
      imageType: 'Proof',
      imageLookupKey: '202',
      imageBase64: 'proof',
    );
    await dao.insertImageOutboxItem(
      requestId: '202',
      imageType: 'Provincial_PickUp_Proof',
      imageLookupKey: '202_provincial_pick_up',
      imageBase64: 'provincial',
    );

    final rows = await dao.getPendingImageOutboxItems();

    expect(rows, hasLength(2));
    expect(
        rows.map((row) => row['ImageType']),
        containsAll([
          'Proof',
          'Provincial_PickUp_Proof',
        ]));
  });
}
