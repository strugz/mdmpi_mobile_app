import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';

/// What is on the collector's plate right now, above the accounts it covers.
///
/// Field Engagement opened on a search bar, one or two account cards, and
/// then most of a screen of nothing. The blank space was not the problem so
/// much as the symptom: the screen never answered the question the collector
/// actually arrives with, which is how much is still out and how far through
/// it they are.
class EngagementSummary extends StatelessWidget {
  const EngagementSummary({
    super.key,
    required this.accounts,
    required this.invoices,
    required this.overdue,
    required this.due,
    required this.collected,
  });

  final int accounts;
  final int invoices;
  final int overdue;
  final double due;
  final double collected;

  double get _progress {
    final total = due + collected;
    if (total <= 0) return 0;
    return (collected / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = due <= 0 && collected > 0;

    return Container(
      padding: const EdgeInsets.all(BSizes.md),
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
        border: Border.all(color: BColors.grey, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            done ? 'All engaged invoices settled' : 'Still to collect',
            style: theme.textTheme.bodySmall?.copyWith(
              color: BColors.darkGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              BFormatter.formatPesoCurrency(done ? collected : due),
              maxLines: 1,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: done ? BColors.success : BColors.primary,
              ),
            ),
          ),
          if (collected > 0) ...[
            const SizedBox(height: BSizes.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _progress),
                // Long enough to read as filling up, short enough that it is
                // finished before the collector has taken the screen in.
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: BColors.grey,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(BColors.success),
                ),
              ),
            ),
            const SizedBox(height: BSizes.xs),
            Text(
              '${BFormatter.formatPesoCurrency(collected)} collected of ${BFormatter.formatPesoCurrency(due + collected)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: BColors.darkGrey),
            ),
          ],
          const Divider(height: BSizes.lg),
          Row(
            children: [
              _stat(theme, Iconsax.profile_2user, accounts,
                  accounts == 1 ? 'account' : 'accounts'),
              const SizedBox(width: BSizes.lg),
              _stat(theme, Iconsax.document_text, invoices,
                  invoices == 1 ? 'invoice' : 'invoices'),
              if (overdue > 0) ...[
                const SizedBox(width: BSizes.lg),
                _stat(theme, Iconsax.clock, overdue, 'overdue',
                    color: BColors.error),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(ThemeData theme, IconData icon, int value, String label,
          {Color color = BColors.darkerGrey}) =>
      Flexible(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: BSizes.xs),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$value ',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700, color: color),
                    ),
                    TextSpan(
                      text: label,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: BColors.darkGrey),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}
