import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/data/local/dao/standard_delivery/standard_delivery_dao.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RequestDao insertRequests', () {
    late Database db;
    late RequestDao dao;

    setUpAll(() async {
      db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, version) async {
        await createAllTables(db);
      });
      dao = RequestDao(db);
    });

    tearDownAll(() async {
      await db.close();
    });

    test('inserts list of StandardDeliveryModel without type errors', () async {
      final model = StandardDeliveryModel(
        id: '2025090002',
        clientId: '5efee5641f22272f3c7b49ba',
        shippingMethod: 'Land',
        deliveryTerms: 'Full',
        deliveryDate: '2025-09-19',
        preference: 'Medium',
        status: 'Item Prepared',
        requestBy: 'JCA',
        createdBy: 'JCA',
        itemPreparedBy: 'JCA',
        deliveredBy: 'JCA',
        itemPreparedAt: '2025-09-19 15:06:33',
        itemPreparedEndAt: '2025-09-19 16:06:33',
        documentReference: ['DRNo.:690005196', 'SINo.:700005196'],
        client: ClientModel.empty(),
        createdAt: '2025-09-19 08:59:31',
        mobileID: 3,
        mobileName: 'Isuzu',
        helper: 'JCA',
        receiver: '',
        tripTicketNumber: '1112223333',
      );

      await dao.insertRequests([model]);

      final rows = await db.query('a_tblRequest');
      expect(rows.length, 1);
      final row = rows.first;
      // Ensure RequestID column exists and matches (string or int)
      expect(row.containsKey('RequestID'), true);
      expect(row['RequestClientID'], '5efee5641f22272f3c7b49ba');
      expect(row['MobileID'], 3);
    });
  });
}

