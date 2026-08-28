import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/rider_realtime_tracking_controller.dart';

String frame(String requestId, String timestamp, {double latitude = 14.5}) {
  return jsonEncode({
    'Type': 'location_update',
    'RequestID': requestId,
    'Latitude': latitude,
    'Longitude': 121.0,
    'Timestamp': timestamp,
  });
}

void main() {
  group('RiderRealtimeTrackingController.collapseQueueToLatestPerRequest', () {
    test('collapses a long single-request queue to its latest frame', () {
      final queue = List.generate(
        200,
        (i) => frame(
          'REQ-1',
          DateTime.utc(2026, 5, 26, 3, 0, i ~/ 60, 0, i % 60).toIso8601String(),
          latitude: 14.5 + i * 0.0001,
        ),
      );

      final collapsed =
          RiderRealtimeTrackingController.collapseQueueToLatestPerRequest(
              queue);

      expect(collapsed.length, 1);
      expect(collapsed.single, queue.last);
    });

    test('keeps the latest frame per RequestID by Timestamp', () {
      final queue = [
        frame('REQ-1', '2026-05-26T03:00:00.000Z', latitude: 14.1),
        frame('REQ-2', '2026-05-26T03:05:00.000Z', latitude: 14.2),
        frame('REQ-1', '2026-05-26T03:10:00.000Z', latitude: 14.3),
        // Out-of-order: older than the REQ-2 frame above.
        frame('REQ-2', '2026-05-26T03:01:00.000Z', latitude: 14.4),
      ];

      final collapsed =
          RiderRealtimeTrackingController.collapseQueueToLatestPerRequest(
              queue);

      expect(collapsed.length, 2);
      expect(collapsed, contains(queue[1]));
      expect(collapsed, contains(queue[2]));
    });

    test('queue order wins timestamp ties', () {
      final queue = [
        frame('REQ-1', '2026-05-26T03:00:00.000Z', latitude: 14.1),
        frame('REQ-1', '2026-05-26T03:00:00.000Z', latitude: 14.2),
      ];

      final collapsed =
          RiderRealtimeTrackingController.collapseQueueToLatestPerRequest(
              queue);

      expect(collapsed.single, queue[1]);
    });

    test('skips malformed entries and frames without a RequestID', () {
      final queue = [
        'not json at all',
        jsonEncode(['a', 'list']),
        jsonEncode({'Type': 'location_update', 'Latitude': 14.5}),
        frame('REQ-1', '2026-05-26T03:00:00.000Z'),
      ];

      final collapsed =
          RiderRealtimeTrackingController.collapseQueueToLatestPerRequest(
              queue);

      expect(collapsed.single, queue[3]);
    });

    test('returns empty for an empty queue', () {
      expect(
        RiderRealtimeTrackingController.collapseQueueToLatestPerRequest(
            const []),
        isEmpty,
      );
    });
  });
}
