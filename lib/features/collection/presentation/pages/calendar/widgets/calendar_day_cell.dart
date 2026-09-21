import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// One day in the month grid.
///
/// Three things have to be legible at a glance and none of them may be
/// confused for another: the day you have selected, today, and a day you did
/// work on. They used to share one channel — a filled circle, green for work
/// and blue for selection — so on a month where the collector worked most days
/// the grid was a wall of discs and the selected day did not stand out from
/// them.
///
/// So each state gets its own channel. Selection is the only fill on this
/// grid. Today is the only ring. Work is a dot under the numeral, always the
/// same size: at grid scale what the reader wants is whether they were out
/// that day, and a second numeral in a 44pt cell stops being legible as soon
/// as the system text size goes up. The count itself is said in the day
/// heading, and announced by [CalendarDayMarker].
///
/// Contains no [Semantics] on purpose. `table_calendar` wraps whatever a day
/// builder returns in `Semantics(..., excludeSemantics: true)`, so anything
/// added here is discarded — see [CalendarDayMarker], which rides on the
/// marker layer outside that exclusion.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    required this.hasEngagements,
    this.isToday = false,
    this.isSelected = false,
    this.isOutside = false,
    this.onTap,
  });

  final DateTime day;
  final bool hasEngagements;
  final bool isToday;
  final bool isSelected;

  /// A day from the neighbouring month, shown to fill the grid.
  final bool isOutside;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color numeral = isSelected
        ? BCollectionColors.onPrimary
        : isToday
            ? BCollectionColors.primary
            : isOutside
                ? BCollectionColors.inkMuted
                : BCollectionColors.ink;

    return BPressableScale(
      onTap: onTap,
      // The disc, not the whole cell: pressing a day should read as that day
      // giving way, not as the grid rippling.
      child: Container(
        margin: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? BCollectionColors.primary : null,
          border: isSelected
              // A halo outside the fill, so today still reads as today once
              // it is also the selected day.
              ? (isToday
                  ? Border.all(color: BCollectionColors.primarySoft, width: 2)
                  : null)
              : (isToday
                  ? Border.all(color: BCollectionColors.primary, width: 1.5)
                  : null),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${day.day}',
              // Seven fixed columns cannot reflow, and at 2.0 a two-digit
              // numeral will not fit its disc. Everything below the grid
              // scales freely.
              textScaler:
                  MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: numeral,
                fontWeight: hasEngagements || isToday || isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 5,
              width: 5,
              child: hasEngagements && !isOutside
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? BCollectionColors.onPrimary
                            : BCollectionColors.primary,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// The engagement count for a day, for a screen reader only.
///
/// `table_calendar` announces the date itself and excludes the semantics of
/// whatever a day builder returns, so the count cannot be attached there. The
/// marker layer is a sibling of the cell in the package's Stack, outside that
/// exclusion, which makes it the one place the count can be heard from.
class CalendarDayMarker extends StatelessWidget {
  const CalendarDayMarker({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    // One logical pixel, not SizedBox.shrink: a zero-size node is dropped
    // before it reaches the semantics tree, and the count with it.
    return Semantics(
      // Its own node, not a label merged into the date's: merged, the count
      // is read as part of the day's name rather than as a fact about it.
      container: true,
      label: count == 1 ? '1 engagement' : '$count engagements',
      child: const SizedBox(width: 1, height: 1),
    );
  }
}
