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
class QuickFilterBar extends StatelessWidget {
  const QuickFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    this.areas = const [],
  });

  final ActivityFilter filter;
  final ValueChanged<ActivityFilter> onChanged;

  /// Territory codes present in the data, offered after the presets.
  final List<String> areas;

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
            selected: !filter.isActive,
            onTap: () => onChanged(filter.copyWith(
              due: DueBand.any,
              amount: AmountBand.any,
              area: '',
            )),
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
