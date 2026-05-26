import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:web_socket_channel/io.dart';

import '../../../notification.dart';
import '../models/combined_message_model.dart';
import '../models/notification_model.dart';
import '../models/rider_location_model.dart';

typedef NotificationCallback = void Function(NotificationModel notification);

class WebSocketNotificationController extends GetxController {
  // Provides a static getter to access the instance of WebSocketNotificationController.
  static WebSocketNotificationController get instance => Get.find();

  final message = ''.obs;
  final isConnected = false.obs;
  final connectionAttempted = false.obs;
  final isSender = false.obs;

  IOWebSocketChannel? _channel;
  Timer? _reconnectTimer;
  final String _webSocketUrl =
      'wss://inventory.mdmpi.com.ph/api2/ws?apiKey=mdmpiIMSmdmpiIMSmdmpiIMS'; // Replace with your actual URL

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
  void connect() {
    if (isConnected.value || _channel != null) {
      return;
    }
    connectionAttempted.value = true;
    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(_webSocketUrl));
      isConnected.value =
      true; // Optimistically set to true, listen stream will confirm

      _channel!.stream.listen(
            (data) {
          message.value = data.toString();
          isConnected.value = true; // Ensure isConnected is true on data
          _cancelReconnectTimer(); // Cancel timer if connection is successful

          // 1. Decode the JSON string
          // Assuming 'data' is a JSON string. If it's bytes, you might need  utf8.decode(data) first.
          final Map<String, dynamic> jsonData = jsonDecode(data);

          // 2. Pass the decoded Map to your fromJson factory method
          final combinedMessage = NotificationModel.fromJson(jsonData);
          // Process the message and show a notification
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
          _channel = null;
          _scheduleReconnect();
        },
        onError: (error) {
          isConnected.value = false;
          _channel = null;
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      isConnected.value = false;
      _channel = null;
      _scheduleReconnect();
    }
  }

  // Schedules an attempt to reconnect to the WebSocket server after a delay.
  // This is typically called when the connection is lost or fails.
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) _reconnectTimer!.cancel();
    // Don't attempt to reconnect if the controller is already closed
    if (isClosed) return;
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!isConnected.value && !isClosed) {
        // Check again before connecting
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
        connect(); // Attempt to establish a new connection.
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
    _cancelReconnectTimer();
    _channel?.sink.close();
    _channel = null;
    isConnected.value = false;
  }

  // Called when the controller is closed. It ensures the WebSocket connection is disconnected.
  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
