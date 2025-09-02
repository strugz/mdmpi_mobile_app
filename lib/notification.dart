import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ShowLocalNotification {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void showNotification(String title, String body) async {
    var android = AndroidNotificationDetails('chat_notifications', 'Notifications',
        priority: Priority.high, importance: Importance.max);

    var platform = NotificationDetails(android: android);

    await flutterLocalNotificationsPlugin.show(0, title, body, platform,
        payload: 'Welcome to the Local Notification demo ');
  }
}
