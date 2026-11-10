import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/standard_delivery/standard_delivery_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/features/logistics/dtos/standard_delivery/standard_delivery_dto.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_form_state.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/standard_delivery_mapper.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The per-request delivery address (plan §4.4b, app side A1–A7).

ClientModel _client([String address = 'N/A']) => ClientModel(
    id: 'C-1',
    name: 'GALINATO CLINIC AND HOSPITAL',
    address: address,
    contact: '',
    emailAddress: '');

StandardDeliveryModel _request({String deliveryAddress = ''}) =>
    StandardDeliveryModel.empty().copyWith(
      id: '4213',
      clientId: 'C-1',
      client: _client(),
      status: 'New Request',
      deliveryAddress: deliveryAddress,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('insert payload', () {
    test('no requestDeliveryAddress key when there is no fallback', () {
      final json = StandardDeliveryMapper.toInsertDto(_request()).toJson();
      expect(json.containsKey('requestDeliveryAddress'), isFalse);
    });

    test('the key is sent when a scan used the fallback', () {
      final json = StandardDeliveryMapper.toInsertDto(
              _request(deliveryAddress: 'Villamor, Esperanza'))
          .toJson();
      expect(json['requestDeliveryAddress'], 'Villamor, Esperanza');
    });
  });

  group('reading a request', () {
    test('API JSON: the delivery address replaces the master address', () {
      final m = StandardDeliveryModel.fromJson({
        'ID': 1,
        'ClientID': 'C-1',
        'Client': _client().toJson(),
        'DeliveryAddress': ' Villamor, Esperanza ',
      });
      expect(m.client.address, 'Villamor, Esperanza');
      expect(m.deliveryAddress, 'Villamor, Esperanza');
    });

    test('API JSON without it (old backend) keeps the master address', () {
      final m = StandardDeliveryModel.fromJson({
        'ID': 1,
        'Client': _client('Rizal Drive').toJson(),
      });
      expect(m.client.address, 'Rizal Drive');
      expect(m.deliveryAddress, '');
      expect(m.toJson().containsKey('DeliveryAddress'), isFalse);
    });

    test('mapper fromDto overrides only when set', () {
      expect(
        StandardDeliveryMapper.fromDto(StandardDeliveryDto(
                id: '1', deliveryAddress: 'Villamor, Esperanza'))
            .client
            .address,
        'Villamor, Esperanza',
      );
      expect(
          StandardDeliveryMapper.fromDto(StandardDeliveryDto(id: '1'))
              .deliveryAddress,
          '');
    });

    test('the master client object is never changed', () {
      final master = _client();
      final copy =
          StandardDeliveryModel.clientWithDeliveryAddress(master, 'Villamor');
      expect(copy.address, 'Villamor');
      expect(master.address, 'N/A');
      expect(
          identical(
              StandardDeliveryModel.clientWithDeliveryAddress(master, ' '),
              master),
          isTrue);
    });
  });

  group('local cache (DB v22)', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath,
          version: 1, onCreate: (db, v) async => createAllTables(db));
      await db.insert('ACCMST_', _client().toJson());
    });

    tearDown(() async => db.close());

    test('round-trips and overrides the cached client address', () async {
      final dao = RequestDao(db);
      await dao.insertRequest(_request(deliveryAddress: 'Villamor, Esperanza'));
      final read = (await dao.getRequests()).single;
      expect(read.deliveryAddress, 'Villamor, Esperanza');
      expect(read.client.address, 'Villamor, Esperanza');
      expect(read.client.name, 'GALINATO CLINIC AND HOSPITAL');
    });

    test('syncing a request with its own address leaves ACCMST_ alone',
        () async {
      final fromApi = StandardDeliveryModel.fromJson({
        'ID': 4213,
        'ClientID': 'C-1',
        'Status': 'New Request',
        'Client': _client().toJson(),
        'DeliveryAddress': 'Villamor, Esperanza',
      });
      expect(fromApi.client.address, 'Villamor, Esperanza');

      await RequestDao(db).insertRequest(fromApi);

      final master = await db.query('ACCMST_', where: 'ACCMID = ?', whereArgs: ['C-1']);
      expect(master.single['ACCMAD'], 'N/A');
    });

    test('a refresh without the address does not blank the stored one',
        () async {
      final dao = RequestDao(db);
      await dao.insertRequest(_request(deliveryAddress: 'Villamor, Esperanza'));
      await dao.replaceWithServerCopy(_request());
      final read = (await dao.getRequests()).single;
      expect(read.deliveryAddress, 'Villamor, Esperanza');
    });

    test('a request without it shows the master address', () async {
      final dao = RequestDao(db);
      await dao.insertRequest(_request());
      final read = (await dao.getRequests()).single;
      expect(read.client.address, 'N/A');
    });
  });

  group('form state', () {
    test('the fallback is saved only for the client it belongs to', () {
      final form = StandardDeliveryFormState();
      expect(form.deliveryAddressFor('C-1'), '');

      form.scannedFallbackAddress.value =
          (clientId: 'C-1', address: 'Villamor, Esperanza');
      expect(form.deliveryAddressFor('C-1'), 'Villamor, Esperanza');
      expect(form.deliveryAddressFor('C-2'), '',
          reason: 'the user picked another client afterwards');

      form.reset();
      expect(form.scannedFallbackAddress.value, isNull);
    });
  });
}
