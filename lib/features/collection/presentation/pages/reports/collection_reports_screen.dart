import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/data/models/report_table.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_reports_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/reports/widgets/report_widgets.dart';

/// Settings → Reports: the three exportable reports.
class CollectionReportsScreen extends StatelessWidget {
  const CollectionReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget tile(String key, IconData icon, String title, String subtitle,
            String route) =>
        Card(
          child: ListTile(
            key: ValueKey(key),
            leading: Icon(icon, color: BCollectionColors.primary),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Iconsax.arrow_right_3, size: 18),
            onTap: () => Get.toNamed(route),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        children: [
          tile(
              'reports-activity',
              Iconsax.calendar_tick,
              'Activity report',
              'Everything you did in a month, for month-end',
              BRoutes.collectionReportActivity),
          tile(
              'reports-collectors',
              Iconsax.people,
              'Collectors summary',
              CollectionReportsController.instance.isHead
                  ? 'Each collector\'s month: collected, visits, cases'
                  : 'Your month: collected, visits, cases',
              BRoutes.collectionReportCollectors),
          tile(
              'reports-recon',
              Iconsax.document_text,
              'Reconciliation detail',
              'Every case and invoice, with its stage and flags',
              BRoutes.collectionReportRecon),
          const SizedBox(height: BSizes.spaceBtwItems),
          Text(
              'Reports are saved as CSV (opens in Excel) where you choose, or '
              'shared. They hold client names and amounts: keep them to '
              'work folders and chats.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: BCollectionColors.inkMuted)),
        ],
      ),
    );
  }
}

/// The month-end Activity report.
class ActivityReportScreen extends StatefulWidget {
  const ActivityReportScreen({super.key});

  @override
  State<ActivityReportScreen> createState() => _ActivityReportScreenState();
}

class _ActivityReportScreenState extends State<ActivityReportScreen> {
  final c = CollectionReportsController.instance;

  @override
  void initState() {
    super.initState();
    c.loadActivity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity report')),
      bottomNavigationBar: ReportExportBar(
          table: () => c.activityTable.value, fileName: c.activityFileName),
      body: Obx(() {
        final table = c.activityTable.value;
        return ReportBody(
          loading: c.activityLoading.value,
          error: c.activityError.value,
          onRetry: c.loadActivity,
          child: ReportRows(
            table: table ?? _empty,
            // Date, Type · Client · Outcome, Amount
            title: 4,
            subtitle: const [0, 1, 2, 6],
            trailing: 7,
            emptyText: 'Nothing recorded this month.',
            header: _Header(
              stepper: ReportMonthStepper(onChanged: c.loadActivity),
              table: table,
            ),
          ),
        );
      }),
    );
  }
}

/// The Collectors summary.
class CollectorsSummaryScreen extends StatefulWidget {
  const CollectorsSummaryScreen({super.key});

  @override
  State<CollectorsSummaryScreen> createState() =>
      _CollectorsSummaryScreenState();
}

class _CollectorsSummaryScreenState extends State<CollectorsSummaryScreen> {
  final c = CollectionReportsController.instance;

  @override
  void initState() {
    super.initState();
    c.loadCollectors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collectors summary')),
      bottomNavigationBar: ReportExportBar(
          table: () => c.collectorsTable.value, fileName: c.collectorsFileName),
      body: Obx(() {
        final table = c.collectorsTable.value;
        final teamError = c.teamError.value;
        return ReportBody(
          loading: c.collectorsLoading.value,
          error: c.collectorsError.value,
          onRetry: c.loadCollectors,
          child: ReportRows(
            table: table ?? _empty,
            // Collector, Engagements · Visits · Settled, Collected
            title: 1,
            subtitle: const [3, 4, 5, 10],
            trailing: 2,
            header: _Header(
              stepper: ReportMonthStepper(onChanged: c.loadCollectors),
              table: table,
              note: teamError == null
                  ? null
                  : 'Team figures unavailable: $teamError',
            ),
          ),
        );
      }),
    );
  }
}

/// The Reconciliation detail: one row per invoice of each case.
class ReconDetailReportScreen extends StatelessWidget {
  const ReconDetailReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = CollectionReportsController.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Reconciliation detail')),
      bottomNavigationBar: ReportExportBar(
          table: () => c.reconTable.value, fileName: c.reconFileName),
      body: Obx(() {
        final table = c.reconTable.value;
        return ReportRows(
          table: table,
          // Client, Invoice · Status · Stage, Still owed
          title: 2,
          subtitle: const [22, 25, 12],
          trailing: 24,
          emptyText: 'No cases here.',
          header: _Header(stepper: const _ReconFilters(), table: table),
        );
      }),
    );
  }
}

const _empty = ReportTable(title: '', headers: [], rows: []);

/// My cases / Team and Open / Closed / All for the Reconciliation detail.
class _ReconFilters extends StatelessWidget {
  const _ReconFilters();

  @override
  Widget build(BuildContext context) {
    final c = CollectionReportsController.instance;
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<ReconScope>(
              key: const ValueKey('report-recon-scope'),
              segments: [
                for (final s in ReconScope.values)
                  ButtonSegment(value: s, label: Text(s.label)),
              ],
              selected: {c.reconScope.value},
              onSelectionChanged: (s) => c.reconScope.value = s.first,
            ),
            const SizedBox(height: BSizes.sm),
            SegmentedButton<ReconDashboardFilter>(
              key: const ValueKey('report-recon-filter'),
              segments: [
                for (final f in ReconDashboardFilter.values)
                  ButtonSegment(value: f, label: Text(f.label)),
              ],
              selected: {c.reconFilter.value},
              onSelectionChanged: (s) => c.reconFilter.value = s.first,
            ),
          ],
        ));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.stepper, required this.table, this.note});

  final Widget stepper;
  final ReportTable? table;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BSizes.spaceBtwItems),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          stepper,
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: BSizes.xs),
              child: Text(note!,
                  key: const ValueKey('report-note'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: BCollectionColors.danger)),
            ),
          if (table != null && table!.summary.isNotEmpty) ...[
            const SizedBox(height: BSizes.sm),
            ReportSummary(table: table!),
          ],
        ],
      ),
    );
  }
}
