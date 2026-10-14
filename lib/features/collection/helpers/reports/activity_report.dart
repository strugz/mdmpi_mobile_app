import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_engagement_dao.dart';
import 'package:mdmpi_mobile_app/data/models/report_table.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_outcome.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_clock.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reports/report_month.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';

/// The month-end Activity report: everything one collector did in a month,
/// from their own archive (what they recorded on this phone, kept for good,
/// plus the server's copy of their history) and the reconciliation steps
/// they logged. Pure, so the screen and the CSV come from the same rows.
class ActivityReportInput {
  const ActivityReportInput({
    required this.collectorCode,
    required this.yearMonth,
    required this.engagements,
    this.cases = const [],
  });

  final String collectorCode;

  /// `yyyy-MM`.
  final String yearMonth;

  /// The collector's archive rows for [yearMonth].
  final List<CollectionEngagementRecord> engagements;

  /// Every case on the phone; only steps this collector logged in the month
  /// are reported.
  final List<ReconCaseBundle> cases;
}

const activityReportHeaders = [
  'Date',
  'Time',
  'Type',
  'Client code',
  'Client',
  'Reference',
  'Outcome',
  'Amount',
  'Counts as collected',
  'Settled invoice',
  'Bank',
  'Check no.',
  'Check date',
  'Purpose of visit',
  'Remarks',
  'Source',
];

/// Visits: distinct (day, client) pairs, an advance not being a visit.
int countVisits(Iterable<CollectionEngagementRecord> engagements) => engagements
    .where((e) => e.kind != 'ADVANCE' && e.clientId.trim().isNotEmpty)
    .map((e) => '${e.engagedOn}|${e.clientId.trim().toUpperCase()}')
    .toSet()
    .length;

/// The steps [collectorCode] logged themselves in [yearMonth] (Philippine
/// days), oldest first. Steps the app logs (a payment, a release) are left
/// out: a payment is already an engagement row.
List<({ReconCaseBundle bundle, ReconActivity step, DateTime at})>
    reconStepsInMonth(Iterable<ReconCaseBundle> cases,
        {required String collectorCode, required String yearMonth}) {
  final me = collectorCode.trim().toUpperCase();
  final steps = [
    for (final bundle in cases)
      for (final step in bundle.activities)
        if (!step.type.isAutomatic &&
            step.recordedBy.trim().toUpperCase() == me)
          if (BReconClock.parse(step.dateTime) case final at?)
            if (BReportMonth.contains(yearMonth, at))
              (bundle: bundle, step: step, at: at),
  ];
  steps.sort((a, b) => a.at.compareTo(b.at));
  return steps;
}

ReportTable buildActivityReport(ActivityReportInput input) {
  final rows = <({DateTime sortKey, List<ReportCell> cells})>[];
  var collected = 0.0;
  var settled = 0;

  for (final e in input.engagements) {
    final at = BFormatter.parseLocal(e.engagedAt);
    final counts = CollectionOutcome.countsAsCollected(e.status, kind: e.kind);
    final settles = CollectionOutcome.settlesInvoice(e);
    if (counts) collected += e.amount;
    if (settles) settled++;
    rows.add((
      sortKey: at ?? DateTime.tryParse(e.engagedOn) ?? DateTime(0),
      cells: [
        ReportCell.date(at ?? DateTime.tryParse(e.engagedOn)),
        ReportCell.text(at == null ? '' : _hhmm(at)),
        ReportCell.text(_kindLabel(e.kind)),
        ReportCell.text(e.clientId),
        ReportCell.text(e.clientName),
        ReportCell.text(
            e.itemId.isNotEmpty ? e.itemId : e.documentIds.join('; ')),
        ReportCell.text(e.status),
        ReportCell.money(e.amount),
        ReportCell.yesNo(counts && e.amount > 0),
        ReportCell.yesNo(settles),
        ReportCell.text(e.bankName),
        ReportCell.text(e.checkNumber),
        ReportCell.text(e.checkDate),
        ReportCell.text(e.purposeOfVisit),
        ReportCell.text(e.remarks),
        ReportCell.text(e.source),
      ],
    ));
  }

  final steps = reconStepsInMonth(input.cases,
      collectorCode: input.collectorCode, yearMonth: input.yearMonth);
  for (final (:bundle, :step, :at) in steps) {
    rows.add((
      sortKey: at,
      cells: [
        ReportCell.date(at),
        ReportCell.text(_hhmm(at)),
        const ReportCell.text('Reconciliation step'),
        ReportCell.text(bundle.reconCase.clientCode),
        ReportCell.text(bundle.reconCase.clientName),
        ReportCell.text([bundle.caseId, ...step.invoiceNos].join('; ')),
        ReportCell.text(step.type.label),
        ReportCell.money(step.amount ?? 0),
        const ReportCell.yesNo(false),
        const ReportCell.yesNo(false),
        ReportCell.blank,
        ReportCell.blank,
        ReportCell.blank,
        ReportCell.blank,
        ReportCell.text(step.remarks),
        const ReportCell.text('RECON'),
      ],
    ));
  }
  rows.sort((a, b) => a.sortKey.compareTo(b.sortKey));

  final visits = countVisits(input.engagements);
  return ReportTable(
    title: 'Activity report · ${input.yearMonth}',
    headers: activityReportHeaders,
    rows: [for (final r in rows) r.cells],
    totals: rows.isEmpty
        ? null
        : [
            const ReportCell.text('Total collected'),
            ...List.filled(6, ReportCell.blank),
            ReportCell.money(collected),
            ...List.filled(activityReportHeaders.length - 8, ReportCell.blank),
          ],
    summary: {
      'Collected': BFormatter.formatPesoCurrency(collected),
      'Engagements': '${input.engagements.length}',
      'Visits': '$visits',
      'Settled invoices': '$settled',
      'Recon steps': '${steps.length}',
    },
  );
}

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _kindLabel(String kind) => switch (kind) {
      'INVOICE' => 'Invoice',
      'ACCOUNT' => 'Account',
      'OFFICE' => 'Office',
      'ADVANCE' => 'Advance',
      _ => kind,
    };
