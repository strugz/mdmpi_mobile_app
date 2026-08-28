import 'dart:math';

/// Exponential backoff with jitter for WebSocket reconnects, following the
/// backend's mobile guidance: 1 s, 2 s, 4 s ... capped at 30 s, ±20% jitter.
/// Cellular drops are constant; immediate tight-loop reconnects burn battery
/// and hammer the server.
class WebSocketBackoff {
  WebSocketBackoff({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.jitterRatio = 0.2,
    Random? random,
  }) : _random = random ?? Random();

  final Duration initialDelay;
  final Duration maxDelay;
  final double jitterRatio;
  final Random _random;

  int _attempt = 0;

  int get attempt => _attempt;

  /// Returns the delay before the next reconnect attempt and advances the
  /// attempt counter: `initialDelay * 2^attempt` capped at [maxDelay], then
  /// randomized by ±[jitterRatio].
  Duration nextDelay() {
    final uncapped = initialDelay.inMicroseconds * pow(2, _attempt);
    final capped = min(uncapped, maxDelay.inMicroseconds.toDouble());
    _attempt++;

    final jitter = 1 + jitterRatio * (2 * _random.nextDouble() - 1);
    return Duration(microseconds: (capped * jitter).round());
  }

  /// Jumps the attempt counter so the next delay lands in the max band.
  /// Used when the server closes with 1008 (rate limit): retrying quickly
  /// would only earn another 1008.
  void escalateToMax() {
    if (initialDelay.inMicroseconds <= 0) return;
    while (initialDelay.inMicroseconds * pow(2, _attempt) <
        maxDelay.inMicroseconds) {
      _attempt++;
    }
  }

  /// Resets the sequence once a connection proves healthy.
  void reset() {
    _attempt = 0;
  }
}
