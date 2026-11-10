import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/daily_quote.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/daily_quote/daily_quote_screen.dart';

/// The once-a-day popup with today's saying and verse. Pops `true` for "Healthy tips"
/// (open the Quote of the Day screen) and `false` for "Thanks".
class DailyQuoteDialog extends StatelessWidget {
  const DailyQuoteDialog({super.key, required this.today});

  final DailyQuotePair today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
          horizontal: BSizes.lg, vertical: BSizes.defaultSpace),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              BSizes.lg, BSizes.lg, BSizes.lg, BSizes.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Quote of the Day',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: BSizes.md),
              // Two quotes on a small phone scroll instead of overflowing.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BDailyQuoteCard(quote: today.saying),
                      const SizedBox(height: BSizes.sm),
                      BDailyQuoteCard(quote: today.verse),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: BSizes.md),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: BSizes.sm,
                runSpacing: BSizes.xs,
                children: [
                  TextButton(
                    key: const ValueKey('daily-quote-tips'),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Healthy tips'),
                  ),
                  FilledButton(
                    key: const ValueKey('daily-quote-thanks'),
                    onPressed: () => Navigator.of(context).pop(false),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(112, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Thanks'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
