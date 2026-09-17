import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/activity_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_fill_chip.dart';

/// Filter and sort the engagement list.
///
/// Replaces a side panel with one slider over a million-peso range. The
/// filters are the questions a collector asks when planning a day: how late,
/// what happened last time, how much, in what order. Each is a row of chips.
/// The apply button carries a live count, "Show 23 accounts", so nobody
/// applies a filter that returns nothing and wonders where the list went.
///
/// The sheet edits a draft and hands it back on apply; the caller owns the
/// controller. [count] is asked for the draft on every change.
class ActivityFilterSheet extends StatefulWidget {
  const ActivityFilterSheet({
    super.key,
    required this.initial,
    required this.count,
    this.areas = const [],
    this.showOutcomes = true,
  });

  final ActivityFilter initial;

  /// How many accounts a candidate filter would show.
  final int Function(ActivityFilter) count;

  /// Territory codes present in the data, so the sheet never offers an area
  /// with nothing in it. Empty hides the group.
  final List<String> areas;

  /// Whether to offer the last-visit outcomes. False in the bucket, where
  /// nothing has been engaged yet, so every account would answer "no visit".
  final bool showOutcomes;

  /// Opens the sheet and resolves to the chosen filter, or null if dismissed.
  static Future<ActivityFilter?> show(
    BuildContext context, {
    required ActivityFilter initial,
    required int Function(ActivityFilter) count,
    List<String> areas = const [],
    bool showOutcomes = true,
  }) =>
      showModalBottomSheet<ActivityFilter>(
        context: context,
        isScrollControlled: true,
        backgroundColor: BCollectionColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(BSizes.borderRadiusLg)),
        ),
        builder: (_) => ActivityFilterSheet(
          initial: initial,
          count: count,
          areas: areas,
          showOutcomes: showOutcomes,
        ),
      );

  @override
  State<ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<ActivityFilterSheet> {
  late ActivityFilter _draft = widget.initial;

  void _set(ActivityFilter next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = widget.count(_draft);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        BSizes.defaultSpace,
        BSizes.md,
        BSizes.defaultSpace,
        BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Filter engagements',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              // Reset is a quiet link, not a second big button competing
              // with Apply. Hidden when there is nothing to reset.
              if (_draft.isActive || _draft.sort != ActivitySort.mostOverdue)
                TextButton(
                  onPressed: () => _set(ActivityFilter.none),
                  child: const Text('Reset'),
                ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Iconsax.close_circle,
                    color: BCollectionColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: BSizes.md),
          _Group(
            title: 'Due',
            child: _chips<DueBand>(
              options: DueBand.values,
              label: (b) => b.label,
              selected: (b) => _draft.due == b,
              onTap: (b) => _set(_draft.copyWith(due: b)),
              color: (b) => b == DueBand.any
                  ? BCollectionColors.primary
                  : BCollectionColors.danger,
            ),
          ),
          if (widget.showOutcomes)
            _Group(
              title: 'Last visit',
              child: _chips<String>(
                options: ActivityFilter.outcomeOptions,
                label: (o) => o,
                selected: (o) => _draft.outcomes.contains(o),
                onTap: (o) => _set(_draft.toggleOutcome(o)),
                // The same colour and icon the card badge will show, so the
                // choice reads the same here as on the list.
                color: (o) => o == ActivityFilter.noVisitYet
                    ? BCollectionColors.neutral
                    : CollectionStatusColors.colorFor(o),
                icon: (o) => o == ActivityFilter.noVisitYet
                    ? Iconsax.location_cross
                    : CollectionStatusColors.iconFor(o),
              ),
            ),
          _Group(
            title: 'Amount due',
            child: _chips<AmountBand>(
              options: AmountBand.values,
              label: (b) => b.label,
              selected: (b) => _draft.amount == b,
              onTap: (b) => _set(_draft.copyWith(amount: b)),
            ),
          ),
          if (widget.areas.isNotEmpty)
            _Group(
              title: 'Area',
              child: _chips<String>(
                options: ['', ...widget.areas],
                label: (a) => a.isEmpty ? 'Any' : BCollectionArea.labelFor(a),
                selected: (a) => _draft.area == a,
                onTap: (a) => _set(_draft.copyWith(area: a)),
              ),
            ),
          _Group(
            title: 'Sort by',
            child: _chips<ActivitySort>(
              options: ActivitySort.values,
              label: (s) => s.label,
              selected: (s) => _draft.sort == s,
              onTap: (s) => _set(_draft.copyWith(sort: s)),
            ),
          ),
          const SizedBox(height: BSizes.sm),
          ElevatedButton(
            onPressed: count == 0 ? null : () => Navigator.pop(context, _draft),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              elevation: 0,
              backgroundColor: BCollectionColors.primary,
              foregroundColor: BCollectionColors.onPrimary,
              disabledBackgroundColor:
                  BCollectionColors.primary.withValues(alpha: 0.35),
              disabledForegroundColor: BCollectionColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
              ),
            ),
            child: Text(_applyLabel(count)),
          ),
        ],
      ),
    );
  }

  static String _applyLabel(int count) => switch (count) {
        0 => 'No accounts match',
        1 => 'Show 1 account',
        _ => 'Show $count accounts',
      };

  Widget _chips<T>({
    required List<T> options,
    required String Function(T) label,
    required bool Function(T) selected,
    required void Function(T) onTap,
    Color Function(T)? color,
    IconData? Function(T)? icon,
  }) {
    return Wrap(
      spacing: BSizes.sm,
      runSpacing: BSizes.sm,
      children: [
        for (final o in options)
          BQuickFillChip(
            label: label(o),
            selected: selected(o),
            onTap: () => onTap(o),
            color: color?.call(o),
            icon: icon?.call(o),
          ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: BCollectionColors.inkSecondary,
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: BSizes.sm),
          child,
        ],
      ),
    );
  }
}

/// The filters in force, shown on the list screen under the search bar as
/// removable chips. Today the only sign a filter was on was a shorter list.
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final ActivityFilter filter;
  final ValueChanged<ActivityFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (filter.due != DueBand.any)
        _chip(filter.due.label, BCollectionColors.danger,
            () => onChanged(filter.copyWith(due: DueBand.any))),
      for (final o in filter.outcomes)
        _chip(
            o,
            o == ActivityFilter.noVisitYet
                ? BCollectionColors.neutral
                : CollectionStatusColors.colorFor(o),
            () => onChanged(filter.toggleOutcome(o))),
      if (filter.amount != AmountBand.any)
        _chip(filter.amount.label, BCollectionColors.primary,
            () => onChanged(filter.copyWith(amount: AmountBand.any))),
      if (filter.area.isNotEmpty)
        _chip(BCollectionArea.labelFor(filter.area), BCollectionColors.primary,
            () => onChanged(filter.copyWith(area: ''))),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace, BSizes.sm, BSizes.defaultSpace, 0),
      child: Wrap(spacing: BSizes.xs, runSpacing: BSizes.xs, children: chips),
    );
  }

  Widget _chip(String label, Color color, VoidCallback onRemove) {
    return InputChip(
      label: Text(label),
      labelStyle:
          TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide.none,
      deleteIcon: Icon(Iconsax.close_circle, size: 16, color: color),
      deleteButtonTooltipMessage: 'Remove $label',
      onDeleted: onRemove,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BSizes.borderRadiusLg)),
    );
  }
}
