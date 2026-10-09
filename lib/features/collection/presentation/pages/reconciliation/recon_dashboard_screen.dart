import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_status_style.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/category_detail_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/reconciliation/recon_case_screen.dart';

/// The collector's reconciliation cases (Home → Reconciliation): open ones
/// first, the one untouched longest at the top, so the case most likely to be
/// forgotten is seen first. Closed ones (completed, not completed, escalated)
/// are kept as history behind the Closed and All filters. Accounts marked for
/// reconciliation that nobody has acquired yet are one tap away.
class ReconDashboardScreen extends StatelessWidget {
  const ReconDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ReconciliationController.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reconciliation'),
        actions: [
          IconButton(
            key: const ValueKey('recon-open-reports'),
            tooltip: 'Reports',
            icon: const Icon(Iconsax.chart_2),
            onPressed: () => Get.toNamed(BRoutes.reconciliationReports),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(() {
          final filter = controller.dashboardFilter.value;
          final scope = controller.dashboardScope.value;
          final cases = controller.dashboardCases;
          final waiting = Get.isRegistered<CollectionActivityController>()
              ? CollectionActivityController
                  .instance.reconciliationAccounts.length
              : 0;
          final open = controller.dashboardOpenCases;
          final under = open.fold<double>(
              0, (s, c) => s + c.evaluation.amountUnderReconciliation);
          return ListView(
            padding: EdgeInsets.fromLTRB(
                BSizes.defaultSpace,
                BSizes.defaultSpace,
                BSizes.defaultSpace,
                BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom),
            children: [
              // Whose cases: mine, or the whole team's (every open case
              // reaches every phone, so the next visitor sees the standing).
              SegmentedButton<ReconScope>(
                key: const ValueKey('recon-dashboard-scope'),
                showSelectedIcon: false,
                segments: [
                  for (final s in ReconScope.values)
                    ButtonSegment(
                        value: s,
                        label: Text(s.label,
                            key: ValueKey('recon-scope-${s.name}'))),
                ],
                selected: {scope},
                onSelectionChanged: (s) =>
                    controller.dashboardScope.value = s.first,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text(
                '${open.length} open ${open.length == 1 ? 'case' : 'cases'} · '
                '${BFormatter.formatPesoCurrency(under)} under reconciliation',
                key: const ValueKey('recon-dashboard-summary'),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: BCollectionColors.inkSecondary),
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              if (waiting > 0)
                Card(
                  margin: const EdgeInsets.only(bottom: BSizes.spaceBtwItems),
                  child: ListTile(
                    key: const ValueKey('recon-waiting'),
                    leading: const Icon(Iconsax.box_add,
                        color: BCollectionColors.reconcile),
                    title: Text(
                        '$waiting ${waiting == 1 ? 'account' : 'accounts'} '
                        'waiting to be acquired'),
                    trailing: const Icon(Iconsax.arrow_right_3, size: 16),
                    onTap: () => Get.to(() => const CategoryDetailScreen(
                        title: 'Reconciliation',
                        color: BCollectionColors.reconcile)),
                  ),
                ),
              Wrap(
                spacing: BSizes.sm,
                runSpacing: BSizes.xs,
                children: [
                  for (final f in ReconDashboardFilter.values)
                    ChoiceChip(
                      key: ValueKey('recon-filter-${f.name}'),
                      label: Text(f.label),
                      selected: f == filter,
                      onSelected: (_) => controller.dashboardFilter.value = f,
                    ),
                ],
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              if (cases.isEmpty &&
                  !controller.isLoading.value &&
                  filter != ReconDashboardFilter.all &&
                  controller.casesIn(scope).isNotEmpty)
                _NoneHere(filter: filter)
              else if (cases.isEmpty && !controller.isLoading.value)
                const _Empty()
              else
                for (final c in cases)
                  _CaseCard(
                      view: c,
                      // Whose it is matters only when it may not be mine.
                      holder: scope == ReconScope.team && !controller.holds(c)
                          ? (c.reconCase.collectorName.trim().isNotEmpty
                              ? c.reconCase.collectorName.trim()
                              : c.reconCase.collectorCode.trim())
                          : null),
            ],
          );
        }),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: BSizes.spaceBtwSections),
        child: Column(
          children: [
            const Icon(Iconsax.document_text,
                size: 40, color: BCollectionColors.inkMuted),
            const SizedBox(height: BSizes.sm),
            Text('No reconciliation cases yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: BSizes.xs),
            Text(
              'Open one from the Calendar: add an engagement, then '
              'Reconciliation.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: BCollectionColors.inkSecondary),
            ),
          ],
        ),
      );
}

class _NoneHere extends StatelessWidget {
  const _NoneHere({required this.filter});

  final ReconDashboardFilter filter;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: BSizes.spaceBtwSections),
        child: Text(
          filter == ReconDashboardFilter.open
              ? 'No open cases. Closed ones are under Closed.'
              : 'No closed cases yet.',
          key: const ValueKey('recon-filter-empty'),
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: BCollectionColors.inkSecondary),
        ),
      );
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.view, this.holder});

  final ReconCaseView view;

  /// Who holds the case when it is not mine: a name, '' for nobody (released
  /// and not yet acquired), or null to say nothing.
  final String? holder;

  static final DateFormat _date = DateFormat('MMM d, yyyy');

  /// Open: who acts next and what is still owed. Closed: when, and what the
  /// case covered.
  String _standing() {
    final e = view.evaluation;
    if (!e.isClosed) {
      return '${BReconStyle.nextActorLabel(e.nextActor)} · '
          '${e.openInvoices.length} open · '
          '${BFormatter.formatPesoCurrency(e.amountUnderReconciliation)}';
    }
    final invoices = view.bundle.invoices;
    final total = invoices.fold<double>(0, (s, i) => s + i.amount);
    return [
      if (e.dateClosed != null) 'Closed ${_date.format(e.dateClosed!)}',
      '${invoices.length} ${invoices.length == 1 ? 'invoice' : 'invoices'}',
      BFormatter.formatPesoCurrency(total),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = view.evaluation;
    final last = e.lastActivity;
    return Card(
      key: ValueKey('recon-case-${view.caseId}'),
      margin: const EdgeInsets.only(bottom: BSizes.spaceBtwItems),
      child: InkWell(
        borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
        onTap: () =>
            Get.toNamed(BRoutes.reconciliationCase, arguments: view.caseId),
        child: Padding(
          padding: const EdgeInsets.all(BSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(view.reconCase.clientName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: BSizes.sm),
                  Flexible(
                    child: ReconChip(
                        label: e.status.label,
                        color: BReconStyle.caseColor(e.status)),
                  ),
                ],
              ),
              const SizedBox(height: BSizes.xs),
              Text(
                last == null
                    ? 'Nothing logged yet · opened '
                        '${ReconCaseScreen.ago(e.daysSinceLastActivity)}'
                    : 'Last: ${last.type.label} · '
                        '${ReconCaseScreen.ago(e.daysSinceLastActivity)}',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                _standing(),
                key: ValueKey('recon-case-standing-${view.caseId}'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: BCollectionColors.inkSecondary),
              ),
              if (holder != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      const Icon(Iconsax.user,
                          size: 12, color: BCollectionColors.inkMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          holder!.isEmpty
                              ? 'No holder · waiting to be acquired'
                              : 'Held by $holder',
                          key: ValueKey('recon-case-holder-${view.caseId}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: BCollectionColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              if (e.flags.isNotEmpty) ...[
                const SizedBox(height: BSizes.sm),
                Wrap(
                  spacing: BSizes.xs,
                  runSpacing: BSizes.xs,
                  children: [
                    for (final f in e.flags)
                      ReconChip(
                          label: f.label,
                          color: BReconStyle.flagColor(f),
                          icon: Iconsax.warning_2),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
