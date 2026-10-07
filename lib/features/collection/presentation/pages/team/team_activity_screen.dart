import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/devices/device_utility.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/team_engagement.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/team_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/calendar/widgets/calendar_day_cell.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/calendar/widgets/calendar_day_heading.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/calendar/widgets/calendar_month_header.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/collection_work_header.dart';

/// The Head's *Team Activity* tab (Collection TODO items 21–22): the team's
/// uploaded field activity on a calendar, for everyone or for one collector.
///
/// Online only. What a collector has not uploaded yet is not here, so the
/// header says when the feed was loaded and offers a refresh.
class TeamActivityScreen extends StatelessWidget {
  const TeamActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TeamActivityController());

    return Scaffold(
      body: Column(
        children: [
          CollectionWorkHeader(
            title: 'Team Activity',
            trailing: Obx(() => IconButton(
                  key: const ValueKey('team-refresh'),
                  onPressed: controller.isLoading.value ? null : controller.load,
                  icon: const Icon(Iconsax.refresh),
                  color: BCollectionColors.onHeader,
                  tooltip: 'Reload',
                )),
          ),
          _CollectorBar(controller: controller),
          Expanded(child: _Body(controller: controller)),
        ],
      ),
    );
  }
}

/// Who is on screen, and how fresh the feed is.
class _CollectorBar extends StatelessWidget {
  const _CollectorBar({required this.controller});

  final TeamActivityController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A full-width selector row, not a chip: it is the one control that
    // changes what the whole screen is about, so it reads like a setting
    // (avatar · name · chevron), with the freshness as its subtitle.
    return Material(
      color: BCollectionColors.surface,
      child: Obx(() {
        final code = controller.selectedCollector.value;
        final at = controller.loadedAt.value;
        final count = controller.collectors.length;
        final subtitle = [
          if (code == null && count > 0)
            '$count collector${count == 1 ? '' : 's'}'
          else if (code != null)
            code,
          if (at != null) 'updated ${_clock(at)}',
        ].join(' · ');
        return InkWell(
          key: const ValueKey('team-collector-picker'),
          onTap: () => _pickCollector(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(BSizes.defaultSpace, BSizes.sm,
                BSizes.md, BSizes.sm),
            child: Row(
              children: [
                _Avatar(code: code, name: controller.selectionLabel),
                const SizedBox(width: BSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(controller.selectionLabel,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: BCollectionColors.inkMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Iconsax.arrow_down_1,
                    size: 18, color: BCollectionColors.inkSecondary),
              ],
            ),
          ),
        );
      }),
    );
  }

  static String _clock(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  Future<void> _pickCollector(BuildContext context) async {
    final code = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BCollectionColors.surface,
      builder: (_) => _CollectorSheet(
        collectors: controller.collectors.toList(),
        selected: controller.selectedCollector.value,
      ),
    );
    // null = dismissed; '' = everyone; else a code.
    if (code == null) return;
    await controller.selectCollector(code.isEmpty ? null : code);
  }
}

/// "All collectors" then everyone by name, searchable. Pops '' for everyone
/// and the code for one person; null when dismissed.
class _CollectorSheet extends StatefulWidget {
  const _CollectorSheet({required this.collectors, required this.selected});

  final List<TeamCollector> collectors;
  final String? selected;

  @override
  State<_CollectorSheet> createState() => _CollectorSheetState();
}

class _CollectorSheetState extends State<_CollectorSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _query.trim().toLowerCase();
    final rows = widget.collectors
        .where((c) =>
            q.isEmpty ||
            c.name.toLowerCase().contains(q) ||
            c.code.toLowerCase().contains(q))
        .toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(BSizes.defaultSpace,
                    BSizes.md, BSizes.defaultSpace, BSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Show activity of', style: theme.textTheme.titleMedium),
                    const SizedBox(height: BSizes.sm),
                    TextField(
                      key: const ValueKey('team-collector-search'),
                      autofocus: false,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.search_normal),
                        hintText: 'Search by name or code',
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (q.isEmpty)
                      ListTile(
                        key: const ValueKey('team-collector-all'),
                        leading: const Icon(Iconsax.people),
                        title: const Text('All collectors'),
                        selected: widget.selected == null,
                        trailing: widget.selected == null
                            ? const Icon(Iconsax.tick_circle,
                                color: BCollectionColors.primary)
                            : null,
                        onTap: () => Navigator.of(context).pop(''),
                      ),
                    if (rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(BSizes.defaultSpace),
                        child: Text(
                          widget.collectors.isEmpty
                              ? 'No collector has uploaded yet.'
                              : 'No one matches.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    for (final c in rows)
                      ListTile(
                        key: ValueKey('team-collector-${c.code}'),
                        leading: CircleAvatar(
                          child: Text(c.code.length > 3
                              ? c.code.substring(0, 3)
                              : c.code),
                        ),
                        title: Text(c.name),
                        subtitle: c.name == c.code ? null : Text(c.code),
                        selected: widget.selected == c.code,
                        trailing: widget.selected == c.code
                            ? const Icon(Iconsax.tick_circle,
                                color: BCollectionColors.primary)
                            : null,
                        onTap: () => Navigator.of(context).pop(c.code),
                      ),
                    const SizedBox(height: BSizes.sm),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller});

  final TeamActivityController controller;

  static final DateTime _firstDay = DateTime(2024, 1, 1);
  static final DateTime _lastDay = DateTime(2100, 12, 31);

  @override
  Widget build(BuildContext context) {
    // One Obx for the calendar and the day list: they read the feed, the
    // month, the day, the loading flag and the error together.
    return Obx(() => _content(context));
  }

  Widget _content(BuildContext context) {
    final byDay = controller.byDay;
    final focused = controller.focusedMonth.value;
    final selected = controller.selectedDay.value;
    final loading = controller.isLoading.value;
    final error = controller.error.value;
    final dayEntries = controller.dayEntries(selected);

    List<TeamEngagement> eventsFor(DateTime day) =>
        byDay[DateTime(day.year, day.month, day.day)] ?? const [];

    return Column(
      children: [
        CalendarMonthHeader(
          month: focused,
          onPreviousMonth: () => controller.stepMonth(-1),
          onNextMonth: () => controller.stepMonth(1),
          onTitleTap: () {},
          onToday: controller.goToToday,
          showToday: !controller.isTodaySelected,
        ),
        TableCalendar<TeamEngagement>(
          firstDay: _firstDay,
          lastDay: _lastDay,
          focusedDay: focused.year == selected.year &&
                  focused.month == selected.month
              ? selected
              : focused,
          calendarFormat: CalendarFormat.month,
          headerVisible: false,
          rowHeight: 44,
          daysOfWeekHeight: 20,
          eventLoader: eventsFor,
          selectedDayPredicate: (day) => isSameDay(selected, day),
          onDaySelected: (day, _) => controller.selectDay(day),
          onPageChanged: controller.showMonth,
          availableGestures: AvailableGestures.horizontalSwipe,
          calendarBuilders: CalendarBuilders<TeamEngagement>(
            prioritizedBuilder: (context, day, focusedDay) => CalendarDayCell(
              day: day,
              hasEngagements: eventsFor(day).isNotEmpty,
              isToday: isSameDay(day, DateTime.now()),
              isSelected: isSameDay(day, selected),
              isOutside: day.month != focusedDay.month,
              onTap: () => controller.selectDay(day),
            ),
            markerBuilder: (context, day, events) =>
                CalendarDayMarker(count: events.length),
          ),
        ),
        if (loading) const LinearProgressIndicator(minHeight: 2),
        const Divider(height: 1, color: BCollectionColors.outline),
        Expanded(
          child: error != null && controller.engagements.isEmpty
              ? _ErrorState(message: error, onRetry: controller.load)
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (error != null)
                        _StaleBanner(message: error, onRetry: controller.load),
                      // The list crossfades between days and collectors. A
                      // change of what is on screen, not a decoration: the
                      // eye keeps its place instead of the list snapping.
                      _DaySwitcher(
                        switchKey: ValueKey(
                            '${selected.toIso8601String()}|${controller.selectedCollector.value}'),
                        child: Column(
                          key: ValueKey(
                              '${selected.toIso8601String()}|${controller.selectedCollector.value}'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DayHeading(
                              day: selected,
                              count: dayEntries.length,
                              collected: controller.collectedOn(selected),
                            ),
                            if (dayEntries.isEmpty)
                              _EmptyDay(
                                loading: loading && controller.loadedAt.value == null,
                                who: controller.selectedCollector.value == null
                                    ? null
                                    : controller.selectionLabel,
                              )
                            else
                              _DayList(
                                entries: dayEntries,
                                groupByCollector:
                                    controller.selectedCollector.value == null,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: BSizes.defaultSpace +
                            BDevicesUtils.systemBottomInset(context),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Initials for one collector, or the team icon for everyone.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.code, required this.name, this.radius = 20});

  final String? code;
  final String name;
  final double radius;

  static String initialsOf(String name, String code) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words.map((w) => w[0]).take(2).join().toUpperCase();
    if (letters.length == 2) return letters;
    final c = code.trim().toUpperCase();
    return c.length >= 2 ? c.substring(0, 2) : (letters.isEmpty ? '?' : letters);
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: BCollectionColors.primarySoft,
      foregroundColor: BCollectionColors.primary,
      child: code == null
          ? Icon(Iconsax.people, size: radius)
          : Text(initialsOf(name, code!),
              style: TextStyle(
                  fontSize: radius * 0.75, fontWeight: FontWeight.w600)),
    );
  }
}

/// "Today · 2 engagements" with what was collected that day on the right.
class _DayHeading extends StatelessWidget {
  const _DayHeading(
      {required this.day, required this.count, required this.collected});

  final DateTime day;
  final int count;
  final double collected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace, BSizes.md, BSizes.defaultSpace, BSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(CalendarDayHeading.label(day), style: theme.textTheme.titleMedium),
          const SizedBox(width: BSizes.xs),
          Expanded(
            child: Text(
              '· $count engagement${count == 1 ? '' : 's'}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: BCollectionColors.inkMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (collected > 0)
            Text(
              BFormatter.formatPesoCurrency(collected),
              key: const ValueKey('team-day-collected'),
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: BCollectionColors.success),
            ),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.loading, required this.who});

  final bool loading;
  final String? who;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(BSizes.defaultSpace),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace, BSizes.sm, BSizes.defaultSpace, 0),
      child: Container(
        key: const ValueKey('team-day-empty'),
        width: double.infinity,
        padding: const EdgeInsets.all(BSizes.md),
        decoration: BoxDecoration(
          color: BCollectionColors.surfaceMuted,
          borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.calendar_remove,
                size: 20, color: BCollectionColors.inkMuted),
            const SizedBox(width: BSizes.sm),
            Expanded(
              child: Text(
                who == null
                    ? 'Nothing uploaded for this day.'
                    : '$who uploaded nothing for this day.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: BCollectionColors.inkSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The day's cards. With everyone on screen they are grouped under the
/// collector who did them, so the Head reads "Juan did these, Maria did
/// those" instead of hunting for a name on each card.
class _DayList extends StatelessWidget {
  const _DayList({required this.entries, required this.groupByCollector});

  final List<Map<String, dynamic>> entries;
  final bool groupByCollector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget card(Map<String, dynamic> e) => ActivityHistoryCard(
          key: ValueKey('team-entry-${e['key']}'),
          history: e['history'] as CollectionHistoryModel,
          accountName: e['accountName'] as String,
          invoiceId: e['invoiceId'] as String?,
          accountFirst: true,
          timeOnly: true,
        );

    if (!groupByCollector) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
        child: Column(children: [for (final e in entries) card(e)]),
      );
    }

    // Insertion order = the feed's order (newest first), so the collector
    // with the latest upload leads.
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final e in entries) {
      groups.putIfAbsent(e['collectorCode'] as String, () => []).add(e);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: BSizes.xs, bottom: BSizes.sm),
              child: Row(
                key: ValueKey('team-group-${entry.key}'),
                children: [
                  _Avatar(
                      code: entry.key,
                      name: entry.value.first['collectorName'] as String,
                      radius: 12),
                  const SizedBox(width: BSizes.sm),
                  Expanded(
                    child: Text(
                      entry.value.first['collectorName'] as String,
                      style: theme.textTheme.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${entry.value.length}',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: BCollectionColors.inkMuted),
                  ),
                ],
              ),
            ),
            for (final e in entry.value) card(e),
          ],
        ],
      ),
    );
  }
}

/// Fade + a 6px rise, 180 ms, ease-out; a plain swap under reduced motion.
class _DaySwitcher extends StatelessWidget {
  const _DaySwitcher({required this.switchKey, required this.child});

  final Key switchKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0, 0.02), end: Offset.zero)
              .animate(animation),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, if (current != null) current],
      ),
      child: child,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.cloud_cross,
                size: 40, color: BCollectionColors.inkMuted),
            const SizedBox(height: BSizes.sm),
            Text('Team activity unavailable',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message,
                key: const ValueKey('team-error'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall),
            TextButton(
                key: const ValueKey('team-retry'),
                onPressed: onRetry,
                child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

/// A reload failed but an earlier month is still on screen.
class _StaleBanner extends StatelessWidget {
  const _StaleBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      key: const ValueKey('team-stale'),
      backgroundColor: BCollectionColors.surfaceMuted,
      content: Text(message),
      leading: const Icon(Iconsax.warning_2, color: BCollectionColors.warning),
      actions: [
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}
