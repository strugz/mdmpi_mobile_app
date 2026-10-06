import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/standard_delivery/standard_delivery_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// After Upload Data is refused (409), the phone must take the server's copy
/// even when that moves the status backwards: a Backload resets the server to
/// New Request, and the normal update path refuses that as a regression, so
/// the stale local copy would be re-sent (and refused) on every upload.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath,
        version: 1, onCreate: (db, v) async => createAllTables(db));

    // The phone's copy from 17 Sep, before the Backload reset.
    await db.insert('a_tblRequest', {
      'RequestID': 2026090145,
      'RequestStatus': 'Item Prepared',
      'RequestDeliveryDate': '2026-09-17',
      'RequestItemPreparedBy': 'EBP',
      'RequestItemPreparedAt': '2026-09-17 09:07:21.149665',
      'RequestItemPreparedEndAt': '2026-09-17 09:09:16.84851',
      'TripTicketNumber': '01019',
      'FormCategoryID': '6',
    });
  });

  tearDown(() async => db.close());

  // The server's copy after the reset: New Request, new date, times cleared.
  StandardDeliveryModel serverCopy({String id = '2026090145'}) =>
      StandardDeliveryModel(
        id: id,
        clientId: 'client-123',
        shippingMethod: 'Land',
        deliveryTerms: 'Full',
        deliveryDate: '2026-09-24',
        preference: 'Medium',
        status: 'New Request',
        requestBy: 'MMA',
        createdBy: 'AMG',
        documentReference: const [],
        client: ClientModel.empty(),
        createdAt: '2026-09-17 08:54:45',
        formCategoryID: '6',
      );

  Future<Map<String, Object?>> row(int id) async =>
      (await db.query('a_tblRequest', where: 'RequestID = ?', whereArgs: [id]))
          .single;

  test('updateRequest keeps the stale copy (regression guard)', () async {
    await RequestDao(db).updateRequest(requestModel: serverCopy());

    expect((await row(2026090145))['RequestStatus'], 'Item Prepared');
  });

  test('replaceWithServerCopy takes the server copy, backwards or not',
      () async {
    await RequestDao(db).replaceWithServerCopy(serverCopy());

    final saved = await row(2026090145);
    expect(saved['RequestStatus'], 'New Request');
    expect(saved['RequestDeliveryDate'], '2026-09-24');
    expect(saved['RequestItemPreparedAt'], '');
    expect(saved['RequestItemPreparedEndAt'], '');
    expect(saved['TripTicketNumber'], '');
  });

  test('replaceWithServerCopy inserts a request the phone does not have',
      () async {
    await RequestDao(db).replaceWithServerCopy(serverCopy(id: '2026090213'));

    expect((await row(2026090213))['RequestStatus'], 'New Request');
  });
}
