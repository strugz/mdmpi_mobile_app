import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_connection_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_delivery_controller.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

class FakeWebSocketChannel implements WebSocketChannel {
  FakeWebSocketChannel({Future<void>? ready}) : ready = ready ?? Future.value();

  final StreamController<dynamic> _streamController =
      StreamController<dynamic>();
  final FakeWebSocketSink _sink = FakeWebSocketSink();

  @override
  final Future<void> ready;

  @override
  String? get protocol => null;

  @override
  int? closeCode;

  @override
  String? closeReason;

  @override
  Stream get stream => _streamController.stream;

  @override
  WebSocketSink get sink => _sink;

  int get closeCount => _sink.closeCount;

  List<dynamic> get sentMessages => _sink.sentMessages;

  void addIncoming(dynamic data) => _streamController.add(data);

  void addError(Object error) => _streamController.addError(error);

  Future<void> closeIncoming([int? code, String? reason]) {
    closeCode = code;
    closeReason = reason;
    return _streamController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWebSocketSink implements WebSocketSink {
  final List<dynamic> sentMessages = [];
  int closeCount = 0;
  int? lastCloseCode;
  String? lastCloseReason;
  final Completer<void> _done = Completer<void>();

  @override
  Future<void> get done => _done.future;

  @override
  void add(dynamic event) {
    sentMessages.add(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (!_done.isCompleted) _done.completeError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream stream) async {
    await for (final event in stream) {
      add(event);
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closeCount += 1;
    lastCloseCode = closeCode;
    lastCloseReason = closeReason;
    if (!_done.isCompleted) _done.complete();
  }
}

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

    test('duplicate connect calls only create one active channel', () async {
      var createCount = 0;
      final fakeChannel = FakeWebSocketChannel();
      controller = WebSocketDeliveryController(
        channelFactory: (_) {
          createCount += 1;
          return fakeChannel;
        },
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
      );

      await controller.connectWebSocket();
      controller.onClose();
      await fakeChannel.closeIncoming(status.goingAway);
      await Future<void>.delayed(WebSocketConnectionConfig.reconnectDelay +
          const Duration(milliseconds: 20));

      expect(fakeChannel.closeCount, 1);
      expect(createCount, 1);
      expect(controller.isConnected.value, false);
      expect(controller.connectionState.value,
          WebSocketConnectionState.disconnected);
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
      );

      await controller.connectWebSocket();
      channels.first.addError(Exception('network dropped'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.connectionState.value,
          WebSocketConnectionState.reconnecting);
      controller.reconnectWebSocket();

      await Future<void>.delayed(WebSocketConnectionConfig.reconnectDelay +
          const Duration(milliseconds: 50));

      expect(channels.length, 2);
      expect(
          controller.connectionState.value, WebSocketConnectionState.connected);
    });
  });
}
