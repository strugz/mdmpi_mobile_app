import 'dart:math';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_connection_config.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Resolves the `clientId` declared to the WebSocket server. Identity is
/// log-only on the server (claimed, not proven), so this only needs to be
/// stable enough to tell devices apart in server logs.
class WebSocketClientIdentity {
  WebSocketClientIdentity._();

  static const String storageKey = 'web_socket_client_id';

  /// The signed-in user's id when available, else a generated id persisted in
  /// GetStorage so the same device keeps the same identity across sessions.
  ///
  /// Resolve at connect time, not construction time: the notification socket
  /// connects before [UserController] is registered (and before login), so
  /// early connections use the fallback and post-login reconnects upgrade to
  /// the real user id.
  static String resolve({GetStorage? storage}) {
    if (Get.isRegistered<UserController>()) {
      final userId = WebSocketConnectionConfig.sanitizeClientId(
        UserController.instance.user.value.id,
      );
      if (userId.isNotEmpty) return userId;
    }

    final generated = 'anon.${DateTime.now().millisecondsSinceEpoch}.'
        '${Random.secure().nextInt(900000) + 100000}';

    // GetStorage may not be initialized yet (very early startup, unit tests);
    // identity is log-only, so a non-persisted id is an acceptable fallback.
    try {
      final box = storage ?? GetStorage();
      final stored = box.read(storageKey);
      if (stored is String) {
        final sanitized = WebSocketConnectionConfig.sanitizeClientId(stored);
        if (sanitized.isNotEmpty) return sanitized;
      }

      box.write(storageKey, generated);
    } catch (_) {
      // Fall through to the unpersisted id.
    }

    return generated;
  }
}
