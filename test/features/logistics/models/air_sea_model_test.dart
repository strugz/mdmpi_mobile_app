import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';

void main() {
  group('AirSeaModel.shippingMethod', () {
    test('fromJson reads the API key in any casing the server may emit', () {
      // POST echoes PascalCase; GET (System.Text.Json defaults) emits camelCase.
      for (final key in ['ShippingMethod', 'shippingMethod', 'shippingmethod']) {
        final model = AirSeaModel.fromJson({
          'RequestID': 1,
          'ClientID': 'C1',
          'Status': 'New Request',
          key: 'Sea',
        });
        expect(model.shippingMethod, 'Sea', reason: 'key $key');
      }
    });

    test('fromJson leaves shippingMethod empty when the key is missing or null',
        () {
      final missing = AirSeaModel.fromJson({'RequestID': 1, 'ClientID': 'C1'});
      expect(missing.shippingMethod, '');

      final nullValue = AirSeaModel.fromJson(
          {'RequestID': 1, 'ClientID': 'C1', 'shippingMethod': null});
      expect(nullValue.shippingMethod, '');
    });

    test('toJson emits null for an empty mode and the value otherwise', () {
      expect(AirSeaModel(id: '1').toJson()['ShippingMethod'], isNull);
      expect(AirSeaModel(id: '1', shippingMethod: 'Air').toJson()['ShippingMethod'],
          'Air');
    });

    test('fromDbJson reads the local SQLite column', () {
      final model = AirSeaModel.fromDbJson({
        'RequestID': 7,
        'ClientID': 'C1',
        'Status': 'New Request',
        'ShippingMethod': 'Land',
      });
      expect(model.shippingMethod, 'Land');

      final legacy = AirSeaModel.fromDbJson({'RequestID': 8, 'ClientID': 'C1'});
      expect(legacy.shippingMethod, '');
    });

    test('copyWith preserves the mode unless overridden', () {
      final base = AirSeaModel(id: '1', shippingMethod: 'Sea');
      expect(base.copyWith(status: 'Item Packed').shippingMethod, 'Sea');
      expect(base.copyWith(shippingMethod: 'Air').shippingMethod, 'Air');
    });
  });
}
