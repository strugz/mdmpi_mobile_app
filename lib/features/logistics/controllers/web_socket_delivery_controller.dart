import 'dart:convert';

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/combined_message_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status; // For status codes

import '../models/rider_location_model.dart'; // Assuming this path is correct

class WebSocketDeliveryController extends GetxController {
  static WebSocketDeliveryController get instance => Get.find();

  late WebSocketChannel channel; // Make nullable for better state management
  final message = ''.obs; // For generic messages, if needed
  final isConnected = false.obs;

  // Specific to your delivery use case
  final riderLocations = RxMap<String, LatLng>();
  final riderLocation = Rx<RiderLocationModel>(RiderLocationModel.empty());
  final websocketLocation =
      Rx<WebSocketCombinedMessageModel>(WebSocketCombinedMessageModel.empty());
  final riderEta = RxString('');
  final riderDistance = RxString('');
  final riderInitial = RxString('');
  final riderDestination = RxString('');

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
            'wss://inventory.mdmpi.com.ph/api/ws?apiKey=mdmpiIMSmdmpiIMSmdmpiIMS'),
      );
      channel.stream.listen(
        (data) {
          if (!isConnected.value) {
            isConnected.value = true;
          }
          try {
            final decodedData = jsonDecode(data);
            if (decodedData is Map<String, dynamic> &&
                decodedData['Type'] == 'location_update') {
              riderLocation.value = RiderLocationModel.fromJson(decodedData);
              String riderId = riderLocation
                  .value.requestId; // Assuming requestId is the unique ID
              LatLng newPosition = LatLng(
                  riderLocation.value.latitude, riderLocation.value.longitude);
              riderLocations[riderId] =
                  newPosition; // Updates the map, GetX will react
              riderEta.value = riderLocation.value.eta;
              riderDistance.value = riderLocation.value.distance;
              riderInitial.value = riderLocation.value.riderInitial;
              riderDestination.value = riderLocation.value.client;

              update();
            } else {
              message.value = data.toString();
            }
          } catch (e) {
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
                  print(
                      'WebSocketDelivery: Inner StackTrace - ${innerError.stackTrace}');
                } else {
                  print(
                      'WebSocketDelivery: Inner error (type Error) does not have a separate stack trace object.');
                }
              } else {
                print(
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
            print(
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

  void reconnectWebSocket() async {
    if (isConnected.value && channel.closeCode == null) {
      return;
    }
    channel.sink.close(status.goingAway).catchError((e) {
      print(
          "WebSocketDelivery: Error closing old channel sink during reconnect: $e");
    });
    await Future.delayed(const Duration(seconds: 5));
    connectWebSocket();
  }

  void sendMessage(String msg) {
    if (isConnected.value) {
      channel.sink.add(msg);
    } else {
      print(
          'WebSocketDelivery: Cannot send message. Not connected or channel is null.');
    }
  }

  @override
  void onClose() {
    isConnected.value = false; // Set state before closing
    channel.sink.close(status.goingAway).catchError((e) {
      print(
          "WebSocketDelivery: Error closing channel sink on controller dispose: $e");
    }); // Use a status code like "going away"
    super.onClose();
  }
}
