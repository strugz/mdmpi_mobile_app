import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/loading_screen_controller.dart';

/// Sign-in loads the Logistics lists (clients, users, requesters, item and
/// form categories) only for the departments whose screens read them.
void main() {
  test('a Collection user skips the Logistics lists', () {
    expect(LoadingScreenController.needsLogisticsData('Collection'), isFalse);
    expect(LoadingScreenController.needsLogisticsData(' collection '), isFalse);
  });

  test('everyone else, and an unknown department, still gets them', () {
    for (final d in ['Logistics', 'Service', 'InHouse', '']) {
      expect(LoadingScreenController.needsLogisticsData(d), isTrue, reason: d);
    }
  });
}
