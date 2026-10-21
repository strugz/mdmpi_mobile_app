import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_notification_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_clock.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/unfinished/unfinished_request.dart';

/// The 08:00 "unfinished requests" notification (Android): every morning,
/// how many of this user's Logistics requests have not reached a final
/// status, by type. A tap opens the Unfinished requests list. The same
/// notification also shows once at the first app open or login of the day
/// ([showNow]; UnfinishedRequestsController keeps it to once a day).
///
/// [sync] runs after every request list load, so the counts follow the
/// phone's data; with nothing unfinished, or the switch off, it cancels.
/// The notification repeats daily, so on a day the app is not opened it
/// shows the counts from the last load; the list reloads when opened.
class BUnfinishedRequestsReminder {
  BUnfinishedRequestsReminder({
    required INotificationService? Function() notifications,
    required bool Function() enabled,
    DateTime Function()? now,
  })  : _notifications = notifications,
        _enabled = enabled,
        _now = now ?? DateTime.now;

  final INotificationService? Function() _notifications;
  final bool Function() _enabled;
  final DateTime Function() _now;

  /// Its own id, next to the upload reminder's (0x20000001) and apart from
  /// the reconciliation reminders' range (bit 30).
  static const int id = 0x20000002;
  static const String payload = 'logistics-unfinished';
  static const String channelId = 'logistics_unfinished_reminders';
  static const String channelName = 'Unfinished request reminders';

  /// The copy shown at once on the first app open or login of the day
  /// ([showNow]); its own id, so it doesn't replace the 08:00 one.
  static const int nowId = 0x20000003;

  /// The hour (Manila) it shows.
  static const int hour = 8;

  /// The next 08:00 Manila after [now]: today's, or tomorrow's once passed.
  static DateTime nextAt(DateTime now) {
    final wall = BReconClock.fromInstant(now);
    final today = DateTime.utc(wall.year, wall.month, wall.day, hour);
    return wall.isBefore(today) ? today : today.add(const Duration(days: 1));
  }

  Future<void>? _running;
  UnfinishedSummary? _queued;

  /// Schedule the daily reminder with [summary]'s counts, or cancel it when
  /// there is nothing unfinished or the switch is off. Calls made while one
  /// runs fold into one more run with the latest summary. Never throws.
  Future<void> sync(UnfinishedSummary summary) async {
    if (_running != null) {
      _queued = summary;
      return _running;
    }
    _running = _run(summary);
    try {
      await _running;
    } finally {
      _running = null;
    }
    final next = _queued;
    _queued = null;
    if (next != null) await sync(next);
  }

  /// Show [summary] at once (Android), for the first app open or login of
  /// the day. Returns true when it was shown; false with nothing unfinished,
  /// the switch off, or no support here. Never throws.
  Future<bool> showNow(UnfinishedSummary summary) async {
    final service = _notifications();
    if (service == null || !service.canSchedule) return false;
    if (summary.total <= 0 || !_enabled()) return false;
    try {
      await service.showNow(
        id: nowId,
        title: summary.title,
        body: summary.body,
        channelId: channelId,
        channelName: channelName,
        payload: payload,
      );
      return true;
    } catch (e) {
      logDebug('BUnfinishedRequestsReminder: showNow failed: $e');
      return false;
    }
  }

  Future<void> _run(UnfinishedSummary summary) async {
    final service = _notifications();
    if (service == null || !service.canSchedule) return;
    try {
      if (summary.total <= 0 || !_enabled()) {
        await service.cancel(id);
        return;
      }
      await service.scheduleAt(
        id: id,
        title: summary.title,
        body: summary.body,
        wallClock: nextAt(_now()),
        channelId: channelId,
        channelName: channelName,
        payload: payload,
        daily: true,
      );
    } catch (e) {
      logDebug('BUnfinishedRequestsReminder: sync failed: $e');
    }
  }
}
