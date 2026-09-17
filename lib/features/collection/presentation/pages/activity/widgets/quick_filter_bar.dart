import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/activity_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_fill_chip.dart';

/// One-tap filters under the search bar.
///
/// The sheet behind the filter button holds every dimension; this row holds
/// the two a collector reaches for every morning, how late the invoice is and
/// which territory, so the common case costs one tap instead of four (open,
/// choose, apply, close). It writes to the same [ActivityFilter], so the row,
/// the sheet and the list never disagree.
///
/// It doubles as the "what is filtering this list" display: a dimension the
/// row has no preset for, such as an amount band, appears at the end as a
/// removable chip, so there is one place to look and one to undo.
///
/// Its order chips carry both directions each. A first tap sorts descending,
/// a second flips to ascending, a third returns to the screen's own order.
class QuickFilterBar extends StatelessWidget {
  const QuickFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    this.areas = const [],
    this.defaultSort = ActivitySort.mostOverdue,
  });

  final ActivityFilter filter;
  final ValueChanged<ActivityFilter> onChanged;

  /// Territory codes present in the data, offered after the presets.
  final List<String> areas;

  /// The order the screen uses when no sort chip is on: the engagement list
  /// leads with the most overdue, the bucket is a catalogue ordered by name.
  /// Turning a sort chip off returns here rather than to a shared default.
  final ActivitySort defaultSort;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: BSizes.defaultSpace, vertical: BSizes.xs),
        children: [
          // Clears everything, including dimensions with no preset here.
          BQuickFillChip(
            label: 'All',
            selected: !filter.isActive && filter.sort == defaultSort,
            onTap: () => onChanged(ActivityFilter(sort: defaultSort)),
          ),
          _gap,
          _toggle(
            label: DueBand.overdue.label,
            icon: Iconsax.timer,
            color: BCollectionColors.danger,
            on: filter.due == DueBand.overdue,
            set: (on) =>
                filter.copyWith(due: on ? DueBand.overdue : DueBand.any),
          ),
          _gap,
          _toggle(
            label: DueBand.late30.label,
            icon: Iconsax.warning_2,
            color: BCollectionColors.danger,
            on: filter.due == DueBand.late30,
            set: (on) =>
                filter.copyWith(due: on ? DueBand.late30 : DueBand.any),
          ),
          _gap,
          // Orders, not filters: they hide nothing, so they never make the
          // list shorter and never count towards a filter being active.
          _cyclingSort(_amountCycle),
          _gap,
          _cyclingSort(_invoiceCycle),
          _gap,
          for (final area in areas) ...[
            _toggle(
              label: BCollectionArea.labelFor(area),
              icon: Iconsax.map_1,
              color: BCollectionColors.primary,
              on: filter.area == area,
              set: (on) => filter.copyWith(area: on ? area : ''),
            ),
            _gap,
          ],
          // Anything set elsewhere that this row has no preset for, so the
          // row always shows the whole truth about the list underneath it.
          if (filter.amount != AmountBand.any) ...[
            _removable(
              filter.amount.label,
              () => onChanged(filter.copyWith(amount: AmountBand.any)),
            ),
            _gap,
          ],
          if (filter.sort != defaultSort &&
              !_cycledSorts.any((entry) => entry.$1 == filter.sort)) ...[
            _removable(
              filter.sort.label,
              () => onChanged(filter.copyWith(sort: defaultSort)),
            ),
            _gap,
          ],
          if (filter.area.isNotEmpty && !areas.contains(filter.area))
            _removable(
              BCollectionArea.labelFor(filter.area),
              () => onChanged(filter.copyWith(area: '')),
            ),
        ],
      ),
    );
  }

  static const _gap = SizedBox(width: BSizes.sm);

  /// The two directions of one order, in tap order. Descending first: asked
  /// for far more often than ascending, so it is the first tap.
  static const _amountCycle = [
    (ActivitySort.amountHigh, Iconsax.arrow_down),
    (ActivitySort.amountLow, Iconsax.arrow_up),
  ];

  static const _invoiceCycle = [
    (ActivitySort.mostInvoices, Iconsax.document_copy),
    (ActivitySort.fewestInvoices, Iconsax.document),
  ];

  /// Every sort a cycling chip can hold, so the removable tail below knows
  /// which orders this row already speaks for.
  static const _cycledSorts = [..._amountCycle, ..._invoiceCycle];

  /// One chip carrying both directions of an order.
  ///
  /// Off, it offers the first direction. On, tapping flips to the other, and
  /// tapping again returns to [defaultSort], so the row never traps the list
  /// in an order with no way back. One chip rather than two keeps the row
  /// short enough to read without scrolling it.
  Widget _cyclingSort(List<(ActivitySort, IconData)> cycle) {
    final index = cycle.indexWhere((entry) => entry.$1 == filter.sort);
    final on = index >= 0;
    final (shownSort, shownIcon) = on ? cycle[index] : cycle.first;
    final next = !on
        ? cycle.first.$1
        : (index + 1 < cycle.length ? cycle[index + 1].$1 : defaultSort);

    return BQuickFillChip(
      label: shownSort.label,
      icon: shownIcon,
      color: BCollectionColors.primary,
      selected: on,
      onTap: () => onChanged(filter.copyWith(sort: next)),
    );
  }

  Widget _toggle({
    required String label,
    required IconData icon,
    required Color color,
    required bool on,
    required ActivityFilter Function(bool turningOn) set,
  }) {
    return BQuickFillChip(
      label: label,
      icon: icon,
      color: color,
      selected: on,
      onTap: () => onChanged(set(!on)),
    );
  }

  Widget _removable(String label, VoidCallback onRemove, {Color? color}) {
    final accent = color ?? BCollectionColors.primary;
    return BQuickFillChip(
      label: label,
      icon: Iconsax.close_circle,
      color: accent,
      selected: true,
      onTap: onRemove,
    );
  }
}
