import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/devices/device_utility.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/daily_quote.dart';

/// Quote of the Day: today's date, saying and verse in large type, then the healthy
/// tips. Open to everyone, signed in or not (Login and Settings link here).
class DailyQuoteScreen extends StatefulWidget {
  const DailyQuoteScreen({super.key, this.now});

  /// The day to show; today when null. For tests.
  final DateTime? now;

  @override
  State<DailyQuoteScreen> createState() => _DailyQuoteScreenState();
}

class _DailyQuoteScreenState extends State<DailyQuoteScreen> {
  late final DateTime _day = widget.now ?? DateTime.now();
  late final DailyQuotePair _today = BDailyQuotes.forDate(_day);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: BAppBar(
        showBackArrow: true,
        title: Text('Quote of the Day',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(BSizes.defaultSpace, BSizes.sm,
            BSizes.defaultSpace,
            BSizes.defaultSpace + BDevicesUtils.systemBottomInset(context)),
        child: Center(
          // Keeps lines readable on large phones and the Windows window.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(DateFormat('EEEE, MMMM d, y').format(_day),
                    key: const ValueKey('daily-quote-date'),
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: BSizes.md),
                BDailyQuoteCard(quote: _today.saying, large: true),
                const SizedBox(height: BSizes.spaceBtwItemsLight),
                BDailyQuoteCard(quote: _today.verse, large: true),
                const SizedBox(height: BSizes.spaceBtwSections),
                Text('Healthy tips',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: BSizes.spaceBtwItemsLight),
                for (final tip in BDailyQuotes.tips) ...[
                  _TipTile(tip: tip),
                  const SizedBox(height: BSizes.sm),
                ],
                const SizedBox(height: BSizes.md),
                Text('These are general tips, not medical advice.',
                    key: const ValueKey('daily-quote-disclaimer'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One quote (saying or verse), shared by the screen and the daily popup. A verse
/// carries its reference and translation underneath ("— John 14:27 (WEB)").
class BDailyQuoteCard extends StatelessWidget {
  const BDailyQuoteCard({super.key, required this.quote, this.large = false});

  final DailyQuote quote;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textStyle =
        (large ? theme.textTheme.headlineSmall : theme.textTheme.titleLarge)
            ?.copyWith(
                height: 1.4, fontWeight: FontWeight.w600, color: cs.onSurface);
    return Container(
      padding: EdgeInsets.all(large ? BSizes.lg : BSizes.md),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(quote.isVerse ? Icons.menu_book_outlined : Icons.format_quote,
              color: cs.primary, size: large ? 32 : 26),
          const SizedBox(height: BSizes.sm),
          Text(quote.text, style: textStyle),
          if (quote.isVerse) ...[
            const SizedBox(height: BSizes.spaceBtwItemsLight),
            Text('— ${quote.reference} (WEB)',
                key: const ValueKey('daily-quote-reference'),
                style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  const _TipTile({required this.tip});

  final HealthyTip tip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(BSizes.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(tip.icon, color: cs.primary),
          ),
          const SizedBox(width: BSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: BSizes.xxs),
                Text(tip.detail,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
