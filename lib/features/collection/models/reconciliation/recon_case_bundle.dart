import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_rules.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_evaluation.dart';

/// Where a stored case, or one of its steps, came from.
abstract final class ReconSource {
  /// Made on this device and not yet returned by the server.
  static const local = 'LOCAL';

  /// The server's copy, from the workspace download.
  static const server = 'SERVER';
}

/// One case with everything it is made of: the unit the phone stores, uploads
/// and downloads. Where it stands is [evaluate]d, never stored as truth.
class ReconCaseBundle {
  const ReconCaseBundle({
    required this.reconCase,
    required this.invoices,
    required this.activities,
    this.source = ReconSource.local,
  });

  final ReconCase reconCase;
  final List<ReconCaseInvoice> invoices;

  /// Oldest first.
  final List<ReconActivity> activities;
  final String source;

  String get caseId => reconCase.caseId;

  ReconEvaluation evaluate(
          {required DateTime now,
          ReconSettings settings = const ReconSettings()}) =>
      evaluateReconCase(
        reconCase: reconCase,
        invoices: invoices,
        activities: activities,
        now: now,
        settings: settings,
      );

  /// The same case with each invoice's balance as the phone knows it now
  /// ([balances], invoice id → still owed). A payment recorded here shows at
  /// once instead of after the next upload and download; an invoice paid in
  /// full reads as Cleared. Invoices the phone does not have keep what the
  /// server last said.
  ReconCaseBundle withBalances(Map<String, double> balances) {
    if (balances.isEmpty) return this;
    return ReconCaseBundle(
      reconCase: reconCase,
      invoices: [
        for (final i in invoices)
          if (balances[i.invoiceNo] case final live?)
            ReconCaseInvoice(
              invoiceNo: i.invoiceNo,
              amount: i.amount,
              currentBalance: live,
              clearedAt: live <= 0.005 ? i.clearedAt : null,
            )
          else
            i,
      ],
      activities: activities,
      source: source,
    );
  }

  ReconCaseBundle withActivity(ReconActivity activity) => ReconCaseBundle(
        reconCase: reconCase,
        invoices: invoices,
        activities: [...activities, activity],
        source: source,
      );
}
