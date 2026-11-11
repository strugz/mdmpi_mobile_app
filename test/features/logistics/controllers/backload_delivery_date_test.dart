import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/backload_controller.dart';

void main() {
  group('BackLoadController.isSameDeliveryDate', () {
    test('same day in different formats is unchanged', () {
      expect(
          BackLoadController.isSameDeliveryDate(
              '2026-11-10T00:00:00', '2026-11-10'),
          isTrue);
      expect(
          BackLoadController.isSameDeliveryDate('2026-11-10', '2026-11-10'),
          isTrue);
    });

    test('a different day is a change', () {
      expect(
          BackLoadController.isSameDeliveryDate(
              '2026-11-10T00:00:00', '2026-11-12'),
          isFalse);
    });

    test('blank stays blank counts as unchanged', () {
      expect(BackLoadController.isSameDeliveryDate('', ''), isTrue);
      expect(BackLoadController.isSameDeliveryDate('', '2026-11-12'), isFalse);
    });
  });
}
