import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

void main() {
  test('fromDbJson handles uppercase keys', () {
    final Map<String, dynamic> row = {
      'RequestID': '2025110002',
      'RequestClientID': 'CLIENT123',
      'RequestShippingMethod': 'Land',
      'MobileID': 5,
      'MobileName': 'Isuzu',
      'RequestStatus': 'Item Prepared',
      'RequestCreatedAt': '2025-11-06 10:00:00',
    };

    final m = StandardDeliveryModel.fromDbJson(row);

    expect(m.id, '2025110002');
    expect(m.clientId, 'CLIENT123');
    expect(m.shippingMethod, 'Land');
    expect(m.mobileID, 5);
    expect(m.mobileName, 'Isuzu');
    expect(m.status, 'Item Prepared');
    expect(m.createdAt, '2025-11-06 10:00:00');
  });

  test('fromDbJson handles lowercase keys', () {
    final Map<String, dynamic> row = {
      'requestid': '2025110003',
      'requestclientid': 'CLIENT456',
      'requestshippingmethod': 'Air',
      'mobileid': '7', // as string
      'mobilename': 'Toyota',
      'requeststatus': 'Cancelled',
      'requestcreatedat': '2025-11-06 11:00:00',
    };

    final m = StandardDeliveryModel.fromDbJson(row);

    expect(m.id, '2025110003');
    expect(m.clientId, 'CLIENT456');
    expect(m.shippingMethod, 'Air');
    expect(m.mobileID, 7);
    expect(m.mobileName, 'Toyota');
    expect(m.status, 'Cancelled');
    expect(m.createdAt, '2025-11-06 11:00:00');
  });
}

