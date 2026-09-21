import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// `‹ September 2026 ›`, with a way back to today.
///
/// The package's own header is Material's default chrome and does not match
/// the month stepper the ledger already uses, so the grid is drawn headerless
/// and this sits above it. Same shape as `_MonthHeader` in the monthly
/// summary, so the two screens step through months the same way.
///
/// Tapping the title expands the grid back to a month. That matters because
/// the month collapses to a week as the collector scrolls their day: without
/// it, getting the month back would mean scrolling the list all the way up.
class CalendarMonthHeader extends StatelessWidget {
  const CalendarMonthHeader({
    super.key,
    required this.month,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onTitleTap,
    required this.onToday,
    required this.showToday,
  });

  final DateTime month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onTitleTap;
  final VoidCallback onToday;

  /// Hidden when today is already the selected day; an action that does
  /// nothing is worse than no action.
  final bool showToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(BSizes.sm, BSizes.sm, BSizes.sm, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onPreviousMonth,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
            color: BCollectionColors.inkSecondary,
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTitleTap,
              child: Text(
                DateFormat('MMMM yyyy').format(month),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: BCollectionColors.ink,
                ),
              ),
            ),
          ),
          // A fixed slot, so the month title stays centred whether or not the
          // Today button is showing.
          SizedBox(
            width: 48,
            child: showToday
                ? IconButton(
                    onPressed: onToday,
                    icon: const Icon(Icons.today_outlined, size: 20),
                    tooltip: 'Go to today',
                    color: BCollectionColors.primary,
                  )
                : null,
          ),
          IconButton(
            onPressed: onNextMonth,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
            color: BCollectionColors.inkSecondary,
          ),
        ],
      ),
    );
  }
}
