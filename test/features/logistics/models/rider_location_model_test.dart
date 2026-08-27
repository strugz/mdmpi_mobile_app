import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/rider_location_model.dart';

void main() {
  group('RiderLocationModel.fromJson', () {
    test('parses the realtime LocationUpdate payload', () {
      final model = RiderLocationModel.fromJson({
        'Type': 'location_update',
        'RequestID': '2026050038',
        'RiderId': '',
        'Latitude': 14.5480786,
        'Longitude': 121.0145692,
        'Timestamp': '2026-05-26T03:17:16.749Z',
        'Status': 'en_route',
        'RiderInitial': 'JCA',
        'ETA': '27 mins',
        'Distance': '10.8 km',
        'Client': 'Chinese General Hospital And Medical Center',
      });

      expect(model.type, 'location_update');
      expect(model.requestId, '2026050038');
      expect(model.latitude, 14.5480786);
      expect(model.longitude, 121.0145692);
      expect(model.riderInitial, 'JCA');
      expect(model.eta, '27 mins');
      expect(model.distance, '10.8 km');
      expect(model.client, 'Chinese General Hospital And Medical Center');
    });

    test('normalizes numeric and string RequestID values to the same key', () {
      final numeric = RiderLocationModel.fromJson({
        'RequestID': 2026050038,
        'Latitude': '14.5480786',
        'Longitude': '121.0145692',
      });
      final string = RiderLocationModel.fromJson({
        'RequestID': '2026050038',
        'Latitude': 14.5480786,
        'Longitude': 121.0145692,
      });

      expect(numeric.requestId, string.requestId);
      expect(numeric.requestId, '2026050038');
    });

    test('defaults missing optional fields and invalid values safely', () {
      final startedAt = DateTime.now();
      final model = RiderLocationModel.fromJson({
        'RequestID': 'REQ-INVALID',
        'Latitude': 'not-a-number',
        'Timestamp': 'not-a-date',
      });
      final finishedAt = DateTime.now();

      expect(model.riderId, '');
      expect(model.longitude, 0.0);
      expect(model.latitude, 0.0);
      expect(model.status, '');
      expect(
          model.timestamp
              .isAfter(startedAt.subtract(const Duration(seconds: 1))),
          true);
      expect(
          model.timestamp.isBefore(finishedAt.add(const Duration(seconds: 1))),
          true);
    });
  });
}
