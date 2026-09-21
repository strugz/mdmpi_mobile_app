import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_engagement_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/calendar/calendar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/calendar/widgets/calendar_day_cell.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/calendar/widgets/calendar_day_heading.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/calendar/widgets/calendar_skeleton.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:table_calendar/table_calendar.dart';

/// The calendar. What these protect: tapping a day answers with that day's
/// engagements rather than with another question; the heading is a date a
/// person reads; the account filter narrows but never gates; and the month
/// gives way to the week once the list has somewhere to go.

class _Activity extends CollectionActivityController {
  @override
  void onInit() {}
}

final _today = DateTime.now();

String _at(int hour, {int daysAgo = 0}) =>
    DateTime(_today.year, _today.month, _today.day - daysAgo, hour)
        .toIso8601String();

CollectionEngagementRecord _engagement(
  String engagedAt, {
  required String itemId,
  required String clientName,
}) =>
    CollectionEngagementRecord(
      localRef: CollectionEngagementRecord.buildLocalRef(
          kind: 'INVOICE', subjectId: itemId, engagedAt: engagedAt),
      collectorCode: 'jay',
      collectorName: 'Jay Bryan Abaoag',
      kind: 'INVOICE',
      itemId: itemId,
      clientId: clientName,
      clientName: clientName,
      engagedAt: engagedAt,
      engagedOn: BFormatter.localDayKey(engagedAt)!,
      status: 'Collected',
      amount: 1200,
      createdAt: engagedAt,
    );

_Activity _seed(List<CollectionEngagementRecord> rows) {
  final controller = _Activity();
  Get.put<CollectionActivityController>(controller);
  controller.startAggregateTracking();
  controller.hasLoadedOnce.value = true;
  controller.ownEngagements.assignAll(rows);
  return controller;
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    theme: BAppTheme.lightTheme,
    home: const CollectionCalendarScreen(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  testWidgets('a day answers with its engagements, not with a question',
      (tester) async {
    _seed([
      _engagement(_at(9), itemId: '97339', clientName: 'Alexis Yu Pharmacy'),
      _engagement(_at(14), itemId: '97340', clientName: 'Bicol Medical'),
    ]);
    await _pump(tester);

    expect(find.byType(ActivityHistoryList), findsOneWidget);
    expect(find.textContaining('select an account'), findsNothing);
    expect(find.text('Alexis Yu Pharmacy'), findsOneWidget);
    expect(find.text('Bicol Medical'), findsOneWidget);
  });

  testWidgets('the heading names the day, and never as an ISO string',
      (tester) async {
    _seed([_engagement(_at(9), itemId: '1', clientName: 'Alexis Yu Pharmacy')]);
    await _pump(tester);

    expect(find.text('Today · 1 engagement'), findsNothing,
        reason: 'the count is a separate Text, so the label can ellipsize');
    expect(find.text('Today'), findsOneWidget);
    expect(find.text(' · 1 engagement'), findsOneWidget);

    final iso = RegExp(r'\d{4}-\d{2}-\d{2}');
    final headings = tester
        .widgetList<Text>(find.descendant(
            of: find.byType(CalendarDayHeading), matching: find.byType(Text)))
        .map((t) => t.data ?? '');
    expect(headings.any(iso.hasMatch), isFalse);
  });

  testWidgets('the account filter is absent when there is one account',
      (tester) async {
    // A filter over one account can only be a no-op or a way to hide your own
    // work, so the row is not built at all.
    _seed([
      _engagement(_at(9), itemId: '1', clientName: 'Alexis Yu Pharmacy'),
      _engagement(_at(10), itemId: '2', clientName: 'Alexis Yu Pharmacy'),
    ]);
    await _pump(tester);
    expect(find.text('All'), findsNothing);
    expect(find.byType(ActivityHistoryList), findsOneWidget);
  });

  testWidgets('the account filter narrows the day without ever emptying it',
      (tester) async {
    _seed([
      _engagement(_at(9), itemId: '1', clientName: 'Alexis Yu Pharmacy'),
      _engagement(_at(10), itemId: '2', clientName: 'Bicol Medical'),
    ]);
    await _pump(tester);

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Alexis Yu Pharmacy · 1'), findsOneWidget);

    await tester.tap(find.text('Bicol Medical · 1'));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityHistoryList), findsOneWidget);
    expect(find.text('Alexis Yu Pharmacy'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('Alexis Yu Pharmacy'), findsOneWidget);
  });

  testWidgets('a long account name does not overflow the filter row',
      (tester) async {
    // The 232-pixel overflow this screen shipped with came from a dropdown
    // sizing itself to the longest account name in the list.
    _seed([
      _engagement(_at(9),
          itemId: '1',
          clientName: 'Accusure Medical Enterprises of Southern Luzon Inc.'),
      _engagement(_at(10), itemId: '2', clientName: 'Bicol Medical'),
    ]);
    await _pump(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'scrolling the day collapses the month to its week, and coming '
      'back opens it again', (tester) async {
    _seed([
      for (var i = 0; i < 12; i++)
        _engagement(_at(8 + i % 12),
            itemId: 'INV-$i', clientName: 'Account $i'),
    ]);
    await _pump(tester);

    double gridHeight() =>
        tester.getSize(find.byType(TableCalendar<Map<String, dynamic>>)).height;
    final monthHeight = gridHeight();

    // A fixed point low in the viewport, which is inside the day list whether
    // the grid is showing a month or a week. Dragging a widget that scrolls
    // out of view does nothing.
    await tester.dragFrom(const Offset(400, 540), const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(gridHeight(), lessThan(monthHeight));

    await tester.dragFrom(const Offset(400, 540), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(gridHeight(), monthHeight);
  });

  testWidgets('a day short enough to fit keeps its month', (tester) async {
    _seed([_engagement(_at(9), itemId: '1', clientName: 'Alexis Yu Pharmacy')]);
    await _pump(tester);

    final before =
        tester.getSize(find.byType(TableCalendar<Map<String, dynamic>>)).height;
    // A fixed point low in the viewport, which is inside the day list whether
    // the grid is showing a month or a week. Dragging a widget that scrolls
    // out of view does nothing.
    await tester.dragFrom(const Offset(400, 540), const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(
        tester.getSize(find.byType(TableCalendar<Map<String, dynamic>>)).height,
        before);
  });

  testWidgets('the empty state says why the day is empty', (tester) async {
    final controller = _seed([]);
    await _pump(tester);
    expect(find.text('Nothing recorded today'), findsOneWidget);
    expect(find.text('Add field engagement'), findsOneWidget);

    // A day that has not happened is not something to log against.
    final future = DateTime.now().add(const Duration(days: 3));
    await tester.tap(find.byWidgetPredicate((w) =>
        w is CalendarDayCell && w.day.day == future.day && !w.isOutside));
    await tester.pumpAndSettle();
    expect(find.textContaining("hasn't happened yet"), findsOneWidget);
    expect(find.text('Add field engagement'), findsNothing);

    expect(controller.ownEngagements, isEmpty);
  });

  testWidgets('the skeleton shows on the first load only', (tester) async {
    final controller = _Activity();
    Get.put<CollectionActivityController>(controller);
    controller.startAggregateTracking();
    controller.isLoading.value = true;

    await tester.pumpWidget(MaterialApp(
      theme: BAppTheme.lightTheme,
      home: const CollectionCalendarScreen(),
    ));
    await tester.pump();
    expect(find.byType(CalendarSkeleton), findsOneWidget);

    controller.hasLoadedOnce.value = true;
    await tester.pumpAndSettle();
    expect(find.byType(CalendarSkeleton), findsNothing);

    // A later refresh is not a first load and must not bring the bones back.
    controller.isLoading.value = true;
    await tester.pumpAndSettle();
    expect(find.byType(CalendarSkeleton), findsNothing);
  });

  testWidgets('a worked day is announced with its count', (tester) async {
    _seed([
      _engagement(_at(9), itemId: '1', clientName: 'Alexis Yu Pharmacy'),
      _engagement(_at(11), itemId: '2', clientName: 'Bicol Medical'),
      _engagement(_at(15), itemId: '3', clientName: 'Bicol Medical'),
      _engagement(_at(10, daysAgo: 1), itemId: '4', clientName: 'Solo Account'),
    ]);
    final handle = tester.ensureSemantics();
    await _pump(tester);

    expect(find.bySemanticsLabel('3 engagements'), findsOneWidget);
    expect(find.bySemanticsLabel('1 engagement'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a worked day is not painted with the status green',
      (tester) async {
    // A filled green disc on every worked day said "status: good" about
    // something that is not a status, and could not be told apart from the
    // selected day, which was also a filled disc. Selection is now the only
    // fill on this grid.
    _seed([_engagement(_at(9), itemId: '1', clientName: 'Alexis Yu Pharmacy')]);
    await _pump(tester);

    final discs = tester.widgetList<Container>(find.descendant(
        of: find.byType(CalendarDayCell), matching: find.byType(Container)));
    final fills = discs
        .map((c) => (c.decoration as BoxDecoration?)?.color)
        .whereType<Color>()
        .toSet();
    expect(fills, isNot(contains(BCollectionColors.success)));
    expect(fills.where((c) => c != BCollectionColors.primary), isEmpty,
        reason: 'the selected day is the only filled disc');
  });
}
