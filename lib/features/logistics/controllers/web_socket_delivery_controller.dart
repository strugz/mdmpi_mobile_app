import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/combined_message_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status; // For status codes

import '../models/rider_location_model.dart'; // Assuming this path is correct
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

class WebSocketDeliveryController extends GetxController {
  static WebSocketDeliveryController get instance => Get.find();

  late WebSocketChannel channel; // Make nullable for better state management
  final message = ''.obs; // For generic messages, if needed
  final isConnected = false.obs;

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

  void connectWebSocket() async {
    isConnected.value = true;
    try {
      channel = WebSocketChannel.connect(
        Uri.parse(
            'wss://inventory.mdmpi.com.ph/api2/ws?apiKey=mdmpiIMSmdmpiIMSmdmpiIMS'),
      );
      channel.stream.listen(
        (data) {
          if (!isConnected.value) {
            isConnected.value = true;
          }
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
          // Consider a brief delay before reconnecting to avoid tight loops on persistent errors.
          // reconnectWebSocket();
        },
        onDone: () {
          isConnected.value = false;
          // If the closure was unexpected, you might want to attempt reconnection.
          if (channel.closeCode != status.normalClosure &&
              channel.closeCode !=
                  status.goingAway && /* add other normal codes if any */
              channel.closeCode !=
                  null /* Ensure there's a close code to check */) {
            reconnectWebSocket(); // Your existing reconnect logic
          } else if (channel.closeCode == null && isConnected.value) {
            // This might happen if the stream is cancelled before a close frame is received
            logDebug(
                'WebSocketDelivery: Stream done, but no close code. Might be an abrupt closure or client-side cancellation. Ensuring isConnected is false.');
          }
          // No need to nullify channel here if reconnectWebSocket is called,
          // as connectWebSocket will reassign it.
          // If not reconnecting, then: channel = null;
        },
        cancelOnError:
            true, // Good: cancels the subscription on the first error.
      );
    } catch (e) {
      isConnected.value = false;
      reconnectWebSocket();
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
    if (location.requestId.isEmpty ||
        location.latitude == 0.0 ||
        location.longitude == 0.0) {
      logDebug(
          'WebSocketDelivery: Ignored invalid rider location for RequestID "${location.requestId}".');
      return;
    }

    final requestId = location.requestId;
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

  void reconnectWebSocket() async {
    if (isConnected.value && channel.closeCode == null) {
      return;
    }
    channel.sink.close(status.goingAway).catchError((e) {
      logDebug(
          "WebSocketDelivery: Error closing old channel sink during reconnect: $e");
    });
    await Future.delayed(const Duration(seconds: 5));
    connectWebSocket();
  }

  void sendMessage(String msg) {
    if (isConnected.value) {
      channel.sink.add(msg);
    } else {
      logDebug(
          'WebSocketDelivery: Cannot send message. Not connected or channel is null.');
    }
  }

  @override
  void onClose() {
    isConnected.value = false; // Set state before closing
    channel.sink.close(status.goingAway).catchError((e) {
      logDebug(
          "WebSocketDelivery: Error closing channel sink on controller dispose: $e");
    }); // Use a status code like "going away"
    super.onClose();
  }
}
