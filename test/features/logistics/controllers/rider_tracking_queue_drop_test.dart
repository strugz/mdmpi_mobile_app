import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/rider_realtime_tracking_controller.dart';

String frame(String requestId, String status) => jsonEncode({
      'Type': 'location_update',
      'RequestID': requestId,
      'Latitude': 14.5,
      'Longitude': 121.0,
      'Timestamp': '2026-09-10T07:00:00.000Z',
      'Status': status,
    });

void main() {
  group('RiderRealtimeTrackingController.dropQueuedForRequest', () {
    test('removes every queued frame of the finished request only', () {
      final queue = [
        frame('A', 'en_route'),
        frame('B', 'en_route'),
        frame('A', 'en_route'),
      ];

      final kept =
          RiderRealtimeTrackingController.dropQueuedForRequest(queue, 'A');

      expect(kept, [frame('B', 'en_route')]);
    });

    test('drops unparsable entries and leaves other requests untouched', () {
      final queue = ['not json', frame('B', 'en_route')];

      final kept =
          RiderRealtimeTrackingController.dropQueuedForRequest(queue, 'A');

      expect(kept, [frame('B', 'en_route')]);
    });

    test('empty queue stays empty', () {
      expect(
          RiderRealtimeTrackingController.dropQueuedForRequest(const [], 'A'),
          isEmpty);
    });
  });
}
