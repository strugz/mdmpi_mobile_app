import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/air_sea_mapper.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

void main() {
  AirSeaModel buildModel({String shippingMethod = ''}) => AirSeaModel(
        id: '2026090001',
        clientId: 'client-123',
        itemCategoryId: '2',
        datePickUp: '2026-09-10',
        status: 'New Request',
        createdBy: 'JCA',
        documentReference: const ['DR1'],
        client: ClientModel.empty(),
        shippingMethod: shippingMethod,
      );

  test('AirSeaMapper.toInsertDto puts ShippingMethod when set', () {
    final json = AirSeaMapper.toInsertDto(buildModel(shippingMethod: 'Sea'))
        .toJson();

    // PascalCase key: the API contract used by /api4/RequestAirSea.
    expect(json['ShippingMethod'], 'Sea');
    expect(json['ClientID'], 'client-123');
    expect(json['Status'], 'New Request');
  });

  test('AirSeaMapper.toInsertDto omits ShippingMethod when empty', () {
    final json = AirSeaMapper.toInsertDto(buildModel()).toJson();
    expect(json.containsKey('ShippingMethod'), isFalse);
  });

  test('AirSeaMapper.toUpdateDto never sends ShippingMethod (create-only)', () {
    final json =
        AirSeaMapper.toUpdateDto(buildModel(shippingMethod: 'Air'), 'JCA')
            .toJson();
    expect(json.containsKey('ShippingMethod'), isFalse);
  });

  test('AirSeaMapper.toUpdateDto sends DepartureAt only when set', () {
    final withTime = AirSeaMapper.toUpdateDto(
            buildModel().copyWith(departureAt: '2026-11-25 15:30:00.000'),
            'JCA')
        .toJson();
    expect(withTime['DepartureAt'], startsWith('2026-11-25T15:30:00'));

    final without = AirSeaMapper.toUpdateDto(buildModel(), 'JCA').toJson();
    expect(without.containsKey('DepartureAt'), isFalse);
  });

  test('AirSeaModel reads DepartureAt from the API and from SQLite', () {
    expect(
        AirSeaModel.fromJson({'DepartureAt': '2026-11-25T15:30:00'}).departureAt,
        '2026-11-25T15:30:00');
  });

  test('a null or missing DepartureAt is empty and never sent back', () {
    // Older rows: the server returns null (or, on an old backend, no key).
    for (final json in <Map<String, dynamic>>[
      {'RequestID': '1', 'DepartureAt': null},
      {'RequestID': '1', 'departureAt': null},
      {'RequestID': '1'},
    ]) {
      final model = AirSeaModel.fromJson(json);
      expect(model.departureAt, '', reason: '$json');
      expect(AirSeaMapper.toUpdateDto(model, 'JCA').toJson(),
          isNot(contains('DepartureAt')),
          reason: 'a null must not clear the server value');
    }
    // SQLite rows cached before the column existed, or with a NULL column.
    expect(AirSeaModel.fromDbJson({'RequestID': '1', 'DepartureAt': null}).departureAt, '');
    expect(AirSeaModel.fromDbJson({'RequestID': '1'}).departureAt, '');
  });

  test('a DepartureAt that is not a date is left out, never sent', () {
    // The API answers 400 to an unparsable date, failing the whole update.
    for (final bad in ['   ', 'N/A', 'not a time']) {
      final model = buildModel().copyWith(departureAt: bad, status: 'Drop Off');
      final json = AirSeaMapper.toUpdateDto(model, 'JCA').toJson();
      expect(json.containsKey('DepartureAt'), isFalse, reason: bad);
      expect(json['Status'], 'Drop Off', reason: 'the rest still goes');
      expect(AirSeaMapper.toUpdateMap(model).containsKey('DepartureAt'),
          isFalse, reason: bad);
    }
  });
}
