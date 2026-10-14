import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// Covers the bucket while an acquire is writing to the database.
///
/// Moving invoices into Field Engagement is fast in memory but the write
/// behind it is not, and one account can hold over a thousand invoices. With
/// nothing on screen the list simply stopped responding, which reads as a
/// crash rather than as work in progress.
///
/// It says what is happening and how far along it is: the write reports each
/// invoice as it lands, so the ring fills and the count ("312 of 1,095") runs
/// from real progress, not from a timer.
class AcquiringOverlay extends StatelessWidget {
  const AcquiringOverlay({
    super.key,
    required this.visible,
    required this.invoiceCount,
    required this.accountCount,
    this.doneCount = 0,
  });

  final bool visible;

  /// What is being moved. Captured before the move so the copy does not
  /// change to zero halfway through.
  final int invoiceCount;
  final int accountCount;

  /// How many of [invoiceCount] have been written so far.
  final int doneCount;

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
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            // Indeterminate until the first invoice lands.
                            value: _fraction,
                          ),
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
                          _progress,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            // Digits keep their width, so the line does not
                            // jitter as the count climbs.
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
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

  double? get _fraction {
    if (invoiceCount <= 0 || doneCount <= 0) return null;
    return (doneCount / invoiceCount).clamp(0.0, 1.0);
  }

  String get _progress {
    final done = doneCount.clamp(0, invoiceCount);
    final pct = invoiceCount <= 0 ? 0 : (done * 100 ~/ invoiceCount);
    return '${_n(done)} of ${_n(invoiceCount)} · $pct%';
  }

  static String _n(int v) => BFormatter.formatIntegerNoDecimal(v.toDouble());

  String get _subtitle {
    final invoices =
        '${_n(invoiceCount)} invoice${invoiceCount == 1 ? '' : 's'}';
    final accounts = '$accountCount account${accountCount == 1 ? '' : 's'}';
    return '$invoices across $accounts';
  }
}
