import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';
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
  });

  final ActivityFilter initial;

  /// How many accounts a candidate filter would show.
  final int Function(ActivityFilter) count;

  /// Territory codes present in the data, so the sheet never offers an area
  /// with nothing in it. Empty hides the group.
  final List<String> areas;

  /// Opens the sheet and resolves to the chosen filter, or null if dismissed.
  static Future<ActivityFilter?> show(
    BuildContext context, {
    required ActivityFilter initial,
    required int Function(ActivityFilter) count,
    List<String> areas = const [],
  }) =>
      showModalBottomSheet<ActivityFilter>(
        context: context,
        isScrollControlled: true,
        backgroundColor: BCollectionColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(BSizes.borderRadiusLg)),
        ),
        builder: (_) =>
            ActivityFilterSheet(initial: initial, count: count, areas: areas),
      );

  @override
  State<ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<ActivityFilterSheet> {
  late ActivityFilter _draft = widget.initial;

  /// Owned here so Reset can empty the field as well as the draft.
  late final TextEditingController _po =
      TextEditingController(text: widget.initial.poNumber);

  void _set(ActivityFilter next) {
    setState(() => _draft = next);
    // The field follows the draft, not the other way round, so a Reset (or
    // any future preset) leaves no stale text behind.
    if (_po.text != next.poNumber) {
      _po.value = TextEditingValue(
        text: next.poNumber,
        selection: TextSelection.collapsed(offset: next.poNumber.length),
      );
    }
  }

  /// The two P.O. controls answer one question, so they never contradict:
  /// asking for invoices with no P.O. discards any typed number, and typing
  /// a number while "No P.O." is on flips it back to Any.
  void _setPoPresence(PoPresence p) => _set(_draft.copyWith(
        poPresence: p,
        poNumber: p == PoPresence.none ? '' : _draft.poNumber,
      ));

  void _setPoNumber(String v) => _set(_draft.copyWith(
        poNumber: v,
        poPresence: v.trim().isNotEmpty && _draft.poPresence == PoPresence.none
            ? PoPresence.any
            : _draft.poPresence,
      ));

  @override
  void dispose() {
    _po.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = widget.count(_draft);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        BSizes.defaultSpace,
        BSizes.md,
        BSizes.defaultSpace,
        // Navigation bar once, keyboard once: the P.O. field sits above the
        // apply button, and a modal sheet does not move for the keyboard by
        // itself. Padding.bottom is already zero while the keyboard is up,
        // so the two never double-count.
        BSizes.defaultSpace +
            MediaQuery.paddingOf(context).bottom +
            MediaQuery.viewInsetsOf(context).bottom,
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
          _Group(
            title: 'Amount due',
            child: _chips<AmountBand>(
              options: AmountBand.values,
              label: (b) => b.label,
              selected: (b) => _draft.amount == b,
              onTap: (b) => _set(_draft.copyWith(amount: b)),
            ),
          ),
          _Group(
            title: 'P.O. number',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chips<PoPresence>(
                  options: PoPresence.values,
                  label: (p) => p.label,
                  selected: (p) => _draft.poPresence == p,
                  onTap: _setPoPresence,
                ),
                const SizedBox(height: BSizes.sm),
                _PoField(
                  controller: _po,
                  onChanged: _setPoNumber,
                  // Nothing to type against when the invoices being asked
                  // for have no P.O. Disabled, not hidden, so the group does
                  // not change height under the finger.
                  enabled: _draft.poPresence != PoPresence.none,
                ),
              ],
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

/// Typed lookup for the customer's P.O. number.
///
/// A text field, not chips: the bucket holds thousands of distinct P.O.s.
/// Styled like the list's search bar so it reads as the same kind of control,
/// and the count on the apply button answers as you type, so a P.O. that is
/// not in the bucket says so before anything is applied. No entrance
/// animation: the sheet opens tens of times a day and the field is just there.
class _PoField extends StatelessWidget {
  const _PoField({
    required this.controller,
    required this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;

  static const Duration _stateDuration = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        enabled: enabled,
        // P.O.s are the customer's codes: no autocorrect rewriting "ADC" and
        // no sentence casing on something matched case-insensitively anyway.
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.characters,
        textInputAction: TextInputAction.done,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Any part of the P.O. number',
          prefixIcon: const Icon(Iconsax.receipt_item, size: 20),
          // Clear affordance: rendered only while there is text, faded rather
          // than popped so the field does not jitter on the first keystroke.
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final hasText = value.text.isNotEmpty;
              return AnimatedOpacity(
                opacity: hasText ? 1 : 0,
                duration: _stateDuration,
                curve: Curves.easeOut,
                child: IgnorePointer(
                  ignoring: !hasText,
                  child: IconButton(
                    tooltip: 'Clear P.O. number',
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: const Icon(Iconsax.close_circle5, size: 18),
                    color: BCollectionColors.inkMuted,
                  ),
                ),
              );
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
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
      if (filter.amount != AmountBand.any)
        _chip(filter.amount.label, BCollectionColors.primary,
            () => onChanged(filter.copyWith(amount: AmountBand.any))),
      if (filter.area.isNotEmpty)
        _chip(BCollectionArea.labelFor(filter.area), BCollectionColors.primary,
            () => onChanged(filter.copyWith(area: ''))),
      if (filter.hasPoNumber)
        _chip('PO ${filter.poNumber.trim()}', BCollectionColors.primary,
            () => onChanged(filter.copyWith(poNumber: '')))
      // A typed P.O. already says "has one"; a second chip would repeat it.
      else if (filter.poPresence != PoPresence.any)
        _chip(filter.poPresence.label, BCollectionColors.primary,
            () => onChanged(filter.copyWith(poPresence: PoPresence.any))),
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
