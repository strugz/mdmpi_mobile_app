import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/devices/device_utility.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/day_entry_grouping.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/widgets/activity_type_modal.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/collection_work_header.dart';

import 'widgets/calendar_day_cell.dart';
import 'widgets/calendar_day_empty_state.dart';
import 'widgets/calendar_day_heading.dart';
import 'widgets/calendar_month_header.dart';
import 'widgets/calendar_skeleton.dart';
import 'widgets/calendar_visit_card.dart';
import 'widgets/day_account_filter_bar.dart';

/// The collector's own record of their days.
///
/// Tap a day, see what you did on it. That is the whole screen, and it used to
/// ask a second question — which account? — before answering the first one,
/// with the day's engagements hidden behind a dropdown until you picked from
/// it. The account filter is still here, as chips, but it only narrows a list
/// that is already on screen.
///
/// The engagements come from the archive, through
/// [CollectionActivityController.activitiesByDate], not from the invoices in
/// the bucket: a settled invoice stops coming back from the server and used to
/// take the visit that settled it off this calendar.
class CollectionCalendarScreen extends StatefulWidget {
  const CollectionCalendarScreen({super.key});

  @override
  State<CollectionCalendarScreen> createState() =>
      _CollectionCalendarScreenState();
}

class _CollectionCalendarScreenState extends State<CollectionCalendarScreen> {
  final controller = Get.find<CollectionActivityController>();

  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  late DateTime _selectedDay;
  String? _accountFilter;

  final ScrollController _listController = ScrollController();
  PageController? _pageController;

  /// The day-grouped engagements this frame is drawing.
  ///
  /// Read once, at the top of the [Obx], and held here for the day builders.
  /// The builders run inside `TableCalendar`'s own build, where an `Obx`
  /// cannot see their reads — which is why this screen used to keep its `Obx`
  /// alive with a throwaway `allRecentHistory.length`, and why every cell was
  /// regrouping the collector's whole history for itself.
  Map<DateTime, List<Map<String, dynamic>>> _byDate = const {};

  /// Past this much scrolling the month gives way to the selected week; back
  /// under the lower figure it opens again.
  ///
  /// Two thresholds rather than one: at a single boundary a finger resting on
  /// the list flips the grid open and shut.
  static const double _collapseAt = BSizes.lg; // 24
  static const double _expandAt = BSizes.sm; // 8

  /// How much the list has to have left to show before the month is worth
  /// giving up.
  ///
  /// Collapsing buys back about four rows of grid. A day whose list runs a
  /// few points past the fold would trade the whole month for that, and then
  /// have nothing to scroll and no way back except scrolling up again. Three
  /// rows' worth is the point where the trade starts paying.
  static const double _worthCollapsing = _rowHeight * 3;

  static const double _rowHeight = 52;

  /// The grid's own height animation, which the package runs for us. Its
  /// default curve is linear; 200ms easeOutCubic is the rung this app uses for
  /// a screen changing state.
  static const Duration _formatDuration = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _listController.addListener(_onListScroll);
  }

  @override
  void dispose() {
    _listController.removeListener(_onListScroll);
    _listController.dispose();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  void _onListScroll() {
    if (!_listController.hasClients) return;
    final position = _listController.position;

    // Back at the top, the month always comes back. Checked before the
    // "is it worth it" test below, because collapsing shortens the grid and
    // so shortens what is left to scroll — gate the way back on that and a
    // day can collapse once and never reopen.
    if (position.pixels < _expandAt) {
      if (_format != CalendarFormat.month) {
        setState(() => _format = CalendarFormat.month);
      }
      return;
    }

    // Only giving up the month has to earn it. A day with little left to show
    // gains nothing from a smaller calendar, and this also keeps an overscroll
    // bounce from collapsing it.
    if (position.maxScrollExtent <= _worthCollapsing) return;
    if (position.pixels > _collapseAt && _format != CalendarFormat.week) {
      setState(() => _format = CalendarFormat.week);
    }
  }

  List<Map<String, dynamic>> _eventsFor(DateTime day) =>
      _byDate[DateTime(day.year, day.month, day.day)] ?? const [];

  void _selectDay(DateTime day) {
    if (isSameDay(_selectedDay, day)) return;
    setState(() {
      _selectedDay = day;
      _focusedDay = day;
      // The filter belonged to the day you were looking at, not to you.
      _accountFilter = null;
    });
  }

  void _expandToMonth() {
    setState(() => _format = CalendarFormat.month);
    if (_listController.hasClients && _listController.offset > 0) {
      _listController.animateTo(0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic);
    }
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _selectedDay = today;
      _focusedDay = today;
      _accountFilter = null;
    });
    _pageController?.animateToPage(
      // The package's page index is months from firstDay.
      (today.year - _firstDay.year) * 12 + today.month - _firstDay.month,
      duration: _formatDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _stepMonth(int months) {
    setState(() => _focusedDay =
        DateTime(_focusedDay.year, _focusedDay.month + months, 1));
    _pageController?.animateToPage(
      (_focusedDay.year - _firstDay.year) * 12 +
          _focusedDay.month -
          _firstDay.month,
      duration: _formatDuration,
      curve: Curves.easeOutCubic,
    );
  }

  static final DateTime _firstDay = DateTime.utc(2020, 1, 1);
  static final DateTime _lastDay = DateTime.utc(2030, 12, 31);

  void _addEngagement() => ActivityTypeModal.show(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CollectionWorkHeader(
            title: 'Calendar',
            // In the header rather than a full-width button between the grid
            // and the list, where it cost about 56pt of the tightest screen in
            // the module and pushed the day's own engagements below the fold.
            trailing: IconButton(
              onPressed: _addEngagement,
              icon: const Icon(Iconsax.add_circle),
              color: BCollectionColors.onHeader,
              tooltip: 'Add field engagement',
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isFirstLoad) {
                return const CalendarSkeleton();
              }

              // The one read of the grouping, for the whole frame. See
              // [_byDate].
              _byDate = controller.activitiesByDate;

              return _buildContent(context);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final dayEntries = _eventsFor(_selectedDay);

    return Column(
      children: [
        CalendarMonthHeader(
          month: _focusedDay,
          onPreviousMonth: () => _stepMonth(-1),
          onNextMonth: () => _stepMonth(1),
          onTitleTap: _expandToMonth,
          onToday: _goToToday,
          showToday: !isSameDay(_selectedDay, DateTime.now()),
        ),
        TableCalendar<Map<String, dynamic>>(
          firstDay: _firstDay,
          lastDay: _lastDay,
          focusedDay: _focusedDay,
          calendarFormat: _format,
          // Drawn by CalendarMonthHeader above, which matches the ledger's
          // month stepper instead of Material's default chrome.
          headerVisible: false,
          rowHeight: _rowHeight,
          daysOfWeekHeight: 20,
          eventLoader: _eventsFor,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, _) => _selectDay(selectedDay),
          onPageChanged: (focusedDay) => _focusedDay = focusedDay,
          onCalendarCreated: (pageController) =>
              _pageController = pageController,
          // Horizontal only. The package's vertical gesture changes the format
          // and would be arguing with the day list's own scroll for the same
          // drag; the format is decided by that scroll instead.
          availableGestures: AvailableGestures.horizontalSwipe,
          formatAnimationDuration: _formatDuration,
          formatAnimationCurve: Curves.easeOutCubic,
          calendarBuilders: CalendarBuilders<Map<String, dynamic>>(
            prioritizedBuilder: (context, day, focusedDay) => CalendarDayCell(
              day: day,
              hasEngagements: _eventsFor(day).isNotEmpty,
              isToday: isSameDay(day, DateTime.now()),
              isSelected: isSameDay(day, _selectedDay),
              isOutside: day.month != focusedDay.month,
              onTap: () => _selectDay(day),
            ),
            // The count rides here because the package discards the semantics
            // of anything a day builder returns. See [CalendarDayMarker].
            markerBuilder: (context, day, events) =>
                CalendarDayMarker(count: events.length),
          ),
        ),
        const Divider(height: 1, color: BCollectionColors.outline),
        Expanded(
          child: SingleChildScrollView(
            controller: _listController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CalendarDayHeading(day: _selectedDay, count: dayEntries.length),
                if (dayEntries.isEmpty)
                  CalendarDayEmptyState(
                      day: _selectedDay, onAdd: _addEngagement)
                else ...[
                  _buildFilterBar(dayEntries),
                  _buildDayList(dayEntries),
                ],
                SizedBox(
                  // The nav shell already takes the gesture bar out of the
                  // MediaQuery, so this is 0 today. It is here because it is
                  // the documented idiom and because it is what this screen
                  // will need the day it is pushed as its own route.
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

  Widget _buildFilterBar(List<Map<String, dynamic>> dayEntries) {
    final counts = <String, int>{};
    for (final entry in dayEntries) {
      final name = (entry['accountName'] ?? '').toString();
      if (name.isEmpty) continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    if (!DayAccountFilterBar.worthShowing(counts)) {
      return const SizedBox.shrink();
    }

    return DayAccountFilterBar(
      counts: counts,
      selected: _accountFilter,
      onSelected: (name) => setState(() => _accountFilter = name),
    );
  }

  Widget _buildDayList(List<Map<String, dynamic>> dayEntries) {
    final entries = _accountFilter == null
        ? dayEntries
        : dayEntries
            .where((e) => e['accountName'].toString() == _accountFilter)
            .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final group in groupDayEntriesByAccount(entries))
            if (group.length == 1)
              _singleEntryCard(group.single)
            else
              CalendarVisitCard(
                key: ValueKey('visit:${group.first['accountName']}'),
                accountName: group.first['accountName'].toString(),
                entries: group,
              ),
        ],
      ),
    );
  }

  /// A day's list is read by who was visited and at what time; the date is
  /// already in the heading above it.
  Widget _singleEntryCard(Map<String, dynamic> e) => ActivityHistoryCard(
        history: e['history'] as CollectionHistoryModel,
        accountName: e['accountName'].toString(),
        invoiceId: e['invoiceId']?.toString(),
        item: e['item'] as CollectionItemModel?,
        reconciledOn: e['reconciledOn'] as String?,
        invoiceCount: e['invoiceCount'] as int?,
        accountFirst: true,
        timeOnly: true,
      );
}
