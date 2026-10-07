import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_posting.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_summary.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/reconciliation/recon_case_screen.dart';

/// The Reconciliation Tracker's reports: the summary, the aging of open cases,
/// and the invoices validated paid that Accounting has yet to post (Step 9).
/// A collector sees their own cases; the Head sees every case on the phone.
class ReconReportsScreen extends StatelessWidget {
  const ReconReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ReconciliationController.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Reconciliation reports')),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(() {
          // Read so the Obx follows reloads; the figures come from it.
          controller.cases.length;
          final summary = controller.summary;
          final posting = controller.awaitingPosting;
          return ListView(
            padding: EdgeInsets.fromLTRB(
                BSizes.defaultSpace,
                BSizes.defaultSpace,
                BSizes.defaultSpace,
                BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom),
            children: [
              Text(
                controller.reportsCoverTeam
                    ? 'Every case on this phone (the team)'
                    : 'Your cases',
                key: const ValueKey('recon-reports-scope'),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: BCollectionColors.inkSecondary),
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              _SummaryCard(summary: summary),
              const SizedBox(height: BSizes.spaceBtwSections),
              _Heading('Aging of open cases'),
              _AgingCard(summary: summary),
              const SizedBox(height: BSizes.spaceBtwSections),
              _Heading('Validated, awaiting posting (${posting.length})'),
              if (posting.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: BSizes.sm),
                  child: Text('Nothing is waiting for Accounting.'),
                )
              else
                for (final p in posting) _PostingRow(item: p),
            ],
          );
        }),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: BSizes.sm),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final ReconSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget stat(String label, int value, Color color) => Expanded(
          child: Column(
            children: [
              Text('$value',
                  key: ValueKey('recon-summary-$label'),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w700)),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: BCollectionColors.inkSecondary)),
            ],
          ),
        );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(BSizes.md),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                stat('Total', summary.totalCases, BCollectionColors.ink),
                stat('Open', summary.open, BCollectionColors.primary),
                stat('Completed', summary.completed, BCollectionColors.success),
              ],
            ),
            const SizedBox(height: BSizes.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                stat('Not completed', summary.notCompleted,
                    BCollectionColors.neutral),
                stat('Escalated', summary.escalated, BCollectionColors.danger),
                const Expanded(child: SizedBox()),
              ],
            ),
            const Divider(height: BSizes.spaceBtwSections),
            _MoneyRow('Under reconciliation', summary.amountUnderReconciliation,
                BCollectionColors.reconcile),
            const SizedBox(height: BSizes.xs),
            _MoneyRow('Validated paid', summary.amountValidatedPaid,
                BCollectionColors.success),
          ],
        ),
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow(this.label, this.amount, this.color);

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Flexible(
          child: Text(BFormatter.formatPesoCurrency(amount),
              key: ValueKey('recon-summary-$label'),
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _AgingCard extends StatelessWidget {
  const _AgingCard({required this.summary});

  final ReconSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final most = summary.aging.values.fold<int>(0, (m, v) => v > m ? v : m);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(BSizes.md),
        child: Column(
          children: [
            for (final b in ReconAgingBucket.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                        width: 92,
                        child: Text(b.label, style: theme.textTheme.bodySmall)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: most == 0 ? 0 : summary.aging[b]! / most,
                          minHeight: 10,
                          backgroundColor: BCollectionColors.surfaceMuted,
                          color: b == ReconAgingBucket.over30
                              ? BCollectionColors.danger
                              : BCollectionColors.reconcile,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text('${summary.aging[b]}',
                          key: ValueKey('recon-aging-${b.name}'),
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PostingRow extends StatelessWidget {
  const _PostingRow({required this.item});

  final ReconAwaitingPosting item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: ValueKey('recon-posting-${item.invoiceNo}'),
      margin: const EdgeInsets.only(bottom: BSizes.sm),
      child: ListTile(
        onTap: () =>
            Get.toNamed(BRoutes.reconciliationCase, arguments: item.caseId),
        leading:
            const Icon(Iconsax.shield_tick, color: BCollectionColors.success),
        title: Text('${item.invoiceNo} · ${item.clientName}',
            maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            BFormatter.formatPesoCurrency(item.amount),
            if (item.validatedAt != null)
              'validated ${ReconCaseScreen.when(item.validatedAt!)}',
            if (item.proof.isNotEmpty) 'proof: ${item.proof}',
            if (item.photos > 0)
              '${item.photos} ${item.photos == 1 ? 'photo' : 'photos'}',
          ].join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Iconsax.arrow_right_3, size: 16),
      ),
    );
  }
}
