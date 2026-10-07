import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';

import 'recon_test_data.dart';

/// One group per rule of the Reconciliation Tracker
/// (docs/application/COLLECTION_RECONCILIATION_TRACKER_PLAN.md, "Rules").

typedef T = ReconActivityType;
typedef S = ReconCaseStatus;
typedef I = ReconInvoiceStatus;

void main() {
  group('who acts next', () {
    test('a new case waits for the collector to send the SOA', () {
      final e = evaluate([]);
      expect(e.status, S.waitingForCollector);
      expect(e.nextActor, ReconActor.collector);
      expect(e.lastActivity, isNull);
      expect(statuses(e).values, everyElement(I.open));
    });

    test('Step 2: SOA sent → waiting for account', () {
      final e = evaluate([step(T.soaSent, '2026-09-02T10:00:00')]);
      expect(e.status, S.waitingForAccount);
      expect(e.nextActor, ReconActor.account);
      expect(e.soaAmount, 60000, reason: 'the open invoices, when not typed');
    });

    test('the SOA amount typed by the collector is kept', () {
      final e =
          evaluate([step(T.soaSent, '2026-09-02T10:00:00', amount: 59500)]);
      expect(e.soaAmount, 59500);
    });

    test('Step 3a: documents requested → waiting for collector', () {
      final e = evaluate([
        step(T.soaSent, '2026-09-02T10:00:00'),
        step(T.documentRequested, '2026-09-03T10:00:00'),
      ]);
      expect(e.status, S.waitingForCollector);
      expect(e.nextActor, ReconActor.collector);
    });

    test('Step 4: documents provided → waiting for account again', () {
      final e = evaluate([
        step(T.soaSent, '2026-09-02T10:00:00'),
        step(T.documentRequested, '2026-09-03T10:00:00'),
        step(T.documentProvided, '2026-09-04T10:00:00'),
      ]);
      expect(e.status, S.waitingForAccount);
    });

    test('a note does not change whose turn it is', () {
      final e = evaluate([
        step(T.soaSent, '2026-09-02T10:00:00'),
        step(T.documentRequested, '2026-09-03T10:00:00'),
        step(T.note, '2026-09-04T10:00:00'),
      ]);
      expect(e.status, S.waitingForCollector);
      expect(e.lastActivity!.type, T.note,
          reason: 'the banner still shows the note as the last activity');
    });

    test('steps logged out of order are applied oldest first', () {
      final e = evaluate([
        step(T.documentProvided, '2026-09-04T10:00:00'),
        step(T.soaSent, '2026-09-02T10:00:00'),
        step(T.documentRequested, '2026-09-03T10:00:00'),
      ]);
      expect(e.status, S.waitingForAccount);
      expect(e.lastActivity!.type, T.documentProvided);
    });
  });

  group('paid claims', () {
    test('Step 5: only the named invoices become claimed paid', () {
      final e = evaluate([
        step(T.soaSent, '2026-09-02T10:00:00'),
        step(T.paidClaim, '2026-09-03T10:00:00', invoices: ['INV-1', 'INV-3']),
      ]);
      expect(statuses(e),
          {'INV-1': I.claimedPaid, 'INV-2': I.open, 'INV-3': I.claimedPaid});
      expect(e.status, S.waitingForCollector);
    });

    test('an invoice not in the case is reported, the rest applied', () {
      final e = evaluate([
        step(T.paidClaim, '2026-09-03T10:00:00',
            invoices: ['INV-1', 'NOT-OURS']),
      ]);
      expect(statuses(e)['INV-1'], I.claimedPaid);
      expect(e.warnings.single, contains('NOT-OURS is not in this case'));
    });

    test('a claim that names nothing changes nothing and is reported', () {
      final e = evaluate([step(T.paidClaim, '2026-09-03T10:00:00')]);
      expect(statuses(e).values, everyElement(I.open));
      expect(e.warnings.single, contains('names no invoice'));
    });
  });

  group('proof', () {
    final claimed = [
      step(T.soaSent, '2026-09-02T10:00:00'),
      step(T.paidClaim, '2026-09-03T10:00:00', invoices: ['INV-1', 'INV-2']),
    ];

    test('Step 6: proof requested → waiting for account, flagged no proof', () {
      final e = evaluate([
        ...claimed,
        step(T.proofRequested, '2026-09-03T15:00:00'),
      ]);
      expect(e.status, S.waitingForAccount);
      expect(e.flags, contains(ReconFlag.claimedPaidNoProof));
      expect(e.invoices.where((i) => i.proofRequested).map((i) => i.invoiceNo),
          ['INV-1', 'INV-2'],
          reason: 'a request naming nothing asks for every claim without '
              'proof');
    });

    test('a claim without a proof request is not flagged yet', () {
      expect(evaluate(claimed).flags,
          isNot(contains(ReconFlag.claimedPaidNoProof)));
    });

    test('Step 7: proof sent → under validation, the collector acts next', () {
      final e = evaluate([
        ...claimed,
        step(T.proofRequested, '2026-09-03T15:00:00'),
        step(T.proofProvided, '2026-09-05T09:00:00'),
      ]);
      expect(e.status, S.underValidation);
      expect(e.nextActor, ReconActor.collector);
      expect(e.flags, isNot(contains(ReconFlag.claimedPaidNoProof)));
      expect(e.invoices.where((i) => i.proofPending).length, 2);
    });

    test('proof for an unclaimed invoice counts as the claim', () {
      final e = evaluate([
        step(T.proofProvided, '2026-09-05T09:00:00', invoices: ['INV-3']),
      ]);
      expect(statuses(e)['INV-3'], I.claimedPaid);
      expect(e.status, S.underValidation);
    });

    test('proof on one invoice leaves the other waiting', () {
      final e = evaluate([
        ...claimed,
        step(T.proofRequested, '2026-09-03T15:00:00'),
        step(T.proofProvided, '2026-09-05T09:00:00', invoices: ['INV-1']),
      ]);
      expect(e.status, S.underValidation);
      expect(e.flags, contains(ReconFlag.claimedPaidNoProof),
          reason: 'INV-2 was asked for and has not come');
    });
  });

  group('validation', () {
    final proofIn = [
      step(T.soaSent, '2026-09-02T10:00:00'),
      step(T.paidClaim, '2026-09-03T10:00:00', invoices: ['INV-1', 'INV-2']),
      step(T.proofProvided, '2026-09-05T09:00:00'),
    ];

    test('Step 8 valid → Step 9: validated paid', () {
      final e = evaluate([
        ...proofIn,
        step(T.proofValidated, '2026-09-06T09:00:00',
            result: ReconValidationResult.valid),
      ]);
      expect(statuses(e), {
        'INV-1': I.validatedPaid,
        'INV-2': I.validatedPaid,
        'INV-3': I.open
      });
      expect(e.amountValidatedPaid, 30000);
      expect(e.amountUnderReconciliation, 30000);
      expect(e.status, S.waitingForAccount,
          reason: 'INV-3 is still open; the collector acted last');
    });

    test('Step 8 invalid → proof invalid, still open, next round', () {
      final e = evaluate([
        ...proofIn,
        step(T.proofValidated, '2026-09-06T09:00:00',
            invoices: ['INV-2'], result: ReconValidationResult.invalid),
      ]);
      expect(statuses(e)['INV-2'], I.proofInvalid);
      expect(e.invoices.firstWhere((i) => i.invoiceNo == 'INV-1').proofPending,
          isTrue);
      expect(e.status, S.underValidation,
          reason: 'INV-1 still has proof to validate');
    });

    test('after an invalid proof, a new round can claim it again', () {
      final e = evaluate([
        ...proofIn,
        step(T.proofValidated, '2026-09-06T09:00:00',
            result: ReconValidationResult.invalid),
        step(T.soaSent, '2026-09-07T09:00:00'),
        step(T.paidClaim, '2026-09-08T09:00:00', invoices: ['INV-1']),
        step(T.proofProvided, '2026-09-09T09:00:00', invoices: ['INV-1']),
        step(T.proofValidated, '2026-09-09T15:00:00',
            result: ReconValidationResult.valid),
      ]);
      expect(statuses(e),
          {'INV-1': I.validatedPaid, 'INV-2': I.proofInvalid, 'INV-3': I.open});
    });

    test('validating when no proof is waiting changes nothing', () {
      final e = evaluate([
        step(T.proofValidated, '2026-09-06T09:00:00',
            result: ReconValidationResult.valid),
      ]);
      expect(statuses(e).values, everyElement(I.open));
      expect(e.warnings.single, contains('no invoice'));
    });

    test('a validation without a result is reported', () {
      final e =
          evaluate([...proofIn, step(T.proofValidated, '2026-09-06T09:00:00')]);
      expect(e.status, S.underValidation);
      expect(e.warnings.single, contains('without a result'));
    });
  });

  group('how a case ends', () {
    test('every invoice validated paid → completed, automatically', () {
      final e = evaluate([
        step(T.paidClaim, '2026-09-03T10:00:00',
            invoices: ['INV-1', 'INV-2', 'INV-3']),
        step(T.proofProvided, '2026-09-05T09:00:00'),
        step(T.proofValidated, '2026-09-06T09:30:00',
            result: ReconValidationResult.valid),
      ]);
      expect(e.status, S.completed);
      expect(e.nextActor, isNull);
      expect(e.dateClosed, DateTime.utc(2026, 9, 6, 9, 30));
      expect(e.daysOpen, 5);
    });

    test('an invoice paid outside the case is cleared and counts', () {
      final e = evaluate(
        [
          step(T.paidClaim, '2026-09-03T10:00:00', invoices: ['INV-1']),
          step(T.proofProvided, '2026-09-05T09:00:00'),
          step(T.proofValidated, '2026-09-06T09:00:00',
              result: ReconValidationResult.valid),
        ],
        invoices: const [
          ReconCaseInvoice(invoiceNo: 'INV-1', amount: 10000),
          ReconCaseInvoice(
              invoiceNo: 'INV-2',
              amount: 20000,
              currentBalance: 0,
              clearedAt: '2026-09-08T11:00:00'),
        ],
      );
      expect(statuses(e), {'INV-1': I.validatedPaid, 'INV-2': I.cleared});
      expect(e.status, S.completed);
      expect(e.dateClosed, DateTime.utc(2026, 9, 8, 11));
    });

    test('a part payment outside the case keeps the invoice open', () {
      final e = evaluate([], invoices: const [
        ReconCaseInvoice(
            invoiceNo: 'INV-1', amount: 10000, currentBalance: 4000),
      ]);
      expect(statuses(e)['INV-1'], I.open);
      expect(e.amountUnderReconciliation, 4000);
    });

    test('Not completed ends the case, and nothing after it applies', () {
      final e = evaluate([
        step(T.soaSent, '2026-09-02T10:00:00'),
        step(T.caseNotCompleted, '2026-09-04T10:00:00'),
        step(T.paidClaim, '2026-09-05T10:00:00', invoices: ['INV-1']),
      ]);
      expect(e.status, S.notCompleted);
      expect(e.nextActor, isNull);
      expect(statuses(e)['INV-1'], I.open);
      expect(e.warnings.single, contains('after the case ended'));
      expect(e.dateClosed, DateTime.utc(2026, 9, 4, 10));
    });

    test('Escalated sticks even when every invoice later clears', () {
      final e = evaluate(
        [step(T.caseEscalated, '2026-09-04T10:00:00')],
        invoices: const [
          ReconCaseInvoice(invoiceNo: 'INV-1', amount: 100, currentBalance: 0),
        ],
      );
      expect(e.status, S.escalated);
    });

    test('a closed case raises no flags', () {
      final e = evaluate([
        step(T.soaSent, '2026-09-01T10:00:00', due: '2026-09-02'),
        step(T.caseEscalated, '2026-09-01T11:00:00'),
      ], now: '2026-09-30T10:00:00');
      expect(e.flags, isEmpty);
    });
  });

  test('an unreadable time is reported, not guessed', () {
    final e = evaluate([step(T.soaSent, 'yesterday')]);
    expect(e.lastActivity, isNull);
    expect(e.warnings.single, contains('unreadable time'));
  });
}
