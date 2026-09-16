import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';

/// What is on the collector's plate right now, above the accounts it covers.
///
/// This is a queue that will normally hold a dozen accounts, so the summary
/// has to earn its height against the rows it pushes down. It is one line of
/// figures and a hairline of progress — enough to answer how much is still
/// out and how far through the day they are, without costing a card.
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
      padding: const EdgeInsets.symmetric(
          horizontal: BSizes.spaceBtwItemsLight, vertical: BSizes.sm),
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
        border: Border.all(color: BColors.grey, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done ? 'All settled' : 'Still to collect',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: BColors.darkGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        BFormatter.formatPesoCurrency(done ? collected : due),
                        maxLines: 1,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: done ? BColors.success : BColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BSizes.sm),
              // Counts on one line, right-aligned against the amount. They
              // were three Flexible columns sharing a row before, which on a
              // phone truncated every one of them to "1 acco…".
              Text(
                _counts(),
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: BColors.darkGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (collected > 0) ...[
            const SizedBox(height: BSizes.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _progress),
                // Long enough to read as filling up, short enough to be over
                // before the collector has taken the screen in.
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
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
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: BColors.darkGrey, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  /// The counts, stacked, with overdue added only when there is any.
  ///
  /// One Text rather than three Flexible columns sharing a row: that layout
  /// gave each count a third of the width and truncated every one of them to
  /// "1 acco…" on a phone.
  String _counts() {
    final parts = [
      '$accounts account${accounts == 1 ? '' : 's'}',
      '$invoices invoice${invoices == 1 ? '' : 's'}',
      if (overdue > 0) '$overdue overdue',
    ];
    return parts.join('\n');
  }
}
