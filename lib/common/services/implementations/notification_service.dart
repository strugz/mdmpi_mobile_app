import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/abstracts/i_notification_service.dart';

/// Notification service backed by flutter_local_notifications.
class NotificationService implements INotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> init({void Function(String? payload)? onSelectNotification}) async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      onSelectNotification?.call(response.payload);
    });

    _initialized = true;
  }

  @override
  Future<void> showSimple({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await init();
    }
    const android = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: android);
    await _plugin.show(id, title, body, details, payload: payload);
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

