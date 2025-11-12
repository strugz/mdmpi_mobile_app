import 'package:flutter_test/flutter_test.dart';
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
    expect(json['documentReference'], ['DR1']);

    // Ensure no uppercase keys exist
    expect(json.containsKey('RequestClientID'), false);
  });
}
