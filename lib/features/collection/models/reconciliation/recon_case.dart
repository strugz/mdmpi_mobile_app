import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';

/// A reconciliation case: one account, one collector, one set of invoices.
///
/// Only what is stored. Where the case stands is worked out from its
/// activity log by `evaluateReconCase`, never read from here.
class ReconCase {
  const ReconCase({
    required this.caseId,
    required this.clientCode,
    required this.clientName,
    required this.collectorCode,
    this.collectorName = '',
    required this.dateOpened,
  });

  final String caseId;
  final String clientCode;
  final String clientName;

  /// The collector holding the account now; follows the account on acquire.
  final String collectorCode;
  final String collectorName;

  /// When the case was opened, as the device stamped it.
  final String dateOpened;
}

/// One invoice of a case.
class ReconCaseInvoice {
  const ReconCaseInvoice({
    required this.invoiceNo,
    required this.amount,
    this.currentBalance,
    this.clearedAt,
  });

  final String invoiceNo;

  /// The balance when the case was opened.
  final double amount;

  /// The server's balance now; null until one has been downloaded.
  final double? currentBalance;

  /// When the server saw the balance reach zero, if it has.
  final String? clearedAt;
}

/// One logged step of a case. Only ever added, never edited.
class ReconActivity {
  const ReconActivity({
    required this.activityId,
    required this.caseId,
    required this.dateTime,
    required this.type,
    this.invoiceNos = const [],
    this.remarks = '',
    this.amount,
    this.validationResult,
    this.nextAction = '',
    this.nextActionDueDate,
    this.attachmentRefs = const [],
    this.recordedBy = '',
  });

  final String activityId;
  final String caseId;

  /// When it happened, as the device stamped it.
  final String dateTime;
  final ReconActivityType type;

  /// The invoices it names. Empty means "the ones the step applies to"
  /// (see the rules), except for a paid claim, which must name them.
  final List<String> invoiceNos;
  final String remarks;

  /// The SOA amount, on SOA_SENT only.
  final double? amount;

  /// On PROOF_VALIDATED only.
  final ReconValidationResult? validationResult;
  final String nextAction;

  /// yyyy-MM-dd, or null for none.
  final String? nextActionDueDate;
  final List<String> attachmentRefs;

  /// The collector who logged it (for the Account's steps too).
  final String recordedBy;

  ReconActor get doneBy => type.doneBy;
}
