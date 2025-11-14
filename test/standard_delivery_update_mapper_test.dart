import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/standard_delivery_mapper.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

void main() {
  test('toUpdateDto omits signature/image/remarks when empty and includes when present', () {
    final baseModel = StandardDeliveryModel(
      id: '2025110006',
      clientId: 'client-123',
      shippingMethod: 'Land',
      deliveryTerms: 'Full',
      deliveryDate: '2025-11-06',
      preference: 'Medium',
      status: 'Item Prepared',
      requestBy: 'JCA',
      createdBy: 'JCA',
      documentReference: [],
      client: ClientModel.empty(),
      createdAt: DateTime.now().toString(),
    );

    // Case 1: no signature/image/remarks
    final dto1 = StandardDeliveryMapper.toUpdateDto(baseModel);
    final json1 = dto1.toJson();
    expect(json1.containsKey('signature'), false);
    expect(json1.containsKey('image'), false);
    expect(json1.containsKey('remarks'), false);

    // Case 2: with signature
    final withSignature = baseModel.copyWith(signature: 'base64signature');
    final dto2 = StandardDeliveryMapper.toUpdateDto(withSignature);
    final json2 = dto2.toJson();
    expect(json2.containsKey('signature'), true);
    expect((json2['signature'] as Map).containsKey('requestReceiverSignature'), true);

    // Case 3: with image
    final withImage = baseModel.copyWith(image: 'base64image');
    final dto3 = StandardDeliveryMapper.toUpdateDto(withImage);
    final json3 = dto3.toJson();
    expect(json3.containsKey('image'), true);
    expect((json3['image'] as Map).containsKey('requestImage'), true);

    // Case 4: with remarks
    final withRemarks = baseModel.copyWith(cancelRemarks: baseModel.cancelRemarks.copyWith(remarks: 'Canceled for X', date: DateTime.now().toString()));
    final dto4 = StandardDeliveryMapper.toUpdateDto(withRemarks);
    final json4 = dto4.toJson();
    expect(json4.containsKey('remarks'), true);
    expect((json4['remarks'] as Map).containsKey('remarks'), true);
  });
}

