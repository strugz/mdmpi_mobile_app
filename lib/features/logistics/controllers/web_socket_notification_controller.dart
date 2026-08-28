import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../notification.dart';
import '../helpers/web_socket_backoff.dart';
import '../helpers/web_socket_client_identity.dart';
import '../models/combined_message_model.dart';
import '../models/notification_model.dart';
import '../models/rider_location_model.dart';
import 'web_socket_connection_config.dart';

typedef NotificationCallback = void Function(NotificationModel notification);

class WebSocketNotificationController extends GetxController {
  // Provides a static getter to access the instance of WebSocketNotificationController.
  static WebSocketNotificationController get instance => Get.find();

  WebSocketNotificationController({
    WebSocketChannelFactory? channelFactory,
    WebSocketBackoff? backoff,
    String Function()? clientIdResolver,
  })  : _channelFactory = channelFactory ?? WebSocketConnectionConfig.connect,
        _backoff = backoff ?? WebSocketBackoff(),
        _clientIdResolver = clientIdResolver ?? WebSocketClientIdentity.resolve;

  final message = ''.obs;
  final isConnected = false.obs;
  final connectionAttempted = false.obs;
  final isSender = false.obs;
  final connectionState = WebSocketConnectionState.disconnected.obs;

  final WebSocketChannelFactory _channelFactory;
  final WebSocketBackoff _backoff;
  final String Function() _clientIdResolver;
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _intentionalDisconnect = false;

  NotificationCallback? _onNotificationReceived;

  // Registers a callback function to be invoked when a new notification is received.
  void registerNotificationListener(NotificationCallback callback) {
    _onNotificationReceived = callback;
  }

  // Called when the controller is initialized. It initiates the WebSocket connection.
  @override
  void onInit() {
    super.onInit();
    connect();
  }

  // Establishes a WebSocket connection to the specified URL.
  // It handles connection success, incoming messages, errors, and disconnections.
  Future<void> connect() async {
    if (_channel != null ||
        connectionState.value == WebSocketConnectionState.connecting ||
        connectionState.value == WebSocketConnectionState.connected) {
      return;
    }

    _intentionalDisconnect = false;
    _cancelReconnectTimer();
    connectionAttempted.value = true;
    connectionState.value = WebSocketConnectionState.connecting;
    try {
      // No role: this socket both sends and receives notifications, so the
      // server logs it as "unspecified".
      final channel = _channelFactory(WebSocketConnectionConfig.endpointFor(
        clientId: _clientIdResolver(),
      ));
      _channel = channel;
      await channel.ready;
      if (_intentionalDisconnect ||
          connectionState.value == WebSocketConnectionState.closing) {
        await channel.sink.close(status.goingAway);
        return;
      }

      isConnected.value = true;
      connectionState.value = WebSocketConnectionState.connected;

      channel.stream.listen(
        (data) {
          message.value = data.toString();
          isConnected.value = true;
          connectionState.value = WebSocketConnectionState.connected;
          _cancelReconnectTimer();
          // Reset on frames rather than on ready: a connect-then-instant-close
          // loop must keep backing off.
          _backoff.reset();

          final Map<String, dynamic> jsonData = jsonDecode(data);
          final combinedMessage = NotificationModel.fromJson(jsonData);
          if (!message.value.contains('location_update')) {
            if (isSender.value != true) {
              ShowLocalNotification().showNotification(
                  combinedMessage.title, combinedMessage.body);
              _onNotificationReceived?.call(combinedMessage);
            }
          }

          isSender.value = false;
        },
        onDone: () {
          isConnected.value = false;
          if (identical(_channel, channel)) {
            _channel = null;
          }
          connectionState.value = WebSocketConnectionState.disconnected;
          if (_intentionalDisconnect ||
              channel.closeCode == status.normalClosure ||
              channel.closeCode == status.goingAway) {
            return;
          }

          if (channel.closeCode == status.policyViolation) {
            // Server rate limit (>20 msg/s sustained). Retrying quickly would
            // only earn another 1008, so jump straight to the max delay.
            logDebug(
                'WebSocketNotification: Server closed with 1008 (rate limit). Backing off to max delay.');
            _backoff.escalateToMax();
          } else if (channel.closeCode == status.messageTooBig) {
            logDebug(
                'WebSocketNotification: Server closed with 1009 (message too big) — client bug, payloads should be far under 64 KB.');
          }

          _scheduleReconnect();
        },
        onError: (error) {
          logDebug('WebSocketNotification: Stream error: $error');
          isConnected.value = false;
          if (identical(_channel, channel)) {
            _channel = null;
          }
          connectionState.value = WebSocketConnectionState.disconnected;
          if (!_intentionalDisconnect) _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      logDebug('WebSocketNotification: Connection failed: $e');
      isConnected.value = false;
      _channel = null;
      connectionState.value = WebSocketConnectionState.disconnected;
      _scheduleReconnect();
    }
  }

  // Schedules an attempt to reconnect to the WebSocket server after a delay.
  // This is typically called when the connection is lost or fails.
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) _reconnectTimer!.cancel();
    if (isClosed || _intentionalDisconnect) return;
    connectionState.value = WebSocketConnectionState.reconnecting;
    final delay = _backoff.nextDelay();
    logDebug(
        'WebSocketNotification: Reconnecting in ${delay.inMilliseconds} ms (attempt ${_backoff.attempt}).');
    _reconnectTimer = Timer(delay, () {
      if (!isConnected.value && !isClosed) {
        connect();
      }
    });
  }

  // Cancels any pending reconnect timer.
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // Sends a raw string message through the WebSocket connection.
  void sendMessage(String data) {
    if (isConnected.value && _channel != null) {
      _channel!.sink.add(data);
    } else {
      BLoaders.errorSnackBar(title: 'Notification', message: 'Not Send.');
    }
  }

  // Sends a structured notification message through the WebSocket.
  // It handles cases where the connection might not be active and attempts to reconnect.
  void sendNotificationMessage(NotificationModel notification) {
    if (_channel != null && isConnected.value) {
      isSender.value = true;
      WebSocketCombinedMessageModel combinedMessage =
          WebSocketCombinedMessageModel(
        message: 'Notification', // Or a relevant type for notifications
        notificationUpdate: notification,
        // Assuming locationUpdate can be null or you have an empty state for it
        locationUpdate:
            RiderLocationModel.empty(), // Or null, depending on your model
      );

      // It's generally more direct to encode the object you just created
      String messageString = jsonEncode(combinedMessage.toJson());
      _channel!.sink.add(messageString);
    } else {
      // Attempt to connect if not already connected.
      if (!isConnected.value) {
        connect();
      }

      // Schedule a retry after a short delay to allow the connection to establish.
      // It's important to handle the case where the connection might still fail.
      Future.delayed(const Duration(seconds: 10), () {
        // Increased delay slightly
        if (_channel != null && isConnected.value) {
          // It's crucial to call the original method to resend the *same* notification
          sendNotificationMessage(notification);
        } else {
          BLoaders.errorSnackBar(
              title: 'Notification', message: 'Notification message not sent.');
          // Here you might want to implement a more robust retry mechanism
          // or inform the user that the message could not be sent.
        }
      });
    }
  }

  // Disconnects from the WebSocket server and cancels any reconnect attempts.
  void disconnect() {
    BLoaders.warningSnackBar(
        title: 'Notification', message: 'Notification Disconnected.');
    _intentionalDisconnect = true;
    connectionState.value = WebSocketConnectionState.closing;
    _cancelReconnectTimer();
    _channel?.sink.close(status.goingAway);
    _channel = null;
    isConnected.value = false;
    connectionState.value = WebSocketConnectionState.disconnected;
  }

  // Called when the controller is closed. It ensures the WebSocket connection is disconnected.
  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
