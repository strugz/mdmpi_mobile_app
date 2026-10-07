import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_attachment_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_case_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/reconciliation_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The Tracker's repository: every write checked by the rules, stored on the
/// phone, and queued for "Upload All" in the shape MDMPI.App accepts
/// (RECON_OPEN_CASE / RECON_ACTIVITY, one unique ItemId each).

typedef _Change = ({String op, String itemId, Map<String, dynamic> fields});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late Directory photoDir;
  late List<_Change> queued;
  late DateTime clock;
  late ReconciliationRepository repo;
  late Map<String, double> live;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath,
        version: 1, onCreate: (db, _) async => ensureCollectionTables(db));
    photoDir = await Directory.systemTemp.createTemp('recon_photos_');
    queued = [];
    live = {};
    // 10:00 in Manila; every read of the clock moves it on a second, so each
    // id and time is distinct, as on a real phone.
    clock = DateTime.parse('2026-09-28T10:00:00+08:00');
    repo = ReconciliationRepository(
      caseDao: () async => ReconCaseDao(db),
      attachmentDao: () async => ReconAttachmentDao(db),
      queue: (op, itemId, fields) async =>
          queued.add((op: op, itemId: itemId, fields: fields)),
      collectorCode: () => 'JCA',
      collectorName: () => 'Jay',
      now: () => clock = clock.add(const Duration(seconds: 1)),
      attachmentDirectory: () async => photoDir,
      liveBalances: () => live,
    );
  });

  tearDown(() async {
    await db.close();
    if (await photoDir.exists()) await photoDir.delete(recursive: true);
  });

  const invoices = [
    ReconCaseInvoice(invoiceNo: '700013391', amount: 24281.25),
    ReconCaseInvoice(invoiceNo: '700013392', amount: 121208.04),
  ];

  Future<String> open() async => (await repo.openCase(
          clientCode: 'NLN-115',
          clientName: 'Accusure Medical Enterprises',
          invoices: invoices))
      .value
      .caseId;

  test('opening a case stores it and queues RECON_OPEN_CASE', () async {
    final r = await repo.openCase(
        clientCode: ' NLN-115 ',
        clientName: 'Accusure Medical Enterprises',
        invoices: invoices);
    expect(r.isSuccess, isTrue);
    final caseId = r.value.caseId;
    expect(caseId, startsWith('RC-JCA-'));
    expect(r.value.reconCase.dateOpened, '2026-09-28T10:00:01',
        reason: 'Manila wall-clock time, no offset');

    final change = queued.single;
    expect(change.op, 'RECON_OPEN_CASE');
    expect(change.itemId, caseId);
    expect(change.fields, {
      'CaseId': caseId,
      'ClientCode': 'NLN-115',
      'DocumentIds': ['700013391', '700013392'],
      'EngagementDate': '2026-09-28T10:00:01',
    });

    final stored = (await repo.loadCase(caseId)).value;
    expect(stored.invoices.map((i) => i.amount), [24281.25, 121208.04]);
    expect(repo.version.value, 1);
  });

  test('an account has one open case, an invoice is in one case', () async {
    await open();
    final again = await repo.openCase(
        clientCode: 'NLN-115', clientName: 'Accusure', invoices: invoices);
    expect(again.isFailure, isTrue);
    expect(again.error, contains('already has an open case'));

    final other = await repo.openCase(
        clientCode: 'NCR-1',
        clientName: 'Other',
        invoices: const [ReconCaseInvoice(invoiceNo: '700013392', amount: 1)]);
    expect(other.error, contains('Already in open case'));

    expect(
        (await repo
                .openCase(clientCode: 'NCR-1', clientName: 'x', invoices: []))
            .error,
        'Pick at least one invoice.');
    expect(queued, hasLength(1), reason: 'nothing refused was queued');
  });

  test('a step is stored, recalculates the case and queues RECON_ACTIVITY',
      () async {
    final caseId = await open();
    final r = await repo.appendActivity(
      caseId: caseId,
      type: ReconActivityType.soaSent,
      amount: 145000,
      remarks: ' Emailed the SOA ',
      nextAction: 'Follow up',
      nextActionDueDate: '2026-10-05',
    );
    expect(r.isSuccess, isTrue);

    final change = queued.last;
    expect(change.op, 'RECON_ACTIVITY');
    expect(change.itemId, r.value.activityId);
    expect(change.itemId, startsWith('RA-JCA-'));
    expect(change.fields, {
      'CaseId': caseId,
      'ActivityType': 'SOA_SENT',
      'DocumentIds': <String>[],
      'Remarks': 'Emailed the SOA',
      'EngagementDate': r.value.dateTime,
      'ReconAmount': 145000.0,
      'ValidationResult': null,
      'NextAction': 'Follow up',
      'NextActionDueDate': '2026-10-05',
      'AttachmentIds': <String>[],
    });

    final row = (await db.query(ReconCaseDao.caseTable)).single;
    expect(row['caseStatus'], 'WAITING_FOR_ACCOUNT');
    expect(row['soaAmount'], 145000);
  });

  test('every queued change has its own ItemId', () async {
    final caseId = await open();
    for (final type in [
      ReconActivityType.soaSent,
      ReconActivityType.documentRequested,
      ReconActivityType.documentProvided,
    ]) {
      await repo.appendActivity(caseId: caseId, type: type);
    }
    final ids = queued.map((c) => c.itemId).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('a step the rules would not apply is refused, not stored or queued',
      () async {
    final caseId = await open();
    final validate = await repo.appendActivity(
        caseId: caseId,
        type: ReconActivityType.proofValidated,
        validationResult: ReconValidationResult.valid);
    expect(validate.error, contains('no proof waiting'));

    final unknown = await repo.appendActivity(
        caseId: caseId,
        type: ReconActivityType.paidClaim,
        invoiceNos: ['NOT-OURS']);
    expect(unknown.error, 'Not in this case: NOT-OURS.');

    await repo.appendActivity(
        caseId: caseId, type: ReconActivityType.caseEscalated);
    final after = await repo.appendActivity(
        caseId: caseId, type: ReconActivityType.note, remarks: 'late');
    expect(after.error, contains('Start a new case'));

    expect((await repo.loadCase(caseId)).value.activities, hasLength(1));
    expect(queued.map((c) => c.op), ['RECON_OPEN_CASE', 'RECON_ACTIVITY']);
    expect(
        (await repo.appendActivity(
                caseId: 'RC-NOPE', type: ReconActivityType.note))
            .error,
        'Case RC-NOPE is not on this phone.');
  });

  test('an ended case frees the account for a new one', () async {
    final caseId = await open();
    await repo.appendActivity(
        caseId: caseId, type: ReconActivityType.caseNotCompleted);
    expect((await repo.openCaseFor('NLN-115')).value, isNull);
    final next = await repo.openCase(
        clientCode: 'NLN-115', clientName: 'Accusure', invoices: invoices);
    expect(next.isSuccess, isTrue);
  });

  test('a payment recorded on the phone shows on its case at once', () async {
    // 2026-09-28: 250k collected on 700004812 left the case at the amount it
    // opened with until the next download.
    final caseId = await open();
    live = {'700013391': 4281.25};
    final e = (await repo.loadCase(caseId)).value.evaluate(now: clock);
    expect(e.invoices.first.amount, 4281.25);
    expect(e.amountUnderReconciliation, 4281.25 + 121208.04);
    expect((await repo.loadCases()).value.single.invoices.first.currentBalance,
        4281.25);

    // Paid in full here: cleared, and the case is completed.
    live = {'700013391': 0, '700013392': 0};
    final paid = (await repo.loadCase(caseId)).value.evaluate(now: clock);
    expect(paid.invoices.map((i) => i.status),
        everyElement(ReconInvoiceStatus.cleared));
    expect(paid.status, ReconCaseStatus.completed);
  });

  test('a claim on an invoice paid in full here is refused', () async {
    final caseId = await open();
    live = {'700013391': 0};
    final r = await repo.appendActivity(
        caseId: caseId,
        type: ReconActivityType.paidClaim,
        invoiceNos: ['700013391']);
    expect(r.error, 'Already settled: 700013391.');
  });

  group('logged by the app', () {
    test('a collection on a case invoice goes on the timeline', () async {
      final caseId = await open();
      final r = await repo.recordPayment(
          invoiceId: '700013391',
          amount: 20000,
          outcome: 'Partially Collected',
          bankName: 'BDO',
          checkNumber: '4588255');
      final step = r.value!;
      expect(step.type, ReconActivityType.paymentRecorded);
      expect(step.doneBy, ReconActor.tracker);
      expect(step.amount, 20000);
      expect(step.invoiceNos, ['700013391']);
      expect(step.remarks, 'Partially Collected · BDO · check 4588255');
      expect(queued.last.fields['ActivityType'], 'PAYMENT_RECORDED');
      expect(queued.last.fields['ReconAmount'], 20000.0);
      expect(queued.last.fields['CaseId'], caseId);
    });

    test('no case, or no amount: nothing is logged', () async {
      await open();
      expect((await repo.recordPayment(invoiceId: 'OTHER', amount: 5)).value,
          isNull);
      expect(
          (await repo.recordPayment(invoiceId: '700013391', amount: 0)).value,
          isNull);
      expect(queued, hasLength(1), reason: 'only the open');
    });

    test('a payment does not change whose turn it is', () async {
      final caseId = await open();
      await repo.appendActivity(
          caseId: caseId, type: ReconActivityType.soaSent);
      await repo.recordPayment(invoiceId: '700013391', amount: 100);
      final e = (await repo.loadCase(caseId)).value.evaluate(now: clock);
      expect(e.status, ReconCaseStatus.waitingForAccount);
      expect(e.lastActivity!.type, ReconActivityType.paymentRecorded);
    });

    test('releasing the account releases the case; acquiring takes it',
        () async {
      final caseId = await open();
      expect(
          (await repo.releaseCasesFor('NLN-115', remarks: 'Done Engagement'))
              .value,
          1);
      var c = (await repo.loadCase(caseId)).value;
      expect(c.reconCase.collectorCode, '',
          reason: 'no holder: it waits to be acquired');
      expect(c.activities.last.type, ReconActivityType.caseReleased);
      expect(c.activities.last.remarks, 'Done Engagement');
      expect((await repo.openCaseFor('NLN-115')).value, isNotNull,
          reason: 'released is not ended: the case stays open');

      expect((await repo.releaseCasesFor('NLN-115')).value, 0,
          reason: 'nothing left to release');

      expect((await repo.acquireCasesFor('NLN-115')).value, 1);
      c = (await repo.loadCase(caseId)).value;
      expect(c.reconCase.collectorCode, 'JCA');
      expect(c.activities.last.type, ReconActivityType.caseAcquired);
      expect((await repo.acquireCasesFor('NLN-115')).value, 0,
          reason: 'already mine');
      expect(queued.map((q) => q.fields['ActivityType']).whereType<String>(),
          ['CASE_RELEASED', 'CASE_ACQUIRED']);
    });

    test('only the holder releases a case', () async {
      await open();
      final other = ReconciliationRepository(
        caseDao: () async => ReconCaseDao(db),
        attachmentDao: () async => ReconAttachmentDao(db),
        queue: (op, itemId, fields) async =>
            queued.add((op: op, itemId: itemId, fields: fields)),
        collectorCode: () => 'MAR',
        collectorName: () => 'Mar',
        now: () => clock = clock.add(const Duration(seconds: 1)),
        attachmentDirectory: () async => photoDir,
      );
      expect((await other.releaseCasesFor('NLN-115')).value, 0);
    });

    test('an ended case gets nothing logged on it', () async {
      final caseId = await open();
      await repo.appendActivity(
          caseId: caseId, type: ReconActivityType.caseEscalated);
      expect(
          (await repo.recordPayment(invoiceId: '700013391', amount: 5)).value,
          isNull);
      expect((await repo.releaseCasesFor('NLN-115')).value, 0);
    });
  });

  test('photos are saved as files and queued for the photo outbox', () async {
    final caseId = await open();
    await repo.appendActivity(
        caseId: caseId,
        type: ReconActivityType.paidClaim,
        invoiceNos: ['700013392']);
    final r = await repo.appendActivity(
      caseId: caseId,
      type: ReconActivityType.proofProvided,
      invoiceNos: ['700013392'],
      photos: [
        Uint8List.fromList([1, 2, 3]),
        Uint8List.fromList([4, 5]),
      ],
    );
    expect(r.value.attachmentRefs, hasLength(2));
    expect(queued.last.fields['AttachmentIds'], r.value.attachmentRefs);

    final rows = await ReconAttachmentDao(db).forActivity(r.value.activityId);
    expect(rows.map((a) => a.attachmentId), r.value.attachmentRefs);
    expect(
        rows.map((a) => a.status), everyElement(ReconAttachmentStatus.pending));
    expect(rows.map((a) => a.caseId), everyElement(caseId));
    expect(await File(rows.first.filePath).readAsBytes(), [1, 2, 3]);
    expect(await File(rows.last.filePath).readAsBytes(), [4, 5]);

    final row = (await db.query(ReconCaseDao.caseTable)).single;
    expect(row['caseStatus'], 'UNDER_VALIDATION');
  });
}
