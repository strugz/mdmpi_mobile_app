import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_clock.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_rules.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';

import 'recon_test_data.dart';

/// The alerts and the calendar-day counting behind them.

typedef T = ReconActivityType;

void main() {
  group('No response (7 days)', () {
    final soa = step(T.soaSent, '2026-09-10T16:00:00');

    test('6 days is not yet flagged, 7 is', () {
      expect(evaluate([soa], now: '2026-09-16T23:59:00').flags,
          isNot(contains(ReconFlag.noResponse)));
      expect(evaluate([soa], now: '2026-09-17T00:01:00').flags,
          contains(ReconFlag.noResponse));
    });

    test('a follow-up note does not restart the wait', () {
      final e = evaluate([soa, step(T.note, '2026-09-15T09:00:00')],
          now: '2026-09-17T09:00:00');
      expect(e.flags, contains(ReconFlag.noResponse));
    });

    test('a second collector step does not restart it either', () {
      final e = evaluate([
        soa,
        step(T.documentProvided, '2026-09-15T09:00:00'),
      ], now: '2026-09-17T09:00:00');
      expect(e.flags, contains(ReconFlag.noResponse),
          reason: 'still no word from the account since the 10th');
    });

    test('the account replying clears it', () {
      final e = evaluate([
        soa,
        step(T.documentRequested, '2026-09-16T09:00:00'),
        step(T.documentProvided, '2026-09-16T15:00:00'),
      ], now: '2026-09-20T09:00:00');
      expect(e.flags, isNot(contains(ReconFlag.noResponse)),
          reason: 'the wait started again on the 16th');
    });

    test('never while the collector is the one to act', () {
      final e = evaluate([
        soa,
        step(T.documentRequested, '2026-09-11T09:00:00'),
      ], now: '2026-09-30T09:00:00');
      expect(e.flags, isNot(contains(ReconFlag.noResponse)));
    });

    test('the limit is a setting', () {
      final e = evaluate([soa],
          now: '2026-09-13T09:00:00',
          settings: const ReconSettings(noResponseDays: 3));
      expect(e.flags, contains(ReconFlag.noResponse));
    });
  });

  group('Next action overdue', () {
    test('due today is not overdue; the day after is', () {
      final s = step(T.soaSent, '2026-09-10T09:00:00', due: '2026-09-12');
      expect(evaluate([s], now: '2026-09-12T23:00:00').flags,
          isNot(contains(ReconFlag.nextActionOverdue)));
      expect(evaluate([s], now: '2026-09-13T08:00:00').flags,
          contains(ReconFlag.nextActionOverdue));
    });

    test('a blank due date is never overdue', () {
      final e = evaluate([step(T.soaSent, '2026-09-01T09:00:00')],
          now: '2026-09-30T09:00:00');
      expect(e.flags, isNot(contains(ReconFlag.nextActionOverdue)));
    });

    test('only the latest step\'s due date counts', () {
      final e = evaluate([
        step(T.soaSent, '2026-09-01T09:00:00', due: '2026-09-02'),
        step(T.documentRequested, '2026-09-03T09:00:00', due: '2026-09-20'),
      ], now: '2026-09-10T09:00:00');
      expect(e.flags, isNot(contains(ReconFlag.nextActionOverdue)));
    });
  });

  group('Philippine calendar days', () {
    test('a UTC stamp just before midnight UTC is the next Manila day', () {
      expect(BReconClock.parse('2026-09-27T23:30:00Z'),
          DateTime.utc(2026, 9, 28, 7, 30));
      expect(BReconClock.parse('2026-09-27T23:30:00+08:00'),
          DateTime.utc(2026, 9, 27, 23, 30));
      expect(BReconClock.parse('2026-09-27T23:30:00'),
          DateTime.utc(2026, 9, 27, 23, 30),
          reason: 'no offset is already Manila time');
    });

    test('23:59 to 00:01 is one day', () {
      expect(
          BReconClock.daysBetween(
              DateTime.utc(2026, 9, 1, 23, 59), DateTime.utc(2026, 9, 2, 0, 1)),
          1);
    });

    test('now is read as a Manila day, whatever the device zone', () {
      // 18:00 UTC on the 16th is 02:00 on the 17th in Manila: day 7.
      final e = evaluateReconCase(
        reconCase: reconCase,
        invoices: threeInvoices,
        activities: [step(T.soaSent, '2026-09-10T16:00:00')],
        now: DateTime.utc(2026, 9, 16, 18),
      );
      expect(e.flags, contains(ReconFlag.noResponse));
      expect(e.daysSinceLastActivity, 7);
    });

    test('unreadable stamps are null', () {
      expect(BReconClock.parse(''), isNull);
      expect(BReconClock.parse(null), isNull);
      expect(BReconClock.parse('28/09/2026'), isNull);
    });
  });
}
