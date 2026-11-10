import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_notification_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_clock.dart';

/// The end-of-day nudge: while anything is waiting in the upload queue, a
/// phone notification at 17:00 Manila, every day until it is uploaded or
/// discarded. Work that stays on the phone is work the office never sees.
///
/// [sync] runs whenever the queue's size changes ([SyncManager]); with
/// nothing waiting it cancels the reminder. The text does not carry a count,
/// since the notification repeats on days the app is not opened and a number
/// would go stale. Tapping it opens Upload Collections.
class BUploadReminder {
  BUploadReminder({
    required INotificationService? Function() notifications,
    DateTime Function()? now,
  })  : _notifications = notifications,
        _now = now ?? DateTime.now;

  final INotificationService? Function() _notifications;
  final DateTime Function() _now;

  /// Its own id, apart from the small ids of one-off notifications and the
  /// reconciliation reminders' range (bit 30).
  static const int id = 0x20000001;
  static const String payload = 'collection-upload';
  static const String channelId = 'collection_upload_reminders';
  static const String channelName = 'Upload reminders';

  /// The hour (Manila) it shows.
  static const int hour = 17;

  /// The next 17:00 Manila after [now]: today's, or tomorrow's once passed.
  static DateTime nextAt(DateTime now) {
    final wall = BReconClock.fromInstant(now);
    final today = DateTime.utc(wall.year, wall.month, wall.day, hour);
    return wall.isBefore(today) ? today : today.add(const Duration(days: 1));
  }

  /// Schedule the daily reminder while [pending] > 0; cancel it at 0.
  /// Never throws.
  Future<void> sync(int pending) async {
    final service = _notifications();
    if (service == null || !service.canSchedule) return;
    try {
      if (pending <= 0) {
        await service.cancel(id);
        return;
      }
      await service.scheduleAt(
        id: id,
        title: 'Upload your collections',
        body: 'Some of your work is not uploaded yet. Open Upload '
            'Collections and tap Upload All.',
        wallClock: nextAt(_now()),
        channelId: channelId,
        channelName: channelName,
        payload: payload,
        daily: true,
      );
    } catch (e) {
      logDebug('BUploadReminder: sync failed: $e');
    }
  }
}
