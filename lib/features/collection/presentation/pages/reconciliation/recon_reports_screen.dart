import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_posting.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_status_style.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_summary.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/reconciliation/recon_case_screen.dart';

/// The Reconciliation Tracker's reports, over my cases or the team's:
/// the summary (counts, amounts, whose turn), what needs attention (the
/// flagged cases), the aging of open cases (each bucket opens to its cases),
/// who holds what (team), and the invoices validated paid that Accounting
/// has yet to post (Step 9). Every figure leads to its cases.
class ReconReportsScreen extends StatelessWidget {
  const ReconReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ReconciliationController.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reconciliation reports'),
        actions: [
          IconButton(
            key: const ValueKey('recon-open-detail-export'),
            tooltip: 'Detail report (CSV)',
            icon: const Icon(Iconsax.document_download),
            onPressed: () => Get.toNamed(BRoutes.collectionReportRecon),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(() {
          // Read so the Obx follows reloads; the figures come from it.
          controller.cases.length;
          final scope = controller.reportScope.value;
          final summary = controller.summary;
          final attention = controller.reportAttention;
          final posting = controller.awaitingPosting;
          final collectors = controller.byCollector;
          return ListView(
            padding: EdgeInsets.fromLTRB(
                BSizes.defaultSpace,
                BSizes.defaultSpace,
                BSizes.defaultSpace,
                BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom),
            children: [
              SegmentedButton<ReconScope>(
                key: const ValueKey('recon-reports-scope'),
                showSelectedIcon: false,
                segments: [
                  for (final s in ReconScope.values)
                    ButtonSegment(
                        value: s,
                        label: Text(s.label,
                            key: ValueKey('recon-reports-scope-${s.name}'))),
                ],
                selected: {scope},
                onSelectionChanged: (s) =>
                    controller.reportScope.value = s.first,
              ),
              const SizedBox(height: BSizes.xs),
              Text(
                scope == ReconScope.team
                    ? 'Every case on this phone, whoever holds it'
                    : 'Cases you hold, and closed ones you worked on',
                key: const ValueKey('recon-reports-scope-note'),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: BCollectionColors.inkSecondary),
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              _SummaryCard(summary: summary),
              const SizedBox(height: BSizes.spaceBtwSections),
              _Heading('Needs attention (${attention.length})'),
              _AttentionCard(summary: summary, cases: attention),
              const SizedBox(height: BSizes.spaceBtwSections),
              _Heading('Aging of open cases'),
              _AgingCard(summary: summary, controller: controller),
              if (scope == ReconScope.team) ...[
                const SizedBox(height: BSizes.spaceBtwSections),
                _Heading('Who holds what'),
                _CollectorsCard(rows: collectors),
              ],
              const SizedBox(height: BSizes.spaceBtwSections),
              _Heading('Validated, awaiting posting (${posting.length})'),
              if (posting.isEmpty)
                const _Quiet('Nothing is waiting for Accounting.')
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

/// A one-line "nothing here" under a heading.
class _Quiet extends StatelessWidget {
  const _Quiet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: BSizes.sm),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: BCollectionColors.inkSecondary)),
      );
}

/// Counts, amounts, and whose turn the open cases are waiting on.
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            if (summary.open > 0) ...[
              const Divider(height: BSizes.spaceBtwSections),
              Text('OPEN CASES · WHOSE TURN',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: BCollectionColors.inkMuted, letterSpacing: 0.8)),
              const SizedBox(height: BSizes.sm),
              _StatusBar(summary: summary),
              const SizedBox(height: BSizes.sm),
              Wrap(
                spacing: BSizes.md,
                runSpacing: BSizes.xs,
                children: [
                  for (final s in ReconSummary.openStatuses)
                    _Legend(
                      color: BReconStyle.caseColor(s),
                      label: '${BReconStyle.statusTurnLabel(s)} '
                          '${summary.openByStatus[s]}',
                      key: ValueKey('recon-status-${s.name}'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One bar split by status, in proportion.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.summary});

  final ReconSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.open;
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (final s in ReconSummary.openStatuses)
              if (summary.openByStatus[s]! > 0)
                Expanded(
                  flex: summary.openByStatus[s]!,
                  child: ColoredBox(color: BReconStyle.caseColor(s)),
                ),
            if (total == 0)
              const Expanded(
                  child: ColoredBox(color: BCollectionColors.surfaceMuted)),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      );
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

/// The flags across the open cases, then the flagged cases themselves, the
/// one untouched longest first. Each leads to its case.
class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.summary, required this.cases});

  final ReconSummary summary;
  final List<ReconCaseView> cases;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (cases.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(BSizes.md),
          child: Row(
            children: [
              const Icon(Iconsax.shield_tick,
                  color: BCollectionColors.success, size: 20),
              const SizedBox(width: BSizes.sm),
              Expanded(
                child: Text('No open case is flagged.',
                    key: const ValueKey('recon-attention-none'),
                    style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                BSizes.md, BSizes.md, BSizes.md, BSizes.sm),
            child: Wrap(
              spacing: BSizes.xs,
              runSpacing: BSizes.xs,
              children: [
                for (final f in ReconFlag.values)
                  if (summary.flagged[f]! > 0)
                    ReconChip(
                        key: ValueKey('recon-flag-${f.name}'),
                        label: '${f.label} · ${summary.flagged[f]}',
                        color: BReconStyle.flagColor(f),
                        icon: Iconsax.warning_2),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final c in cases) _CaseRow(view: c, prefix: 'recon-attention'),
        ],
      ),
    );
  }
}

/// A case in a report list: the client, where it stands, and its flags.
class _CaseRow extends StatelessWidget {
  const _CaseRow({required this.view, required this.prefix});

  final ReconCaseView view;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = view.evaluation;
    final last = e.lastActivity;
    return InkWell(
      key: ValueKey('$prefix-${view.caseId}'),
      onTap: () =>
          Get.toNamed(BRoutes.reconciliationCase, arguments: view.caseId),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: BSizes.md, vertical: BSizes.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(view.reconCase.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    '${last == null ? 'Nothing logged' : last.type.label} · '
                    '${ReconCaseScreen.ago(e.daysSinceLastActivity)} · '
                    '${BFormatter.formatPesoCurrency(e.amountUnderReconciliation)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: BCollectionColors.inkSecondary),
                  ),
                  if (e.flags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
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
                    ),
                ],
              ),
            ),
            const SizedBox(width: BSizes.sm),
            const Icon(Iconsax.arrow_right_3,
                size: 16, color: BCollectionColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// Open cases by how long they have been open. Each bucket shows its count
/// and amount, and opens to its cases.
class _AgingCard extends StatefulWidget {
  const _AgingCard({required this.summary, required this.controller});

  final ReconSummary summary;
  final ReconciliationController controller;

  @override
  State<_AgingCard> createState() => _AgingCardState();
}

class _AgingCardState extends State<_AgingCard> {
  ReconAgingBucket? _open;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.summary;
    final most = summary.aging.values.fold<int>(0, (m, v) => v > m ? v : m);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BSizes.xs),
        child: Column(
          children: [
            for (final b in ReconAgingBucket.values) ...[
              InkWell(
                key: ValueKey('recon-aging-row-${b.name}'),
                onTap: summary.aging[b]! == 0
                    ? null
                    : () => setState(() => _open = _open == b ? null : b),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: BSizes.md, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 76,
                          child:
                              Text(b.label, style: theme.textTheme.bodySmall)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: most == 0 ? 0 : summary.aging[b]! / most,
                                minHeight: 10,
                                backgroundColor: BCollectionColors.surfaceMuted,
                                color: _agingColor(b),
                              ),
                            ),
                            if (summary.aging[b]! > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  BFormatter.formatPesoCurrency(
                                      summary.agingAmount[b]!),
                                  key: ValueKey('recon-aging-amount-${b.name}'),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: BCollectionColors.inkMuted),
                                ),
                              ),
                          ],
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
                      Icon(
                        _open == b ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                        size: 14,
                        color: summary.aging[b]! == 0
                            ? Colors.transparent
                            : BCollectionColors.inkMuted,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _open == b
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Divider(height: 1),
                          for (final c in widget.controller.reportCasesAging(b))
                            _CaseRow(view: c, prefix: 'recon-aging-case'),
                          const Divider(height: 1),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Older is louder: the reconcile tint up to 15 days, amber to 30, red past.
  static Color _agingColor(ReconAgingBucket b) => switch (b) {
        ReconAgingBucket.upTo7 ||
        ReconAgingBucket.upTo15 =>
          BCollectionColors.reconcile,
        ReconAgingBucket.upTo30 => BCollectionColors.warning,
        ReconAgingBucket.over30 => BCollectionColors.danger,
      };
}

/// Team: one row per collector, the most open cases first.
class _CollectorsCard extends StatelessWidget {
  const _CollectorsCard({required this.rows});

  final List<ReconCollectorSummary> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (rows.isEmpty) {
      return const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(BSizes.md),
          child: Text('No cases on this phone yet.'),
        ),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BSizes.xs),
        child: Column(
          children: [
            for (final r in rows)
              Padding(
                key: ValueKey('recon-collector-${r.collectorCode}'),
                padding: const EdgeInsets.symmetric(
                    horizontal: BSizes.md, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: r.collectorCode.isEmpty
                          ? BCollectionColors.surfaceMuted
                          : BCollectionColors.primarySoft,
                      child: Icon(
                          r.collectorCode.isEmpty
                              ? Iconsax.box_add
                              : Iconsax.user,
                          size: 14,
                          color: r.collectorCode.isEmpty
                              ? BCollectionColors.inkMuted
                              : BCollectionColors.primary),
                    ),
                    const SizedBox(width: BSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            [
                              '${r.open} open',
                              if (r.needsAttention > 0)
                                '${r.needsAttention} flagged',
                              if (r.closed > 0) '${r.closed} closed',
                            ].join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: r.needsAttention > 0
                                    ? BCollectionColors.danger
                                    : BCollectionColors.inkSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: BSizes.sm),
                    Text(
                      BFormatter.formatPesoCurrency(
                          r.amountUnderReconciliation),
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: BCollectionColors.reconcile),
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
