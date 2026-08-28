import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  closing,
}

typedef WebSocketChannelFactory = WebSocketChannel Function(Uri uri);

class WebSocketConnectionConfig {
  WebSocketConnectionConfig._();

  static const String _fallbackApiKey = 'mdmpiIMSmdmpiIMSmdmpiIMS';

  static String get _apiKey {
    if (!dotenv.isInitialized) return _fallbackApiKey;
    final value = dotenv.env['WS_API_KEY']?.trim();
    return value == null || value.isEmpty ? _fallbackApiKey : value;
  }

  /// Builds the full endpoint URI including the identity the server logs.
  /// [role] is `'rider'`, `'watcher'`, or null (server logs "unspecified").
  /// A [clientId] that sanitizes to empty is omitted (server falls back to
  /// "anon").
  static Uri endpointFor({required String clientId, String? role}) {
    final sanitized = sanitizeClientId(clientId);
    return BApiEnvironment.webSocketBaseUri.replace(queryParameters: {
      'apiKey': _apiKey,
      if (sanitized.isNotEmpty) 'clientId': sanitized,
      if (role != null) 'role': role,
    });
  }

  /// Mirrors the server's identity rule: keep `[A-Za-z0-9_.:@-]`, max 64
  /// chars. The server replaces anything else with "anon", so filtering here
  /// keeps the declared identity usable in its logs.
  static String sanitizeClientId(String raw) {
    final filtered = raw.trim().replaceAll(RegExp(r'[^A-Za-z0-9_.:@-]'), '');
    return filtered.length > 64 ? filtered.substring(0, 64) : filtered;
  }

  static WebSocketChannel connect(Uri uri) => WebSocketChannel.connect(uri);
}
