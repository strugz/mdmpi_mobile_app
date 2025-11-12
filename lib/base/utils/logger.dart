import 'package:flutter/foundation.dart';

/// Simple logging helper to centralize debug logging and avoid `print`.
/// Use `logDebug(...)` for development-time logging. This uses `debugPrint`
/// which is safe for large messages and disabled in release builds.
void logDebug(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

