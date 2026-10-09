import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';

/// How the Reconciliation Tracker's statuses look, in one place, so the
/// dashboard, the case screen and the log sheet agree. Status colours live on
/// chips only (the Collection colour budget).
class BReconStyle {
  BReconStyle._();

  static Color caseColor(ReconCaseStatus s) => switch (s) {
        ReconCaseStatus.waitingForCollector => BCollectionColors.primary,
        ReconCaseStatus.waitingForAccount => BCollectionColors.info,
        ReconCaseStatus.underValidation => BCollectionColors.reconcile,
        ReconCaseStatus.completed => BCollectionColors.success,
        ReconCaseStatus.notCompleted => BCollectionColors.neutral,
        ReconCaseStatus.escalated => BCollectionColors.danger,
      };

  static Color invoiceColor(ReconInvoiceStatus s) => switch (s) {
        ReconInvoiceStatus.open => BCollectionColors.neutral,
        ReconInvoiceStatus.claimedPaid => BCollectionColors.warning,
        ReconInvoiceStatus.proofInvalid => BCollectionColors.danger,
        ReconInvoiceStatus.validatedPaid => BCollectionColors.success,
        ReconInvoiceStatus.cleared => BCollectionColors.success,
      };

  static Color flagColor(ReconFlag f) => switch (f) {
        ReconFlag.noResponse => BCollectionColors.danger,
        ReconFlag.claimedPaidNoProof => BCollectionColors.warning,
        ReconFlag.nextActionOverdue => BCollectionColors.danger,
      };

  static IconData activityIcon(ReconActivityType t) => switch (t) {
        ReconActivityType.soaSent => Iconsax.document_upload,
        ReconActivityType.followUp => Iconsax.call_calling,
        ReconActivityType.collectionLetterSent => Iconsax.sms,
        ReconActivityType.documentRequested => Iconsax.document_text,
        ReconActivityType.documentProvided => Iconsax.document_forward,
        ReconActivityType.paidClaim => Iconsax.money_tick,
        ReconActivityType.proofRequested => Iconsax.receipt_search,
        ReconActivityType.proofProvided => Iconsax.receipt_item,
        ReconActivityType.proofValidated => Iconsax.shield_tick,
        ReconActivityType.note => Iconsax.note_2,
        ReconActivityType.caseNotCompleted => Iconsax.close_circle,
        ReconActivityType.caseEscalated => Iconsax.arrow_up_3,
        ReconActivityType.paymentRecorded => Iconsax.money_recive,
        ReconActivityType.caseReleased => Iconsax.logout,
        ReconActivityType.caseAcquired => Iconsax.login,
      };

  /// An open status as whose turn it is, for a set of cases that may not all
  /// be mine (the reports): "Collector's turn 3".
  static String statusTurnLabel(ReconCaseStatus s) => switch (s) {
        ReconCaseStatus.waitingForCollector => "Collector's turn",
        ReconCaseStatus.waitingForAccount => "Account's turn",
        ReconCaseStatus.underValidation => 'Validating proof',
        _ => s.label,
      };

  /// "Your turn" / "The account's turn", from the collector's side.
  static String nextActorLabel(ReconActor? actor) => switch (actor) {
        ReconActor.collector => 'Your turn',
        ReconActor.account => "Waiting for the account",
        _ => 'Case ended',
      };

  /// The step to suggest next. While waiting on the account, [stage] (the
  /// case's first stage not yet done) says how to chase it.
  static String nextStepHint(ReconCaseStatus s,
          {required bool hasActivity, ReconStage? stage}) =>
      switch (s) {
        ReconCaseStatus.waitingForCollector =>
          hasActivity ? 'Reply to the account' : 'Send the SOA',
        ReconCaseStatus.underValidation => 'Validate the proof of payment',
        ReconCaseStatus.waitingForAccount => switch (stage) {
            ReconStage.soa => 'Send the SOA',
            ReconStage.followUp => 'Follow up with the account',
            ReconStage.collectionLetter =>
              'Follow up again, or send the collection letter',
            null => 'Follow up, send another letter, or escalate',
          },
        _ => '',
      };
}

/// A small tinted label: a status, an invoice status or a flag.
class ReconChip extends StatelessWidget {
  const ReconChip(
      {super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}
