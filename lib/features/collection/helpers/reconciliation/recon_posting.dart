import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_evaluation.dart';

/// One invoice validated paid and not yet posted by Accounting (Step 9).
class ReconAwaitingPosting {
  const ReconAwaitingPosting({
    required this.caseId,
    required this.clientName,
    required this.invoiceNo,
    required this.amount,
    this.validatedAt,
    this.proof = '',
    this.photos = 0,
  });

  final String caseId;
  final String clientName;
  final String invoiceNo;

  /// Still owed on it, the amount Accounting posts.
  final double amount;

  /// When the collector validated the proof (Manila wall-clock stamp).
  final String? validatedAt;

  /// What the account sent as proof: its remarks (deposit slip, OR, transfer).
  final String proof;

  /// Photos of that proof.
  final int photos;
}

/// Invoices validated paid whose balance has not reached zero yet: waiting for
/// Accounting to post the payment. Once posted, the balance the server sends
/// (or the phone's own) is zero and the invoice leaves the list by itself.
/// Newest validation first.
List<ReconAwaitingPosting> reconAwaitingPosting(
    Iterable<({ReconCaseBundle bundle, ReconEvaluation evaluation})> cases) {
  final out = <ReconAwaitingPosting>[];
  for (final (:bundle, :evaluation) in cases) {
    final byNo = {for (final i in bundle.invoices) i.invoiceNo: i};
    for (final state in evaluation.invoices) {
      if (state.status != ReconInvoiceStatus.validatedPaid) continue;
      final balance = byNo[state.invoiceNo]?.currentBalance;
      if (balance != null && balance <= 0.005) continue;

      final validated = _latest(
          bundle.activities,
          (a) =>
              a.type == ReconActivityType.proofValidated &&
              a.validationResult == ReconValidationResult.valid &&
              _names(a, state.invoiceNo));
      final proof = _latest(
          bundle.activities,
          (a) =>
              a.type == ReconActivityType.proofProvided &&
              _names(a, state.invoiceNo) &&
              (validated == null ||
                  a.dateTime.compareTo(validated.dateTime) <= 0));
      out.add(ReconAwaitingPosting(
        caseId: bundle.caseId,
        clientName: bundle.reconCase.clientName,
        invoiceNo: state.invoiceNo,
        amount: state.amount,
        validatedAt: validated?.dateTime,
        proof: proof?.remarks ?? '',
        photos: proof?.attachmentRefs.length ?? 0,
      ));
    }
  }
  out.sort((a, b) => (b.validatedAt ?? '').compareTo(a.validatedAt ?? ''));
  return out;
}

/// A step that names no invoice applies to every one it could.
bool _names(ReconActivity a, String invoiceNo) =>
    a.invoiceNos.isEmpty || a.invoiceNos.contains(invoiceNo);

ReconActivity? _latest(
    List<ReconActivity> activities, bool Function(ReconActivity) test) {
  ReconActivity? found;
  for (final a in activities) {
    if (!test(a)) continue;
    if (found == null || a.dateTime.compareTo(found.dateTime) >= 0) found = a;
  }
  return found;
}
