import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/shipping_methods.dart';

void main() {
  test('ShippingMethods.all matches the backend allow-list (Air|Sea|Land)', () {
    // Order is the dropdown order; values must match the API's
    // [RegularExpression("^(Air|Sea|Land)$")] exactly, including casing.
    expect(ShippingMethods.all, ['Land', 'Air', 'Sea']);
    expect(ShippingMethods.all.toSet().length, ShippingMethods.all.length);
  });
}
