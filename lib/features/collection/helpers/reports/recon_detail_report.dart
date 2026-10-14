import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/data/models/report_table.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_clock.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_evaluation.dart';

/// The Reconciliation detailed report: one row per invoice of each case,
/// with the case's standing, its stages and its flags. Case-level amounts
/// are on the case's first row only, so a spreadsheet total does not count
/// a case once per invoice.
const reconDetailHeaders = [
  'Case',
  'Client code',
  'Client',
  'Holder code',
  'Holder',
  'Case status',
  'Opened',
  'Closed',
  'Days open',
  'Last step',
  'Last step on',
  'Days since last step',
  'Current stage',
  'SOA on',
  'SOA amount',
  'Follow ups',
  'Last follow up',
  'Letters',
  'Last letter',
  'Flags',
  'Steps logged',
  'Invoice #',
  'Invoice',
  'Invoice amount at opening',
  'Invoice still owed',
  'Invoice status',
  'Proof pending',
  'Proof requested',
  'Cleared on',
  'Case amount under reconciliation',
  'Case amount validated paid',
];

ReportTable buildReconDetail(
    Iterable<({ReconCaseBundle bundle, ReconEvaluation evaluation})> cases) {
  final rows = <List<ReportCell>>[];
  var caseCount = 0;
  var openCount = 0;
  var under = 0.0;
  for (final (:bundle, :evaluation) in cases) {
    final e = evaluation;
    final c = bundle.reconCase;
    caseCount++;
    if (!e.isClosed) {
      openCount++;
      under += e.amountUnderReconciliation;
    }
    final follow = e.stageProgress(ReconStage.followUp);
    final letter = e.stageProgress(ReconStage.collectionLetter);
    final caseCells = [
      ReportCell.text(bundle.caseId),
      ReportCell.text(c.clientCode),
      ReportCell.text(c.clientName),
      ReportCell.text(c.collectorCode),
      ReportCell.text(c.collectorName),
      ReportCell.text(e.status.label),
      ReportCell.date(BReconClock.parse(c.dateOpened)),
      ReportCell.date(e.dateClosed),
      ReportCell.integer(e.daysOpen),
      ReportCell.text(e.lastActivity?.type.label),
      ReportCell.date(BReconClock.parse(e.lastActivity?.dateTime)),
      ReportCell.integer(e.daysSinceLastActivity),
      ReportCell.text(e.currentStage?.label ?? 'All stages done'),
      ReportCell.date(e.soaDate),
      e.soaAmount == null ? ReportCell.blank : ReportCell.money(e.soaAmount!),
      ReportCell.integer(follow.count),
      ReportCell.date(follow.lastAt),
      ReportCell.integer(letter.count),
      ReportCell.date(letter.lastAt),
      ReportCell.text(e.flags.map((f) => f.label).join('; ')),
      ReportCell.integer(bundle.activities.length),
    ];
    final cleared = {
      for (final i in bundle.invoices) i.invoiceNo.trim(): i.clearedAt
    };
    final opening = {
      for (final i in bundle.invoices) i.invoiceNo.trim(): i.amount
    };
    var seq = 0;
    for (final inv in e.invoices.isEmpty ? [null] : e.invoices) {
      seq++;
      final first = seq == 1;
      rows.add([
        ...caseCells,
        ReportCell.integer(seq),
        ReportCell.text(inv?.invoiceNo),
        inv == null
            ? ReportCell.blank
            : ReportCell.money(opening[inv.invoiceNo] ?? 0),
        inv == null ? ReportCell.blank : ReportCell.money(inv.amount),
        ReportCell.text(inv?.status.label),
        inv == null ? ReportCell.blank : ReportCell.yesNo(inv.proofPending),
        inv == null ? ReportCell.blank : ReportCell.yesNo(inv.proofRequested),
        ReportCell.date(BReconClock.parse(cleared[inv?.invoiceNo])),
        first
            ? ReportCell.money(e.amountUnderReconciliation)
            : ReportCell.blank,
        first ? ReportCell.money(e.amountValidatedPaid) : ReportCell.blank,
      ]);
    }
  }
  return ReportTable(
    title: 'Reconciliation detail',
    headers: reconDetailHeaders,
    rows: rows,
    summary: {
      'Cases': '$caseCount',
      'Open': '$openCount',
      'Under reconciliation': BFormatter.formatPesoCurrency(under),
    },
  );
}
