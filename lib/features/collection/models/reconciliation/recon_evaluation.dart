import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';

/// Where one invoice of a case stands, as the log says.
class ReconInvoiceState {
  const ReconInvoiceState({
    required this.invoiceNo,
    required this.amount,
    required this.status,
    this.proofPending = false,
    this.proofRequested = false,
  });

  final String invoiceNo;

  /// Still owed on it: the server's current balance when known, else the
  /// amount at opening.
  final double amount;
  final ReconInvoiceStatus status;

  /// Proof received and not yet validated.
  final bool proofPending;

  /// Proof asked for since the latest claim, and none received since.
  final bool proofRequested;
}

/// Everything the Tracker derives for one case at one moment: the result of
/// `evaluateReconCase`. Nothing here is stored as truth.
class ReconEvaluation {
  const ReconEvaluation({
    required this.status,
    required this.nextActor,
    required this.invoices,
    required this.flags,
    required this.warnings,
    required this.lastActivity,
    required this.daysSinceLastActivity,
    required this.daysOpen,
    required this.dateClosed,
    required this.soaDate,
    required this.soaAmount,
  });

  final ReconCaseStatus status;

  /// Who acts next; null once the case has ended.
  final ReconActor? nextActor;

  /// In the case's own invoice order.
  final List<ReconInvoiceState> invoices;
  final Set<ReconFlag> flags;

  /// Logged steps the rules could not apply (an unknown invoice, a
  /// validation with no proof pending, a step after the case ended). Shown
  /// on the timeline, never silently dropped.
  final List<String> warnings;

  /// The latest step of any kind (Step 1: "check the last activity").
  final ReconActivity? lastActivity;

  /// Calendar days since [lastActivity], or since opening when none.
  final int daysSinceLastActivity;

  /// Calendar days since opening, to today or to [dateClosed].
  final int daysOpen;

  /// When it ended, as a Philippine wall-clock time; null while open.
  final DateTime? dateClosed;
  final DateTime? soaDate;
  final double? soaAmount;

  bool get isClosed => status.isClosed;

  List<ReconInvoiceState> get openInvoices =>
      invoices.where((i) => !i.status.isSettled).toList();

  /// Still owed on the invoices not yet settled.
  double get amountUnderReconciliation =>
      openInvoices.fold(0.0, (sum, i) => sum + i.amount);

  /// Validated paid, waiting for Accounting to post it.
  double get amountValidatedPaid => invoices
      .where((i) => i.status == ReconInvoiceStatus.validatedPaid)
      .fold(0.0, (sum, i) => sum + i.amount);

  bool get anyProofPending => invoices.any((i) => i.proofPending);
}
