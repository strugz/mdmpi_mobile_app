import 'package:mdmpi_mobile_app/base/utils/logger.dart';

/// Collapses concurrent identical fetches into one round trip.
///
/// Hold one instance per repository. Two callers that ask for the same [key]
/// while the first call is still running share its future; the network is hit
/// once. This is what stops the paired tabs (Standard Delivery + Hotline
/// Direct, Air / Sea + Air / Sea HD, Pull Out + Stock Receive) from each
/// fetching the same endpoint when the dashboard loads all of them at once.
///
/// Two consequences callers must respect:
/// - joined callers receive the **same list instance**; copy before mutating
///   (every current call site does `.where(...).toList()` or `assignAll`);
/// - joined callers receive the **same error** if the shared call throws.
class BInFlightRequests {
  final Map<String, Future<Object?>> _pending = <String, Future<Object?>>{};

  /// True while a call for [key] is running.
  bool isInFlight(String key) => _pending.containsKey(key);

  /// True while any call whose key starts with [prefix] is running.
  bool isAnyInFlight(String prefix) =>
      _pending.keys.any((key) => key.startsWith(prefix));

  /// Runs [action] for [key], or joins the call already running for it.
  Future<T> run<T>(String key, Future<T> Function() action) {
    final existing = _pending[key];
    if (existing != null) {
      logDebug('BInFlightRequests: joining in-flight "$key"');
      return existing.then((value) => value as T);
    }

    final future = action();
    _pending[key] = future;
    return future.whenComplete(() {
      // Only evict our own entry; a later call may have replaced it.
      if (identical(_pending[key], future)) _pending.remove(key);
    });
  }
}
