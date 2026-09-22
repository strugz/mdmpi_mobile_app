import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// A day with nothing on it.
///
/// The copy branches on *why* the day is empty, the same way the bucket's does.
/// "No engagements recorded for this day" was true of a Sunday, of next
/// Tuesday and of a day the collector had simply not got to yet, and told them
/// nothing about which one they were looking at.
///
/// There is deliberately no "no accounts match" branch: the account chips are
/// built from the day's own engagements, so every chip has rows behind it and
/// a filter here cannot empty the list.
class CalendarDayEmptyState extends StatelessWidget {
  const CalendarDayEmptyState({
    super.key,
    required this.day,
    required this.onAdd,
    this.today,
  });

  final DateTime day;
  final VoidCallback onAdd;

  /// Injectable so a test does not have to wait for midnight.
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final now = today ?? DateTime.now();
    final thisDay = DateTime(day.year, day.month, day.day);
    final nowDay = DateTime(now.year, now.month, now.day);
    final isToday = thisDay == nowDay;
    final isFuture = thisDay.isAfter(nowDay);
    final date = DateFormat('MMM d').format(day);

    final IconData icon = isToday
        ? Iconsax.calendar_add
        : isFuture
            ? Iconsax.calendar
            : Iconsax.calendar_1;
    final String headline = isToday
        ? 'Nothing recorded today'
        : isFuture
            ? "$date hasn't happened yet"
            : 'Nothing recorded on $date';
    final String explainer = isToday
        ? 'Log a field engagement and it will appear here.'
        : isFuture
            ? 'This calendar shows engagements you have already recorded.'
            : 'No field engagements were logged on this day.';

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child:
              Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              BSizes.defaultSpace, BSizes.lg, BSizes.defaultSpace, BSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BCollectionColors.primary.withValues(alpha: 0.06),
                ),
                alignment: Alignment.center,
                child: Icon(icon,
                    size: 40,
                    color: BCollectionColors.primary.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: BCollectionColors.inkSecondary,
                ),
              ),
              const SizedBox(height: BSizes.xs),
              Text(
                explainer,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: BCollectionColors.inkMuted),
              ),
              // Nothing to offer on a day that has not happened: an engagement
              // is recorded where the collector is standing, now.
              // The one action on an empty day, so it wears the accent
              // rather than the grey outline that read as secondary.
              if (!isFuture) ...[
                const SizedBox(height: BSizes.spaceBtwItems),
                FilledButton.icon(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: BCollectionColors.primary,
                    foregroundColor: BCollectionColors.onPrimary,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                        horizontal: BSizes.lg, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(BSizes.borderRadiusLg),
                    ),
                    textStyle: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Iconsax.add_circle, size: 18),
                  label: const Text('Add field engagement'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
