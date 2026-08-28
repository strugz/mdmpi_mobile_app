import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/web_socket_backoff.dart';

void main() {
  group('WebSocketBackoff', () {
    test('delays double from initialDelay and stay within the jitter band',
        () {
      final backoff = WebSocketBackoff(random: Random(42));

      for (var attempt = 0; attempt < 5; attempt++) {
        final expectedBase = Duration(seconds: 1 << attempt);
        final delay = backoff.nextDelay();

        expect(
          delay.inMicroseconds,
          inInclusiveRange(
            (expectedBase.inMicroseconds * 0.8).round() - 1,
            (expectedBase.inMicroseconds * 1.2).round() + 1,
          ),
          reason: 'attempt $attempt should be ~${expectedBase.inSeconds}s ±20%',
        );
      }
    });

    test('delay is capped at maxDelay (±jitter)', () {
      final backoff = WebSocketBackoff(random: Random(7));

      Duration delay = Duration.zero;
      for (var i = 0; i < 12; i++) {
        delay = backoff.nextDelay();
      }

      expect(
        delay.inMicroseconds,
        inInclusiveRange(
          (const Duration(seconds: 30).inMicroseconds * 0.8).round() - 1,
          (const Duration(seconds: 30).inMicroseconds * 1.2).round() + 1,
        ),
      );
    });

    test('reset returns the sequence to the initial delay', () {
      final backoff = WebSocketBackoff(random: Random(3));
      backoff.nextDelay();
      backoff.nextDelay();
      backoff.nextDelay();

      backoff.reset();

      expect(backoff.attempt, 0);
      final delay = backoff.nextDelay();
      expect(
        delay.inMicroseconds,
        inInclusiveRange(
          (const Duration(seconds: 1).inMicroseconds * 0.8).round() - 1,
          (const Duration(seconds: 1).inMicroseconds * 1.2).round() + 1,
        ),
      );
    });

    test('escalateToMax makes the next delay land in the max band', () {
      final backoff = WebSocketBackoff(random: Random(5));

      backoff.escalateToMax();
      final delay = backoff.nextDelay();

      expect(
        delay.inMicroseconds,
        inInclusiveRange(
          (const Duration(seconds: 30).inMicroseconds * 0.8).round() - 1,
          (const Duration(seconds: 30).inMicroseconds * 1.2).round() + 1,
        ),
      );
    });

    test('custom small delays keep the same shape (test seam)', () {
      final backoff = WebSocketBackoff(
        initialDelay: const Duration(milliseconds: 5),
        maxDelay: const Duration(milliseconds: 40),
        jitterRatio: 0,
        random: Random(1),
      );

      expect(backoff.nextDelay(), const Duration(milliseconds: 5));
      expect(backoff.nextDelay(), const Duration(milliseconds: 10));
      expect(backoff.nextDelay(), const Duration(milliseconds: 20));
      expect(backoff.nextDelay(), const Duration(milliseconds: 40));
      expect(backoff.nextDelay(), const Duration(milliseconds: 40));
    });
  });
}
