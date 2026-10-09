import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/reconciliation/recon_case_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/reconciliation/recon_dashboard_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/reconciliation/widgets/recon_log_activity_sheet.dart';

/// The Reconciliation Tracker's screens: the dashboard, the case screen with
/// its Step 1 banner, and the log sheet that only offers valid steps.

final _now = DateTime.parse('2026-09-28T10:00:00+08:00');

typedef _Logged = ({
  ReconActivityType type,
  List<String> invoices,
  ReconValidationResult? result,
  int photos,
});

class _Tracker extends ReconciliationController {
  _Tracker() : super(collectorCode: () => 'JCA', heldInvoiceIds: () => {});

  final logged = <_Logged>[];
  String? refuse;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> load() async {}

  @override
  Future<Result<ReconActivity>> logActivity({
    required String caseId,
    required ReconActivityType type,
    List<String> invoiceNos = const [],
    String remarks = '',
    double? amount,
    ReconValidationResult? validationResult,
    String nextAction = '',
    String? nextActionDueDate,
    List<Uint8List> photos = const [],
  }) async {
    if (refuse != null) return Result.failure(refuse!);
    logged.add((
      type: type,
      invoices: invoiceNos,
      result: validationResult,
      photos: photos.length,
    ));
    return Result.success(ReconActivity(
        activityId: 'RA-X', caseId: caseId, dateTime: '', type: type));
  }
}

ReconActivity _step(String id, ReconActivityType type, String at,
        {List<String> invoices = const [], String? due, String by = ''}) =>
    ReconActivity(
        activityId: id,
        caseId: 'x',
        dateTime: at,
        type: type,
        invoiceNos: invoices,
        nextAction: due == null ? '' : 'Follow up',
        nextActionDueDate: due,
        recordedBy: by);

ReconCaseView _view(String caseId, String client, List<ReconActivity> steps,
    {String collector = 'JCA'}) {
  final bundle = ReconCaseBundle(
    reconCase: ReconCase(
        caseId: caseId,
        clientCode: 'C-$caseId',
        clientName: client,
        collectorCode: collector,
        collectorName: 'Jay',
        dateOpened: '2026-09-14T09:00:00'),
    invoices: const [
      ReconCaseInvoice(invoiceNo: '700009771', amount: 21048.87),
      ReconCaseInvoice(invoiceNo: '700009347', amount: 6570.80),
    ],
    activities: steps,
  );
  return ReconCaseView(bundle, bundle.evaluate(now: _now));
}

final _stale = _view('RC-1', 'Amka Trading', [
  _step('RA-1', ReconActivityType.soaSent, '2026-09-15T09:30:00',
      due: '2026-09-21'),
]);
final _recent = _view('RC-2', 'Accuteqs Diagnostics Corp.', [
  _step('RA-2', ReconActivityType.soaSent, '2026-09-26T09:00:00'),
  _step('RA-3', ReconActivityType.paidClaim, '2026-09-27T09:00:00',
      invoices: ['700009771']),
]);
final _closed = _view('RC-3', 'Abbott Laboratories', [
  _step('RA-4', ReconActivityType.caseEscalated, '2026-09-20T09:00:00'),
]);
final _someoneElse = _view('RC-4', 'Metro Globe', const [], collector: 'MAR');

Future<_Tracker> _pump(WidgetTester tester, Widget home,
    {List<ReconCaseView>? cases, double scale = 1.0}) async {
  final tracker = _Tracker();
  Get.put<ReconciliationController>(tracker);
  tracker.cases.assignAll(cases ?? [_recent, _closed, _stale, _someoneElse]);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GetMaterialApp(
    theme: BCollectionTheme.light,
    home: MediaQuery(
      data: MediaQueryData(
          size: const Size(360, 800), textScaler: TextScaler.linear(scale)),
      child: home,
    ),
  ));
  await tester.pumpAndSettle();
  return tracker;
}

void main() {
  tearDown(Get.reset);

  group('dashboard', () {
    testWidgets('my cases only, the one untouched longest first, closed last',
        (tester) async {
      await _pump(tester, const ReconDashboardScreen());
      await tester.tap(find.byKey(const ValueKey('recon-filter-all')));
      await tester.pumpAndSettle();
      double top(String id) =>
          tester.getTopLeft(find.byKey(ValueKey('recon-case-$id'))).dy;
      expect(find.byKey(const ValueKey('recon-case-RC-4')), findsNothing,
          reason: "another collector's case, on invoices I don't hold");
      expect(top('RC-1'), lessThan(top('RC-2')));
      await tester.scrollUntilVisible(
          find.byKey(const ValueKey('recon-case-RC-3')), 200);
      expect(top('RC-2'), lessThan(top('RC-3')));
    });

    testWidgets('each case says where it stands and what is wrong',
        (tester) async {
      await _pump(tester, const ReconDashboardScreen());
      expect(find.text('2 open cases · ₱55,239.34 under reconciliation'),
          findsOneWidget);
      expect(find.text('Last: SOA sent · 13 days ago'), findsOneWidget);
      expect(find.text('No response'), findsOneWidget);
      expect(find.text('Next action overdue'), findsOneWidget);
      expect(find.text('Waiting for account'), findsOneWidget);
      expect(find.text('Waiting for collector'), findsOneWidget);
    });

    testWidgets('open cases by default; closed ones are history under Closed',
        (tester) async {
      await _pump(tester, const ReconDashboardScreen());
      expect(find.byKey(const ValueKey('recon-case-RC-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('recon-case-RC-3')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('recon-filter-closed')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recon-case-RC-1')), findsNothing);
      expect(find.byKey(const ValueKey('recon-case-RC-3')), findsOneWidget);
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('recon-case-standing-RC-3')))
              .data,
          'Closed Sep 20, 2026 · 2 invoices · ₱27,619.67');
      expect(find.text('2 open cases · ₱55,239.34 under reconciliation'),
          findsOneWidget,
          reason: 'the summary is always the open cases');
    });

    testWidgets(
        'a paid case I worked on stays after someone else took the account',
        (tester) async {
      // Completed by MAR's collection; JCA sent the SOA before releasing.
      final paidByMar = ReconCaseBundle(
        reconCase: const ReconCase(
            caseId: 'RC-7',
            clientCode: 'NLN-115',
            clientName: 'Accusure Medical Enterprises',
            collectorCode: 'MAR',
            dateOpened: '2026-09-14T09:00:00'),
        invoices: const [
          ReconCaseInvoice(
              invoiceNo: '700013391',
              amount: 24281.25,
              currentBalance: 0,
              clearedAt: '2026-09-25T14:00:00'),
        ],
        activities: [
          _step('RA-71', ReconActivityType.soaSent, '2026-09-15T09:00:00',
              by: 'JCA'),
          _step('RA-72', ReconActivityType.caseAcquired, '2026-09-22T09:00:00',
              by: 'MAR'),
        ],
      );
      // Still open, and MAR holds it now: theirs, not in my list.
      final openAtMar = _view(
          'RC-8',
          'Metro Globe',
          [
            _step('RA-81', ReconActivityType.soaSent, '2026-09-15T09:00:00',
                by: 'JCA'),
          ],
          collector: 'MAR');
      final tracker = await _pump(tester, const ReconDashboardScreen(), cases: [
        ReconCaseView(paidByMar, paidByMar.evaluate(now: _now)),
        openAtMar,
      ]);
      expect(tracker.myCases.map((c) => c.caseId), ['RC-7']);
      expect(
          tracker.myCases.single.evaluation.status, ReconCaseStatus.completed);
      expect(find.text('No open cases. Closed ones are under Closed.'),
          findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('recon-filter-closed')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recon-case-RC-7')), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    test('invoices of an ended case are locked, unless a new case took them',
        () {
      final tracker = _Tracker()..cases.assignAll([_closed]);
      expect(tracker.endedCaseInvoiceIds, {'700009771', '700009347'});
      tracker.cases.add(_recent);
      expect(tracker.endedCaseInvoiceIds, isEmpty,
          reason: 'the open case RC-2 covers the same invoices');
    });

    testWidgets('with no cases it says how to open one', (tester) async {
      await _pump(tester, const ReconDashboardScreen(), cases: const []);
      expect(find.text('No reconciliation cases yet'), findsOneWidget);
    });

    testWidgets("Team shows everyone's open cases, and who holds them",
        (tester) async {
      final tracker = await _pump(tester, const ReconDashboardScreen());
      await tester.tap(find.byKey(const ValueKey('recon-scope-team')));
      await tester.pumpAndSettle();
      expect(tracker.dashboardScope.value, ReconScope.team);
      expect(find.byKey(const ValueKey('recon-case-RC-4')), findsOneWidget,
          reason: "MAR's open case, for whoever visits the account next");
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('recon-case-holder-RC-4')))
              .data,
          'Held by Jay');
      expect(find.byKey(const ValueKey('recon-case-holder-RC-1')), findsNothing,
          reason: 'mine: no need to say so');
      expect(find.text('3 open cases · ₱82,859.01 under reconciliation'),
          findsOneWidget,
          reason: 'the summary follows the scope');
    });
  });

  group('case screen', () {
    testWidgets('Step 1: the last activity comes first', (tester) async {
      await _pump(tester, const ReconCaseScreen(caseId: 'RC-1'));
      final banner = find.byKey(const ValueKey('recon-last-activity'));
      expect(
          find.descendant(
              of: banner, matching: find.text('SOA sent · Collector')),
          findsOneWidget);
      expect(
          find.descendant(
              of: banner, matching: find.textContaining('13 days ago')),
          findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const ValueKey('recon-next'))).data,
          'Waiting for the account · Follow up with the account');
      expect(find.descendant(of: banner, matching: find.text('No response')),
          findsOneWidget);
      expect(find.text('700009771'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Timeline (1)'), 200);
      expect(find.text('Timeline (1)'), findsOneWidget);
    });

    testWidgets('the timeline is newest first', (tester) async {
      await _pump(tester, const ReconCaseScreen(caseId: 'RC-2'));
      await tester.scrollUntilVisible(find.text('SOA sent · Collector'), 200);
      final claim =
          tester.getTopLeft(find.text('Claims already paid · Account').last).dy;
      final soa = tester.getTopLeft(find.text('SOA sent · Collector').last).dy;
      expect(claim, lessThan(soa));
    });

    testWidgets('an ended case cannot be logged on', (tester) async {
      await _pump(tester, const ReconCaseScreen(caseId: 'RC-3'));
      final button = tester
          .widget<ButtonStyleButton>(find.byKey(const ValueKey('recon-log')));
      expect(button.onPressed, isNull);
      expect(find.text('Case escalated'), findsOneWidget);
    });

    testWidgets("someone else's case is read-only until acquired",
        (tester) async {
      await _pump(tester, const ReconCaseScreen(caseId: 'RC-4'));
      final button = tester
          .widget<ButtonStyleButton>(find.byKey(const ValueKey('recon-log')));
      expect(button.onPressed, isNull);
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('recon-log-label')))
              .data,
          'Held by Jay · acquire to log');
      expect(find.text('Metro Globe'), findsOneWidget,
          reason: 'the case itself is still shown');
    });

    testWidgets('a released case says to acquire the account', (tester) async {
      // No holder at all: no code and no name.
      const bundle = ReconCaseBundle(
        reconCase: ReconCase(
            caseId: 'RC-5',
            clientCode: 'C-5',
            clientName: 'Nobody Pharmacy',
            collectorCode: '',
            dateOpened: '2026-09-14T09:00:00'),
        invoices: [ReconCaseInvoice(invoiceNo: '700009771', amount: 100)],
        activities: [],
      );
      final released = ReconCaseView(bundle, bundle.evaluate(now: _now));
      await _pump(tester, const ReconCaseScreen(caseId: 'RC-5'),
          cases: [released]);
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('recon-log-label')))
              .data,
          'Acquire the account to log a step');
    });

    testWidgets('an unknown case says so', (tester) async {
      await _pump(tester, const ReconCaseScreen(caseId: 'RC-NOPE'));
      expect(find.text('This case is not on this phone.'), findsOneWidget);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('long names fit a narrow phone at $scale', (tester) async {
        final long = _view('RC-9',
            'Accusure Medical Enterprises Incorporated Hospital and Clinic', [
          _step('RA-9', ReconActivityType.paidClaim, '2026-09-27T09:00:00',
              invoices: ['700009771', '700009347']),
        ]);
        await _pump(tester, const ReconCaseScreen(caseId: 'RC-9'),
            cases: [long], scale: scale);
        expect(tester.takeException(), isNull);
        await _pump(tester, const ReconDashboardScreen(),
            cases: [long, _stale], scale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('log sheet', () {
    Future<_Tracker> openSheet(WidgetTester tester, ReconCaseView view,
        {ReconPhotoPicker? picker}) async {
      final tracker = await _pump(
          tester,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ReconLogActivitySheet.show(view,
                    pickPhoto: picker, cameraAvailable: true),
                child: const Text('open'),
              ),
            ),
          ),
          cases: [view]);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return tracker;
    }

    Future<void> save(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const ValueKey('recon-save')));
      await tester.tap(find.byKey(const ValueKey('recon-save')));
      await tester.pumpAndSettle();
    }

    testWidgets('offers only the steps that make sense now', (tester) async {
      await openSheet(tester, _stale);
      expect(find.byKey(const ValueKey('recon-type-SOA_SENT')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('recon-type-PAID_CLAIM')), findsOneWidget);
      expect(find.byKey(const ValueKey('recon-type-PROOF_VALIDATED')),
          findsNothing,
          reason: 'no proof has been received');
      expect(find.byKey(const ValueKey('recon-type-PROOF_REQUESTED')),
          findsNothing,
          reason: 'nothing is claimed paid');
      expect(find.text('What the account did'), findsOneWidget);
    });

    testWidgets('a paid claim must name invoices, and then logs them',
        (tester) async {
      final tracker = await openSheet(tester, _stale);
      await tester.tap(find.byKey(const ValueKey('recon-type-PAID_CLAIM')));
      await tester.pumpAndSettle();
      await save(tester);
      expect(find.byKey(const ValueKey('recon-error')), findsOneWidget);
      expect(tracker.logged, isEmpty);

      await tester.tap(find.byKey(const ValueKey('recon-invoice-700009347')));
      await tester.pumpAndSettle();
      await save(tester);
      expect(tracker.logged.single.type, ReconActivityType.paidClaim);
      expect(tracker.logged.single.invoices, ['700009347']);
      expect(find.text('Log a step'), findsNothing, reason: 'the sheet closed');
    });

    testWidgets('a photo is attached to the step', (tester) async {
      final tracker = await openSheet(tester, _recent,
          picker: (_) async => Uint8List.fromList([1, 2, 3]));
      await tester.tap(find.byKey(const ValueKey('recon-type-PROOF_PROVIDED')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('recon-camera')));
      await tester.tap(find.byKey(const ValueKey('recon-camera')));
      await tester.pumpAndSettle();
      await save(tester);
      expect(tracker.logged.single.type, ReconActivityType.proofProvided);
      expect(tracker.logged.single.photos, 1);
    });

    testWidgets('the refusal reason is shown in the sheet', (tester) async {
      final tracker = await openSheet(tester, _stale);
      tracker.refuse = 'Could not log the step: disk full';
      await tester.tap(find.byKey(const ValueKey('recon-type-NOTE')));
      await tester.pumpAndSettle();
      await save(tester);
      expect(find.text('Could not log the step: disk full'), findsOneWidget);
    });

    testWidgets('ending a case asks first', (tester) async {
      final tracker = await openSheet(tester, _stale);
      await tester.ensureVisible(
          find.byKey(const ValueKey('recon-type-CASE_NOT_COMPLETED')));
      await tester
          .tap(find.byKey(const ValueKey('recon-type-CASE_NOT_COMPLETED')));
      await tester.pumpAndSettle();
      await save(tester);
      expect(find.text('End this case?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(tracker.logged, isEmpty);

      await save(tester);
      await tester.tap(find.text('End case').last);
      await tester.pumpAndSettle();
      expect(tracker.logged.single.type, ReconActivityType.caseNotCompleted);
    });
  });

  group('stages', () {
    testWidgets('the case screen shows the stage track', (tester) async {
      await _pump(tester, ReconCaseScreen(caseId: _stale.caseId),
          cases: [_stale]);
      expect(find.byKey(const ValueKey('recon-stage-track')), findsOneWidget);
      expect(find.byKey(const ValueKey('recon-stage-soa')), findsOneWidget);
      expect(find.text('next'), findsOneWidget,
          reason: 'the SOA is done; Follow up is next');
      expect(find.text('after follow up'), findsOneWidget,
          reason: 'the letter waits for a follow up');
    });

    testWidgets('a locked stage shows locked with its reason', (tester) async {
      final fresh = _view('RC-9', 'Fresh Co', const []);
      await _pump(
          tester,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ReconLogActivitySheet.show(fresh),
                child: const Text('open'),
              ),
            ),
          ),
          cases: [fresh]);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recon-type-FOLLOW_UP-locked')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('recon-type-FOLLOW_UP')), findsNothing);
      expect(find.text('Log the SOA before a follow up.'), findsOneWidget);
    });

    testWidgets('the letter cannot be logged without a photo', (tester) async {
      final followed = _view('RC-8', 'Followed Co', [
        _step('RA-81', ReconActivityType.soaSent, '2026-09-15T09:00:00'),
        _step('RA-82', ReconActivityType.followUp, '2026-09-18T09:00:00'),
      ]);
      final tracker = await _pump(
          tester,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ReconLogActivitySheet.show(followed,
                    pickPhoto: (_) async => Uint8List.fromList([1]),
                    cameraAvailable: true,
                    initialType: ReconActivityType.collectionLetterSent),
                child: const Text('open'),
              ),
            ),
          ),
          cases: [followed]);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recon-letter-photo-required')),
          findsOneWidget,
          reason: 'the sheet opened on the letter step');

      Future<void> save() async {
        await tester.ensureVisible(find.byKey(const ValueKey('recon-save')));
        await tester.tap(find.byKey(const ValueKey('recon-save')));
        await tester.pumpAndSettle();
      }

      await save();
      expect(find.text('Attach a photo of the letter.'), findsOneWidget);
      expect(tracker.logged, isEmpty);

      await tester.ensureVisible(find.byKey(const ValueKey('recon-camera')));
      await tester.tap(find.byKey(const ValueKey('recon-camera')));
      await tester.pumpAndSettle();
      await save();
      expect(tracker.logged.single.type, ReconActivityType.collectionLetterSent);
      expect(tracker.logged.single.photos, 1);
    });
  });

  test('the photo picker type is the ImagePicker source', () {
    // Guards the typedef the app wires to ImagePicker.
    Future<Uint8List?> picker(ImageSource s) async => null;
    expect(picker, isA<ReconPhotoPicker>());
  });
}
