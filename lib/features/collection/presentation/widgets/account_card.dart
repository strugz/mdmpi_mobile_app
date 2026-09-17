import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// One account in a list, in the Bucket and in Field Engagement.
///
/// The card used to present three statistics of equal weight — an invoice
/// count on the left, an amount due and an amount collected stacked on the
/// right — across two alignment axes, with "Total Collected ₱0.00" painted
/// green on an account where nothing had been collected. Green says the work
/// is done. Zero collected is the work still to do.
///
/// So the outstanding balance is the only number set large. Everything else
/// is context for it: how many invoices it spans, how much of the account has
/// already been settled, and whether any of it is late.
///
/// It is also a row in a work queue rather than a feature card. A collector
/// carries a stack of accounts, not one, so the layout is built to put eight
/// of them on a phone screen: name and amount share the top line, and the
/// rest is one line of metadata under it.
class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.client,
    required this.invoiceCount,
    required this.totalAmount,
    required this.onTap,
    this.onInfoTap,
    this.onSelectTap,
    this.totalCollected = 0.0,
    this.overdueCount = 0,
    this.onClaimTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  final ClientModel client;
  final int invoiceCount;

  /// What is still owed. The reason to open this account.
  final double totalAmount;

  /// What has already been collected against it.
  final double totalCollected;

  /// How many of its invoices are past due.
  final int overdueCount;

  final VoidCallback onTap;

  /// Opens the account's page, from a labelled "Details" control on the
  /// row. Null where tapping the row already does that, so the row is not
  /// offered the same destination twice.
  final VoidCallback? onInfoTap;

  /// Given, the row carries a selection circle on its left. The circle
  /// toggles on tap; what the rest of the row does is up to [onTap] — on a
  /// picking screen that is also toggle, so the whole card is the target and
  /// [onInfoTap] is the way in. This is how picking several rows becomes an
  /// ordinary thing to do rather than a mode found by holding a finger down.
  final VoidCallback? onSelectTap;

  final VoidCallback? onClaimTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  static const Duration _stateDuration = Duration(milliseconds: 160);

  /// Placeholders the backend sends for an address it does not have. A pin
  /// icon next to the letters "N/A" is a row that costs space and says
  /// nothing, so an unknown address is simply not shown.
  static const Set<String> _emptyAddresses = {'', 'n/a', 'na', 'none', '-'};

  String? get _address {
    final trimmed = client.address.trim();
    return _emptyAddresses.contains(trimmed.toLowerCase()) ? null : trimmed;
  }

  bool get _settled => totalAmount <= 0;

  /// How much of this account has been settled, 0 to 1.
  double get _progress {
    final total = totalAmount + totalCollected;
    if (total <= 0) return 0;
    return (totalCollected / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = _address;

    return BPressableScale(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: _stateDuration,
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(BSizes.spaceBtwItemsLight),
        decoration: BoxDecoration(
          color: isSelected
              ? BColors.primary.withValues(alpha: 0.05)
              : BColors.white,
          borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
          // Constant width, colour only: a 1→2px border nudges the content on
          // every selection toggle.
          border: Border.all(
            color: isSelected ? BColors.primary : BColors.grey,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _topLine(theme, address),
            const SizedBox(height: BSizes.xs),
            _meta(theme),
            if (totalCollected > 0) ...[
              const SizedBox(height: BSizes.sm),
              _progressBar(theme),
            ],
            if (onClaimTap != null && !isSelectionMode) ...[
              const SizedBox(height: BSizes.spaceBtwItemsLight),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton(
                  onPressed: onClaimTap,
                  style: OutlinedButton.styleFrom(
                    // The app's OutlinedButton theme pads 16pt top and bottom.
                    // Inside a 40pt button that leaves an 8pt window, and the
                    // label rendered as four dots — the middle of the letters.
                    // Padding is set here so the theme's cannot apply.
                    padding: const EdgeInsets.symmetric(horizontal: BSizes.md),
                    side: const BorderSide(color: BColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(BSizes.borderRadiusMd),
                    ),
                  ),
                  child: Text(
                    'Acquire Account',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: BColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Name on the left, what is owed on the right. One line each way, so a
  /// row costs about 80pt instead of 150 and the queue is scannable.
  Widget _topLine(ThemeData theme, String? address) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onSelectTap != null) ...[
            _selectionCircle(),
            const SizedBox(width: BSizes.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
                ),
                if (address != null)
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: BColors.darkGrey),
                  ),
              ],
            ),
          ),
          const SizedBox(width: BSizes.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                BFormatter.formatPesoCurrency(
                    _settled ? totalCollected : totalAmount),
                maxLines: 1,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: _settled ? BColors.success : BColors.primary,
                ),
              ),
              // Only on the rows that are the exception. Every other row in
              // this list is an outstanding balance, so labelling each one
              // "outstanding" repeats the column heading seven times and
              // costs a line per row.
              if (_settled)
                Text(
                  'collected',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: BColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          // The long-press selection mode is the only state that still needs
          // a trailing glyph; a selectable row carries its circle on the left.
          // The info button moved into the metadata line, where it no longer
          // competes with the amount for the strongest corner of the row.
          if (isSelectionMode && onSelectTap == null) ...[
            const SizedBox(width: BSizes.sm),
            Icon(
              isSelected ? Iconsax.tick_circle5 : Iconsax.add_circle,
              size: 22,
              color: isSelected ? BColors.primary : BColors.darkGrey,
            ),
          ],
        ],
      );

  /// Tick on the left. A 40pt target around a 22pt mark, because it is hit
  /// with a thumb while walking, and one tap per account is the whole point.
  Widget _selectionCircle() => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelectTap,
        child: Semantics(
          checked: isSelected,
          label: 'Select ${client.name}',
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: AnimatedContainer(
                duration: _stateDuration,
                curve: Curves.easeOut,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? BColors.primary : BColors.white,
                  border: Border.all(
                    color: isSelected ? BColors.primary : BColors.darkGrey,
                    width: 1.5,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: _stateDuration,
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    // From 0.6, not 0: nothing appears from nowhere.
                    scale: Tween<double>(begin: 0.6, end: 1).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check,
                          key: ValueKey('on'), size: 14, color: BColors.white)
                      : const SizedBox(key: ValueKey('off')),
                ),
              ),
            ),
          ),
        ),
      );

  /// Only drawn once something has actually been collected, so an untouched
  /// account shows no bar rather than an empty one implying a stalled job.
  Widget _progressBar(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _progress),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 3,
                backgroundColor: BColors.grey,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(BColors.success),
              ),
            ),
          ),
          // Only where it adds something. On a settled account the amount
          // already reads as collected, so repeating it under a full bar is
          // the same sentence twice.
          if (!_settled) ...[
            const SizedBox(height: 3),
            Text(
              '${BFormatter.formatPesoCurrency(totalCollected)} collected so far',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: BColors.darkGrey, fontSize: 10),
            ),
          ],
        ],
      );

  /// Invoice count, how much of it is late, and the way into the account's
  /// details.
  Widget _meta(ThemeData theme) => Row(
        children: [
          // Under the name, not under the circle: secondary text lines up
          // with the primary text it belongs to, the way a mail list does.
          if (onSelectTap != null) const SizedBox(width: 40 + BSizes.sm),
          // The count and badge take whatever width the Details control
          // leaves. As one Expanded group, the count only ellipsizes when
          // there is genuinely no room. As a Flexible beside a Spacer it got
          // half the free space and truncated "1 invoice" at 390pt.
          Expanded(
            child: Row(
              children: [
                const Icon(Iconsax.document_text,
                    size: 13, color: BColors.darkGrey),
                const SizedBox(width: BSizes.xs),
                Flexible(
                  child: Text(
                    '$invoiceCount invoice${invoiceCount == 1 ? '' : 's'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: BColors.darkGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (overdueCount > 0) ...[
                  const SizedBox(width: BSizes.sm),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      // Tinted, not solid: in these lists almost everything
                      // is overdue, and a wall of filled red badges carries
                      // no signal.
                      color: BColors.error.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(BSizes.borderRadiusSm),
                    ),
                    child: Text(
                      '$overdueCount overdue',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: BColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // A labelled way into the account. Where the row itself selects,
          // this is the only route to the account's page, so it has to read
          // as one — a bare 18pt info glyph in the corner did not, and a
          // control nobody recognises is a control nobody finds.
          if (!isSelectionMode && onInfoTap != null)
            Semantics(
              // Its own node: a discrete button, announced on its own rather
              // than folded into whatever surrounds it.
              container: true,
              button: true,
              label: 'Open ${client.name}',
              // The visible "Details" is for sighted users; a screen reader
              // should hear which account this opens, not "Details" tacked
              // onto the end of it.
              excludeSemantics: true,
              child: InkWell(
                onTap: onInfoTap,
                borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
                child: Padding(
                  // 32pt tall target on a 20pt line: reachable with a thumb
                  // without pushing the row taller.
                  padding: const EdgeInsets.symmetric(
                      horizontal: BSizes.sm, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Details',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: BColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Iconsax.arrow_right_3,
                          size: 14, color: BColors.primary),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
}
