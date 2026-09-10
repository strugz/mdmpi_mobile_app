import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/web_socket_backoff.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/web_socket_client_identity.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/combined_message_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status; // For status codes

import '../models/rider_location_model.dart'; // Assuming this path is correct
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

import 'web_socket_connection_config.dart';

class WebSocketDeliveryController extends GetxController {
  static WebSocketDeliveryController get instance => Get.find();

  WebSocketDeliveryController({
    WebSocketChannelFactory? channelFactory,
    WebSocketBackoff? backoff,
    String Function()? clientIdResolver,
  })  : _channelFactory = channelFactory ?? WebSocketConnectionConfig.connect,
        _backoff = backoff ?? WebSocketBackoff(),
        _clientIdResolver = clientIdResolver ?? WebSocketClientIdentity.resolve;

  WebSocketChannel? channel;
  final WebSocketChannelFactory _channelFactory;
  final WebSocketBackoff _backoff;
  final String Function() _clientIdResolver;
  Timer? _reconnectTimer;
  final message = ''.obs; // For generic messages, if needed
  final isConnected = false.obs;
  final connectionState = WebSocketConnectionState.disconnected.obs;
  bool _intentionalDisconnect = false;

  // Specific to your delivery use case
  final riderLocations = RxMap<String, LatLng>();
  final riderLocationUpdates = RxMap<String, RiderLocationModel>();
  final riderMarkerColors = RxMap<String, Color>();
  final riderLocation = Rx<RiderLocationModel>(RiderLocationModel.empty());
  final websocketLocation =
      Rx<WebSocketCombinedMessageModel>(WebSocketCombinedMessageModel.empty());
  final riderEta = RxString('');
  final riderDistance = RxString('');
  final riderInitial = RxString('');
  final riderDestination = RxString('');

  static const List<Color> dispatchMarkerPalette = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFDD835),
    Color(0xFF8E24AA),
    Color(0xFFFB8C00),
    Color(0xFF00ACC1),
    Color(0xFF3949AB),
    Color(0xFFD81B60),
    Color(0xFF6D4C41),
  ];

  @override
  void onInit() {
    super.onInit();
    connectWebSocket();
  }

  Future<void> connectWebSocket() async {
    if (channel != null ||
        connectionState.value == WebSocketConnectionState.connecting ||
        connectionState.value == WebSocketConnectionState.connected) {
      return;
    }

    connectionState.value = WebSocketConnectionState.connecting;
    _intentionalDisconnect = false;
    _cancelReconnectTimer();
    try {
      final activeChannel = _channelFactory(WebSocketConnectionConfig.endpointFor(
        clientId: _clientIdResolver(),
        role: 'watcher',
      ));
      channel = activeChannel;
      await activeChannel.ready;
      if (_intentionalDisconnect ||
          connectionState.value == WebSocketConnectionState.closing) {
        await activeChannel.sink.close(status.goingAway);
        return;
      }

      isConnected.value = true;
      connectionState.value = WebSocketConnectionState.connected;
      activeChannel.stream.listen(
        (data) {
          isConnected.value = true;
          connectionState.value = WebSocketConnectionState.connected;
          // Reset on frames rather than on ready: a connect-then-instant-close
          // loop must keep backing off.
          _backoff.reset();
          try {
            handleIncomingData(data);
          } catch (e) {
            logDebug('WebSocketDelivery: Failed to handle message: $e');
            message.value = data.toString();
          }
        },
        onError: (error) {
          if (error is WebSocketChannelException) {
            if (error.inner != null) {
              if (error.inner is Error) {
                // Check if inner is an Error type
                final innerError = error.inner as Error;
                if (innerError.stackTrace != null) {
                  logDebug(
                      'WebSocketDelivery: Inner StackTrace - ${innerError.stackTrace}');
                } else {
                  logDebug(
                      'WebSocketDelivery: Inner error (type Error) does not have a separate stack trace object.');
                }
              } else {
                logDebug(
                    'WebSocketDelivery: Inner error is not of type Error, printing its string representation.');
              }
            }
          }
          isConnected.value = false;
          if (identical(channel, activeChannel)) {
            channel = null;
          }
          connectionState.value = WebSocketConnectionState.disconnected;
          // Consider a brief delay before reconnecting to avoid tight loops on persistent errors.
          if (!_intentionalDisconnect) reconnectWebSocket();
        },
        onDone: () {
          isConnected.value = false;
          if (identical(channel, activeChannel)) {
            channel = null;
          }
          connectionState.value = WebSocketConnectionState.disconnected;
          if (_intentionalDisconnect ||
              activeChannel.closeCode == status.normalClosure ||
              activeChannel.closeCode == status.goingAway) {
            return;
          }

          if (activeChannel.closeCode == status.policyViolation) {
            // Server rate limit (>20 msg/s sustained). Retrying quickly would
            // only earn another 1008, so jump straight to the max delay.
            logDebug(
                'WebSocketDelivery: Server closed with 1008 (rate limit). Backing off to max delay.');
            _backoff.escalateToMax();
          } else if (activeChannel.closeCode == status.messageTooBig) {
            logDebug(
                'WebSocketDelivery: Server closed with 1009 (message too big) — client bug, payloads should be far under 64 KB.');
          } else if (activeChannel.closeCode == null) {
            // Abrupt closure with no close frame (dead cellular link etc.) —
            // still worth reconnecting.
            logDebug(
                'WebSocketDelivery: Stream done with no close code (abrupt closure). Reconnecting.');
          }

          reconnectWebSocket();
        },
        cancelOnError:
            true, // Good: cancels the subscription on the first error.
      );
    } catch (e) {
      logDebug('WebSocketDelivery: Connection failed: $e');
      isConnected.value = false;
      channel = null;
      connectionState.value = WebSocketConnectionState.disconnected;
      if (!_intentionalDisconnect) reconnectWebSocket();
    }
  }

  void handleIncomingData(dynamic data) {
    final decodedData = data is String ? jsonDecode(data) : data;
    if (decodedData is! Map) {
      message.value = data.toString();
      return;
    }

    final payload = Map<String, dynamic>.from(decodedData);
    final locationJson = _extractLocationPayload(payload);
    if (locationJson == null) {
      message.value = data.toString();
      return;
    }

    final location = RiderLocationModel.fromJson(locationJson);
    if (location.requestId.isEmpty) {
      logDebug('WebSocketDelivery: Ignored rider location without RequestID.');
      return;
    }

    final requestId = location.requestId;

    // A terminal frame (the courier dropped off / cancelled / stopped
    // tracking) removes the car instead of moving it. Handled before the
    // coordinate check so a courier without a GPS fix can still retire it.
    if (isTerminalStatus(location.status)) {
      retireRequest(requestId, at: location.timestamp);
      update();
      return;
    }

    if (location.latitude == 0.0 || location.longitude == 0.0) {
      logDebug(
          'WebSocketDelivery: Ignored invalid rider location for RequestID "$requestId".');
      return;
    }

    // The server replays the cached latest envelope per RequestID on connect
    // and the courier's offline queue replays old frames: neither may bring a
    // retired car back. Only a frame newer than the retirement (the same
    // request genuinely dispatched again) re-adds it.
    final retiredAt = _retiredAt[requestId];
    if (retiredAt != null) {
      if (!location.timestamp.isAfter(retiredAt)) {
        logDebug(
            'WebSocketDelivery: Ignored frame for retired RequestID $requestId.');
        return;
      }
      _retiredAt.remove(requestId);
    }

    // Reconnect bursts can also arrive out of order — never let an older
    // frame rewind a marker. Equal timestamps re-apply (idempotent duplicates).
    // Caveat: frames with a missing/unparsable Timestamp get DateTime.now()
    // from RiderLocationModel, so they always count as newest.
    final existing = riderLocationUpdates[requestId];
    if (existing != null && location.timestamp.isBefore(existing.timestamp)) {
      logDebug(
          'WebSocketDelivery: Ignored stale frame for RequestID $requestId '
          '(incoming ${location.timestamp.toIso8601String()} < stored ${existing.timestamp.toIso8601String()}).');
      return;
    }

    final newPosition = LatLng(location.latitude, location.longitude);

    riderLocation.value = location;
    riderLocations[requestId] = newPosition;
    riderLocationUpdates[requestId] = location;
    riderMarkerColors[requestId] = colorForRequestId(requestId);
    riderEta.value = location.eta;
    riderDistance.value = location.distance;
    riderInitial.value = location.riderInitial;
    riderDestination.value = location.client;

    if (payload['Message'] == 'Location') {
      websocketLocation.value = WebSocketCombinedMessageModel.fromJson({
        'Message': 'Location',
        'LocationUpdate': location.toJson(),
        'NotificationUpdate': payload['NotificationUpdate'] ?? {},
      });
    }

    logDebug(
        'WebSocketDelivery: Updated rider marker for RequestID $requestId at ${location.latitude}, ${location.longitude}.');
    update();
  }

  // ── Marker lifecycle ────────────────────────────────────────────────────
  //
  // Markers are keyed per RequestID and used to live forever: once a request
  // had sent one frame its car stayed on the map through Done Delivery and
  // the courier's next dispatch — so one courier showed up as two cars
  // (TODO item 17). Three things now retire a car: a terminal frame from the
  // courier, an age cut-off, and — at render time — a newer car for the same
  // rider.

  /// Statuses the courier sends when a request stops moving.
  static const Set<String> terminalStatuses = {
    'completed',
    'delivered',
    'cancelled',
    'tracking_stopped',
  };

  /// How long a car may sit without a fresh frame before it is dropped
  /// (a crashed courier phone must not leave a ghost car all day).
  static const Duration staleMarkerAge = Duration(minutes: 30);

  final Map<String, DateTime> _retiredAt = {};

  /// RequestIDs whose car has been retired and not re-dispatched since.
  Set<String> get retiredRequestIds => Set.unmodifiable(_retiredAt.keys);

  static bool isTerminalStatus(String status) =>
      terminalStatuses.contains(status.trim().toLowerCase());

  /// Removes the request's car and remembers when, so replayed frames older
  /// than [at] cannot resurrect it.
  void retireRequest(String requestId, {DateTime? at}) {
    riderLocations.remove(requestId);
    riderLocationUpdates.remove(requestId);
    riderMarkerColors.remove(requestId);
    _retiredAt[requestId] = at ?? DateTime.now();
    logDebug('WebSocketDelivery: Retired rider marker for RequestID $requestId.');
  }

  /// Drops cars whose last frame is older than [maxAge].
  void pruneStale({DateTime? now, Duration maxAge = staleMarkerAge}) {
    final cutoff = (now ?? DateTime.now()).subtract(maxAge);
    final stale = riderLocationUpdates.entries
        .where((e) => e.value.timestamp.isBefore(cutoff))
        .map((e) => e.key)
        .toList();
    for (final id in stale) {
      retireRequest(id, at: riderLocationUpdates[id]?.timestamp);
    }
  }

  /// The RequestIDs worth drawing: fresh within [maxAge], and — when several
  /// requests share the same rider — only the newest one, since one courier
  /// cannot be two cars.
  static Set<String> visibleRequestIds(
    Map<String, RiderLocationModel> updates, {
    required DateTime now,
    Duration maxAge = staleMarkerAge,
  }) {
    final cutoff = now.subtract(maxAge);
    final newestByRider = <String, MapEntry<String, RiderLocationModel>>{};
    final visible = <String>{};

    for (final entry in updates.entries) {
      if (entry.value.timestamp.isBefore(cutoff)) continue;
      final rider = entry.value.riderInitial.trim().toLowerCase();
      if (rider.isEmpty) {
        visible.add(entry.key);
        continue;
      }
      final current = newestByRider[rider];
      if (current == null ||
          entry.value.timestamp.isAfter(current.value.timestamp)) {
        newestByRider[rider] = entry;
      }
    }

    visible.addAll(newestByRider.values.map((e) => e.key));
    return visible;
  }

  Map<String, dynamic>? _extractLocationPayload(Map<String, dynamic> payload) {
    if (payload['Message'] == 'Location' && payload['LocationUpdate'] is Map) {
      return Map<String, dynamic>.from(payload['LocationUpdate'] as Map);
    }

    if (payload['Type'] == 'location_update') {
      return payload;
    }

    return null;
  }

  static Color colorForRequestId(String requestId) {
    return dispatchMarkerPalette[dispatchMarkerIndexForRequestId(
        requestId, dispatchMarkerPalette.length)];
  }

  static int dispatchMarkerIndexForRequestId(String requestId, int itemCount) {
    if (itemCount <= 0) return 0;

    var hash = 0;
    for (final codeUnit in requestId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }

    return hash % itemCount;
  }

  void reconnectWebSocket() {
    if (isConnected.value ||
        connectionState.value == WebSocketConnectionState.reconnecting ||
        connectionState.value == WebSocketConnectionState.connecting ||
        _intentionalDisconnect ||
        isClosed) {
      return;
    }
    connectionState.value = WebSocketConnectionState.reconnecting;
    channel?.sink.close(status.goingAway).catchError((e) {
      logDebug(
          "WebSocketDelivery: Error closing old channel sink during reconnect: $e");
    });
    channel = null;
    _cancelReconnectTimer();
    final delay = _backoff.nextDelay();
    logDebug(
        'WebSocketDelivery: Reconnecting in ${delay.inMilliseconds} ms (attempt ${_backoff.attempt}).');
    _reconnectTimer = Timer(delay, () {
      if (_intentionalDisconnect || isClosed || isConnected.value) return;
      connectWebSocket();
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void sendMessage(String msg) {
    if (isConnected.value && channel != null) {
      channel!.sink.add(msg);
    } else {
      logDebug(
          'WebSocketDelivery: Cannot send message. Not connected or channel is null.');
    }
  }

  @override
  void onClose() {
    _intentionalDisconnect = true;
    _cancelReconnectTimer();
    connectionState.value = WebSocketConnectionState.closing;
    isConnected.value = false; // Set state before closing
    channel?.sink.close(status.goingAway).catchError((e) {
      logDebug(
          "WebSocketDelivery: Error closing channel sink on controller dispose: $e");
    }); // Use a status code like "going away"
    channel = null;
    connectionState.value = WebSocketConnectionState.disconnected;
    super.onClose();
  }
}
