import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/standard_delivery_mapper.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

/// The update endpoint keeps any field the payload omits and stores any field
/// it carries, so removing a helper needs an explicit empty value while every
/// other update must keep omitting an empty helper.
void main() {
  StandardDeliveryModel request({required String helper}) =>
      StandardDeliveryModel.empty()
          .copyWith(id: '2026110001', deliveredBy: 'NDV', helper: helper);

  Map<String, dynamic> payload(String helper, {bool clearHelper = false}) =>
      StandardDeliveryMapper.toUpdateDto(request(helper: helper), 'JCA',
              clearHelper: clearHelper)
          .toJson();

  test('an empty helper is omitted by default', () {
    expect(payload('').containsKey('requestDriverHelper'), isFalse);
  });

  test('clearHelper sends an empty helper', () {
    expect(payload('', clearHelper: true)['requestDriverHelper'], '');
  });

  test('a chosen helper is sent either way', () {
    expect(payload('CMA')['requestDriverHelper'], 'CMA');
    expect(payload('CMA', clearHelper: true)['requestDriverHelper'], 'CMA');
  });
}
