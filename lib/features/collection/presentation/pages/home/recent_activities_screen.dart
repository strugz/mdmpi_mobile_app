import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/engagement_history_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/collection_search_filter_bar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/engagement_filter_sheet.dart';
import 'package:get/get.dart';

/// Engagement History, over the days the collector chooses.
///
/// It listed every entry the phone had ever cached, filtered by ten raw
/// statuses and no Advanced Payment. Now it shows From to To (today unless
/// the collector picks otherwise), read from the engagement archive, with a
/// search over account, invoice and P.O. The dates and the statuses are both
/// set in one filter sheet ([EngagementFilterSheet]) behind the button beside
/// the search, and what is in force shows as removable chips under it. Over
/// more than one day the list is headed by day, so a week reads as a week.
class RecentActivitiesScreen extends StatefulWidget {
  const RecentActivitiesScreen({super.key});

  @override
  State<RecentActivitiesScreen> createState() => _RecentActivitiesScreenState();
}

class _RecentActivitiesScreenState extends State<RecentActivitiesScreen> {
  EngagementFilter _filter = EngagementFilter.forToday();
  String _query = '';

  void _clearFilters() => setState(() {
        _filter = _filter.copyWith(statuses: const {});
        _query = '';
      });

  Future<void> _openFilter(CollectionActivityController controller) async {
    final chosen = await EngagementFilterSheet.show(
      context,
      initial: _filter,
      entriesBetween: controller.engagementsBetween,
      query: _query,
    );
    if (chosen != null && mounted) setState(() => _filter = chosen);
  }

  /// The day an entry happened, or null when its stamp cannot be read.
  static DateTime? _dayOf(Map<String, dynamic> e) {
    final at =
        BFormatter.parseLocal((e['history'] as CollectionHistoryModel).date);
    return at == null ? null : DateTime(at.year, at.month, at.day);
  }

  /// The list's rows: over one day just the entries; over several, a
  /// heading before each day's first entry (entries are newest first).
  static List<Object> _rows(List<Map<String, dynamic>> shown, bool byDay) {
    if (!byDay) return shown;
    final rows = <Object>[];
    DateTime? current;
    for (final e in shown) {
      final day = _dayOf(e);
      if (day != null && day != current) {
        current = day;
        rows.add(day);
      }
      rows.add(e);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Engagement History')),
      body: Obx(() {
        final entries = controller.engagementsBetween(_filter.from, _filter.to);
        final shown = EngagementHistoryFilter.apply(entries,
            statuses: _filter.statuses, query: _query);
        final filtering =
            _filter.statuses.isNotEmpty || _query.trim().isNotEmpty;
        final byDay = !_filter.isSingleDay;
        final rows = _rows(shown, byDay);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: CollectionSearchFilterBar(
                key: const ValueKey('history-search-bar'),
                searchHint: 'Search account, invoice or P.O.',
                // Follows _query, so Clear filters empties the field too.
                initialValue: _query,
                onSearchChanged: (v) => setState(() => _query = v),
                onFilterTap: () => _openFilter(controller),
                hasActiveFilter: _filter.isActive,
              ),
            ),
            SliverToBoxAdapter(
              child: EngagementFilterChips(
                filter: _filter,
                onChanged: (next) => setState(() => _filter = next),
              ),
            ),
            SliverToBoxAdapter(
              child: _RangeSummary(
                label: _filter.rangeLabel,
                count: entries.length,
                collected: EngagementHistoryFilter.collected(entries),
              ),
            ),
            if (entries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  icon: Iconsax.calendar_1,
                  title: _filter.isToday
                      ? 'No engagements yet today'
                      : _filter.isSingleDay
                          ? 'No engagements on ${_filter.rangeLabel}'
                          : 'No engagements from ${_filter.rangeLabel}',
                  message: 'Tap the filter button to choose other dates.',
                ),
              )
            else if (shown.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  icon: Iconsax.search_status,
                  title: 'Nothing matches',
                  message: 'No engagement in these dates matches the filters.',
                  action: filtering
                      ? TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear filters'),
                        )
                      : null,
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    BSizes.defaultSpace,
                    0,
                    BSizes.defaultSpace,
                    BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom),
                sliver: SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    if (row is DateTime) {
                      return _DayHeading(
                        key: ValueKey('history-heading-$row'),
                        day: row,
                        first: i == 0,
                      );
                    }
                    final e = row as Map<String, dynamic>;
                    final history = e['history'] as CollectionHistoryModel;
                    return ActivityHistoryCard(
                      key: ValueKey(history),
                      history: history,
                      accountName: e['accountName']?.toString(),
                      invoiceId: e['invoiceId']?.toString(),
                      item: e['item'] as CollectionItemModel?,
                      reconciledOn: e['reconciledOn'] as String?,
                      invoiceCount: e['invoiceCount'] as int?,
                      // The day is in the line or heading above; each card
                      // says when.
                      timeOnly: true,
                    );
                  },
                ),
              ),
          ],
        );
      }),
    );
  }
}

/// "Sep 19 – 25, 2026 · 12 engagements · ₱756,305.23 collected": which days
/// the list covers and what they add up to, in one quiet line. The dates are
/// set in the filter.
class _RangeSummary extends StatelessWidget {
  const _RangeSummary({
    required this.label,
    required this.count,
    required this.collected,
  });

  final String label;
  final int count;
  final double collected;

  @override
  Widget build(BuildContext context) {
    final parts = [
      label,
      if (count > 0) ...[
        '$count engagement${count == 1 ? '' : 's'}',
        '${BFormatter.formatPesoCurrency(collected)} collected',
      ],
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace, 0, BSizes.defaultSpace, BSizes.sm),
      child: Text(
        parts.join(' · '),
        key: const ValueKey('history-day-summary'),
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: BCollectionColors.inkMuted),
      ),
    );
  }
}

/// "Today", "Yesterday", "Tuesday, Sep 23": the day the cards under it
/// happened, when the list spans more than one.
class _DayHeading extends StatelessWidget {
  const _DayHeading({super.key, required this.day, required this.first});

  final DateTime day;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final diff = EngagementFilter.today.difference(day).inDays;
    final label = diff == 0
        ? 'Today'
        : diff == 1
            ? 'Yesterday'
            : DateFormat('EEEE, MMM d').format(day);
    return Padding(
      padding: EdgeInsets.only(
          top: first ? 0 : BSizes.spaceBtwItems, bottom: BSizes.xs),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700, color: BCollectionColors.inkSecondary),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: BSizes.defaultSpace * 2, vertical: BSizes.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: BCollectionColors.inkMuted),
          const SizedBox(height: BSizes.spaceBtwItemsLight),
          Text(title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: BCollectionColors.inkSecondary)),
          const SizedBox(height: BSizes.xs),
          Text(message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: BCollectionColors.inkMuted)),
          if (action != null) ...[
            const SizedBox(height: BSizes.sm),
            action!,
          ],
        ],
      ),
    );
  }
}
