import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_engagement_dao.dart';
import 'package:mdmpi_mobile_app/data/models/report_table.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_outcome.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_summary.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reports/activity_report.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reports/report_month.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_evaluation.dart';
import 'package:mdmpi_mobile_app/features/collection/models/team_engagement.dart';

/// One collector's month, for the Collectors summary.
class CollectorSummaryRow {
  const CollectorSummaryRow({
    required this.code,
    this.name = '',
    this.collected = 0,
    this.engagements = 0,
    this.visits = 0,
    this.settledInvoices = 0,
    this.reconOpen = 0,
    this.reconFlagged = 0,
    this.reconClosed = 0,
    this.reconSteps = 0,
    required this.source,
  });

  final String code;
  final String name;
  final double collected;
  final int engagements;
  final int visits;
  final int settledInvoices;
  final int reconOpen;
  final int reconFlagged;
  final int reconClosed;

  /// Steps they logged on cases this month.
  final int reconSteps;

  /// [sourcePhone], [sourceServer] or [sourceFeed].
  final String source;

  /// The signed-in collector's own row, from this phone's archive (exact,
  /// including work not uploaded yet).
  static const sourcePhone = 'This phone';

  /// A teammate's row, from the uploaded team feed (approximate; see the
  /// Notes column). Only when the server has no summary yet.
  static const sourceFeed = 'Team feed';

  /// A teammate's row counted on the server (`team/summary`): exact for
  /// uploaded work, case counts included.
  static const sourceServer = 'Server';

  String get label => name.trim().isNotEmpty ? name.trim() : code;

  CollectorSummaryRow withRecon(
          {required int open,
          required int flagged,
          required int closed,
          required int steps}) =>
      CollectorSummaryRow(
        code: code,
        name: name,
        collected: collected,
        engagements: engagements,
        visits: visits,
        settledInvoices: settledInvoices,
        reconOpen: open,
        reconFlagged: flagged,
        reconClosed: closed,
        reconSteps: steps,
        source: source,
      );
}

/// The signed-in collector's row, from their archive for the month.
CollectorSummaryRow ownSummaryRow({
  required String code,
  required String name,
  required List<CollectionEngagementRecord> engagements,
}) =>
    CollectorSummaryRow(
      code: code,
      name: name,
      collected: engagements
          .where((e) =>
              CollectionOutcome.countsAsCollected(e.status, kind: e.kind))
          .fold(0.0, (sum, e) => sum + e.amount),
      engagements: engagements.length,
      visits: countVisits(engagements),
      settledInvoices:
          engagements.where(CollectionOutcome.settlesInvoice).length,
      source: CollectorSummaryRow.sourcePhone,
    );

/// Teammates' rows from the server's summary, skipping [skipCode] (the
/// signed-in collector, whose own row is exact). Their case counts are the
/// server's and are kept by [withReconCounts].
List<CollectorSummaryRow> serverSummaryRows(TeamSummary summary,
    {String skipCode = ''}) {
  final skip = skipCode.trim().toUpperCase();
  return [
    for (final c in summary.collectors)
      // Codes compared as the phone keeps them (" jca " is JCA), so the
      // server can never stand in for the signed-in collector's own row.
      if (c.code.trim().toUpperCase() case final code
          when code.isNotEmpty && code != skip)
        CollectorSummaryRow(
          code: code,
          name: c.name,
          collected: c.collected,
          engagements: c.engagements,
          visits: c.visits,
          settledInvoices: c.settledInvoices,
          reconOpen: c.reconOpen,
          reconFlagged: c.reconFlagged,
          reconClosed: c.reconClosed,
          reconSteps: c.reconSteps,
          source: CollectorSummaryRow.sourceServer,
        ),
  ];
}

/// Teammates' rows from the team feed, one per collector, skipping
/// [skipCode] (the signed-in collector, whose own row is exact).
List<CollectorSummaryRow> teamSummaryRows(TeamActivityFeed feed,
    {String skipCode = ''}) {
  final skip = skipCode.trim().toUpperCase();
  final byCode = <String, List<TeamEngagement>>{};
  final names = <String, String>{};
  for (final e in feed.engagements) {
    final code = e.collectorCode.trim().toUpperCase();
    if (code.isEmpty || code == skip) continue;
    byCode.putIfAbsent(code, () => []).add(e);
    if (e.collectorName.trim().isNotEmpty) names[code] = e.collectorName.trim();
  }
  return [
    for (final MapEntry(key: code, value: rows) in byCode.entries)
      CollectorSummaryRow(
        code: code,
        name: names[code] ?? '',
        collected: rows
            .where((e) =>
                !e.isDeposit &&
                CollectionOutcome.countsAsCollected(
                    e.status.trim().isEmpty ? e.activityType : e.status))
            .fold(0.0, (sum, e) => sum + e.amount),
        engagements: rows.length,
        visits: rows
            .where((e) => e.clientCode.trim().isNotEmpty)
            .map((e) => '${e.date}|${e.clientCode.trim().toUpperCase()}')
            .toSet()
            .length,
        settledInvoices: rows
            .where((e) =>
                e.documentId.trim().isNotEmpty &&
                e.status.trim() == CollectionStatusColors.statusCollected)
            .map((e) => e.documentId.trim())
            .toSet()
            .length,
        source: CollectorSummaryRow.sourceFeed,
      ),
  ];
}

/// [rows] with each collector's case counts from the cases on this phone
/// ([reconByCollector]: open and flagged cases they hold now, ones that
/// closed in [yearMonth] while they held them) and the steps they logged in
/// [yearMonth]. A [CollectorSummaryRow.sourceServer] row keeps the server's
/// counts. A collector who only has cases gets a row of their own.
List<CollectorSummaryRow> withReconCounts(
  List<CollectorSummaryRow> rows,
  Iterable<({ReconCaseBundle bundle, ReconEvaluation evaluation})> cases, {
  required String yearMonth,
}) {
  final held = {
    for (final c in reconByCollector(cases.where((c) =>
        !c.evaluation.isClosed ||
        BReportMonth.contains(yearMonth, c.evaluation.dateClosed))))
      if (c.collectorCode.isNotEmpty) c.collectorCode: c,
  };
  final bundles = [for (final c in cases) c.bundle];
  // The first row for a code wins: the caller puts the signed-in collector's
  // own (exact) row first, and nothing later may replace it.
  final byCode = <String, CollectorSummaryRow>{};
  for (final r in rows) {
    byCode.putIfAbsent(r.code.trim().toUpperCase(), () => r);
  }
  for (final c in held.values) {
    byCode.putIfAbsent(
        c.collectorCode,
        () => CollectorSummaryRow(
            code: c.collectorCode,
            name: c.collectorName,
            source: CollectorSummaryRow.sourceFeed));
  }
  return [
    for (final MapEntry(key: code, value: row) in byCode.entries)
      if (row.source == CollectorSummaryRow.sourceServer)
        row
      else
        row.withRecon(
          open: held[code]?.open ?? 0,
          flagged: held[code]?.needsAttention ?? 0,
          closed: held[code]?.closed ?? 0,
          steps: reconStepsInMonth(bundles,
                  collectorCode: code, yearMonth: yearMonth)
              .length,
        ),
  ]..sort((a, b) {
      if (a.source != b.source) {
        return a.source == CollectorSummaryRow.sourcePhone ? -1 : 1;
      }
      final byCollected = b.collected.compareTo(a.collected);
      return byCollected != 0 ? byCollected : a.label.compareTo(b.label);
    });
}

const collectorsSummaryHeaders = [
  'Collector code',
  'Collector',
  'Collected',
  'Engagements',
  'Visits',
  'Settled invoices',
  'Recon open',
  'Recon flagged',
  'Recon closed',
  'Recon steps logged',
  'Data source',
  'Notes',
];

ReportTable buildCollectorsSummary(List<CollectorSummaryRow> rows,
    {required String yearMonth}) {
  int sumOf(int Function(CollectorSummaryRow) f) =>
      rows.fold(0, (sum, r) => sum + f(r));
  final collected = rows.fold(0.0, (sum, r) => sum + r.collected);
  return ReportTable(
    title: 'Collectors summary · $yearMonth',
    headers: collectorsSummaryHeaders,
    rows: [
      for (final r in rows)
        [
          ReportCell.text(r.code),
          ReportCell.text(r.label),
          ReportCell.money(r.collected),
          ReportCell.integer(r.engagements),
          ReportCell.integer(r.visits),
          ReportCell.integer(r.settledInvoices),
          ReportCell.integer(r.reconOpen),
          ReportCell.integer(r.reconFlagged),
          ReportCell.integer(r.reconClosed),
          ReportCell.integer(r.reconSteps),
          ReportCell.text(r.source),
          ReportCell.text(switch (r.source) {
            CollectorSummaryRow.sourceFeed =>
              'Uploaded work only; settled = invoices collected in full, '
                  'instalments not counted; recon counts are the cases on '
                  'this phone',
            CollectorSummaryRow.sourceServer =>
              'Uploaded work only; open and flagged cases as they stand now',
            _ => '',
          }),
        ],
    ],
    totals: rows.isEmpty
        ? null
        : [
            const ReportCell.text('Total'),
            ReportCell.blank,
            ReportCell.money(collected),
            ReportCell.integer(sumOf((r) => r.engagements)),
            ReportCell.integer(sumOf((r) => r.visits)),
            ReportCell.integer(sumOf((r) => r.settledInvoices)),
            ReportCell.integer(sumOf((r) => r.reconOpen)),
            ReportCell.integer(sumOf((r) => r.reconFlagged)),
            ReportCell.integer(sumOf((r) => r.reconClosed)),
            ReportCell.integer(sumOf((r) => r.reconSteps)),
            ReportCell.blank,
            ReportCell.blank,
          ],
    summary: {
      'Collectors': '${rows.length}',
      'Collected': BFormatter.formatPesoCurrency(collected),
      'Engagements': '${sumOf((r) => r.engagements)}',
    },
  );
}
