import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_validator.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';

import 'recon_test_data.dart';

/// What the log sheet refuses before a step is ever logged.

typedef T = ReconActivityType;

void main() {
  final claimed = evaluate([
    step(T.soaSent, '2026-09-02T10:00:00'),
    step(T.paidClaim, '2026-09-03T10:00:00', invoices: ['INV-1']),
  ]);
  final proofIn = evaluate([
    step(T.paidClaim, '2026-09-03T10:00:00', invoices: ['INV-1']),
    step(T.proofProvided, '2026-09-04T10:00:00'),
  ]);

  String? reason(Result<void> r) => r.isFailure ? r.error : null;

  test('an ordinary step on an open case is allowed', () {
    expect(
        canAppendReconActivity(
                claimed, const ReconActivityDraft(type: T.documentProvided))
            .isSuccess,
        isTrue);
  });

  test('nothing is logged once the case has ended', () {
    final ended = evaluate([step(T.caseEscalated, '2026-09-02T10:00:00')]);
    expect(
        reason(canAppendReconActivity(
            ended, const ReconActivityDraft(type: T.note))),
        contains('Start a new case'));
    expect(allowedReconActivityTypes(ended), isEmpty);
  });

  test('invoices not in the case are refused', () {
    expect(
        reason(canAppendReconActivity(
            claimed,
            const ReconActivityDraft(
                type: T.paidClaim, invoiceNos: ['INV-2', 'X-9']))),
        'Not in this case: X-9.');
  });

  test('a paid claim must name invoices, none of them settled', () {
    expect(
        reason(canAppendReconActivity(
            claimed, const ReconActivityDraft(type: T.paidClaim))),
        contains('Pick the invoices'));
    final validated = evaluate([
      step(T.paidClaim, '2026-09-03T10:00:00', invoices: ['INV-1']),
      step(T.proofProvided, '2026-09-04T10:00:00'),
      step(T.proofValidated, '2026-09-05T10:00:00',
          result: ReconValidationResult.valid),
    ]);
    expect(
        reason(canAppendReconActivity(
            validated,
            const ReconActivityDraft(
                type: T.paidClaim, invoiceNos: ['INV-1']))),
        'Already settled: INV-1.');
  });

  test('proof is requested only for claims without proof', () {
    expect(
        canAppendReconActivity(
                claimed, const ReconActivityDraft(type: T.proofRequested))
            .isSuccess,
        isTrue);
    expect(
        reason(canAppendReconActivity(
            claimed,
            const ReconActivityDraft(
                type: T.proofRequested, invoiceNos: ['INV-2']))),
        contains('claimed paid without proof'));
  });

  test('validation needs a result and a proof waiting', () {
    expect(
        reason(canAppendReconActivity(
            proofIn, const ReconActivityDraft(type: T.proofValidated))),
        'Choose valid or invalid.');
    expect(
        canAppendReconActivity(
                proofIn,
                const ReconActivityDraft(
                    type: T.proofValidated,
                    validationResult: ReconValidationResult.valid))
            .isSuccess,
        isTrue);
    expect(
        reason(canAppendReconActivity(
            claimed,
            const ReconActivityDraft(
                type: T.proofValidated,
                validationResult: ReconValidationResult.valid))),
        contains('no proof waiting'));
  });

  test('the steps the app logs itself are never offered', () {
    final offered = allowedReconActivityTypes(proofIn);
    expect(offered.where((t) => t.isAutomatic), isEmpty);
    expect(T.paymentRecorded.isConversation, isFalse);
    expect(T.caseReleased.isLifecycle, isFalse,
        reason: 'a released case is still open');
  });

  test('the log sheet offers only the steps that make sense now', () {
    final fresh = allowedReconActivityTypes(evaluate([]));
    expect(fresh, isNot(contains(T.proofRequested)));
    expect(fresh, isNot(contains(T.proofValidated)));
    expect(fresh, contains(T.soaSent));
    expect(allowedReconActivityTypes(claimed), contains(T.proofRequested));
    expect(allowedReconActivityTypes(proofIn), contains(T.proofValidated));
  });
}
