import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_fill_chip.dart';

/// Narrows a day to one account.
///
/// This replaces a dropdown that was not a filter at all: until you picked an
/// account the day showed nothing, so tapping a day answered with another
/// question. Here the list is already on screen and the chips only narrow it.
///
/// A chip row rather than the sheet the area filter uses, because the set is
/// two to six accounts, it is different every day, and most days it is not
/// needed — a sheet would cost a tap and a dismiss to reach a filter you
/// usually do not want.
class DayAccountFilterBar extends StatelessWidget {
  const DayAccountFilterBar({
    super.key,
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  /// Account name to number of engagements on this day, which is what orders
  /// the row.
  final Map<String, int> counts;

  /// Null means All.
  final String? selected;

  final ValueChanged<String?> onSelected;

  /// Below two accounts there is nothing to narrow: the row would be a no-op
  /// or a way to hide your own data. It is absent, not disabled.
  static bool worthShowing(Map<String, int> counts) => counts.length >= 2;

  @override
  Widget build(BuildContext context) {
    final names = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: BSizes.defaultSpace, vertical: BSizes.xs),
        children: [
          BQuickFillChip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final name in names) ...[
            const SizedBox(width: BSizes.sm),
            // Bounded, because the chip's own Flexible cannot bound it here:
            // a horizontal ListView gives its children unbounded width, so a
            // long account name would stretch the chip to four hundred points.
            // The same shape of mistake as the dropdown this row replaced.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: BQuickFillChip(
                label: '$name · ${counts[name]}',
                selected: selected == name,
                onTap: () => onSelected(name),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
