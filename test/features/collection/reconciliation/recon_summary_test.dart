import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_summary.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';

import 'recon_test_data.dart';

/// The Aging and Summary reports and the dashboard's order.

typedef T = ReconActivityType;

void main() {
  test('aging bucket edges: 7/8, 15/16, 30/31', () {
    expect(ReconAgingBucket.forDays(0), ReconAgingBucket.upTo7);
    expect(ReconAgingBucket.forDays(7), ReconAgingBucket.upTo7);
    expect(ReconAgingBucket.forDays(8), ReconAgingBucket.upTo15);
    expect(ReconAgingBucket.forDays(15), ReconAgingBucket.upTo15);
    expect(ReconAgingBucket.forDays(16), ReconAgingBucket.upTo30);
    expect(ReconAgingBucket.forDays(30), ReconAgingBucket.upTo30);
    expect(ReconAgingBucket.forDays(31), ReconAgingBucket.over30);
    expect(ReconAgingBucket.forDays(400), ReconAgingBucket.over30);
  });

  test('the summary counts end states and the money', () {
    // Opened 2026-09-01; aged on the 10th (9 days) and on the 20th (19).
    final waiting = evaluate([step(T.soaSent, '2026-09-02T10:00:00')]);
    final oldWaiting = evaluate([step(T.soaSent, '2026-09-02T10:00:00')],
        now: '2026-09-20T10:00:00');
    final completed = evaluate([
      step(T.paidClaim, '2026-09-03T10:00:00',
          invoices: ['INV-1', 'INV-2', 'INV-3']),
      step(T.proofProvided, '2026-09-04T10:00:00'),
      step(T.proofValidated, '2026-09-05T10:00:00',
          result: ReconValidationResult.valid),
    ]);
    final escalated = evaluate([step(T.caseEscalated, '2026-09-03T10:00:00')]);
    final notCompleted =
        evaluate([step(T.caseNotCompleted, '2026-09-03T10:00:00')]);

    final s = ReconSummary.of(
        [waiting, oldWaiting, completed, escalated, notCompleted]);
    expect(s.totalCases, 5);
    expect(s.open, 2);
    expect(s.completed, 1);
    expect(s.escalated, 1);
    expect(s.notCompleted, 1);
    expect(s.amountUnderReconciliation, 120000,
        reason: 'the two open cases, 60,000 each');
    expect(s.amountValidatedPaid, 60000);
    expect(s.aging, {
      ReconAgingBucket.upTo7: 0,
      ReconAgingBucket.upTo15: 1,
      ReconAgingBucket.upTo30: 1,
      ReconAgingBucket.over30: 0,
    });
  });

  test('the dashboard puts the case untouched longest first, closed last', () {
    final recent = evaluate([step(T.soaSent, '2026-09-09T10:00:00')]);
    final stale = evaluate([step(T.soaSent, '2026-09-02T10:00:00')]);
    final closed = evaluate([step(T.caseEscalated, '2026-09-01T10:00:00')]);
    final sorted = [recent, closed, stale]..sort(compareForReconDashboard);
    expect(sorted, [stale, recent, closed]);
  });

  test('closed cases are history: the latest closed first', () {
    final open = evaluate([step(T.soaSent, '2026-09-02T10:00:00')]);
    final longAgo = evaluate([step(T.caseEscalated, '2026-08-01T10:00:00')]);
    final lately = evaluate([step(T.caseNotCompleted, '2026-09-08T10:00:00')]);
    final sorted = [longAgo, lately, open]..sort(compareForReconDashboard);
    expect(sorted, [open, lately, longAgo]);
  });
}
