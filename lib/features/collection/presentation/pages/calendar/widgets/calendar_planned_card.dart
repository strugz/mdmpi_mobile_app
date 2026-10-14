import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_status_style.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';

/// The "Planned" part of a calendar day: reconciliation follow ups due on it
/// (docs/application/COLLECTION_RECON_FOLLOWUP_REMINDERS_PLAN.md, Phase 2).
///
/// Above the day's engagements, because a plan is what the collector reads
/// first when looking at a day ahead. Planned items are not engagements: they
/// do not count in the heading, the filter or any total.
class CalendarPlannedSection extends StatelessWidget {
  const CalendarPlannedSection({super.key, required this.cases});

  final List<ReconCaseView> cases;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('calendar-planned'),
      padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace, 0, BSizes.defaultSpace, BSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: BSizes.xs),
            child: Text(
              cases.length == 1 ? 'PLANNED' : 'PLANNED · ${cases.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: BCollectionColors.inkMuted, letterSpacing: 0.8),
            ),
          ),
          for (final c in cases) CalendarPlannedCard(view: c),
        ],
      ),
    );
  }
}

/// One planned follow up: the account, what to do, what is still owed, and
/// when it is due. Outlined rather than filled, so it never reads as work
/// already done. Tapping opens the case, where the follow up is logged.
class CalendarPlannedCard extends StatelessWidget {
  const CalendarPlannedCard({super.key, required this.view});

  final ReconCaseView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = view.evaluation;
    final due = BReconStyle.dueLabel(e);
    return Padding(
      key: ValueKey('planned:${view.caseId}'),
      padding: const EdgeInsets.only(bottom: BSizes.sm),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
          side: BorderSide(
              color: e.dueState.isPressing
                  ? BReconStyle.dueColor(e.dueState)
                  : BCollectionColors.outline,
              width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              Get.toNamed(BRoutes.reconciliationCase, arguments: view.caseId),
          child: Padding(
            padding: const EdgeInsets.all(BSizes.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Iconsax.calendar_tick,
                      size: 18, color: BCollectionColors.reconcile),
                ),
                const SizedBox(width: BSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(view.reconCase.clientName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(BReconStyle.nextActionText(e),
                          key: ValueKey('planned-what:${view.caseId}'),
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Reconciliation · ${e.openInvoices.length} open · '
                        '${BFormatter.formatPesoCurrency(e.amountUnderReconciliation)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: BCollectionColors.inkSecondary),
                      ),
                      if (due.isNotEmpty) ...[
                        const SizedBox(height: BSizes.xs),
                        ReconChip(
                            key: ValueKey('planned-due:${view.caseId}'),
                            label: due,
                            color: BReconStyle.dueColor(e.dueState),
                            icon: Iconsax.calendar_1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: BSizes.xs),
                const Icon(Iconsax.arrow_right_3,
                    size: 16, color: BCollectionColors.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
