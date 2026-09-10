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
}
