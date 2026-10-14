import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_rules.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_status_style.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_summary.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';

import 'recon_test_data.dart';

/// The next action's due state (docs/application/
/// COLLECTION_RECON_FOLLOWUP_REMINDERS_PLAN.md, Phase 0) and how the
/// dashboard orders and counts it (Phase 1).

typedef T = ReconActivityType;

void main() {
  group('due state', () {
    // The SOA on the 10th, follow up agreed for the 20th.
    final soa = step(T.soaSent, '2026-09-10T09:00:00',
        due: '2026-09-20', action: 'Visit to follow up on SOA');

    test('later, soon, today, overdue as the days pass', () {
      final days = {
        '2026-09-17T09:00:00': (ReconDueState.later, 3),
        '2026-09-18T09:00:00': (ReconDueState.soon, 2),
        '2026-09-19T09:00:00': (ReconDueState.soon, 1),
        '2026-09-20T09:00:00': (ReconDueState.today, 0),
        '2026-09-21T09:00:00': (ReconDueState.overdue, -1),
      };
      days.forEach((now, want) {
        final e = evaluate([soa], now: now);
        expect((e.dueState, e.daysUntilDue), want, reason: now);
      });
    });

    test('the due day turns over at Manila midnight', () {
      expect(evaluate([soa], now: '2026-09-19T23:59:00').dueState,
          ReconDueState.soon);
      expect(evaluate([soa], now: '2026-09-20T00:01:00').dueState,
          ReconDueState.today);
      expect(evaluate([soa], now: '2026-09-20T23:59:00').dueState,
          ReconDueState.today);
      expect(evaluate([soa], now: '2026-09-21T00:01:00').dueState,
          ReconDueState.overdue);
    });

    test('overdue and the Next action overdue flag agree', () {
      expect(evaluate([soa], now: '2026-09-20T09:00:00').flags,
          isNot(contains(ReconFlag.nextActionOverdue)),
          reason: 'due today is not overdue');
      expect(evaluate([soa], now: '2026-09-21T09:00:00').flags,
          contains(ReconFlag.nextActionOverdue));
    });

    test('carries the date and what to do', () {
      final e = evaluate([soa], now: '2026-09-17T09:00:00');
      expect(e.nextActionDue, DateTime.utc(2026, 9, 20));
      expect(e.nextAction, 'Visit to follow up on SOA');
    });

    test('a step the app logged since keeps the date', () {
      final e = evaluate([
        soa,
        step(T.paymentRecorded, '2026-09-15T09:00:00', invoices: ['INV-1']),
      ], now: '2026-09-20T09:00:00');
      expect(e.dueState, ReconDueState.today);
    });

    test('a later own step without a date clears it', () {
      final e = evaluate([
        soa,
        step(T.followUp, '2026-09-19T09:00:00'),
      ], now: '2026-09-20T09:00:00');
      expect(e.dueState, ReconDueState.none);
      expect(e.nextActionDue, isNull);
    });

    test('a later own step moves it', () {
      final e = evaluate([
        soa,
        step(T.followUp, '2026-09-19T09:00:00', due: '2026-09-30'),
      ], now: '2026-09-29T09:00:00');
      expect(e.dueState, ReconDueState.soon);
      expect(e.nextActionDue, DateTime.utc(2026, 9, 30));
    });

    test('a closed case has nothing due', () {
      final e = evaluate([
        soa,
        step(T.caseNotCompleted, '2026-09-12T09:00:00'),
      ], now: '2026-09-25T09:00:00');
      expect(e.dueState, ReconDueState.none);
      expect(e.nextAction, '');
    });

    test('no date, nothing due', () {
      expect(evaluate([step(T.soaSent, '2026-09-10T09:00:00')]).dueState,
          ReconDueState.none);
    });

    test('the "due soon" window is a setting', () {
      final e = evaluate([soa],
          now: '2026-09-15T09:00:00',
          settings: const ReconSettings(dueSoonDays: 5));
      expect(e.dueState, ReconDueState.soon);
    });
  });

  group('labels', () {
    final soa = step(T.soaSent, '2026-09-10T09:00:00', due: '2026-09-20');
    String label(String now) => BReconStyle.dueLabel(evaluate([soa], now: now));

    test('in words', () {
      expect(label('2026-09-15T09:00:00'), 'Due Sep 20');
      expect(label('2026-09-18T09:00:00'), 'Due in 2 days');
      expect(label('2026-09-19T09:00:00'), 'Due tomorrow');
      expect(label('2026-09-20T09:00:00'), 'Due today');
      expect(label('2026-09-23T09:00:00'), 'Overdue since Sep 20');
      expect(
          BReconStyle.dueLabel(
              evaluate([step(T.soaSent, '2026-09-10T09:00:00')])),
          '');
    });
  });

  group('dashboard', () {
    const now = '2026-09-20T09:00:00';
    final overdueLong = evaluate(
        [step(T.soaSent, '2026-09-12T09:00:00', due: '2026-09-15')],
        now: now);
    final overdueShort = evaluate(
        [step(T.soaSent, '2026-09-12T09:00:00', due: '2026-09-18')],
        now: now);
    final today = evaluate(
        [step(T.soaSent, '2026-09-19T09:00:00', due: '2026-09-20')],
        now: now);
    final soonFar = evaluate(
        [step(T.soaSent, '2026-09-19T09:00:00', due: '2026-09-22')],
        now: now);
    final soonNear = evaluate(
        [step(T.soaSent, '2026-09-19T09:00:00', due: '2026-09-21')],
        now: now);
    final untouched =
        evaluate([step(T.soaSent, '2026-09-02T09:00:00')], now: now);
    final later = evaluate(
        [step(T.soaSent, '2026-09-18T09:00:00', due: '2026-10-30')],
        now: now);
    final closed =
        evaluate([step(T.caseEscalated, '2026-09-03T09:00:00')], now: now);

    test('overdue, due today and due soon come before the rest', () {
      final sorted = [
        later,
        closed,
        soonFar,
        untouched,
        today,
        overdueShort,
        soonNear,
        overdueLong,
      ]..sort(compareForReconDashboard);
      expect(sorted, [
        overdueLong,
        overdueShort,
        today,
        soonNear,
        soonFar,
        untouched, // untouched since the 2nd
        later, // touched on the 18th
        closed,
      ]);
    });

    test('counts and words', () {
      final counts = reconDueCounts(
          [overdueLong, overdueShort, today, soonNear, later, closed]);
      expect(counts, (today: 1, overdue: 2));
      expect(reconDueSummary(counts), '1 follow up due today · 2 overdue');
      expect(reconDueNote(counts), '1 due today · 2 overdue');
      expect(reconDueSummary((today: 0, overdue: 0)), '');
      expect(reconDueSummary((today: 3, overdue: 0)),
          '3 follow ups due today');
    });
  });
}
