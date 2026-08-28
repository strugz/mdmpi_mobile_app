import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_connection_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_dispatcher_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/web_socket_backoff.dart';
import 'package:web_socket_channel/status.dart' as status;

import 'fake_web_socket_channel.dart';

WebSocketBackoff shortBackoff() => WebSocketBackoff(
      initialDelay: const Duration(milliseconds: 5),
      maxDelay: const Duration(milliseconds: 40),
      random: Random(1),
    );

Map<String, dynamic> flatLocationPayload() => {
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
    };

void main() {
  group('WebSocketDispatcherController', () {
    test('connects with role=rider, a clientId, and the apiKey', () async {
      Uri? capturedUri;
      final controller = WebSocketDispatcherController(
        channelFactory: (uri) {
          capturedUri = uri;
          return FakeWebSocketChannel();
        },
        backoff: shortBackoff(),
        clientIdResolver: () => 'test-rider',
      );

      await controller.connectWebSocket();

      expect(capturedUri, isNotNull);
      expect(capturedUri!.queryParameters['role'], 'rider');
      expect(capturedUri!.queryParameters['clientId'], 'test-rider');
      expect(capturedUri!.queryParameters['apiKey'], isNotEmpty);
    });

    test('sendMessage wraps the flat payload into a Location envelope',
        () async {
      final fakeChannel = FakeWebSocketChannel();
      final controller = WebSocketDispatcherController(
        channelFactory: (_) => fakeChannel,
        backoff: shortBackoff(),
        clientIdResolver: () => 'test-rider',
      );

      await controller.connectWebSocket();
      controller.sendMessage(jsonEncode(flatLocationPayload()));

      expect(fakeChannel.sentMessages.length, 1);
      final sent =
          jsonDecode(fakeChannel.sentMessages.single as String) as Map;
      expect(sent['Message'], 'Location');
      expect(sent['LocationUpdate']['RequestID'], '2026050038');
    });

    test('sendMessage while disconnected does not blind-fire a raw payload',
        () async {
      final channels = <FakeWebSocketChannel>[];
      final controller = WebSocketDispatcherController(
        channelFactory: (_) {
          final channel = FakeWebSocketChannel();
          channels.add(channel);
          return channel;
        },
        backoff: shortBackoff(),
        clientIdResolver: () => 'test-rider',
      );

      controller.sendMessage(jsonEncode(flatLocationPayload()));
      // Allow the reconnect timer to fire and the connection to establish.
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(channels, isNotEmpty);
      for (final channel in channels) {
        expect(channel.sentMessages, isEmpty,
            reason: 'queued frames are resent by the tracking controller, '
                'never blind-fired by the dispatcher');
      }
    });

    test('1008 (policy violation) escalates the backoff and reconnects',
        () async {
      var createCount = 0;
      final backoff = shortBackoff();
      final controller = WebSocketDispatcherController(
        channelFactory: (_) {
          createCount += 1;
          return FakeWebSocketChannel();
        },
        backoff: backoff,
        clientIdResolver: () => 'test-rider',
      );

      await controller.connectWebSocket();
      final channel = controller.channel as FakeWebSocketChannel;
      await channel.closeIncoming(status.policyViolation);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(backoff.attempt, greaterThanOrEqualTo(3));

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(createCount, 2);
    });

    test('onClose cancels a pending reconnect', () async {
      var createCount = 0;
      final controller = WebSocketDispatcherController(
        channelFactory: (_) {
          createCount += 1;
          return FakeWebSocketChannel();
        },
        backoff: shortBackoff(),
        clientIdResolver: () => 'test-rider',
      );

      await controller.connectWebSocket();
      final channel = controller.channel as FakeWebSocketChannel;
      await channel.closeIncoming(); // abrupt closure schedules a reconnect
      controller.onClose();
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(createCount, 1);
      expect(controller.connectionState.value,
          WebSocketConnectionState.disconnected);
    });
  });
}
