import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resolves API hosts while preserving the application's backend boundary.
///
/// [liveBaseUrl] is used by `/api3/*` and other live integrations. Only
/// `/api4/*` requests may use the platform-specific production-testing host.
class BApiEnvironment {
  BApiEnvironment._();

  static const String _productionFallback = 'https://inventory.mdmpi.com.ph';

  static String get liveBaseUrl => _read('API_URL') ?? _productionFallback;

  static String get api4BaseUrl => resolveApi4BaseUrl(
        allowLocalOverrides: kDebugMode,
      );

  @visibleForTesting
  static String resolveApi4BaseUrl({required bool allowLocalOverrides}) {
    final platformOverride = allowLocalOverrides
        ? Platform.isAndroid
            ? _read('API4_URL_ANDROID')
            : Platform.isWindows
                ? _read('API4_URL_WINDOWS')
                : null
        : null;

    return platformOverride ?? _read('API4_URL') ?? liveBaseUrl;
  }

  static Uri api4Uri(String path) => Uri.parse(
        '${_withoutTrailingSlash(api4BaseUrl)}${_withLeadingSlash(path)}',
      );

  /// Builds a URI against the live host for endpoints unavailable locally.
  static Uri liveUri(String path) => Uri.parse(
        '${_withoutTrailingSlash(liveBaseUrl)}${_withLeadingSlash(path)}',
      );

  /// WebSocket endpoint base (scheme/host/path only — query params are added
  /// by the caller). The path is always `/api2/ws`; debug builds swap the host
  /// for the api4 one when the api4 chain (`API4_URL_ANDROID` /
  /// `API4_URL_WINDOWS` / `API4_URL` in `.env`) resolves to a host other than
  /// the live one. Release builds always use the live host.
  static Uri get webSocketBaseUri => resolveWebSocketBaseUri(
        allowLocalOverrides: kDebugMode,
      );

  @visibleForTesting
  static Uri resolveWebSocketBaseUri({required bool allowLocalOverrides}) {
    if (allowLocalOverrides) {
      final api4Base = resolveApi4BaseUrl(allowLocalOverrides: true);
      if (api4Base != liveBaseUrl) {
        return toWebSocketUri(api4Base, '/api2/ws');
      }
    }

    return toWebSocketUri(liveBaseUrl, '/api2/ws');
  }

  /// Converts an http(s) base URL into its ws(s) counterpart with [path].
  @visibleForTesting
  static Uri toWebSocketUri(String httpBaseUrl, String path) {
    final uri = Uri.parse(
      '${_withoutTrailingSlash(httpBaseUrl)}${_withLeadingSlash(path)}',
    );
    return uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws');
  }

  static String? _read(String key) {
    if (!dotenv.isInitialized) return null;
    final value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static String _withoutTrailingSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;

  static String _withLeadingSlash(String value) =>
      value.startsWith('/') ? value : '/$value';
}
