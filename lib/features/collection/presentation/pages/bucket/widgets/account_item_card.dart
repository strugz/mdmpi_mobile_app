import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

class AccountItemCard extends StatelessWidget {
  final ClientModel client;
  final int invoiceCount;
  final double totalAmount;
  final double totalCollected;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;
  final VoidCallback? onClaimTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  const AccountItemCard({
    super.key,
    required this.client,
    required this.invoiceCount,
    required this.totalAmount,
    this.totalCollected = 0.0,
    required this.onTap,
    required this.onInfoTap,
    this.onClaimTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  /// Selection tint/border and the mode-dependent icon both animate at this
  /// speed so the card reads as one surface changing state, not two.
  static const Duration _stateDuration = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₱');
    final theme = Theme.of(context);

    return BPressableScale(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: _stateDuration,
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(BSizes.md),
        decoration: BoxDecoration(
          color: isSelected ? BColors.primary.withValues(alpha: 0.05) : BColors.white,
          borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
          // Keep width constant and animate colour only: a 1→2px border
          // shifts the content by a pixel on every toggle.
          border: Border.all(
            color: isSelected ? BColors.primary : BColors.grey,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: BColors.black.withValues(alpha: isSelected ? 0.0 : 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    // Optically align the title with the 24px trailing glyph.
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      client.name,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: BSizes.xs),
                // Trailing glyph: info button normally, selection mark in
                // selection mode. Cross-fades with a slight scale so the
                // swap is a single morph rather than a pop.
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
                            color: isSelected ? BColors.primary : BColors.darkGrey,
                            size: 24,
                          )
                        : IconButton(
                            key: const ValueKey('info'),
                            tooltip: 'Account details',
                            onPressed: onInfoTap,
                            icon: const Icon(Iconsax.info_circle, size: 22, color: BColors.primary),
                            // Visually compact, but keep a 40px hit area so
                            // the target is reachable with a thumb.
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                            splashRadius: 20,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BSizes.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Iconsax.location, size: 16, color: BColors.darkGrey),
                ),
                const SizedBox(width: BSizes.xs),
                Expanded(
                  child: Text(
                    client.address,
                    style: theme.textTheme.bodyMedium?.copyWith(color: BColors.darkGrey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: BSizes.spaceBtwSections),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invoices', style: theme.textTheme.labelMedium),
                    Text(
                      '$invoiceCount invoice${invoiceCount == 1 ? '' : 's'}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (onClaimTap != null && !isSelectionMode) ...[
                      const SizedBox(height: BSizes.md),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: onClaimTap,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: BSizes.md),
                            side: const BorderSide(color: BColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                            ),
                          ),
                          child: Text(
                            'Acquire Account',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: BColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total Amount Due', style: theme.textTheme.labelMedium),
                    Text(
                      currencyFormat.format(totalAmount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: BColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: BSizes.xs),
                    Text('Total Collected', style: theme.textTheme.labelMedium),
                    Text(
                      currencyFormat.format(totalCollected),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: BColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
