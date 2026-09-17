import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/activity_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_fill_chip.dart';

/// One-tap filters under the search bar.
///
/// The sheet behind the filter button holds every dimension; this row holds
/// the four or five a collector reaches for every morning, so the common case
/// costs one tap instead of four (open, choose, apply, close). It writes to
/// the same [ActivityFilter], so the row, the sheet and the list never
/// disagree.
///
/// It doubles as the "what is filtering this list" display: a dimension the
/// row has no preset for (an amount band, a sort) appears at the end as a
/// removable chip, so there is one place to look and one place to undo.
class QuickFilterBar extends StatelessWidget {
  const QuickFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    this.areas = const [],
    this.showOutcomes = true,
  });

  final ActivityFilter filter;
  final ValueChanged<ActivityFilter> onChanged;

  /// Territory codes present in the data, offered after the presets.
  final List<String> areas;

  /// Whether to offer the last-visit outcomes. False in the bucket, where
  /// nothing has been engaged yet, so every account would answer "no visit".
  final bool showOutcomes;

  /// The presets, in the order a day is planned: how late first, then how the
  /// last visit went.
  static const _outcomePresets = [
    CollectionStatusColors.statusFollowUp,
    CollectionStatusColors.statusUnavailable,
  ];

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
              outcomes: const {},
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
          if (showOutcomes)
            for (final outcome in _outcomePresets) ...[
              _toggle(
                label: outcome,
                icon: CollectionStatusColors.iconFor(outcome),
                color: CollectionStatusColors.colorFor(outcome),
                on: filter.outcomes.contains(outcome),
                set: (_) => filter.toggleOutcome(outcome),
              ),
              _gap,
            ],
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
          for (final outcome in filter.outcomes
              .where((o) => !_outcomePresets.contains(o))) ...[
            _removable(
              outcome,
              () => onChanged(filter.toggleOutcome(outcome)),
              color: outcome == ActivityFilter.noVisitYet
                  ? BCollectionColors.neutral
                  : CollectionStatusColors.colorFor(outcome),
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
