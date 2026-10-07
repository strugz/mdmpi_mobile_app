import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_posting.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/reconciliation/recon_reports_screen.dart';

/// Stage 5: the Summary and Aging reports, and "Validated, awaiting
/// posting" (Step 9: validated paid, until Accounting posts it and the
/// balance reaches zero).

final _now = DateTime.parse('2026-09-28T10:00:00+08:00');

ReconActivity _step(String id, ReconActivityType type, String at,
        {List<String> invoices = const [],
        ReconValidationResult? result,
        String remarks = '',
        List<String> photos = const []}) =>
    ReconActivity(
        activityId: id,
        caseId: 'x',
        dateTime: at,
        type: type,
        invoiceNos: invoices,
        validationResult: result,
        remarks: remarks,
        attachmentRefs: photos);

ReconCaseView _view(
  String caseId,
  String client,
  String opened,
  List<ReconActivity> steps, {
  List<ReconCaseInvoice>? invoices,
  String collector = 'JCA',
}) {
  final b = ReconCaseBundle(
    reconCase: ReconCase(
        caseId: caseId,
        clientCode: 'C-$caseId',
        clientName: client,
        collectorCode: collector,
        dateOpened: opened),
    invoices: invoices ??
        const [
          ReconCaseInvoice(invoiceNo: 'A1', amount: 1000),
          ReconCaseInvoice(invoiceNo: 'A2', amount: 500),
        ],
    activities: steps,
  );
  return ReconCaseView(b, b.evaluate(now: _now));
}

/// A1 validated paid (with proof and a photo); A2 still open.
final _validated =
    _view('RC-1', 'Ace Diagnostics Corp.', '2026-09-25T09:00:00', [
  _step('RA-1', ReconActivityType.paidClaim, '2026-09-25T10:00:00',
      invoices: ['A1']),
  _step('RA-2', ReconActivityType.proofProvided, '2026-09-26T10:00:00',
      remarks: 'BDO deposit slip 88213', photos: ['RP-1']),
  _step('RA-3', ReconActivityType.proofValidated, '2026-09-27T11:00:00',
      result: ReconValidationResult.valid),
]);

/// Validated, and Accounting has since posted it: the balance is zero.
final _posted = _view('RC-2', 'Metro Globe', '2026-09-10T09:00:00', [
  _step('RA-4', ReconActivityType.paidClaim, '2026-09-10T10:00:00',
      invoices: ['B1']),
  _step('RA-5', ReconActivityType.proofProvided, '2026-09-11T10:00:00'),
  _step('RA-6', ReconActivityType.proofValidated, '2026-09-12T10:00:00',
      result: ReconValidationResult.valid),
], invoices: const [
  ReconCaseInvoice(invoiceNo: 'B1', amount: 700, currentBalance: 0),
]);

final _old = _view('RC-3', 'Amka Trading', '2026-08-20T09:00:00', [
  _step('RA-7', ReconActivityType.soaSent, '2026-08-20T10:00:00'),
]);
final _escalated = _view('RC-4', 'Abbott Laboratories', '2026-09-01T09:00:00', [
  _step('RA-8', ReconActivityType.caseEscalated, '2026-09-20T10:00:00'),
]);
final _teammate = _view(
    'RC-5', 'Alexis Yu Best Care Pharmacy', '2026-09-27T09:00:00', const [],
    collector: 'MAR');

class _Tracker extends ReconciliationController {
  _Tracker({required bool head})
      : super(
            collectorCode: () => 'JCA',
            heldInvoiceIds: () => {},
            isHead: () => head);

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> load() async {}
}

void main() {
  tearDown(Get.reset);

  group('awaiting posting', () {
    test('validated paid, with when and the proof; posted ones leave', () {
      final list = reconAwaitingPosting([
        for (final v in [_validated, _posted, _old])
          (bundle: v.bundle, evaluation: v.evaluation),
      ]);
      final item = list.single;
      expect(item.caseId, 'RC-1');
      expect(item.invoiceNo, 'A1');
      expect(item.amount, 1000);
      expect(item.validatedAt, '2026-09-27T11:00:00');
      expect(item.proof, 'BDO deposit slip 88213');
      expect(item.photos, 1);
    });

    test('an invalid proof is not waiting for posting', () {
      final invalid = _view('RC-6', 'X', '2026-09-25T09:00:00', [
        _step('RA-1', ReconActivityType.paidClaim, '2026-09-25T10:00:00',
            invoices: ['A1']),
        _step('RA-2', ReconActivityType.proofProvided, '2026-09-26T10:00:00'),
        _step('RA-3', ReconActivityType.proofValidated, '2026-09-27T10:00:00',
            result: ReconValidationResult.invalid),
      ]);
      expect(
          reconAwaitingPosting(
              [(bundle: invalid.bundle, evaluation: invalid.evaluation)]),
          isEmpty);
    });
  });

  Future<void> pump(WidgetTester tester,
      {required bool head, double scale = 1}) async {
    final tracker = _Tracker(head: head);
    Get.put<ReconciliationController>(tracker);
    tracker.cases.assignAll([_validated, _posted, _old, _escalated, _teammate]);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(
      theme: BCollectionTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
            size: const Size(360, 800), textScaler: TextScaler.linear(scale)),
        child: const ReconReportsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  String text(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(ValueKey(key))).data!;

  testWidgets('a collector sees the summary and aging of their own cases',
      (tester) async {
    await pump(tester, head: false);
    expect(text(tester, 'recon-reports-scope'), 'Your cases');
    expect(text(tester, 'recon-summary-Total'), '4',
        reason: "the teammate's case is not mine");
    expect(text(tester, 'recon-summary-Open'), '2');
    expect(text(tester, 'recon-summary-Completed'), '1');
    expect(text(tester, 'recon-summary-Escalated'), '1');
    expect(text(tester, 'recon-summary-Not completed'), '0');
    expect(text(tester, 'recon-summary-Under reconciliation'), '₱2,000.00',
        reason: 'RC-1 has 500 open; RC-3 owes 1,000 + 500 (1,500)');
    // RC-1 is 3 days open, RC-3 39 days.
    expect(text(tester, 'recon-aging-upTo7'), '1');
    expect(text(tester, 'recon-aging-over30'), '1');
    expect(text(tester, 'recon-aging-upTo15'), '0');
  });

  testWidgets('the awaiting-posting list shows the validated invoice',
      (tester) async {
    await pump(tester, head: false);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('recon-posting-A1')), 200);
    expect(find.text('Validated, awaiting posting (1)'), findsOneWidget);
    expect(
        find.textContaining('proof: BDO deposit slip 88213'), findsOneWidget);
    expect(find.byKey(const ValueKey('recon-posting-B1')), findsNothing,
        reason: 'already posted');
  });

  testWidgets('the Head sees every case on the phone', (tester) async {
    await pump(tester, head: true);
    expect(text(tester, 'recon-reports-scope'),
        'Every case on this phone (the team)');
    expect(text(tester, 'recon-summary-Total'), '5');
    expect(text(tester, 'recon-summary-Open'), '3');
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('fits a narrow phone at $scale', (tester) async {
      await pump(tester, head: false, scale: scale);
      expect(tester.takeException(), isNull);
    });
  }
}
