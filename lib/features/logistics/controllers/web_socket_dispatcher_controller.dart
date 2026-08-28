import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/web_socket_backoff.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/web_socket_client_identity.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/combined_message_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/notification_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../models/rider_location_model.dart'; // For status codes
import 'web_socket_connection_config.dart';

class WebSocketDispatcherController extends GetxController {
  static WebSocketDispatcherController get instance => Get.find();

  WebSocketDispatcherController({
    WebSocketChannelFactory? channelFactory,
    WebSocketBackoff? backoff,
    String Function()? clientIdResolver,
  })  : _channelFactory = channelFactory ?? WebSocketConnectionConfig.connect,
        _backoff = backoff ?? WebSocketBackoff(),
        _clientIdResolver = clientIdResolver ?? WebSocketClientIdentity.resolve;

  WebSocketChannel? channel; // Make it nullable
  final WebSocketChannelFactory _channelFactory;
  final WebSocketBackoff _backoff;
  final String Function() _clientIdResolver;
  Timer? _reconnectTimer;
  final message = ''.obs;
  final isConnected = false.obs;
  final connectionState = WebSocketConnectionState.disconnected.obs;
  final connectionAttempted =
      false.obs; // To track if a connection has been tried
  bool _intentionalDisconnect = false;

  @override
  void onInit() {
    super.onInit();
    connectWebSocket();
  }

  Future<void> connectWebSocket() async {
    if (channel != null ||
        connectionState.value == WebSocketConnectionState.connecting ||
        connectionState.value == WebSocketConnectionState.connected) {
      logDebug('WebSocket: Already connected or connecting.');
      return;
    }

    logDebug('WebSocket: Attempting to connect...');
    connectionAttempted.value = true;
    connectionState.value = WebSocketConnectionState.connecting;
    _intentionalDisconnect = false;
    _cancelReconnectTimer();

    try {
      final activeChannel = _channelFactory(WebSocketConnectionConfig.endpointFor(
        clientId: _clientIdResolver(),
        role: 'rider',
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

      logDebug('WebSocket: Connection initiated. Listening to stream...');

      activeChannel.stream.listen(
        (data) {
          logDebug('WebSocket: Data received: $data');
          message.value = data.toString(); // Ensure data is a string
          isConnected.value = true;
          connectionState.value = WebSocketConnectionState.connected;
          // Reset on frames rather than on ready: a connect-then-instant-close
          // loop must keep backing off.
          _backoff.reset();
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
                  logDebug(
                      'WebSocket: Inner StackTrace - ${innerError.stackTrace}');
                } else {
                  logDebug(
                      'WebSocket: Inner error does not have a separate stack trace object, check its string representation above.');
                }
              }
            }
          }
          isConnected.value = false;
          if (identical(channel, activeChannel)) {
            channel = null;
          }
          connectionState.value = WebSocketConnectionState.disconnected;
          if (!_intentionalDisconnect) reconnectWebSocket();
        },
        onDone: () {
          logDebug(
              'WebSocket: Stream done (closed). Status code: ${activeChannel.closeCode}, Reason: ${activeChannel.closeReason}');
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
                'WebSocket: Server closed with 1008 (rate limit). Backing off to max delay.');
            _backoff.escalateToMax();
          } else if (activeChannel.closeCode == status.messageTooBig) {
            logDebug(
                'WebSocket: Server closed with 1009 (message too big) — client bug, payloads should be far under 64 KB.');
          }

          logDebug(
              'WebSocket: Connection closed unexpectedly. Attempting to reconnect...');
          reconnectWebSocket();
        },
        cancelOnError:
            true, // This is good, it cancels the subscription on the first error.
      );
    } catch (e) {
      // This catch block handles errors during the WebSocketChannel.connect() call itself.
      logDebug('WebSocket: Connection failed to establish: $e');
      isConnected.value = false;
      channel = null; // Ensure channel is null if connection fails
      connectionState.value = WebSocketConnectionState.disconnected;
      if (!_intentionalDisconnect) reconnectWebSocket();
    }
  }

  void reconnectWebSocket() {
    if (isConnected.value ||
        connectionState.value == WebSocketConnectionState.reconnecting ||
        connectionState.value == WebSocketConnectionState.connecting ||
        _intentionalDisconnect ||
        isClosed) {
      logDebug('WebSocket: Reconnect called, but already connected.');
      return;
    }
    connectionState.value = WebSocketConnectionState.reconnecting;
    channel?.sink.close(status.goingAway).catchError((e) {
      logDebug('WebSocket: Error closing old channel sink during reconnect: $e');
    });
    channel = null;
    _cancelReconnectTimer();
    final delay = _backoff.nextDelay();
    logDebug(
        'WebSocket: Reconnecting in ${delay.inMilliseconds} ms (attempt ${_backoff.attempt}).');
    _reconnectTimer = Timer(delay, () {
      if (_intentionalDisconnect || isClosed || isConnected.value) return;
      connectWebSocket(); // Call the main connect method
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
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
        // Do NOT blind-fire the raw payload after a delay: it would bypass the
        // envelope wrapper above, and RiderRealtimeTrackingController already
        // queues the frame for a flush once the connection is back.
        logDebug(
            'WebSocket: Message not sent because connection is not active. Reconnecting.');
        reconnectWebSocket();
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
    _intentionalDisconnect = true;
    _cancelReconnectTimer();
    connectionState.value = WebSocketConnectionState.closing;
    channel?.sink.close(status.goingAway); // Use a status code if appropriate
    isConnected.value = false; // Explicitly set as not connected
    channel = null; // Clean up
    connectionState.value = WebSocketConnectionState.disconnected;
    super.onClose();
  }
}
