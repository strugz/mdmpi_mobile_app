import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_status_style.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_validator.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';

import 'recon_test_data.dart';

/// The case-level stages, in order: SOA → Follow up → Collection letter.
/// They run beside the invoices' claim → proof → validate chain.

typedef T = ReconActivityType;

void main() {
  String? reason(Result<void> r) => r.isFailure ? r.error : null;

  group('rules', () {
    test('a fresh case is at the SOA stage, nothing done', () {
      final e = evaluate([]);
      expect(e.currentStage, ReconStage.soa);
      expect(e.stages.map((p) => p.done), [false, false, false]);
      expect(e.stageUnlocked(ReconStage.soa), isTrue);
      expect(e.stageUnlocked(ReconStage.followUp), isFalse);
    });

    test('SOA, follow ups, then letters, each counted with its dates', () {
      final e = evaluate([
        step(T.soaSent, '2026-09-02T10:00:00'),
        step(T.followUp, '2026-09-04T10:00:00'),
        step(T.followUp, '2026-09-06T10:00:00'),
        step(T.collectionLetterSent, '2026-09-08T10:00:00'),
        step(T.collectionLetterSent, '2026-09-09T10:00:00'),
      ]);
      final follow = e.stageProgress(ReconStage.followUp);
      expect(follow.count, 2);
      expect(follow.firstAt, DateTime.utc(2026, 9, 4, 10));
      expect(follow.lastAt, DateTime.utc(2026, 9, 6, 10));
      expect(e.stageProgress(ReconStage.collectionLetter).count, 2,
          reason: 'a second letter (final demand) is allowed');
      expect(e.currentStage, isNull);
      expect(e.warnings, isEmpty);
    });

    test('out-of-order steps are reported and not counted', () {
      final e = evaluate([
        step(T.followUp, '2026-09-02T10:00:00', id: 'RA-F'),
        step(T.soaSent, '2026-09-03T10:00:00'),
        step(T.collectionLetterSent, '2026-09-04T10:00:00', id: 'RA-L'),
      ]);
      expect(e.stageProgress(ReconStage.followUp).count, 0);
      expect(e.stageProgress(ReconStage.collectionLetter).count, 0);
      expect(e.currentStage, ReconStage.followUp);
      expect(e.warnings, [
        'RA-F: follow up before any SOA, not counted',
        'RA-L: collection letter before any follow up, not counted',
      ]);
    });

    test('a re-issued SOA keeps the stage done and replaces the SOA date', () {
      final e = evaluate([
        step(T.soaSent, '2026-09-02T10:00:00', amount: 60000),
        step(T.soaSent, '2026-09-05T10:00:00', amount: 50000),
      ]);
      expect(e.stageProgress(ReconStage.soa).count, 2);
      expect(e.soaDate, DateTime.utc(2026, 9, 5, 10));
      expect(e.soaAmount, 50000);
    });

    test('a follow up is the collector chasing: it waits on the account', () {
      final e = evaluate([
        step(T.soaSent, '2026-09-01T10:00:00'),
        step(T.followUp, '2026-09-05T10:00:00'),
      ], now: '2026-09-08T12:00:00');
      expect(e.status, ReconCaseStatus.waitingForAccount);
      expect(e.flags, contains(ReconFlag.noResponse),
          reason: 'the follow up does not restart the 7-day wait');
    });

    test('stages never decide the case status', () {
      final e = evaluate([
        step(T.paidClaim, '2026-09-02T10:00:00',
            invoices: ['INV-1', 'INV-2', 'INV-3']),
        step(T.proofProvided, '2026-09-03T10:00:00'),
        step(T.proofValidated, '2026-09-04T10:00:00',
            result: ReconValidationResult.valid),
      ]);
      expect(e.status, ReconCaseStatus.completed);
      expect(e.currentStage, ReconStage.soa);
    });
  });

  group('validator', () {
    final fresh = evaluate([]);
    final soaOnly = evaluate([step(T.soaSent, '2026-09-02T10:00:00')]);
    final followed = evaluate([
      step(T.soaSent, '2026-09-02T10:00:00'),
      step(T.followUp, '2026-09-04T10:00:00'),
    ]);

    test('a follow up needs the SOA first', () {
      expect(
          reason(canAppendReconActivity(
              fresh, const ReconActivityDraft(type: T.followUp))),
          'Log the SOA before a follow up.');
      expect(
          canAppendReconActivity(
                  soaOnly, const ReconActivityDraft(type: T.followUp))
              .isSuccess,
          isTrue);
    });

    test('a letter needs a follow up first, and a photo', () {
      expect(
          reason(canAppendReconActivity(soaOnly,
              const ReconActivityDraft(type: T.collectionLetterSent))),
          'Log at least one follow up before the collection letter.');
      expect(
          reason(canAppendReconActivity(followed,
              const ReconActivityDraft(type: T.collectionLetterSent))),
          'Attach a photo of the letter.');
      expect(
          canAppendReconActivity(
                  followed,
                  const ReconActivityDraft(
                      type: T.collectionLetterSent, attachmentCount: 1))
              .isSuccess,
          isTrue);
    });

    test('locked stage steps are not offered; the lock reason says why', () {
      expect(allowedReconActivityTypes(fresh),
          isNot(anyOf(contains(T.followUp), contains(T.collectionLetterSent))));
      expect(allowedReconActivityTypes(soaOnly), contains(T.followUp));
      expect(allowedReconActivityTypes(soaOnly),
          isNot(contains(T.collectionLetterSent)));
      expect(allowedReconActivityTypes(followed),
          containsAll([T.soaSent, T.followUp, T.collectionLetterSent]));
      expect(reconStageLockReason(fresh, T.followUp),
          'Log the SOA before a follow up.');
      expect(reconStageLockReason(fresh, T.soaSent), isNull);
      expect(reconStageLockReason(fresh, T.note), isNull);
    });
  });

  test('the hint follows the stage while waiting on the account', () {
    String hint(ReconStage? stage) => BReconStyle.nextStepHint(
        ReconCaseStatus.waitingForAccount,
        hasActivity: true,
        stage: stage);
    expect(hint(ReconStage.followUp), 'Follow up with the account');
    expect(hint(ReconStage.collectionLetter),
        'Follow up again, or send the collection letter');
  });

  test('one lock reason per stage', () {
    expect(ReconStage.soa.lockReason, isNull);
    expect(ReconStage.followUp.lockReason, 'Log the SOA before a follow up.');
    expect(ReconStage.collectionLetter.lockReason,
        'Log at least one follow up before the collection letter.');
  });

  test('wire codes', () {
    expect(T.fromCode('FOLLOW_UP'), T.followUp);
    expect(T.fromCode('COLLECTION_LETTER_SENT'), T.collectionLetterSent);
    expect(T.followUp.isConversation, isTrue);
    expect(T.collectionLetterSent.doneBy, ReconActor.collector);
    expect(T.soaSent.stage, ReconStage.soa);
    expect(T.note.stage, isNull);
  });
}
