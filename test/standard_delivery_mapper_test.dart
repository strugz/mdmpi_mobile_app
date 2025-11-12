import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/dtos/standard_delivery_dto.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/standard_delivery_mapper.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

void main() {
  group('StandardDeliveryMapper', () {
    test('maps DTO->Model->DTO and Model JSON roundtrip', () {
      final Map<String, dynamic> sampleJson = {
        'ID': 'REQ-123',
        'ClientID': 'C001',
        'ShippingMethod': 'Road',
        'DeliveryTerms': 'Door_to_Door',
        'DeliveryDate': '2025-11-10',
        'Preference': 'Morning',
        'Status': 'New Request',
        'RequestBy': 'user@example.com',
        'CreatedBy': 'creator@example.com',
        'CreatedAt': '2025-11-05T10:00:00Z',
        'ItemPreparedBy': 'preparer',
        'DeliveredBy': null,
        'ItemPreparedAt': null,
        'ItemPreparedEndAt': null,
        'DeliveredAt': null,
        'DeliveredEndAt': null,
        'MobileID': 42,
        'MobileName': 'Van 1',
        'Helper': 'Helper Joe',
        'Receiver': '',
        'TripTicketNumber': 'TT-001',
        'LocationStartedAt': null,
        'LocationEndAt': null,
        'DocumentReference': ['doc://1', 'doc://2'],
        'Client': {
          'ClientID': 'C001',
          'Name': 'ACME Corp',
        },
        'CancelRemarks': {'Remarks': 'Cancelled due to X'},
        'Image': {'Path': 'https://example.com/image.jpg'},
        'Signature': {'Path': 'https://example.com/sign.png'},
      };

      // Parse DTO from JSON
      final dto = StandardDeliveryDto.fromJson(sampleJson);
      expect(dto.id, 'REQ-123');
      expect(dto.clientId, 'C001');
      expect(dto.documentReference?.length, 2);
      expect(dto.client?.name, 'ACME Corp');

      // Map DTO -> Model
      final model = StandardDeliveryMapper.fromDto(dto);
      expect(model.id, 'REQ-123');
      expect(model.clientId, 'C001');
      expect(model.shippingMethod, 'Road');
      expect(model.mobileID, 42);
      expect(model.documentReference.length, 2);
      expect(model.client.name, 'ACME Corp');
      expect(model.image, 'https://example.com/image.jpg');
      expect(model.signature, 'https://example.com/sign.png');
      expect(model.cancelRemarks.remarks, 'Cancelled due to X');

      // Map Model -> DTO
      final dto2 = StandardDeliveryMapper.toDto(model);
      expect(dto2.id, model.id);
      expect(dto2.clientId, model.clientId);
      expect(dto2.mobileID, model.mobileID);
      expect(dto2.documentReference?.length, model.documentReference.length);

      // Model JSON roundtrip using model.toJson / fromJson
      final jsonFromModel = model.toJson();
      final backModel = StandardDeliveryModel.fromJson(jsonFromModel);
      expect(backModel.id, model.id);
      expect(backModel.client.name, model.client.name);
    });
  });
}

