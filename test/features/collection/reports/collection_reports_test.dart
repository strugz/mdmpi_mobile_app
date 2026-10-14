import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_engagement_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reports/activity_report.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reports/collectors_summary_report.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reports/recon_detail_report.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reports/report_month.dart';
import 'package:mdmpi_mobile_app/data/models/report_table.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/models/team_engagement.dart';

/// The three exportable reports, built from plain data.

CollectionEngagementRecord _e(
  String engagedAt, {
  String kind = 'INVOICE',
  String item = '700001',
  String client = 'NLN-115',
  String status = 'Collected',
  double amount = 0,
  bool settled = false,
}) =>
    CollectionEngagementRecord(
      localRef: '$kind|$item|$engagedAt',
      collectorCode: 'JCA',
      kind: kind,
      itemId: item,
      clientId: client,
      clientName: 'Client $client',
      engagedAt: engagedAt,
      engagedOn: engagedAt.substring(0, 10),
      status: status,
      amount: amount,
      createdAt: engagedAt,
      settled: settled,
    );

ReconActivity _step(String id, ReconActivityType type, String at,
        {String by = 'JCA', double? amount}) =>
    ReconActivity(
        activityId: id,
        caseId: 'RC-1',
        dateTime: at,
        type: type,
        amount: amount,
        recordedBy: by);

final _case = ReconCaseBundle(
  reconCase: const ReconCase(
      caseId: 'RC-1',
      clientCode: 'NLN-115',
      clientName: 'Accusure',
      collectorCode: 'JCA',
      collectorName: 'Jay',
      dateOpened: '2026-09-01T09:00:00'),
  invoices: const [
    ReconCaseInvoice(invoiceNo: 'INV-1', amount: 1000),
    ReconCaseInvoice(invoiceNo: 'INV-2', amount: 500),
  ],
  activities: [
    _step('RA-1', ReconActivityType.soaSent, '2026-09-02T10:00:00',
        amount: 1500),
    _step('RA-2', ReconActivityType.followUp, '2026-09-05T10:00:00'),
    _step('RA-3', ReconActivityType.note, '2026-09-06T10:00:00', by: 'MAR'),
    _step('RA-4', ReconActivityType.paymentRecorded, '2026-09-07T10:00:00'),
    _step('RA-5', ReconActivityType.followUp, '2026-10-01T10:00:00'),
  ],
);

void main() {
  final now = DateTime.parse('2026-09-28T10:00:00+08:00');

  group('months', () {
    test('keys, first and last days, across the year end', () {
      final dec = DateTime(2025, 12, 31, 23, 59);
      expect(BReportMonth.key(dec), '2025-12');
      expect(BReportMonth.first(dec), DateTime(2025, 12));
      expect(BReportMonth.last(DateTime(2026, 2)), DateTime(2026, 2, 28));
      expect(BReportMonth.first(DateTime(2025, 12 + 1)), DateTime(2026, 1));
      expect(BReportMonth.label(DateTime(2026, 1)), 'January 2026');
    });

    test('contains compares the calendar month, whatever the zone flag', () {
      expect(BReportMonth.contains('2026-09', DateTime.utc(2026, 9, 30, 23)),
          isTrue);
      expect(BReportMonth.contains('2026-09', DateTime(2026, 10, 1)), isFalse);
      expect(BReportMonth.contains('2026-09', null), isFalse);
    });

    test('yes/no cells', () {
      expect(const ReportCell.yesNo(true).csv, 'Y');
      expect(const ReportCell.yesNo(false).display, 'N');
    });
  });

  group('Activity report', () {
    final engagements = [
      _e('2026-09-03T10:00:00', amount: 1000, settled: true),
      _e('2026-09-03T15:00:00',
          item: '700002', status: 'Partially Collected', amount: 200),
      _e('2026-09-04T09:00:00',
          item: '700003', status: 'Deposit', amount: 5000),
      _e('2026-09-05T09:00:00',
          kind: 'ADVANCE',
          item: 'AP-1',
          status: 'Advanced Payment',
          amount: 800),
      _e('2026-09-02T08:00:00',
          kind: 'ACCOUNT', item: '', client: 'NCR-1', status: 'Follow Up'),
    ];
    final table = buildActivityReport(ActivityReportInput(
      collectorCode: 'jca',
      yearMonth: '2026-09',
      engagements: engagements,
      cases: [_case],
    ));

    test('only real collections count toward the total', () {
      expect(table.summary['Collected'], contains('1,200.00'));
      expect(table.totals![7].csv, '1200.00');
    });

    test('settled, engagements and visits', () {
      expect(table.summary['Settled invoices'], '1');
      expect(table.summary['Engagements'], '5');
      // (09-03, NLN-115), (09-04, NLN-115), (09-02, NCR-1); the advance is not a visit.
      expect(table.summary['Visits'], '3');
    });

    test('my own logged recon steps in the month, never automatic ones', () {
      expect(table.summary['Recon steps'], '2',
          reason: 'SOA and one follow up');
      final recon = table.rows.where((r) => r[2].csv == 'Reconciliation step');
      expect(recon.map((r) => r[6].csv), ['SOA sent', 'Follow up']);
      expect(recon.every((r) => r[8].csv == 'N'), isTrue);
    });

    test('rows are in time order', () {
      final days = table.rows.map((r) => r[0].csv).toList();
      expect(days, [...days]..sort());
      expect(table.rows.first[2].csv, 'Account');
    });

    test('an empty month has no rows and no totals', () {
      final empty = buildActivityReport(const ActivityReportInput(
          collectorCode: 'JCA', yearMonth: '2026-08', engagements: []));
      expect(empty.isEmpty, isTrue);
      expect(empty.totals, isNull);
    });
  });

  group('Collectors summary', () {
    final own = ownSummaryRow(
        code: 'JCA',
        name: 'Jay',
        engagements: [_e('2026-09-03T10:00:00', amount: 1000, settled: true)]);
    final feed =
        TeamActivityFeed(from: '2026-09-01', to: '2026-09-30', engagements: [
      const TeamEngagement(
          kind: 'Engagement',
          id: 1,
          collectorCode: 'MAR',
          collectorName: 'Mar',
          clientCode: 'C1',
          documentId: 'D1',
          status: 'Collected',
          amount: 300,
          date: '2026-09-02'),
      const TeamEngagement(
          kind: 'Engagement',
          id: 2,
          collectorCode: 'MAR',
          clientCode: 'C1',
          documentId: 'D2',
          status: 'Partial Payment',
          amount: 100,
          date: '2026-09-02'),
      const TeamEngagement(
          kind: 'Deposit',
          id: 3,
          collectorCode: 'MAR',
          amount: 999,
          date: '2026-09-03'),
      const TeamEngagement(
          kind: 'Engagement',
          id: 4,
          collectorCode: 'jca',
          status: 'Collected',
          amount: 77,
          date: '2026-09-03'),
    ]);

    test('team rows skip my own code and leave deposits out of collected', () {
      final rows = teamSummaryRows(feed, skipCode: 'JCA');
      expect(rows.single.code, 'MAR');
      expect(rows.single.collected, 400);
      expect(rows.single.visits, 1);
      expect(rows.single.settledInvoices, 1);
    });

    test('case counts per holder, mine first, totals summed', () {
      final rows = withReconCounts(
        [own, ...teamSummaryRows(feed, skipCode: 'JCA')],
        [(bundle: _case, evaluation: _case.evaluate(now: now))],
        yearMonth: '2026-09',
      );
      expect(rows.first.code, 'JCA');
      expect(rows.first.reconOpen, 1);
      expect(rows.first.reconSteps, 2);
      expect(rows.last.reconSteps, 1, reason: "Mar's note");
      final table = buildCollectorsSummary(rows, yearMonth: '2026-09');
      expect(table.totals![2].csv, '1400.00');
      expect(table.rows.last[11].csv, contains('Uploaded work only'));
    });

    const summary = TeamSummary(month: '2026-09', collectors: [
      TeamCollectorSummary(
          code: 'JCA', name: 'Jay', collected: 77, engagements: 1),
      TeamCollectorSummary(
          code: 'MAR',
          name: 'Mar',
          collected: 400,
          engagements: 3,
          visits: 1,
          settledInvoices: 2,
          reconOpen: 4,
          reconFlagged: 1,
          reconClosed: 2,
          reconSteps: 5),
    ]);

    test('server rows skip my own code and keep the server case counts', () {
      final rows = withReconCounts(
        [own, ...serverSummaryRows(summary, skipCode: 'jca')],
        [(bundle: _case, evaluation: _case.evaluate(now: now))],
        yearMonth: '2026-09',
      );
      expect(rows.map((r) => r.code), ['JCA', 'MAR']);
      final mar = rows.last;
      expect(mar.source, CollectorSummaryRow.sourceServer);
      expect(mar.settledInvoices, 2, reason: 'instalments counted');
      expect(mar.reconOpen, 4);
      expect(mar.reconSteps, 5,
          reason: "the server's count, not the note on this phone");
      expect(rows.first.reconOpen, 1, reason: 'my own row: this phone');
      final table = buildCollectorsSummary(rows, yearMonth: '2026-09');
      expect(table.rows.last[10].csv, 'Server');
      expect(table.rows.last[11].csv, contains('as they stand now'));
    });

    test('a case closed in another month is not counted as closed', () {
      final closed = ReconCaseBundle(
        reconCase: _case.reconCase,
        invoices: _case.invoices,
        activities: [
          ..._case.activities.take(2),
          _step('RA-9', ReconActivityType.caseNotCompleted,
              '2026-09-10T10:00:00'),
        ],
      );
      final cases = [(bundle: closed, evaluation: closed.evaluate(now: now))];
      expect(
          withReconCounts([own], cases, yearMonth: '2026-09')
              .single
              .reconClosed,
          1);
      expect(
          withReconCounts([own], cases, yearMonth: '2026-10')
              .single
              .reconClosed,
          0);
    });

    test('closed at the month edge counts in its own Manila month', () {
      int closedIn(String closedAt, String ym) {
        final b = ReconCaseBundle(
          reconCase: _case.reconCase,
          invoices: _case.invoices,
          activities: [
            ..._case.activities.take(2),
            _step('RA-9', ReconActivityType.caseNotCompleted, closedAt),
          ],
        );
        return withReconCounts(
                [own], [(bundle: b, evaluation: b.evaluate(now: now))],
                yearMonth: ym)
            .single
            .reconClosed;
      }

      expect(closedIn('2026-09-30T23:59:59', '2026-09'), 1);
      expect(closedIn('2026-09-30T23:59:59', '2026-10'), 0);
      expect(closedIn('2026-10-01T00:00:00', '2026-09'), 0);
      expect(closedIn('2026-10-01T00:00:00', '2026-10'), 1);
    });

    test('no close date is never "closed in the month"', () {
      expect(BReportMonth.contains('2026-09', null), isFalse);
    });

    test('the summary reads PascalCase and camelCase alike', () {
      final parsed = TeamSummary.fromJson({
        'Month': '2026-09',
        'Collectors': [
          {
            'Code': ' mar ',
            'Name': 'Mar',
            'Collected': 400.5,
            'SettledInvoices': 2,
            'ReconFlagged': 1,
          },
          {'code': 'EMP2', 'reconSteps': 3},
          {'Code': ''},
        ],
      });
      expect(parsed.month, '2026-09');
      expect(parsed.collectors.map((c) => c.code), ['MAR', 'EMP2']);
      expect(parsed.collectors.first.collected, 400.5);
      expect(parsed.collectors.first.settledInvoices, 2);
      expect(parsed.collectors.first.reconFlagged, 1);
      expect(parsed.collectors.last.reconSteps, 3);
    });
  });

  group('Reconciliation detail', () {
    final table = buildReconDetail(
        [(bundle: _case, evaluation: _case.evaluate(now: now))]);
    int col(String h) => reconDetailHeaders.indexOf(h);

    test('one row per invoice; case amounts on the first only', () {
      expect(table.rows, hasLength(2));
      expect(table.rows[0][col('Invoice')].csv, 'INV-1');
      expect(table.rows[0][col('Case amount under reconciliation')].csv,
          '1500.00');
      expect(table.rows[1][col('Case amount under reconciliation')].csv, '');
    });

    test('stages: SOA done, follow ups counted, letter next', () {
      final r = table.rows.first;
      expect(r[col('SOA on')].csv, '2026-09-02');
      expect(r[col('Follow ups')].csv, '2');
      expect(r[col('Last follow up')].csv, '2026-10-01');
      expect(r[col('Current stage')].csv, 'Collection letter');
    });
  });
}
