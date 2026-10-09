import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_clock.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_status_style.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_evaluation.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/reconciliation/widgets/recon_stage_track.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/reconciliation/widgets/recon_log_activity_sheet.dart';

/// One reconciliation case: the account's last activity first (Step 1 of
/// every round), then its invoices and the whole timeline, and the way to log
/// the next step.
class ReconCaseScreen extends StatelessWidget {
  const ReconCaseScreen({super.key, required this.caseId, this.photoRoot});

  final String caseId;

  /// Where local photo files live; defaults to the controller's folder.
  final String? photoRoot;

  static final DateFormat _when = DateFormat('MMM d, yyyy · h:mm a');
  static final DateFormat _date = DateFormat('MMM d, yyyy');

  static String when(String stamp) {
    final t = BReconClock.parse(stamp);
    return t == null ? stamp : _when.format(t);
  }

  static String ago(int days) => switch (days) {
        <= 0 => 'today',
        1 => 'yesterday',
        _ => '$days days ago',
      };

  @override
  Widget build(BuildContext context) {
    final controller = ReconciliationController.instance;
    return Obx(() {
      final view = controller.caseById(caseId);
      if (view == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Reconciliation case')),
          body: Center(
            child: controller.isLoading.value
                ? const CircularProgressIndicator()
                : const Text('This case is not on this phone.'),
          ),
        );
      }
      final e = view.evaluation;
      final canLog = controller.canLog(view);
      final holder = view.reconCase.collectorName.trim().isNotEmpty
          ? view.reconCase.collectorName.trim()
          : view.reconCase.collectorCode.trim();
      // Closed: say how it ended. Someone else's: say whose, since only
      // the holder of the account logs on it. Nobody's: say how to take it.
      final label = e.isClosed
          ? 'Case ${e.status.label.toLowerCase()}'
          : canLog
              ? 'Log a step'
              : holder.isEmpty
                  ? 'Acquire the account to log a step'
                  : 'Held by $holder · acquire to log';
      return Scaffold(
        appBar: AppBar(title: Text(view.reconCase.clientName)),
        // Pinned, so the next step is always one tap away.
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
                BSizes.defaultSpace,
                BSizes.spaceBtwItemsLight,
                BSizes.defaultSpace,
                BSizes.spaceBtwItemsLight),
            decoration: const BoxDecoration(
              color: BCollectionColors.surface,
              border: Border(top: BorderSide(color: BCollectionColors.outline)),
            ),
            child: ElevatedButton.icon(
              key: const ValueKey('recon-log'),
              onPressed: canLog ? () => ReconLogActivitySheet.show(view) : null,
              icon: Icon(
                  e.isClosed
                      ? Iconsax.lock
                      : canLog
                          ? Iconsax.add_circle
                          : Iconsax.user,
                  size: 18),
              label: Text(label,
                  key: const ValueKey('recon-log-label'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(BSizes.defaultSpace),
            children: [
              _Header(view: view),
              const SizedBox(height: BSizes.spaceBtwItems),
              _LastActivity(evaluation: e),
              const SizedBox(height: BSizes.spaceBtwSections),
              const _SectionTitle('Stage'),
              ReconStageTrack(
                evaluation: e,
                onLog: canLog
                    ? (type) =>
                        ReconLogActivitySheet.show(view, initialType: type)
                    : null,
              ),
              const SizedBox(height: BSizes.spaceBtwSections),
              _SectionTitle('Invoices (${e.invoices.length})'),
              for (final i in e.invoices) _InvoiceRow(invoice: i),
              const SizedBox(height: BSizes.spaceBtwSections),
              _SectionTitle('Timeline (${view.bundle.activities.length})'),
              if (view.bundle.activities.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: BSizes.sm),
                  child: Text('Nothing logged yet. Start with the SOA.'),
                ),
              for (final a in view.bundle.activities.reversed)
                _TimelineEntry(
                    activity: a,
                    photoRoot: photoRoot ?? controller.photoDirectory.value),
              if (e.warnings.isNotEmpty) ...[
                const SizedBox(height: BSizes.spaceBtwItems),
                _SectionTitle('Not applied'),
                for (final w in e.warnings)
                  Text(w,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: BCollectionColors.inkMuted)),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.view});

  final ReconCaseView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = view.evaluation;
    final opened = BReconClock.parse(view.reconCase.dateOpened);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Case ${view.caseId}'
                  '${opened == null ? '' : ' · opened ${ReconCaseScreen._date.format(opened)}'}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: BCollectionColors.inkMuted)),
              if (view.reconCase.collectorName.isNotEmpty)
                Text('Held by ${view.reconCase.collectorName}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: BCollectionColors.inkMuted)),
            ],
          ),
        ),
        // Flexible: at a large font the label shortens rather than
        // pushing the row off the screen.
        Flexible(
          child: ReconChip(
              key: const ValueKey('recon-case-status'),
              label: e.status.label,
              color: BReconStyle.caseColor(e.status)),
        ),
      ],
    );
  }
}

/// Step 1: last activity, days since, who acts next, next action due, open
/// invoices, and the alerts.
class _LastActivity extends StatelessWidget {
  const _LastActivity({required this.evaluation});

  final ReconEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = evaluation;
    final last = e.lastActivity;
    final due = last?.nextActionDueDate;
    final hint = BReconStyle.nextStepHint(e.status,
        hasActivity: last != null, stage: e.currentStage);
    return Container(
      key: const ValueKey('recon-last-activity'),
      padding: const EdgeInsets.all(BSizes.md),
      decoration: BoxDecoration(
        color: BCollectionColors.surface,
        borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
        border: Border.all(color: BCollectionColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LAST ACTIVITY',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: BCollectionColors.inkMuted, letterSpacing: 0.8)),
          const SizedBox(height: BSizes.xs),
          Text(
            last == null
                ? 'Nothing logged yet'
                : '${last.type.label} · ${last.doneBy.label}',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            last == null
                ? 'Opened ${ReconCaseScreen.ago(e.daysSinceLastActivity)}'
                : '${ReconCaseScreen.when(last.dateTime)} · '
                    '${ReconCaseScreen.ago(e.daysSinceLastActivity)}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: BCollectionColors.inkSecondary),
          ),
          const SizedBox(height: BSizes.sm),
          Row(
            children: [
              Icon(
                  e.nextActor == ReconActor.collector
                      ? Iconsax.user_tick
                      : Iconsax.clock,
                  size: 16,
                  color: BCollectionColors.inkSecondary),
              const SizedBox(width: BSizes.xs),
              Expanded(
                child: Text(
                  [
                    BReconStyle.nextActorLabel(e.nextActor),
                    if (hint.isNotEmpty) hint
                  ].join(' · '),
                  key: const ValueKey('recon-next'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (last != null && last.nextAction.isNotEmpty || due != null) ...[
            const SizedBox(height: BSizes.xs),
            Text(
              [
                if (last!.nextAction.isNotEmpty) 'Next: ${last.nextAction}',
                if (due != null)
                  'due ${ReconCaseScreen.when(due).split(' · ').first}',
              ].join(', '),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: BSizes.xs),
          Text(
            '${e.openInvoices.length} open · '
            '${BFormatter.formatPesoCurrency(e.amountUnderReconciliation)}'
            '${e.amountValidatedPaid > 0 ? ' · validated ${BFormatter.formatPesoCurrency(e.amountValidatedPaid)}' : ''}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: BCollectionColors.inkSecondary),
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: BSizes.xs),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice});

  final ReconInvoiceState invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.invoiceNo, style: theme.textTheme.bodyMedium),
                Text(
                  [
                    BFormatter.formatPesoCurrency(invoice.amount),
                    if (invoice.proofPending) 'proof to validate',
                    if (invoice.proofRequested) 'proof asked for',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: BCollectionColors.inkSecondary),
                ),
              ],
            ),
          ),
          ReconChip(
              label: invoice.status.label,
              color: BReconStyle.invoiceColor(invoice.status)),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.activity, this.photoRoot});

  final ReconActivity activity;
  final String? photoRoot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = activity;
    // Blue for the collector, amber for the account, grey for what the app
    // logged itself (a payment, a release, an acquire).
    final tint = switch (a.doneBy) {
      ReconActor.account => BCollectionColors.warning,
      ReconActor.tracker => BCollectionColors.neutral,
      ReconActor.collector => BCollectionColors.primary,
    };
    final details = [
      if (a.type == ReconActivityType.soaSent && a.amount != null)
        'SOA ${BFormatter.formatPesoCurrency(a.amount!)}',
      if (a.type == ReconActivityType.paymentRecorded && a.amount != null)
        BFormatter.formatPesoCurrency(a.amount!),
      if (a.validationResult != null)
        a.validationResult == ReconValidationResult.valid ? 'Valid' : 'Invalid',
      if (a.invoiceNos.isNotEmpty) 'Invoices ${a.invoiceNos.join(', ')}',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: tint.withValues(alpha: 0.12),
            child:
                Icon(BReconStyle.activityIcon(a.type), size: 16, color: tint),
          ),
          const SizedBox(width: BSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${a.type.label} · ${a.doneBy.label}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(ReconCaseScreen.when(a.dateTime),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: BCollectionColors.inkMuted)),
                if (details.isNotEmpty)
                  Text(details.join(' · '), style: theme.textTheme.bodySmall),
                if (a.remarks.isNotEmpty)
                  Text(a.remarks, style: theme.textTheme.bodySmall),
                if (a.nextAction.isNotEmpty || a.nextActionDueDate != null)
                  Text(
                    'Next: ${[
                      if (a.nextAction.isNotEmpty) a.nextAction,
                      if (a.nextActionDueDate != null)
                        'due ${a.nextActionDueDate}',
                    ].join(', ')}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: BCollectionColors.inkSecondary),
                  ),
                if (a.attachmentRefs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: BSizes.xs),
                    child: Wrap(
                      spacing: BSizes.xs,
                      runSpacing: BSizes.xs,
                      children: [
                        for (final id in a.attachmentRefs)
                          _Photo(id: id, root: photoRoot),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A photo taken on this phone shows from its file; one from another phone
/// shows as a placeholder until opened (it lives on the server).
class _Photo extends StatelessWidget {
  const _Photo({required this.id, this.root});

  final String id;
  final String? root;

  @override
  Widget build(BuildContext context) {
    final file =
        root == null ? null : File('$root${Platform.pathSeparator}$id.jpg');
    final exists = file != null && file.existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
      child: SizedBox(
        width: 56,
        height: 56,
        child: exists
            ? Image.file(file, fit: BoxFit.cover)
            : const ColoredBox(
                color: BCollectionColors.surfaceMuted,
                child: Icon(Iconsax.image, color: BCollectionColors.inkMuted)),
      ),
    );
  }
}
