import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

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
/// carries a stack of accounts, not one, so the layout is built to fit as many
/// as possible on a phone: the name across the full width, the amount on its
/// own line under it, then one line of metadata.
///
/// The name and the amount shared the top line once, which left the name a
/// fraction of the width. Hospital names are long here, so they broke early
/// and truncated anyway — "Ace Diagnostics C…" under a near-empty first line —
/// on the very screen whose job is finding an account by name. Full width
/// fits most names on one line, so moving the amount down costs no height on
/// a typical row and none of them lose their name.
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
              ? BCollectionColors.primary.withValues(alpha: 0.05)
              : BCollectionColors.surface,
          borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
          // Constant width, colour only: a 1→2px border nudges the content on
          // every selection toggle.
          border: Border.all(
            color: isSelected
                ? BCollectionColors.primary
                : BCollectionColors.outline,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _topLine(theme, address),
            const SizedBox(height: BSizes.xs),
            _amountLine(theme),
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
                    side: const BorderSide(color: BCollectionColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(BSizes.borderRadiusMd),
                    ),
                  ),
                  child: Text(
                    'Acquire Account',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: BCollectionColors.primary,
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

  /// The name, across the whole card.
  ///
  /// The amount used to sit beside it, so the name got whatever width was
  /// left: "Ace Diagnostics C…" broke early and still truncated, with a
  /// near-empty first line above it. This is the list you find an account by
  /// name in, so the name takes the full width and the amount moves to its
  /// own line below. Most names now fit on one line, which buys back the line
  /// the amount costs.
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
                        ?.copyWith(color: BCollectionColors.inkMuted),
                  ),
              ],
            ),
          ),
          // The long-press selection mode is the only state that still needs
          // a trailing glyph; a selectable row carries its circle on the left.
          // The info button lives in the metadata line.
          if (isSelectionMode && onSelectTap == null) ...[
            const SizedBox(width: BSizes.sm),
            Icon(
              isSelected ? Iconsax.tick_circle5 : Iconsax.add_circle,
              size: 22,
              color: isSelected
                  ? BCollectionColors.primary
                  : BCollectionColors.inkMuted,
            ),
          ],
        ],
      );

  /// What is owed, on its own line under the name.
  ///
  /// Flush to the card's right edge, so the figures line up on their last
  /// digit and a column of different-length amounts can be compared at a
  /// glance. Nothing shares the line, so the figure is never squeezed and
  /// never truncated: a cut number is a different number, not merely a
  /// shorter one.
  Widget _amountLine(ThemeData theme) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // Only on the rows that are the exception. Every other row in this
          // list is an outstanding balance, so labelling each one
          // "outstanding" repeats the column heading down the whole screen.
          if (_settled) ...[
            Text(
              'collected',
              style: theme.textTheme.labelSmall?.copyWith(
                color: BCollectionColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: BSizes.xs),
          ],
          Text(
            BFormatter.formatPesoCurrency(
                _settled ? totalCollected : totalAmount),
            maxLines: 1,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 17,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: _settled
                  ? BCollectionColors.success
                  : BCollectionColors.primary,
            ),
          ),
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
                  color: isSelected
                      ? BCollectionColors.primary
                      : BCollectionColors.surface,
                  border: Border.all(
                    color: isSelected
                        ? BCollectionColors.primary
                        : BCollectionColors.inkMuted,
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
                          key: ValueKey('on'),
                          size: 14,
                          color: BCollectionColors.surface)
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
                backgroundColor: BCollectionColors.outline,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    BCollectionColors.success),
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
                  ?.copyWith(color: BCollectionColors.inkMuted, fontSize: 10),
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
                    size: 13, color: BCollectionColors.inkMuted),
                const SizedBox(width: BSizes.xs),
                Flexible(
                  child: Text(
                    '$invoiceCount invoice${invoiceCount == 1 ? '' : 's'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: BCollectionColors.inkMuted,
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
                      color: BCollectionColors.danger.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(BSizes.borderRadiusSm),
                    ),
                    child: Text(
                      '$overdueCount overdue',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: BCollectionColors.danger,
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
                          color: BCollectionColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Iconsax.arrow_right_3,
                          size: 14, color: BCollectionColors.primary),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
}
