import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/engagement_history_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_fill_chip.dart';

/// The days and statuses Engagement History shows: From to To, both
/// included, and any statuses (none: every status).
class EngagementFilter {
  const EngagementFilter({
    required this.from,
    required this.to,
    this.statuses = const {},
  });

  /// Today to today, every status: what the page opens on.
  factory EngagementFilter.forToday() {
    final t = today;
    return EngagementFilter(from: t, to: t);
  }

  /// Midnight of the first and last day shown.
  final DateTime from;
  final DateTime to;
  final Set<EngagementStatus> statuses;

  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get isSingleDay => from == to;

  bool get isToday => isSingleDay && from == today;

  /// Anything other than "today, every status".
  bool get isActive => !isToday || statuses.isNotEmpty;

  EngagementFilter copyWith({
    DateTime? from,
    DateTime? to,
    Set<EngagementStatus>? statuses,
  }) =>
      EngagementFilter(
        from: from ?? this.from,
        to: to ?? this.to,
        statuses: statuses ?? this.statuses,
      );

  /// Whether this covers exactly [f] to [t], whatever the statuses.
  bool sameRange(DateTime f, DateTime t) => from == f && to == t;

  /// "Today", "Yesterday", else "Sep 20, 2026".
  static String dayLabel(DateTime day) {
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(day);
  }

  /// One day as [dayLabel]; a range as "Sep 19 – 25, 2026",
  /// "Aug 28 – Sep 3, 2026" or "Dec 29, 2025 – Jan 4, 2026".
  String get rangeLabel {
    if (isSingleDay) return dayLabel(from);
    if (from.year != to.year) {
      final f = DateFormat('MMM d, yyyy');
      return '${f.format(from)} – ${f.format(to)}';
    }
    if (from.month != to.month) {
      return '${DateFormat('MMM d').format(from)} – '
          '${DateFormat('MMM d, yyyy').format(to)}';
    }
    return '${DateFormat('MMM d').format(from)} – '
        '${DateFormat('d, yyyy').format(to)}';
  }
}

/// Filter Engagement History: which days, which statuses.
///
/// The date used to be its own bar across the top of the page, one day at a
/// time. It is the first group here: a From and a To date, with presets for
/// the ranges a collector asks for most (Today, Yesterday, Last 7 days, This
/// month). The statuses sit in three short groups, each chip with the count
/// for the range in the draft, and more than one can be picked. The apply
/// button counts as the draft changes, so nobody applies a filter that shows
/// nothing.
///
/// Edits a draft and hands it back on apply; null when dismissed.
class EngagementFilterSheet extends StatefulWidget {
  const EngagementFilterSheet({
    super.key,
    required this.initial,
    required this.entriesBetween,
    this.query = '',
  });

  final EngagementFilter initial;

  /// The engagements from one day to another, both included, so the counts
  /// follow the range in the draft.
  final List<Map<String, dynamic>> Function(DateTime from, DateTime to)
      entriesBetween;

  /// The page's search, which the apply count also honours.
  final String query;

  static Future<EngagementFilter?> show(
    BuildContext context, {
    required EngagementFilter initial,
    required List<Map<String, dynamic>> Function(DateTime from, DateTime to)
        entriesBetween,
    String query = '',
  }) =>
      showModalBottomSheet<EngagementFilter>(
        context: context,
        isScrollControlled: true,
        backgroundColor: BCollectionColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(BSizes.borderRadiusLg)),
        ),
        builder: (_) => EngagementFilterSheet(
            initial: initial, entriesBetween: entriesBetween, query: query),
      );

  @override
  State<EngagementFilterSheet> createState() => _EngagementFilterSheetState();
}

class _EngagementFilterSheetState extends State<EngagementFilterSheet> {
  late EngagementFilter _draft = widget.initial;

  static final DateFormat _fieldFormat = DateFormat('MMM d, yyyy');

  /// The presets, each a From–To pair ending no later than today.
  static List<(String key, String label, DateTime from, DateTime to)>
      get _presets {
    final t = EngagementFilter.today;
    return [
      ('today', 'Today', t, t),
      (
        'yesterday',
        'Yesterday',
        t.subtract(const Duration(days: 1)),
        t.subtract(const Duration(days: 1))
      ),
      ('last7', 'Last 7 days', t.subtract(const Duration(days: 6)), t),
      ('month', 'This month', DateTime(t.year, t.month), t),
    ];
  }

  void _toggle(EngagementStatus s) {
    final next = {..._draft.statuses};
    next.contains(s) ? next.remove(s) : next.add(s);
    setState(() => _draft = _draft.copyWith(statuses: next));
  }

  void _setRange(DateTime from, DateTime to) =>
      setState(() => _draft = _draft.copyWith(from: from, to: to));

  /// From never goes past To, and To never before From: picking a From after
  /// the current To moves To with it, and the other way round, so the range
  /// can never be empty.
  Future<void> _pickFrom() async {
    final picked = await _pick(_draft.from, 'From');
    if (picked == null) return;
    _setRange(picked, picked.isAfter(_draft.to) ? picked : _draft.to);
  }

  Future<void> _pickTo() async {
    final picked = await _pick(_draft.to, 'To');
    if (picked == null) return;
    _setRange(picked.isBefore(_draft.from) ? picked : _draft.from, picked);
  }

  Future<DateTime?> _pick(DateTime initial, String which) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: EngagementFilter.today,
      helpText: 'Show engagements · $which',
    );
    if (picked == null || !mounted) return null;
    return DateTime(picked.year, picked.month, picked.day);
  }

  static String _applyLabel(int count) => switch (count) {
        0 => 'No engagements match',
        1 => 'Show 1 engagement',
        _ => 'Show $count engagements',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = widget.entriesBetween(_draft.from, _draft.to);
    final counts = EngagementHistoryFilter.counts(entries);
    final count = EngagementHistoryFilter.apply(entries,
            statuses: _draft.statuses, query: widget.query)
        .length;

    // No text field here, so the navigation bar is the only inset: once, at
    // the bottom of the scroll content.
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          BSizes.defaultSpace,
          BSizes.md,
          BSizes.defaultSpace,
          BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom),
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
              // A quiet link, only when there is something to reset.
              if (_draft.isActive)
                TextButton(
                  key: const ValueKey('filter-sheet-reset'),
                  onPressed: () =>
                      setState(() => _draft = EngagementFilter.forToday()),
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
            title: 'Date',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        key: const ValueKey('filter-from'),
                        label: 'From',
                        value: _fieldFormat.format(_draft.from),
                        onTap: _pickFrom,
                      ),
                    ),
                    const SizedBox(width: BSizes.sm),
                    Expanded(
                      child: _DateField(
                        key: const ValueKey('filter-to'),
                        label: 'To',
                        value: _fieldFormat.format(_draft.to),
                        onTap: _pickTo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BSizes.sm),
                // Shortcuts that fill both fields; the one matching the
                // fields is shown selected, so picking the same days by hand
                // lights it too.
                Wrap(
                  spacing: BSizes.sm,
                  runSpacing: BSizes.sm,
                  children: [
                    for (final (key, label, from, to) in _presets)
                      BQuickFillChip(
                        key: ValueKey('filter-range-$key'),
                        label: label,
                        selected: _draft.sameRange(from, to),
                        onTap: () => _setRange(from, to),
                      ),
                  ],
                ),
              ],
            ),
          ),
          for (final group in EngagementStatusGroup.values)
            _Group(
              title: group.label,
              child: Wrap(
                spacing: BSizes.sm,
                runSpacing: BSizes.sm,
                children: [
                  for (final s in EngagementStatus.values)
                    if (s.group == group)
                      BQuickFillChip(
                        key: ValueKey('status-chip-${s.name}'),
                        label: '${s.label} · ${counts[s] ?? 0}',
                        selected: _draft.statuses.contains(s),
                        onTap: () => _toggle(s),
                      ),
                ],
              ),
            ),
          const SizedBox(height: BSizes.sm),
          ElevatedButton(
            key: const ValueKey('filter-sheet-apply'),
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
}

/// A date that opens a picker: a label above, the date inside, a calendar
/// glyph. Read-only, so the keyboard never comes up for it.
class _DateField extends StatelessWidget {
  const _DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          prefixIcon: const Icon(Iconsax.calendar_1, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
          ),
        ),
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
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

/// The filters in force, under the search bar, each removable: the days when
/// they are not just today (removing them goes back to today), then the
/// statuses.
/// Without them the only sign of a filter was a shorter list.
class EngagementFilterChips extends StatelessWidget {
  const EngagementFilterChips({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final EngagementFilter filter;
  final ValueChanged<EngagementFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!filter.isActive) return const SizedBox.shrink();
    // Sheet order, not the order they were picked, so the row reads the same
    // way the sheet does.
    final statuses =
        EngagementStatus.values.where(filter.statuses.contains).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace, 0, BSizes.defaultSpace, BSizes.sm),
      child: Wrap(
        spacing: BSizes.xs,
        runSpacing: BSizes.xs,
        children: [
          if (!filter.isToday)
            _chip(
              context,
              key: const ValueKey('filter-active-day'),
              label: filter.rangeLabel,
              icon: Iconsax.calendar_1,
              onRemove: () => onChanged(filter.copyWith(
                  from: EngagementFilter.today, to: EngagementFilter.today)),
            ),
          for (final s in statuses)
            _chip(
              context,
              key: ValueKey('status-active-${s.name}'),
              label: s.label,
              onRemove: () => onChanged(
                  filter.copyWith(statuses: {...filter.statuses}..remove(s))),
            ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required Key key,
    required String label,
    required VoidCallback onRemove,
    IconData? icon,
  }) {
    return InputChip(
      key: key,
      avatar: icon == null
          ? null
          : Icon(icon, size: 16, color: BCollectionColors.primary),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: BCollectionColors.primary, fontWeight: FontWeight.w600),
      backgroundColor: BCollectionColors.primary.withValues(alpha: 0.10),
      side: BorderSide.none,
      deleteIcon: const Icon(Iconsax.close_circle,
          size: 16, color: BCollectionColors.primary),
      deleteButtonTooltipMessage: 'Remove $label',
      onDeleted: onRemove,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BSizes.borderRadiusLg)),
    );
  }
}
