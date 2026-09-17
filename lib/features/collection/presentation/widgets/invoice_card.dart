import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

/// How urgent an invoice is. Drives the accent stripe and the due-date colour.
enum InvoiceUrgency { settled, upcoming, due, late }

/// One invoice in a list.
///
/// Replaces the two near-identical tiles that had drifted apart (the Activity
/// tile and the Bucket card), so Bucket, Activity and the dashboard category
/// lists all read the same.
///
/// The amount is the hero, but the invoice number is a close second: it is
/// what the collector and the customer both call the document, and what a
/// deposit is matched back to. Both are set to be read. Earlier the number
/// was reduced to a grey label so it would not compete with the amount, and
/// it stopped being findable.
///
/// Urgency is graded rather than binary. Every overdue invoice used to paint
/// its whole card red, and since almost all of them are overdue the entire
/// list went red and the signal carried no information. A thin accent stripe
/// now separates late (30+ days) from merely due, and settled from both.
///
/// Colour budget: one hue per card beyond ink and grey. The amount is set in
/// ink, not the primary blue, because blue is what buttons and the selection
/// state use, and a blue amount on every row reads as a row of links. The
/// urgency colour appears on the stripe and the days-overdue badge only; the
/// due date itself is dark grey. Blue is left for the info glyph's pressed
/// state, selection, and the screen's one primary button.
class InvoiceCard extends StatelessWidget {
  const InvoiceCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.onInfoTap,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.showAccountName = false,
  });

  final CollectionItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onInfoTap;
  final bool isSelected;
  final bool isSelectionMode;

  /// Show the client name. Off inside a single account's screen, where the
  /// name is already the page title and repeating it on every row is noise.
  /// On for mixed lists such as the dashboard category screens.
  final bool showAccountName;

  /// Days overdue past which an invoice counts as [InvoiceUrgency.late].
  static const int lateAfterDays = 30;

  static const Duration _stateDuration = Duration(milliseconds: 160);

  /// Width of the urgency stripe. Reserved on every card, coloured on some.
  static const double _stripeWidth = 4;

  InvoiceUrgency get urgency {
    if (item.toBeCollected == 0) return InvoiceUrgency.settled;
    if (!item.isOverdue) return InvoiceUrgency.upcoming;
    return item.daysPastDue > lateAfterDays
        ? InvoiceUrgency.late
        : InvoiceUrgency.due;
  }

  Color? get _accentColor => switch (urgency) {
        InvoiceUrgency.settled => BColors.success,
        InvoiceUrgency.late => BColors.error,
        InvoiceUrgency.due => BColors.warning,
        InvoiceUrgency.upcoming => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settled = urgency == InvoiceUrgency.settled;
    final accent = _accentColor;

    return BPressableScale(
      onTap: onTap,
      onLongPress: onLongPress,
      // No handler means nothing happens on tap, so don't imply otherwise by
      // depressing the card. Some lists show invoices for reading only.
      enabled: onTap != null || onLongPress != null,
      child: AnimatedContainer(
        duration: _stateDuration,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected
              ? BColors.primary.withValues(alpha: 0.05)
              : BColors.white,
          borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
          // Constant width: animating 1 -> 2px would nudge the content on
          // every selection toggle.
          // A hairline in a lighter grey: the old 1.5px E0E0E0 boxed every
          // card and fought the stripe for the eye.
          border: Border.all(
            color: isSelected ? BColors.primary : BColors.softGrey,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        // Clip so the accent stripe follows the rounded corners.
        clipBehavior: Clip.antiAlias,
        // Stack, not a Row with IntrinsicHeight: the stripe stretches to
        // whatever the content measures without costing a second layout pass
        // on every row of a long list.
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _stripeWidth + BSizes.spaceBtwItemsLight,
                BSizes.spaceBtwItemsLight,
                BSizes.spaceBtwItemsLight,
                BSizes.spaceBtwItemsLight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _headerRow(theme),
                  const SizedBox(height: BSizes.xs),
                  _amountRow(theme, settled),
                  const SizedBox(height: BSizes.xs),
                  _dueRow(theme),
                ],
              ),
            ),
            // Urgency at a glance, without flooding the card. The slot is
            // always this wide and only its colour changes, so text stays on
            // one left edge whether or not a card carries a stripe.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _stripeWidth,
              child: AnimatedContainer(
                duration: _stateDuration,
                color: accent ?? Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Invoice number, status badges, and the trailing info / selection glyph.
  Widget _headerRow(ThemeData theme) {
    final lastOutcome = item.lastOutcome?.trim() ?? '';
    final status = item.status.trim();
    final showOutcome = lastOutcome.isNotEmpty &&
        lastOutcome.toLowerCase() != status.toLowerCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Set to be read, not merely present. The number is how the
              // collector and the customer both refer to the document, and
              // what a deposit is matched back to. It was labelMedium grey —
              // the quietest thing on the card — which is the wrong weight
              // for the one line people look up.
              Text(
                '#${item.id}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              if (showAccountName)
                Text(
                  item.client.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: BColors.darkerGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: BSizes.xs),
        if (status.isNotEmpty) _statusBadge(theme, status),
        if (showOutcome) ...[
          const SizedBox(width: BSizes.xs),
          _statusBadge(theme, lastOutcome),
        ],
        // Info button normally, selection mark in selection mode. Cross-faded
        // so the swap is one morph rather than a pop.
        if (onInfoTap != null || isSelectionMode) ...[
          const SizedBox(width: BSizes.xs),
          SizedBox(
            width: 28,
            height: 28,
            child: AnimatedSwitcher(
              duration: _stateDuration,
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: isSelectionMode
                  ? Icon(
                      isSelected ? Iconsax.tick_circle5 : Iconsax.add_circle,
                      key: ValueKey('select-$isSelected'),
                      size: 22,
                      color: isSelected ? BColors.primary : BColors.darkGrey,
                    )
                  : IconButton(
                      key: const ValueKey('info'),
                      tooltip: 'Invoice details',
                      onPressed: onInfoTap,
                      icon: const Icon(Iconsax.info_circle,
                          size: 20, color: BColors.darkGrey),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints.tightFor(width: 28, height: 28),
                      splashRadius: 20,
                    ),
            ),
          ),
        ],
      ],
    );
  }

  /// The number the collector is here for.
  Widget _amountRow(ThemeData theme, bool settled) {
    final amount = settled ? item.totalCollected : item.toBeCollected;

    return Row(
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              BFormatter.formatPesoCurrency(amount),
              maxLines: 1,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: settled ? BColors.success : BColors.black,
              ),
            ),
          ),
        ),
        if (settled) ...[
          const SizedBox(width: BSizes.xs),
          const Icon(Iconsax.tick_circle5, color: BColors.success, size: 18),
        ],
      ],
    );
  }

  /// Due date and how late it is, on one line.
  ///
  /// The posting date used to sit on its own row above this one, where it
  /// truncated and pushed the due date down. It lives in the details sheet now.
  Widget _dueRow(ThemeData theme) {
    final hasDueDate =
        item.dueDate.trim().isNotEmpty && item.dueDate.trim() != 'N/A';
    final overdue =
        urgency == InvoiceUrgency.due || urgency == InvoiceUrgency.late;
    // The date stays grey even when overdue. The stripe and the badge already
    // say how late it is; a third red element per row was the loudest thing
    // on a list where every row is overdue.
    const dateColor = BColors.darkerGrey;
    final badgeColor = _accentColor ?? BColors.darkGrey;

    return Row(
      children: [
        const Icon(Iconsax.calendar_1, size: 14, color: BColors.darkGrey),
        const SizedBox(width: BSizes.xs),
        Flexible(
          child: Text(
            hasDueDate
                ? 'Due ${BFormatter.formatDate3(item.dueDate)}'
                : 'No due date',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: dateColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (overdue) ...[
          const SizedBox(width: BSizes.xs),
          // Tinted, not a solid red block: every row in these lists is
          // overdue, and a filled badge on all of them is just noise.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
            ),
            child: Text(
              BFormatter.formatDaysOverdue(item.daysPastDue),
              style: theme.textTheme.labelSmall?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statusBadge(ThemeData theme, String status) {
    final (bg, fg) = CollectionStatusColors.colorsFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: BSizes.sm, vertical: BSizes.xxs),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg == BColors.white ? bg : fg,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
