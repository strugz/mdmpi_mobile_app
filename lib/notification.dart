import 'package:get/get.dart';
import 'common/services/abstracts/i_notification_service.dart';

/// Backward-compatible wrapper used by some controllers to trigger
/// a simple local notification. Internally delegates to INotificationService.
class ShowLocalNotification {
  Future<void> showNotification(String title, String body) async {
    final service = Get.find<INotificationService>();
    await service.showSimple(id: 0, title: title, body: body);
  }
}
