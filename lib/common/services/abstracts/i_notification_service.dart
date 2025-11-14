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

  /// Cancels all scheduled and displayed notifications.
  Future<void> cancelAll();
}

