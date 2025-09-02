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
  final websocketLocation = Rx<WebSocketCombinedMessageModel>(WebSocketCombinedMessageModel.empty());
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

      print('WebSocketDelivery: Connection initiated. Listening to stream...');

      channel.stream.listen(
            (data) {
          if (!isConnected.value) {
            // If it was marked disconnected by a quick error/done cycle but data flows
            isConnected.value = true;
          }
          // print('WebSocketDelivery: Data received: $data');
          try {
            final decodedData = jsonDecode(data);
            if (decodedData is Map<String, dynamic> && decodedData['Type'] == 'location_update') {
              riderLocation.value = RiderLocationModel.fromJson(decodedData);
              String riderId = riderLocation.value.requestId; // Assuming requestId is the unique ID
              LatLng newPosition = LatLng(riderLocation.value.latitude, riderLocation.value.longitude);
              riderLocations[riderId] = newPosition; // Updates the map, GetX will react
              riderEta.value = riderLocation.value.eta;
              riderDistance.value = riderLocation.value.distance;
              riderInitial.value = riderLocation.value.riderInitial;
              riderDestination.value = riderLocation.value.client;

              update(); // Not strictly necessary for Rx variables, but Get.find().update() might be used elsewhere
            } else {
              // Handle other message types or log if unexpected
              print('WebSocketDelivery: Received non-location_update message or unknown type: $data');
              message.value = data.toString(); // Store generic messages if needed
            }
          } catch (e) {
            print('WebSocketDelivery: Error processing received data: $e. Raw data: $data');
            message.value = data.toString(); // Store raw message on processing error
          }
        },
        onError: (error) {
          print('WebSocketDelivery: Error in stream: $error');
          // Check if the error is a WebSocketChannelException for more details
          if (error is WebSocketChannelException) {
            print('WebSocketDelivery: Channel Exception - ${error.message}');
            // Access the inner error and its stack trace if it exists
            if (error.inner != null) {
              print('WebSocketDelivery: Inner error: ${error.inner}');
              // Try to get the stack trace of the inner error.
              if (error.inner is Error) { // Check if inner is an Error type
                final innerError = error.inner as Error;
                if (innerError.stackTrace != null) {
                  print('WebSocketDelivery: Inner StackTrace - ${innerError.stackTrace}');
                } else {
                  print('WebSocketDelivery: Inner error (type Error) does not have a separate stack trace object.');
                }
              } else {
                print('WebSocketDelivery: Inner error is not of type Error, printing its string representation.');
              }
            }
          }
          isConnected.value = false;
          // Consider a brief delay before reconnecting to avoid tight loops on persistent errors.
          // reconnectWebSocket();
        },
        onDone: () {
          print('WebSocketDelivery: Stream done (closed). Status code: ${channel.closeCode}, Reason: ${channel.closeReason}');
          isConnected.value = false;
          // If the closure was unexpected, you might want to attempt reconnection.
          if (channel.closeCode != status.normalClosure &&
              channel.closeCode != status.goingAway && /* add other normal codes if any */
              channel.closeCode != null /* Ensure there's a close code to check */) {
            print('WebSocketDelivery: Connection closed unexpectedly. Attempting to reconnect...');
            reconnectWebSocket(); // Your existing reconnect logic
          } else if (channel.closeCode == null && isConnected.value) {
            // This might happen if the stream is cancelled before a close frame is received
            print('WebSocketDelivery: Stream done, but no close code. Might be an abrupt closure or client-side cancellation. Ensuring isConnected is false.');
          }
          // No need to nullify channel here if reconnectWebSocket is called,
          // as connectWebSocket will reassign it.
          // If not reconnecting, then: channel = null;
        },
        cancelOnError: true, // Good: cancels the subscription on the first error.
      );
    } catch (e) {
      // This catch block handles errors during the WebSocketChannel.connect() call itself.
      print('WebSocketDelivery: Connection failed to establish: $e');
      isConnected.value = false;
      // Consider retrying connection here after a delay
      reconnectWebSocket();
    }
  }

  void reconnectWebSocket() async {
    if (isConnected.value && channel.closeCode == null) {
      // If isConnected is true, and channel exists, and there's no close code,
      // it might mean the connection is actually active or a reconnect is already in progress.
      // However, onDone usually sets isConnected to false. This is a safeguard.
      print('WebSocketDelivery: Reconnect called, but seems connected or previous attempt ongoing.');
      return;
    }
    print('WebSocketDelivery: Attempting to reconnect in 5 seconds...');
    // Ensure any existing channel's sink is closed before creating a new one
    // This is important to free up resources and signal the server.
    channel.sink.close(status.goingAway).catchError((e) {
      print("WebSocketDelivery: Error closing old channel sink during reconnect: $e");
    });
      await Future.delayed(const Duration(seconds: 5));
    connectWebSocket(); // Call the main connect method
  }

  void sendMessage(String msg) {
    if (isConnected.value) {
      print('WebSocketDelivery: Sending message: $msg');
      channel.sink.add(msg);
    } else {
      print('WebSocketDelivery: Cannot send message. Not connected or channel is null.');
    }
  }

  @override
  void onClose() { // GetX lifecycle method
    print('WebSocketDelivery: Controller closing. Closing WebSocket sink.');
    isConnected.value = false; // Set state before closing
    channel.sink.close(status.goingAway).catchError((e) {
      print("WebSocketDelivery: Error closing channel sink on controller dispose: $e");
    }); // Use a status code like "going away"
    super.onClose();
  }
}