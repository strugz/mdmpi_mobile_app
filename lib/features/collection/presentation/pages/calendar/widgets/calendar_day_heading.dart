import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// `Today · 3 engagements` over the day's list.
///
/// The heading used to print the selected day as `2026-09-17`, straight out of
/// `DateTime.toString()`. That is a machine's way of writing a date, on a
/// screen a collector reads a hundred times a week.
///
/// The count lives here rather than in the grid: a 44pt day cell cannot hold a
/// second legible numeral, and by the time you are reading this line you have
/// already chosen the day and the number means something.
class CalendarDayHeading extends StatelessWidget {
  const CalendarDayHeading({
    super.key,
    required this.day,
    required this.count,
    this.today,
  });

  final DateTime day;
  final int count;

  /// Injectable so a test does not have to wait for midnight.
  final DateTime? today;

  /// 'Today', 'Yesterday', or the date. The year appears only when the day
  /// falls outside the current one, where it is the thing that disambiguates.
  static String label(DateTime day, {DateTime? today}) {
    final now = today ?? DateTime.now();
    final thisDay = DateTime(day.year, day.month, day.day);
    final nowDay = DateTime(now.year, now.month, now.day);
    final difference = nowDay.difference(thisDay).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference == -1) return 'Tomorrow';
    return day.year == now.year
        ? DateFormat('EEE, MMM d').format(day)
        : DateFormat('EEE, MMM d, y').format(day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace, BSizes.md, BSizes.defaultSpace, BSizes.sm),
      child: Row(
        children: [
          Flexible(
            child: Text(
              label(day, today: today),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: BCollectionColors.ink,
              ),
            ),
          ),
          // No count on an empty day: the empty state below says it in words,
          // and "· 0 engagements" is a sentence nobody needs twice.
          if (count > 0)
            Text(
              count == 1 ? ' · 1 engagement' : ' · $count engagements',
              maxLines: 1,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: BCollectionColors.inkMuted),
            ),
        ],
      ),
    );
  }
}
