import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_connection_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/web_socket_backoff.dart';
import 'package:web_socket_channel/status.dart' as status;

import 'fake_web_socket_channel.dart';

WebSocketBackoff shortBackoff() => WebSocketBackoff(
      initialDelay: const Duration(milliseconds: 5),
      maxDelay: const Duration(milliseconds: 40),
      random: Random(1),
    );

Map<String, dynamic> locationEnvelope({
  String requestId = '2026050038',
  double latitude = 14.5480786,
  double longitude = 121.0145692,
  String timestamp = '2026-05-26T03:17:16.749Z',
}) {
  return {
    'Message': 'Location',
    'LocationUpdate': {
      'Type': 'location_update',
      'RequestID': requestId,
      'RiderId': '',
      'Latitude': latitude,
      'Longitude': longitude,
      'Timestamp': timestamp,
      'Status': 'en_route',
      'RiderInitial': 'JCA',
      'ETA': '27 mins',
      'Distance': '10.8 km',
      'Client': 'Chinese General Hospital And Medical Center',
    },
    'NotificationUpdate': {'Title': '', 'Body': ''},
  };
}

void main() {
  group('WebSocketDeliveryController', () {
    late WebSocketDeliveryController controller;

    setUp(() {
      controller = WebSocketDeliveryController(backoff: shortBackoff());
    });

    test('wrapped Message=Location updates rider state by RequestID', () {
      controller.handleIncomingData(jsonEncode(locationEnvelope()));

      expect(controller.riderLocations.length, 1);
      expect(controller.riderLocations.containsKey('2026050038'), true);
      expect(
          controller.riderLocationUpdates['2026050038']?.riderInitial, 'JCA');
      expect(controller.riderLocationUpdates['2026050038']?.client,
          'Chinese General Hospital And Medical Center');
    });

    test('second update with same RequestID replaces existing marker state',
        () {
      controller.handleIncomingData(jsonEncode(locationEnvelope()));
      controller.handleIncomingData(jsonEncode(locationEnvelope(
        latitude: 14.55,
        longitude: 121.02,
        timestamp: '2026-05-26T03:18:16.749Z',
      )));

      expect(controller.riderLocations.length, 1);
      expect(controller.riderLocations['2026050038']?.latitude, 14.55);
      expect(controller.riderLocations['2026050038']?.longitude, 121.02);
    });

    test('stale frame (older Timestamp) is ignored per RequestID', () {
      controller.handleIncomingData(jsonEncode(locationEnvelope(
        latitude: 14.55,
        longitude: 121.02,
        timestamp: '2026-05-26T03:18:16.749Z',
      )));
      // Replay/out-of-order frame from before the stored one.
      controller.handleIncomingData(jsonEncode(locationEnvelope(
        latitude: 14.50,
        longitude: 121.00,
        timestamp: '2026-05-26T03:17:16.749Z',
      )));

      expect(controller.riderLocations['2026050038']?.latitude, 14.55);
      expect(controller.riderLocations['2026050038']?.longitude, 121.02);
    });

    test('equal-Timestamp duplicate frame re-applies harmlessly', () {
      controller.handleIncomingData(jsonEncode(locationEnvelope()));
      controller.handleIncomingData(jsonEncode(locationEnvelope()));

      expect(controller.riderLocations.length, 1);
      expect(controller.riderLocations['2026050038']?.latitude, 14.5480786);
    });

    test('stale flat legacy frame is also ignored', () {
      controller.handleIncomingData(jsonEncode({
        'Type': 'location_update',
        'RequestID': 'REQ-DIRECT',
        'Latitude': 14.6,
        'Longitude': 121.1,
        'Timestamp': '2026-05-26T03:18:00.000Z',
      }));
      controller.handleIncomingData(jsonEncode({
        'Type': 'location_update',
        'RequestID': 'REQ-DIRECT',
        'Latitude': 14.5,
        'Longitude': 121.0,
        'Timestamp': '2026-05-26T03:17:00.000Z',
      }));

      expect(controller.riderLocations['REQ-DIRECT']?.latitude, 14.6);
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

    test('connects with role=watcher, a clientId, and the apiKey', () async {
      Uri? capturedUri;
      final fakeChannel = FakeWebSocketChannel();
      controller = WebSocketDeliveryController(
        channelFactory: (uri) {
          capturedUri = uri;
          return fakeChannel;
        },
        backoff: shortBackoff(),
        clientIdResolver: () => 'test-client',
      );

      await controller.connectWebSocket();

      expect(capturedUri, isNotNull);
      expect(capturedUri!.queryParameters['role'], 'watcher');
      expect(capturedUri!.queryParameters['clientId'], 'test-client');
      expect(capturedUri!.queryParameters['apiKey'], isNotEmpty);
    });

    test('duplicate connect calls only create one active channel', () async {
      var createCount = 0;
      final fakeChannel = FakeWebSocketChannel();
      controller = WebSocketDeliveryController(
        channelFactory: (_) {
          createCount += 1;
          return fakeChannel;
        },
        backoff: shortBackoff(),
        clientIdResolver: () => 'test-client',
      );

      await Future.wait([
        controller.connectWebSocket(),
        controller.connectWebSocket(),
      ]);

      expect(createCount, 1);
      expect(
          controller.connectionState.value, WebSocketConnectionState.connected);
      expect(controller.isConnected.value, true);
    });

    test('intentional onClose closes once and disables reconnect', () async {
      var createCount = 0;
      final fakeChannel = FakeWebSocketChannel();
      controller = WebSocketDeliveryController(
        channelFactory: (_) {
          createCount += 1;
          return fakeChannel;
        },
        backoff: shortBackoff(),
        clientIdResolver: () => 'test-client',
      );

      await controller.connectWebSocket();
      controller.onClose();
      await fakeChannel.closeIncoming(status.goingAway);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(fakeChannel.closeCount, 1);
      expect(createCount, 1);
      expect(controller.isConnected.value, false);
      expect(controller.connectionState.value,
          WebSocketConnectionState.disconnected);
    });

    test('normal closure (1000) does not reconnect', () async {
      var createCount = 0;
      controller = WebSocketDeliveryController(
        channelFactory: (_) {
          createCount += 1;
          return FakeWebSocketChannel();
        },
        backoff: shortBackoff(),
        clientIdResolver: () => 'test-client',
      );

      await controller.connectWebSocket();
      final channel = controller.channel as FakeWebSocketChannel;
      await channel.closeIncoming(status.normalClosure);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(createCount, 1);
      expect(controller.connectionState.value,
          WebSocketConnectionState.disconnected);
    });

    test('abrupt closure with no close code reconnects', () async {
      var createCount = 0;
      controller = WebSocketDeliveryController(
        channelFactory: (_) {
          createCount += 1;
          return FakeWebSocketChannel();
        },
        backoff: shortBackoff(),
        clientIdResolver: () => 'test-client',
      );

      await controller.connectWebSocket();
      final channel = controller.channel as FakeWebSocketChannel;
      await channel.closeIncoming();
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(createCount, 2);
      expect(
          controller.connectionState.value, WebSocketConnectionState.connected);
    });

    test('1009 (message too big) still reconnects', () async {
      var createCount = 0;
      controller = WebSocketDeliveryController(
        channelFactory: (_) {
          createCount += 1;
          return FakeWebSocketChannel();
        },
        backoff: shortBackoff(),
        clientIdResolver: () => 'test-client',
      );

      await controller.connectWebSocket();
      final channel = controller.channel as FakeWebSocketChannel;
      await channel.closeIncoming(status.messageTooBig);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(createCount, 2);
    });

    test('1008 (policy violation) escalates the backoff to max and reconnects',
        () async {
      var createCount = 0;
      final backoff = shortBackoff();
      controller = WebSocketDeliveryController(
        channelFactory: (_) {
          createCount += 1;
          return FakeWebSocketChannel();
        },
        backoff: backoff,
        clientIdResolver: () => 'test-client',
      );

      await controller.connectWebSocket();
      final channel = controller.channel as FakeWebSocketChannel;
      await channel.closeIncoming(status.policyViolation);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // escalateToMax jumps to the max band before nextDelay is consumed.
      expect(backoff.attempt, greaterThanOrEqualTo(3));

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(createCount, 2);
    });

    test('receiving a frame resets the backoff sequence', () async {
      final backoff = shortBackoff();
      controller = WebSocketDeliveryController(
        channelFactory: (_) => FakeWebSocketChannel(),
        backoff: backoff,
        clientIdResolver: () => 'test-client',
      );

      await controller.connectWebSocket();
      backoff.escalateToMax();
      final channel = controller.channel as FakeWebSocketChannel;
      channel.addIncoming(jsonEncode(locationEnvelope()));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(backoff.attempt, 0);
    });

    test('stream error schedules only one reconnect while reconnecting',
        () async {
      final channels = <FakeWebSocketChannel>[];
      controller = WebSocketDeliveryController(
        channelFactory: (_) {
          final channel = FakeWebSocketChannel();
          channels.add(channel);
          return channel;
        },
        backoff: shortBackoff(),
        clientIdResolver: () => 'test-client',
      );

      await controller.connectWebSocket();
      channels.first.addError(Exception('network dropped'));
      await Future<void>.delayed(const Duration(milliseconds: 2));

      expect(controller.connectionState.value,
          WebSocketConnectionState.reconnecting);
      controller.reconnectWebSocket();

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(channels.length, 2);
      expect(
          controller.connectionState.value, WebSocketConnectionState.connected);
    });
  });
}
