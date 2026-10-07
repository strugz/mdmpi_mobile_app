import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';
import 'package:mdmpi_mobile_app/data/models/directory_user.dart';
import 'package:mdmpi_mobile_app/features/collection/models/team_engagement.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/team_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/team/team_activity_screen.dart';

/// The Head's Team Activity tab (Collection TODO items 21–22): the calendar
/// shows the picked collector's uploaded activity for the selected day.

TeamActivityFeed _feed(List<TeamEngagement> rows) => TeamActivityFeed(
      from: '2026-09-01',
      to: '2026-09-30',
      collectors: const [
        TeamCollector(code: 'EMP1', name: 'Juan Reyes'),
        TeamCollector(code: 'EMP2', name: 'Maria Santos'),
      ],
      engagements: rows,
    );

const _juan = TeamEngagement(
    kind: 'Engagement',
    id: 1,
    collectorCode: 'EMP1',
    collectorName: 'Juan Reyes',
    clientCode: 'NCR-300',
    clientName: 'Metro Globe',
    documentId: 'S1',
    activityType: 'Field',
    status: 'Collected',
    amount: 900,
    date: '2026-09-25');
const _maria = TeamEngagement(
    kind: 'Engagement',
    id: 2,
    collectorCode: 'EMP2',
    collectorName: 'Maria Santos',
    clientCode: 'VIS-052',
    clientName: 'Bacolod Adventist',
    documentId: 'S3',
    activityType: 'Field',
    status: 'Partial Payment',
    amount: 100,
    date: '2026-09-25');
const _yesterday = TeamEngagement(
    kind: 'Deposit',
    id: 9,
    collectorCode: 'EMP1',
    collectorName: 'Juan Reyes',
    activityType: 'Deposit',
    amount: 2500,
    bankName: 'BPI',
    referenceNo: '1254897',
    date: '2026-09-24');

void main() {
  tearDown(Get.reset);

  late List<String?> asked;
  late bool fail;

  Future<TeamActivityController> pump(WidgetTester tester) async {
    asked = [];
    fail = false;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final controller = TeamActivityController(
      now: () => DateTime(2026, 9, 25, 10),
      members: () async => Result.success(const [
        DirectoryUser(
            key: 'PSR',
            name: 'Pedro Silang',
            department: 'Collection',
            username: 'psilang',
            inFirestore: true),
        DirectoryUser(
            key: 'MSA',
            name: 'Maria Santos',
            department: 'Collection',
            username: 'EMP2',
            inFirestore: true),
        DirectoryUser(
            key: 'LOG',
            name: 'Logistics Guy',
            department: 'Logistics',
            username: 'log',
            inFirestore: true),
      ]),
      load: ({required from, required to, collector}) async {
        asked.add(collector);
        if (fail) return Result.failure('Could not reach the server.');
        final all = [_juan, _maria, _yesterday];
        return Result.success(_feed(collector == null
            ? all
            : all.where((e) => e.collectorCode == collector).toList()));
      },
    );
    Get.put(controller);
    await tester.pumpWidget(MaterialApp(
        theme: BAppTheme.lightTheme, home: const TeamActivityScreen()));
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('today shows everyone\'s uploaded activity, naming who did it',
      (tester) async {
    await pump(tester);

    expect(find.text('All collectors'), findsOneWidget);
    expect(find.byKey(const ValueKey('team-entry-Engagement:1')), findsOneWidget);
    expect(find.byKey(const ValueKey('team-entry-Engagement:2')), findsOneWidget);
    expect(find.byKey(const ValueKey('team-entry-Deposit:9')), findsNothing,
        reason: 'yesterday is not today');
    expect(find.textContaining('Juan Reyes'), findsWidgets);
    expect(find.textContaining('Maria Santos'), findsWidgets);
    expect(find.textContaining('updated 10:00 AM'), findsOneWidget);
    expect(find.textContaining('2 collectors'), findsOneWidget,
        reason: 'Pedro and Maria are the Collection Firestore users');
    // With everyone on screen the day is grouped by who did it.
    expect(find.byKey(const ValueKey('team-group-EMP1')), findsOneWidget);
    expect(find.byKey(const ValueKey('team-group-EMP2')), findsOneWidget);
    expect(find.byKey(const ValueKey('team-day-collected')), findsOneWidget);
    expect(find.textContaining('1,000.00'), findsOneWidget,
        reason: '900 + 100 collected today');
  });

  testWidgets('picking a collector reloads for them and narrows the day',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('team-collector-picker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('team-collector-all')), findsOneWidget);
    expect(find.byKey(const ValueKey('team-collector-psilang')), findsOneWidget,
        reason: 'the whole department is listed, uploads or not');
    expect(find.byKey(const ValueKey('team-collector-EMP1')), findsNothing,
        reason: 'uploaded, but no Collection Firestore user');
    expect(find.byKey(const ValueKey('team-collector-log')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('team-collector-EMP2')));
    await tester.pumpAndSettle();

    expect(asked, [null, 'EMP2']);
    expect(find.text('Maria Santos'), findsWidgets);
    expect(find.byKey(const ValueKey('team-group-EMP2')), findsNothing,
        reason: 'one collector: no grouping headers');
    expect(find.byKey(const ValueKey('team-entry-Engagement:2')), findsOneWidget);
    expect(find.byKey(const ValueKey('team-entry-Engagement:1')), findsNothing);
  });

  testWidgets('the sheet search narrows the names', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('team-collector-picker')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('team-collector-search')), 'mar');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('team-collector-EMP2')), findsOneWidget);
    expect(find.byKey(const ValueKey('team-collector-EMP1')), findsNothing);
    expect(find.byKey(const ValueKey('team-collector-all')), findsNothing);
  });

  testWidgets('another day lists that day, or says nothing was uploaded',
      (tester) async {
    final controller = await pump(tester);

    await controller.selectDay(DateTime(2026, 9, 24));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('team-entry-Deposit:9')), findsOneWidget);
    expect(find.textContaining('Bank deposit · BPI'), findsOneWidget);

    await controller.selectDay(DateTime(2026, 9, 23));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('team-day-empty')), findsOneWidget);
    expect(find.text('Nothing uploaded for this day.'), findsOneWidget);
  });

  testWidgets('a failed first load shows the message and a retry',
      (tester) async {
    asked = [];
    fail = true;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final controller = TeamActivityController(
      now: () => DateTime(2026, 9, 25, 10),
      members: () async => Result.success(const []),
      load: ({required from, required to, collector}) async {
        asked.add(collector);
        if (fail) return Result.failure('Could not reach the server.');
        return Result.success(_feed([_juan]));
      },
    );
    Get.put(controller);
    await tester.pumpWidget(MaterialApp(
        theme: BAppTheme.lightTheme, home: const TeamActivityScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('team-error')), findsOneWidget);
    expect(find.text('Could not reach the server.'), findsOneWidget);

    fail = false;
    await tester.tap(find.byKey(const ValueKey('team-retry')));
    await tester.pumpAndSettle();

    expect(asked.length, 2);
    expect(find.byKey(const ValueKey('team-error')), findsNothing);
    expect(find.byKey(const ValueKey('team-entry-Engagement:1')), findsOneWidget);
  });
}
