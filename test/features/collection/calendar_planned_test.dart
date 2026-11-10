import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_clock.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/calendar/calendar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/calendar/widgets/calendar_day_empty_state.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/calendar/widgets/calendar_day_heading.dart';

/// Reconciliation follow ups on the calendar
/// (docs/application/COLLECTION_RECON_FOLLOWUP_REMINDERS_PLAN.md, Phase 2):
/// planned on their due day, an overdue one also under today, mine only,
/// never counted as engagements, and a tap opens the case.

class _Activity extends CollectionActivityController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _Tracker extends ReconciliationController {
  _Tracker() : super(collectorCode: () => 'JCA', heldInvoiceIds: () => {});

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> load() async {}
}

final _now = DateTime.now();

/// The Manila calendar day [days] from today, as a log's due date.
String _day(int days) {
  final wall = BReconClock.fromInstant(_now);
  final d = DateTime.utc(wall.year, wall.month, wall.day + days);
  return BReconClock.format(d).substring(0, 10);
}

String _at(int daysAgo) => '${_day(-daysAgo)}T09:00:00';

ReconCaseView _case(String id, String client,
    {required String due, String collector = 'JCA', String action = ''}) {
  final bundle = ReconCaseBundle(
    reconCase: ReconCase(
        caseId: id,
        clientCode: 'C-$id',
        clientName: client,
        collectorCode: collector,
        collectorName: 'Jay',
        dateOpened: _at(10)),
    invoices: const [ReconCaseInvoice(invoiceNo: '700011347', amount: 6001)],
    activities: [
      ReconActivity(
          activityId: 'RA-$id',
          caseId: id,
          dateTime: _at(6),
          type: ReconActivityType.soaSent,
          nextAction: action,
          nextActionDueDate: due,
          recordedBy: collector),
    ],
  );
  return ReconCaseView(bundle, bundle.evaluate(now: _now));
}

final _overdue = _case('RC-1', "5'R's Medical Supply",
    due: _day(-2), action: 'Visit to follow up on SOA');
final _ahead = _case('RC-2', 'Accuteqs Diagnostics Corp.', due: _day(3));
final _theirs =
    _case('RC-3', 'Metro Globe', due: _day(0), collector: 'MAR');

DateTime _key(int days) {
  final d = DateTime.parse(_day(days));
  return DateTime(d.year, d.month, d.day);
}

Future<_Tracker> _pump(WidgetTester tester) async {
  final activity = _Activity();
  Get.put<CollectionActivityController>(activity);
  activity.startAggregateTracking();
  activity.hasLoadedOnce.value = true;
  final tracker = _Tracker();
  Get.put<ReconciliationController>(tracker);
  tracker.cases.assignAll([_overdue, _ahead, _theirs]);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GetMaterialApp(
    theme: BAppTheme.lightTheme,
    home: const CollectionCalendarScreen(),
    getPages: [
      GetPage(
          name: BRoutes.reconciliationCase,
          page: () => Scaffold(body: Text('case ${Get.arguments}'))),
    ],
  ));
  await tester.pumpAndSettle();
  return tracker;
}

void main() {
  tearDown(Get.reset);

  test('mine only, on the due day, and an overdue one under today too', () {
    Get.put<ReconciliationController>(_Tracker());
    final tracker = ReconciliationController.instance
      ..cases.assignAll([_overdue, _ahead, _theirs]);
    final planned = tracker.plannedFollowUps;
    expect(planned[_key(3)]!.map((c) => c.caseId), ['RC-2']);
    expect(planned[_key(-2)]!.map((c) => c.caseId), ['RC-1']);
    expect(planned[_key(0)]!.map((c) => c.caseId), ['RC-1'],
        reason: "overdue shows on today; MAR's case due today is not mine");
    Get.reset();
  });

  testWidgets('today lists the overdue follow up, not as an engagement',
      (tester) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('calendar-planned')), findsOneWidget);
    expect(find.byKey(const ValueKey('planned:RC-1')), findsOneWidget);
    expect(find.text('Visit to follow up on SOA'), findsOneWidget);
    expect(find.text('Overdue since ${_monthDay(-2)}'), findsOneWidget);
    expect(find.byKey(const ValueKey('planned:RC-2')), findsNothing,
        reason: 'due in 3 days, on its own day');
    expect(find.byKey(const ValueKey('planned:RC-3')), findsNothing,
        reason: "another collector's case");
    expect(find.byType(CalendarDayEmptyState), findsNothing,
        reason: 'a day with a plan is not empty');
    expect(
        tester
            .widget<CalendarDayHeading>(find.byType(CalendarDayHeading))
            .count,
        0,
        reason: 'planned items are not engagements');
    expect(find.byKey(const ValueKey('day-mark-planned')), findsWidgets);
  });

  testWidgets('tapping a planned follow up opens the case', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('planned:RC-1')));
    await tester.pumpAndSettle();
    expect(find.text('case RC-1'), findsOneWidget);
  });

  testWidgets('logging the follow up takes it off the calendar',
      (tester) async {
    final tracker = await _pump(tester);
    tracker.cases.assignAll([_ahead]);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('calendar-planned')), findsNothing);
    expect(find.byType(CalendarDayEmptyState), findsOneWidget);
  });
}

String _monthDay(int days) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final d = DateTime.parse(_day(days));
  return '${months[d.month - 1]} ${d.day}';
}
