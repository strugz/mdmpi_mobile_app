import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/web_socket_backoff.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/rider_location_model.dart';

WebSocketBackoff shortBackoff() => WebSocketBackoff(
      initialDelay: const Duration(milliseconds: 5),
      maxDelay: const Duration(milliseconds: 40),
      random: Random(1),
    );

String frame({
  required String requestId,
  required String timestamp,
  String status = 'en_route',
  String rider = 'BPT',
  double latitude = 14.55,
  double longitude = 121.02,
}) =>
    jsonEncode({
      'Type': 'location_update',
      'RequestID': requestId,
      'Latitude': latitude,
      'Longitude': longitude,
      'Timestamp': timestamp,
      'Status': status,
      'RiderInitial': rider,
      'ETA': '',
      'Distance': '',
      'Client': 'Eton City Square',
    });

RiderLocationModel update({
  required String requestId,
  required DateTime at,
  String rider = 'BPT',
}) =>
    RiderLocationModel(
      type: 'location_update',
      requestId: requestId,
      latitude: 14.55,
      longitude: 121.02,
      timestamp: at,
      status: 'en_route',
      riderInitial: rider,
      eta: '',
      distance: '',
      client: '',
    );

void main() {
  group('WebSocketDeliveryController marker lifecycle (TODO 17)', () {
    late WebSocketDeliveryController controller;

    setUp(() {
      controller = WebSocketDeliveryController(backoff: shortBackoff());
    });

    test('a terminal frame removes the car and remembers the retirement', () {
      controller.handleIncomingData(
          frame(requestId: 'A', timestamp: '2026-09-10T07:00:00.000Z'));
      expect(controller.riderLocations.containsKey('A'), isTrue);

      controller.handleIncomingData(frame(
          requestId: 'A',
          timestamp: '2026-09-10T07:30:00.000Z',
          status: 'completed'));

      expect(controller.riderLocations.containsKey('A'), isFalse);
      expect(controller.riderLocationUpdates.containsKey('A'), isFalse);
      expect(controller.riderMarkerColors.containsKey('A'), isFalse);
      expect(controller.retiredRequestIds, contains('A'));
    });

    test('terminal frame works even without a GPS fix (0,0)', () {
      controller.handleIncomingData(
          frame(requestId: 'A', timestamp: '2026-09-10T07:00:00.000Z'));
      controller.handleIncomingData(frame(
          requestId: 'A',
          timestamp: '2026-09-10T07:30:00.000Z',
          status: 'tracking_stopped',
          latitude: 0,
          longitude: 0));

      expect(controller.riderLocations.containsKey('A'), isFalse);
    });

    test('a replayed older en_route frame cannot resurrect a retired car', () {
      controller.handleIncomingData(frame(
          requestId: 'A',
          timestamp: '2026-09-10T07:30:00.000Z',
          status: 'completed'));
      // Server replay / offline queue: older than the retirement.
      controller.handleIncomingData(
          frame(requestId: 'A', timestamp: '2026-09-10T07:10:00.000Z'));

      expect(controller.riderLocations.containsKey('A'), isFalse);
    });

    test('a genuinely newer frame re-adds the car (re-dispatched request)', () {
      controller.handleIncomingData(frame(
          requestId: 'A',
          timestamp: '2026-09-10T07:30:00.000Z',
          status: 'completed'));
      controller.handleIncomingData(
          frame(requestId: 'A', timestamp: '2026-09-10T08:00:00.000Z'));

      expect(controller.riderLocations.containsKey('A'), isTrue);
      expect(controller.retiredRequestIds, isNot(contains('A')));
    });

    test('isTerminalStatus is case/whitespace tolerant', () {
      expect(WebSocketDeliveryController.isTerminalStatus(' Completed '), isTrue);
      expect(WebSocketDeliveryController.isTerminalStatus('en_route'), isFalse);
    });

    test('pruneStale drops cars without a fresh frame', () {
      controller.handleIncomingData(
          frame(requestId: 'OLD', timestamp: '2026-09-10T06:00:00.000Z'));
      controller.handleIncomingData(
          frame(requestId: 'NEW', timestamp: '2026-09-10T07:55:00.000Z'));

      controller.pruneStale(now: DateTime.utc(2026, 9, 10, 8, 0));

      expect(controller.riderLocations.keys, ['NEW']);
    });
  });

  group('WebSocketDeliveryController.visibleRequestIds', () {
    final now = DateTime.utc(2026, 9, 10, 8, 0);

    test('one car per rider: the screenshot case keeps only the newest', () {
      final updates = {
        'A': update(requestId: 'A', at: DateTime.utc(2026, 9, 10, 7, 40)),
        'B': update(requestId: 'B', at: DateTime.utc(2026, 9, 10, 7, 58)),
      };

      expect(WebSocketDeliveryController.visibleRequestIds(updates, now: now),
          {'B'});
    });

    test('different riders both stay visible', () {
      final updates = {
        'A': update(requestId: 'A', at: DateTime.utc(2026, 9, 10, 7, 50)),
        'B': update(
            requestId: 'B', at: DateTime.utc(2026, 9, 10, 7, 58), rider: 'JDC'),
      };

      expect(WebSocketDeliveryController.visibleRequestIds(updates, now: now),
          {'A', 'B'});
    });

    test('rider match ignores case and whitespace', () {
      final updates = {
        'A': update(
            requestId: 'A', at: DateTime.utc(2026, 9, 10, 7, 50), rider: 'bpt '),
        'B': update(requestId: 'B', at: DateTime.utc(2026, 9, 10, 7, 58)),
      };

      expect(WebSocketDeliveryController.visibleRequestIds(updates, now: now),
          {'B'});
    });

    test('frames older than maxAge are not drawn', () {
      final updates = {
        'A': update(requestId: 'A', at: DateTime.utc(2026, 9, 10, 7, 0)),
      };

      expect(WebSocketDeliveryController.visibleRequestIds(updates, now: now),
          isEmpty);
      expect(
          WebSocketDeliveryController.visibleRequestIds(updates,
              now: now, maxAge: const Duration(hours: 2)),
          {'A'});
    });

    test('unknown rider initial never de-dups', () {
      final updates = {
        'A': update(
            requestId: 'A', at: DateTime.utc(2026, 9, 10, 7, 50), rider: ''),
        'B': update(
            requestId: 'B', at: DateTime.utc(2026, 9, 10, 7, 58), rider: ''),
      };

      expect(WebSocketDeliveryController.visibleRequestIds(updates, now: now),
          {'A', 'B'});
    });
  });
}
