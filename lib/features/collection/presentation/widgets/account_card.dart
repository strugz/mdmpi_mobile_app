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
class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.client,
    required this.invoiceCount,
    required this.totalAmount,
    required this.onTap,
    required this.onInfoTap,
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
  final VoidCallback onInfoTap;
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
        padding: const EdgeInsets.all(BSizes.md),
        decoration: BoxDecoration(
          color:
              isSelected ? BColors.primary.withValues(alpha: 0.05) : BColors.white,
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
            _header(theme, address),
            const SizedBox(height: BSizes.spaceBtwItemsLight),
            _outstanding(theme),
            if (totalCollected > 0) ...[
              const SizedBox(height: BSizes.sm),
              _progressBar(theme),
            ],
            const SizedBox(height: BSizes.sm),
            _meta(theme),
            if (onClaimTap != null && !isSelectionMode) ...[
              const SizedBox(height: BSizes.spaceBtwItemsLight),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton(
                  onPressed: onClaimTap,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: BColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
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

  /// Name, optional address, and the trailing glyph.
  Widget _header(ThemeData theme, String? address) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
                ),
                if (address != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Iconsax.location,
                            size: 14, color: BColors.darkGrey),
                      ),
                      const SizedBox(width: BSizes.xs),
                      Expanded(
                        child: Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: BColors.darkGrey),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
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
                      size: 24,
                      color: isSelected ? BColors.primary : BColors.darkGrey,
                    )
                  : IconButton(
                      key: const ValueKey('info'),
                      tooltip: 'Account details',
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
      );

  /// The number the collector came for.
  Widget _outstanding(ThemeData theme) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                BFormatter.formatPesoCurrency(
                    _settled ? totalCollected : totalAmount),
                maxLines: 1,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: _settled ? BColors.success : BColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: BSizes.xs),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              _settled ? 'collected' : 'outstanding',
              style: theme.textTheme.bodySmall?.copyWith(
                color: BColors.darkGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
                minHeight: 4,
                backgroundColor: BColors.grey,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(BColors.success),
              ),
            ),
          ),
          // Only where it adds something. On a settled account the headline
          // already reads "₱45,000.00 collected", so repeating it under a
          // full bar is the same sentence twice.
          if (!_settled) ...[
            const SizedBox(height: BSizes.xs),
            Text(
              '${BFormatter.formatPesoCurrency(totalCollected)} collected so far',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: BColors.darkGrey),
            ),
          ],
        ],
      );

  /// Invoice count, and how much of it is late.
  Widget _meta(ThemeData theme) => Row(
        children: [
          Icon(Iconsax.document_text, size: 14, color: BColors.darkGrey),
          const SizedBox(width: BSizes.xs),
          Text(
            '$invoiceCount invoice${invoiceCount == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: BColors.darkGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (overdueCount > 0) ...[
            const SizedBox(width: BSizes.sm),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                // Tinted, not solid: in these lists almost everything is
                // overdue, and a wall of filled red badges carries no signal.
                color: BColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
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
      );
}
