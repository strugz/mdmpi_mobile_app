import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// Covers the bucket while an acquire is writing to the database.
///
/// Moving invoices into Field Engagement is fast in memory but the write
/// behind it is not, and one account can hold over a thousand invoices. With
/// nothing on screen the list simply stopped responding, which reads as a
/// crash rather than as work in progress.
///
/// It says what is happening and how much of it, because "1,095 invoices" is
/// the reason for the wait and knowing the number makes it tolerable. There is
/// no progress bar: the write reports no intermediate steps, and a bar that
/// fills on a timer is a lie about state.
class AcquiringOverlay extends StatelessWidget {
  const AcquiringOverlay({
    super.key,
    required this.visible,
    required this.invoiceCount,
    required this.accountCount,
  });

  final bool visible;

  /// What is being moved. Captured before the move so the copy does not
  /// change to zero halfway through.
  final int invoiceCount;
  final int accountCount;

  static const Duration fadeDuration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Positioned.fill must be a direct Stack child, so it wraps the switcher
    // rather than sitting inside the fade.
    return Positioned.fill(
      child: IgnorePointer(
        // Absorbs taps while active: a second Acquire mid-write would claim
        // an already-emptied selection.
        ignoring: !visible,
        child: AnimatedSwitcher(
          duration: fadeDuration,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: !visible
              ? const SizedBox.shrink(key: ValueKey('acquire-idle'))
              : Container(
                  key: const ValueKey('acquire-busy'),
                  color: BCollectionColors.ink.withValues(alpha: 0.45),
                  alignment: Alignment.center,
                  child: Container(
                    margin: const EdgeInsets.all(BSizes.defaultSpace),
                    padding: const EdgeInsets.symmetric(
                        horizontal: BSizes.lg, vertical: BSizes.defaultSpace),
                    decoration: BoxDecoration(
                      color: BCollectionColors.surface,
                      borderRadius:
                          BorderRadius.circular(BSizes.borderRadiusLg),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        const SizedBox(height: BSizes.md),
                        Text(
                          'Moving to Field Engagement',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: BSizes.xs),
                        Text(
                          _subtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: BCollectionColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  String get _subtitle {
    final invoices = '$invoiceCount invoice${invoiceCount == 1 ? '' : 's'}';
    final accounts = '$accountCount account${accountCount == 1 ? '' : 's'}';
    return '$invoices across $accounts';
  }
}
