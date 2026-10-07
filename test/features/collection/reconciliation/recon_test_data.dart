import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_rules.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_evaluation.dart';

/// Builders for the Reconciliation Tracker tests. Times are written as the
/// phone stamps them: Philippine wall-clock time, no offset.

const reconCase = ReconCase(
  caseId: 'RC-JCA-1',
  clientCode: 'NLN-115',
  clientName: 'Accusure Medical Enterprises',
  collectorCode: 'JCA',
  dateOpened: '2026-09-01T09:00:00',
);

/// Three invoices, the usual shape of a case.
const threeInvoices = [
  ReconCaseInvoice(invoiceNo: 'INV-1', amount: 10000),
  ReconCaseInvoice(invoiceNo: 'INV-2', amount: 20000),
  ReconCaseInvoice(invoiceNo: 'INV-3', amount: 30000),
];

/// The real instant at Philippine wall-clock time [wallClock].
DateTime phInstant(String wallClock) => DateTime.parse('$wallClock+08:00');

var _seq = 0;

ReconActivity step(
  ReconActivityType type,
  String at, {
  List<String> invoices = const [],
  ReconValidationResult? result,
  String? due,
  double? amount,
  String? id,
}) =>
    ReconActivity(
      activityId: id ?? 'RA-${(++_seq).toString().padLeft(4, '0')}',
      caseId: reconCase.caseId,
      dateTime: at,
      type: type,
      invoiceNos: invoices,
      validationResult: result,
      nextActionDueDate: due,
      amount: amount,
      recordedBy: 'JCA',
    );

ReconEvaluation evaluate(
  List<ReconActivity> activities, {
  List<ReconCaseInvoice> invoices = threeInvoices,
  String now = '2026-09-10T12:00:00',
  ReconSettings settings = const ReconSettings(),
}) =>
    evaluateReconCase(
      reconCase: reconCase,
      invoices: invoices,
      activities: activities,
      now: phInstant(now),
      settings: settings,
    );

Map<String, ReconInvoiceStatus> statuses(ReconEvaluation e) =>
    {for (final i in e.invoices) i.invoiceNo: i.status};
