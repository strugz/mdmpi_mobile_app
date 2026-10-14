import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_evaluation.dart';

/// A step the collector is about to log, before it has an id or a time.
class ReconActivityDraft {
  const ReconActivityDraft({
    required this.type,
    this.invoiceNos = const [],
    this.validationResult,
    this.attachmentCount = 0,
  });

  final ReconActivityType type;
  final List<String> invoiceNos;
  final ReconValidationResult? validationResult;

  /// Photos attached to it (a collection letter needs one).
  final int attachmentCount;
}

/// Whether [draft] may be logged on a case that stands as [evaluation].
///
/// The rules skip a step they cannot apply and say why on the timeline;
/// this stops it being logged in the first place, with the reason in words
/// the collector can act on.
Result<void> canAppendReconActivity(
    ReconEvaluation evaluation, ReconActivityDraft draft) {
  if (evaluation.isClosed) {
    return Result.failure(
        'This case is ${evaluation.status.label.toLowerCase()}. Start a new '
        'case to continue.');
  }

  final byNo = {for (final i in evaluation.invoices) i.invoiceNo: i};
  final names =
      draft.invoiceNos.map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
  final unknown = names.where((n) => !byNo.containsKey(n)).toList();
  if (unknown.isNotEmpty) {
    return Result.failure('Not in this case: ${unknown.join(', ')}.');
  }
  final locked = reconStageLockReason(evaluation, draft.type);
  if (locked != null) return Result.failure(locked);

  final picked = [for (final n in names) byNo[n]!];
  final settled = picked.where((i) => i.status.isSettled).toList();

  switch (draft.type) {
    case ReconActivityType.paidClaim:
      if (picked.isEmpty) {
        return Result.failure('Pick the invoices the account says are paid.');
      }
      if (settled.isNotEmpty) {
        return Result.failure(
            'Already settled: ${settled.map((i) => i.invoiceNo).join(', ')}.');
      }

    case ReconActivityType.proofRequested:
      final waiting = picked.isEmpty
          ? evaluation.invoices.where(_awaitsProof).toList()
          : picked;
      if (waiting.isEmpty || !waiting.every(_awaitsProof)) {
        return Result.failure(
            'Proof can only be requested for invoices claimed paid without '
            'proof.');
      }

    case ReconActivityType.proofProvided:
      if (picked.isEmpty && !evaluation.invoices.any(_awaitsProof)) {
        return Result.failure('Pick the invoices this proof is for.');
      }
      if (settled.isNotEmpty) {
        return Result.failure(
            'Already settled: ${settled.map((i) => i.invoiceNo).join(', ')}.');
      }

    case ReconActivityType.proofValidated:
      if (draft.validationResult == null) {
        return Result.failure('Choose valid or invalid.');
      }
      final pending = picked.isEmpty
          ? evaluation.invoices.where((i) => i.proofPending).toList()
          : picked;
      if (pending.isEmpty || !pending.every((i) => i.proofPending)) {
        return Result.failure('There is no proof waiting to be validated.');
      }

    case ReconActivityType.collectionLetterSent:
      if (draft.attachmentCount < 1) {
        return Result.failure('Attach a photo of the letter.');
      }

    case ReconActivityType.paymentRecorded:
    case ReconActivityType.caseReleased:
    case ReconActivityType.caseAcquired:
    case ReconActivityType.soaSent:
    case ReconActivityType.followUp:
    case ReconActivityType.documentRequested:
    case ReconActivityType.documentProvided:
    case ReconActivityType.note:
    case ReconActivityType.caseNotCompleted:
    case ReconActivityType.caseEscalated:
      break;
  }
  return Result.success(null);
}

/// Why [type] cannot be logged yet because the case's stages go in order
/// (SOA, then Follow up, then the Collection Letter); null when it can. The
/// log sheet shows it under the locked step, the validator refuses with it.
String? reconStageLockReason(
    ReconEvaluation evaluation, ReconActivityType type) {
  final stage = type.stage;
  if (stage == null || evaluation.stageUnlocked(stage)) return null;
  return stage.lockReason;
}

/// The steps that make sense on [evaluation] now, for the log sheet: every
/// step on an open case, except asking for or validating proof that is not
/// there, a stage step whose earlier stage is not done (the sheet shows those
/// locked, with [reconStageLockReason]), and the ones the app logs itself.
/// Nothing once the case has ended.
List<ReconActivityType> allowedReconActivityTypes(ReconEvaluation evaluation) {
  if (evaluation.isClosed) return const [];
  return [
    for (final type in ReconActivityType.values)
      if (!type.isAutomatic &&
          switch (type) {
            ReconActivityType.proofRequested =>
              evaluation.invoices.any(_awaitsProof),
            ReconActivityType.proofValidated => evaluation.anyProofPending,
            _ => reconStageLockReason(evaluation, type) == null,
          })
        type,
  ];
}

bool _awaitsProof(ReconInvoiceState i) =>
    i.status == ReconInvoiceStatus.claimedPaid && !i.proofPending;
