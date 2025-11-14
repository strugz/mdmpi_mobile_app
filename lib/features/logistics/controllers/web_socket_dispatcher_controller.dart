import 'dart:convert';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/combined_message_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/notification_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../models/rider_location_model.dart'; // For status codes

class WebSocketDispatcherController extends GetxController {
  static WebSocketDispatcherController get instance => Get.find();

  WebSocketChannel? channel; // Make it nullable
  final message = ''.obs;
  final isConnected = false.obs;
  final connectionAttempted =
      false.obs; // To track if a connection has been tried

  @override
  void onInit() {
    super.onInit();
    connectWebSocket();
  }

  void connectWebSocket() async {
    if (isConnected.value) {
      logDebug('WebSocket: Already connected or connecting.');
      return;
    }

    logDebug('WebSocket: Attempting to connect...');
    connectionAttempted.value = true;
    // We are about to connect, so optimistically set isConnected to true.
    // The onError or onDone will set it to false if connection fails or closes.
    // However, for more accurate UI, you might want a "connecting" state.
    // For now, let's keep it simple:
    isConnected.value = true; // Assume connection will succeed initially

    try {
      channel = WebSocketChannel.connect(
        Uri.parse(
            'wss://inventory.mdmpi.com.ph/api/ws?apiKey=mdmpiIMSmdmpiIMSmdmpiIMS'), // Your actual URL
      );

      logDebug('WebSocket: Connection initiated. Listening to stream...');

      channel!.stream.listen(
        (data) {
          logDebug('WebSocket: Data received: $data');
          message.value = data.toString(); // Ensure data is a string
          if (!isConnected.value) {
            // If it was marked as disconnected by onDone/onError
            isConnected.value =
                true; // Mark as connected since we received data
          }
        },
        onError: (error) {
          logDebug('WebSocket: Error in stream: $error');
          // Check if the error is a WebSocketChannelException for more details
          if (error is WebSocketChannelException) {
            logDebug('WebSocket: Channel Exception - ${error.message}');
            // Access the inner error and its stack trace if it exists
            if (error.inner != null) {
              logDebug('WebSocket: Inner error: ${error.inner}');
              // Try to get the stack trace of the inner error.
              // Note: Not all error objects will have a stackTrace property,
              // or it might be null if not captured.
              // You might need to cast error.inner to a more specific Error type
              // if you know what it might be, to safely access stackTrace.
              // However, printing error.inner itself often includes stack trace info.
              // For a more robust way if error.inner is an Error type:
              if (error.inner is Error) {
                final innerError = error.inner as Error;
                if (innerError.stackTrace != null) {
                  logDebug('WebSocket: Inner StackTrace - ${innerError.stackTrace}');
                } else {
                  logDebug('WebSocket: Inner error does not have a separate stack trace object, check its string representation above.');
                }
              }
            }
          }
          isConnected.value = false;
          // Optionally, you might want to nullify the channel here or in onDone
          channel = null;
          // Attempt to reconnect if desired
          reconnectWebSocket();
        },
        onDone: () {
          logDebug(
              'WebSocket: Stream done (closed). Status code: ${channel?.closeCode}, Reason: ${channel?.closeReason}');
          isConnected.value = false;
          // channel = null; // Good practice to nullify the channel when it's definitively closed
          // If the closure was unexpected, you might want to attempt reconnection.
          // For example, if closeCode is not a normal closure (like 1000 or 1001)
          if (channel?.closeCode != status.normalClosure &&
              channel?.closeCode != status.goingAway) {
            logDebug(
                'WebSocket: Connection closed unexpectedly. Attempting to reconnect...');
            // Be careful with immediate reconnection to avoid tight loops if the server is down.
            // Consider a delay, as you have in your reconnectWebSocket method.
            // reconnectWebSocket();
          }
        },
        cancelOnError:
            true, // This is good, it cancels the subscription on the first error.
      );
    } catch (e) {
      // This catch block handles errors during the WebSocketChannel.connect() call itself.
      logDebug('WebSocket: Connection failed to establish: $e');
      isConnected.value = false;
      channel = null; // Ensure channel is null if connection fails
    }
  }

  void reconnectWebSocket() async {
    if (isConnected.value) {
      logDebug('WebSocket: Reconnect called, but already connected.');
      return;
    }
    logDebug('WebSocket: Attempting to reconnect in 5 seconds...');
    await Future.delayed(Duration(seconds: 5));
    connectWebSocket(); // Call the main connect method
  }

  void sendMessage(String msg) {
    try {
      if (channel != null && isConnected.value) {
        WebSocketCombinedMessageModel combinedMessage =
            WebSocketCombinedMessageModel(
          message: 'Location',
          locationUpdate: RiderLocationModel.fromJson(
            jsonDecode(msg),
          ),
          notificationUpdate: NotificationModel.empty(),
        );

        String message = jsonEncode(
          WebSocketCombinedMessageModel.fromJson(
            combinedMessage.toJson(),
          ),
        );

        logDebug(jsonEncode(combinedMessage));
        channel!.sink.add(message);
      } else {
        connectWebSocket(); // This might try to connect even if already attempting
        Future.delayed(
          Duration(seconds: 2),
          () {
            // Wait a bit for connection
            if (channel != null && isConnected.value) {
              channel!.sink.add(msg);
            } else {
              logDebug(
                  'WebSocket: Still not connected after attempting reconnect. Message not sent.');
            }
          },
        );

        // Option 2: Just log and don't send, or notify user
        logDebug(
            'WebSocket: Message "$msg" not sent because connection is not active.');
        // You might want to queue the message and send it once reconnected.
      }
    } catch (e) {
      logDebug('WebSocket: Error sending message: $e');
    }
  }

  @override
  void onClose() {
    // GetX lifecycle method
    logDebug('WebSocket: Controller closing. Closing sink.');
    // It's important to close the sink to inform the server.
    // The stream's onDone will be called as a result.
    channel?.sink.close(status.goingAway); // Use a status code if appropriate
    isConnected.value = false; // Explicitly set as not connected
    channel = null; // Clean up
    super.onClose();
  }
}
