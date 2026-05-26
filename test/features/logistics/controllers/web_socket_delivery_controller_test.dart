import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_delivery_controller.dart';

void main() {
  group('WebSocketDeliveryController', () {
    late WebSocketDeliveryController controller;

    setUp(() {
      controller = WebSocketDeliveryController();
    });

    test('wrapped Message=Location updates rider state by RequestID', () {
      controller.handleIncomingData(jsonEncode({
        'Message': 'Location',
        'LocationUpdate': {
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
        },
        'NotificationUpdate': {'Title': '', 'Body': ''},
      }));

      expect(controller.riderLocations.length, 1);
      expect(controller.riderLocations.containsKey('2026050038'), true);
      expect(
          controller.riderLocationUpdates['2026050038']?.riderInitial, 'JCA');
      expect(controller.riderLocationUpdates['2026050038']?.client,
          'Chinese General Hospital And Medical Center');
    });

    test('second update with same RequestID replaces existing marker state',
        () {
      controller.handleIncomingData(jsonEncode({
        'Message': 'Location',
        'LocationUpdate': {
          'Type': 'location_update',
          'RequestID': '2026050038',
          'Latitude': 14.5480786,
          'Longitude': 121.0145692,
          'Timestamp': '2026-05-26T03:17:16.749Z',
        },
        'NotificationUpdate': {'Title': '', 'Body': ''},
      }));
      controller.handleIncomingData(jsonEncode({
        'Message': 'Location',
        'LocationUpdate': {
          'Type': 'location_update',
          'RequestID': '2026050038',
          'Latitude': 14.55,
          'Longitude': 121.02,
          'Timestamp': '2026-05-26T03:18:16.749Z',
        },
        'NotificationUpdate': {'Title': '', 'Body': ''},
      }));

      expect(controller.riderLocations.length, 1);
      expect(controller.riderLocations['2026050038']?.latitude, 14.55);
      expect(controller.riderLocations['2026050038']?.longitude, 121.02);
    });

    test('direct Type=location_update payload still works', () {
      controller.handleIncomingData(jsonEncode({
        'Type': 'location_update',
        'RequestID': 'REQ-DIRECT',
        'Latitude': 14.6,
        'Longitude': 121.1,
      }));

      expect(controller.riderLocations.length, 1);
      expect(controller.riderLocations.containsKey('REQ-DIRECT'), true);
    });

    test('same RequestID receives deterministic marker color', () {
      final first = WebSocketDeliveryController.colorForRequestId('2026050038');
      final second =
          WebSocketDeliveryController.colorForRequestId('2026050038');

      expect(first, second);
    });

    test('same RequestID receives deterministic marker asset index', () {
      final first = WebSocketDeliveryController.dispatchMarkerIndexForRequestId(
        '2026050038',
        10,
      );
      final second =
          WebSocketDeliveryController.dispatchMarkerIndexForRequestId(
        '2026050038',
        10,
      );

      expect(first, second);
      expect(first, inInclusiveRange(0, 9));
    });
  });
}
