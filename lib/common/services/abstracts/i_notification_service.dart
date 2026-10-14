/// A notification waiting to be shown at a later time.
typedef PendingNotification = ({int id, String? payload});

/// Contract for local notifications used across the app.
abstract class INotificationService {
  /// Initializes platform-specific channels and handlers.
  /// Optionally provide [onSelectNotification] to handle tap payloads.
  Future<void> init({void Function(String? payload)? onSelectNotification});

  /// Shows a simple notification with title/body and optional payload.
  Future<void> showSimple({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  /// Whether [scheduleAt] can work on this platform (Android). Elsewhere it
  /// does nothing, and callers rely on what the app shows on screen.
  bool get canSchedule;

  /// Shows [title]/[body] at [wallClock] in [timeZone] (an IANA name), read
  /// as plain wall-clock fields whatever the phone's own zone. Inexact, so it
  /// may land a few minutes late, and needs no exact-alarm permission.
  /// Replaces any notification scheduled under [id]. With [daily], it comes
  /// back at the same time every day until cancelled. Returns false when it
  /// was not scheduled (no support here, or the time has passed).
  Future<bool> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime wallClock,
    required String channelId,
    required String channelName,
    String timeZone = 'Asia/Manila',
    String? payload,
    bool daily = false,
  });

  /// Cancels the notification scheduled or shown under [id].
  Future<void> cancel(int id);

  /// The notifications scheduled and not yet shown.
  Future<List<PendingNotification>> pending();

  /// The payload of the notification whose tap launched the app, if it was
  /// launched that way.
  Future<String?> launchPayload();

  /// Cancels all scheduled and displayed notifications.
  Future<void> cancelAll();
}
