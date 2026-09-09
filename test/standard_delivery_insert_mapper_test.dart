import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/standard_delivery_mapper.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

void main() {
  test('StandardDeliveryMapper.toInsertDto produces expected JSON map', () {
    final model = StandardDeliveryModel(
      id: '2025110006',
      clientId: 'client-123',
      shippingMethod: 'Land',
      deliveryTerms: 'Full',
      deliveryDate: '2025-11-06',
      preference: 'Medium',
      status: 'New Request',
      requestBy: 'JCA',
      createdBy: 'JCA',
      recipientContactDetails: '09171234567',
      recipientName: 'Juan Dela Cruz',
      documentReference: ['DR1'],
      client: ClientModel.empty(),
      createdAt: DateTime.now().toString(),
    );

    final dto = StandardDeliveryMapper.toInsertDto(model);
    final json = dto.toJson();

    expect(json['requestClientID'], 'client-123');
    expect(json['requestShippingMethod'], 'Land');
    expect(json['requestDeliveryTerms'], 'Full');
    expect(json['requestDeliveryDate'], '2025-11-06');
    expect(json['requestPreference'], 'Medium');
    expect(json['requestStatus'], 'New Request');
    expect(json['requestBy'], 'JCA');
    expect(json['requestCreatedBy'], 'JCA');
    // The API contract uses these lowerCamel keys; see InsertRequestDto in
    // the MDMPI.App backend.
    expect(json['recipientContactDetails'], '09171234567');
    expect(json['recipientName'], 'Juan Dela Cruz');
    expect(json['documentReference'], ['DR1']);

    // Ensure no uppercase keys exist
    expect(json.containsKey('RequestClientID'), false);
  });

  test('toInsertDto serializes every Stock Issue Slip column per item', () {
    final model = StandardDeliveryModel(
      id: '2025110006',
      clientId: 'client-123',
      shippingMethod: 'Land',
      deliveryTerms: 'Full',
      deliveryDate: '2025-11-06',
      preference: 'Medium',
      status: 'New Request',
      requestBy: 'JCA',
      createdBy: 'JCA',
      recipientContactDetails: '09171234567',
      recipientName: 'Juan Dela Cruz',
      documentReference: ['DR1'],
      client: ClientModel.empty(),
      createdAt: DateTime.now().toString(),
    );

    final items = [
      InventoryItemModel(
        itemCode: '629029',
        description: 'Dell 800 Hematology System Analyzer',
        qty: 1,
        unit: 'UNIT',
        partNo: 'AY19270',
        serialNo: 'FA2440433',
        ptn: 'ACS16-6435',
      ),
    ];

    final json = StandardDeliveryMapper.toInsertDto(model, items).toJson();

    final serialized = json['items'] as List<dynamic>;
    expect(serialized.length, 1);

    final first = serialized.first as Map<String, dynamic>;
    expect(first['Qty'], 1);
    expect(first['Unit'], 'UNIT');
    expect(first['Part No.'], 'AY19270');
    expect(first['Item Code'], '629029');
    expect(first['Description'], 'Dell 800 Hematology System Analyzer');
    expect(first['Serial No.'], 'FA2440433');
    expect(first['PTN'], 'ACS16-6435');
    expect(first.containsKey('Remarks'), isFalse,
        reason: 'the client does not send remarks');
  });

  test('toInsertDto sends an empty items list when there are no items', () {
    final model = StandardDeliveryModel(
      id: '2025110007',
      clientId: 'client-123',
      shippingMethod: 'Land',
      deliveryTerms: 'Full',
      deliveryDate: '2025-11-06',
      preference: 'Medium',
      status: 'New Request',
      requestBy: 'JCA',
      createdBy: 'JCA',
      recipientContactDetails: '09171234567',
      recipientName: 'Juan Dela Cruz',
      documentReference: const [],
      client: ClientModel.empty(),
      createdAt: DateTime.now().toString(),
    );

    final json = StandardDeliveryMapper.toInsertDto(model).toJson();

    expect(json['items'], isEmpty);
  });
}
