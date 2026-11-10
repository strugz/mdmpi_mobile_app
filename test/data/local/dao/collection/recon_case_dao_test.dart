import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_attachment_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_case_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The Reconciliation Tracker's tables on the phone. The rule that matters
/// most: a download never loses a step this device logged and has not
/// uploaded yet.

final _now = DateTime.parse('2026-09-28T10:00:00+08:00');

ReconCaseBundle _case(String id,
        {List<ReconActivity> activities = const [],
        String source = ReconSource.local,
        String client = 'NLN-115'}) =>
    ReconCaseBundle(
      reconCase: ReconCase(
        caseId: id,
        clientCode: client,
        clientName: 'Accusure Medical Enterprises',
        collectorCode: 'JCA',
        collectorName: 'Jay',
        dateOpened: '2026-09-20T09:00:00',
      ),
      invoices: const [
        ReconCaseInvoice(invoiceNo: '700013391', amount: 24281.25),
        ReconCaseInvoice(invoiceNo: '700013392', amount: 121208.04),
      ],
      activities: activities,
      source: source,
    );

ReconActivity _step(String id, String caseId, ReconActivityType type, String at,
        {List<String> invoices = const [], List<String> photos = const []}) =>
    ReconActivity(
      activityId: id,
      caseId: caseId,
      dateTime: at,
      type: type,
      invoiceNos: invoices,
      remarks: 'r $id',
      attachmentRefs: photos,
      recordedBy: 'JCA',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ReconCaseDao dao;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async => ensureCollectionTables(db),
    );
    dao = ReconCaseDao(db);
  });

  tearDown(() async => db.close());

  Future<String?> sourceOf(String activityId) async =>
      (await db.query(ReconCaseDao.activityTable,
              where: 'activityId = ?', whereArgs: [activityId]))
          .singleOrNull?['source'] as String?;

  test('the four tables exist, and creating them twice is harmless', () async {
    await ensureCollectionTables(db);
    final names = (await listUserTables(db)).toSet();
    expect(
        names,
        containsAll([
          ReconCaseDao.caseTable,
          ReconCaseDao.invoiceTable,
          ReconCaseDao.activityTable,
          ReconAttachmentDao.table,
        ]));
  });

  test('a case round-trips with its invoices, log and cached status', () async {
    final b = _case('RC-1', activities: [
      _step('RA-1', 'RC-1', ReconActivityType.soaSent, '2026-09-20T09:15:00'),
    ]);
    await dao.saveLocalCase(b, b.evaluate(now: _now));

    final back = (await dao.getCase('RC-1'))!;
    expect(back.reconCase.clientName, 'Accusure Medical Enterprises');
    expect(back.invoices.map((i) => i.invoiceNo), ['700013391', '700013392']);
    expect(back.invoices.first.amount, 24281.25);
    expect(back.activities.single.type, ReconActivityType.soaSent);
    expect(back.activities.single.remarks, 'r RA-1');
    expect(back.source, ReconSource.local);

    final row = (await db.query(ReconCaseDao.caseTable)).single;
    expect(row['caseStatus'], 'WAITING_FOR_ACCOUNT');
    expect(row['nextActor'], 'ACCOUNT');
    expect(row['soaAmount'], closeTo(145489.29, 0.001));
    expect(await dao.getCase('RC-NOPE'), isNull);
  });

  test('a logged step updates the cache in the same write', () async {
    final b = _case('RC-1');
    await dao.saveLocalCase(b, b.evaluate(now: _now));
    final step = _step(
        'RA-1', 'RC-1', ReconActivityType.paidClaim, '2026-09-21T10:00:00',
        invoices: ['700013392'], photos: ['RP-1', 'RP-2']);
    await dao.addLocalActivity(step, b.withActivity(step).evaluate(now: _now));

    final back = (await dao.getCase('RC-1'))!;
    expect(back.activities.single.invoiceNos, ['700013392']);
    expect(back.activities.single.attachmentRefs, ['RP-1', 'RP-2']);
    final row = (await db.query(ReconCaseDao.caseTable)).single;
    expect(row['caseStatus'], 'WAITING_FOR_COLLECTOR');
    expect(row['lastActivityAt'], '2026-09-21T10:00:00');
  });

  group('a download', () {
    test('keeps a step logged here and not uploaded yet', () async {
      final b = _case('RC-1', activities: [
        _step('RA-1', 'RC-1', ReconActivityType.soaSent, '2026-09-20T09:15:00'),
      ]);
      await dao.saveLocalCase(b, b.evaluate(now: _now));
      final pending = _step('RA-2', 'RC-1', ReconActivityType.documentProvided,
          '2026-09-22T09:00:00');
      await dao.addLocalActivity(
          pending, b.withActivity(pending).evaluate(now: _now));

      // The server has the case and its first step only.
      await dao.replaceServerCopies([
        _case('RC-1', source: ReconSource.server, activities: [
          _step(
              'RA-1', 'RC-1', ReconActivityType.soaSent, '2026-09-20T09:15:00'),
        ]),
      ], (x) => x.evaluate(now: _now));

      final back = (await dao.getCase('RC-1'))!;
      expect(back.source, ReconSource.server);
      expect(back.activities.map((a) => a.activityId), ['RA-1', 'RA-2']);
      expect(await sourceOf('RA-1'), ReconSource.server);
      expect(await sourceOf('RA-2'), ReconSource.local,
          reason: 'still in the outbox; the next download will return it');
      expect((await db.query(ReconCaseDao.caseTable)).single['lastActivityAt'],
          '2026-09-22T09:00:00',
          reason: 'the cache counts the pending step too');
    });

    test('a step the server returns becomes the server copy', () async {
      final b = _case('RC-1');
      await dao.saveLocalCase(b, b.evaluate(now: _now));
      final s = _step(
          'RA-1', 'RC-1', ReconActivityType.soaSent, '2026-09-20T09:15:00');
      await dao.addLocalActivity(s, b.withActivity(s).evaluate(now: _now));

      await dao.replaceServerCopies([
        _case('RC-1', source: ReconSource.server, activities: [s]),
      ], (x) => x.evaluate(now: _now));

      expect(await sourceOf('RA-1'), ReconSource.server);
      expect((await dao.getCase('RC-1'))!.activities, hasLength(1));
    });

    test('drops a server copy the server no longer sends, keeps an unsent case',
        () async {
      await dao.replaceServerCopies([
        _case('RC-OLD',
            source: ReconSource.server,
            client: 'NCR-1',
            activities: [
              _step('RA-9', 'RC-OLD', ReconActivityType.soaSent,
                  '2026-08-01T09:00:00'),
            ]),
      ], (x) => x.evaluate(now: _now));
      final mine = _case('RC-NEW');
      await dao.saveLocalCase(mine, mine.evaluate(now: _now));

      await dao.replaceServerCopies(const [], (x) => x.evaluate(now: _now));

      final ids = (await dao.getAll()).map((b) => b.caseId);
      expect(ids, ['RC-NEW']);
      expect(
          await db.query(ReconCaseDao.invoiceTable,
              where: 'caseId = ?', whereArgs: ['RC-OLD']),
          isEmpty);
      expect(await sourceOf('RA-9'), isNull);
    });

    test('replaces the server\'s invoices and balances', () async {
      await dao.replaceServerCopies([_case('RC-1', source: ReconSource.server)],
          (x) => x.evaluate(now: _now));
      await dao.replaceServerCopies([
        ReconCaseBundle(
          reconCase: _case('RC-1').reconCase,
          invoices: const [
            ReconCaseInvoice(
                invoiceNo: '700013391',
                amount: 24281.25,
                currentBalance: 0,
                clearedAt: '2026-09-25T14:00:00'),
          ],
          activities: const [],
          source: ReconSource.server,
        ),
      ], (x) => x.evaluate(now: _now));

      final back = (await dao.getCase('RC-1'))!;
      expect(back.invoices.single.currentBalance, 0);
      expect(back.invoices.single.clearedAt, '2026-09-25T14:00:00');
      expect((await db.query(ReconCaseDao.caseTable)).single['caseStatus'],
          'COMPLETED');
    });
  });

  group('photos', () {
    late ReconAttachmentDao photos;
    setUp(() => photos = ReconAttachmentDao(db));

    ReconAttachmentRecord photo(String id, {String createdAt = '1'}) =>
        ReconAttachmentRecord(
            attachmentId: id,
            caseId: 'RC-1',
            activityId: 'RA-1',
            filePath: '/tmp/$id.jpg',
            createdAt: createdAt);

    test('unsent photos, then uploaded ones leave the list', () async {
      await photos.insert(photo('RP-1', createdAt: '1'));
      await photos.insert(photo('RP-2', createdAt: '2'));
      expect((await photos.getUnsent()).map((p) => p.attachmentId),
          ['RP-1', 'RP-2']);

      await photos.markUploaded('RP-1');
      expect((await photos.getUnsent()).map((p) => p.attachmentId), ['RP-2']);
      expect(await photos.countUnsent(), 1);
      expect((await photos.forActivity('RA-1')).map((p) => p.status),
          [ReconAttachmentStatus.uploaded, ReconAttachmentStatus.pending]);
    });

    test('a failure is counted, and a photo is given up after the limit',
        () async {
      await photos.insert(photo('RP-1'));
      await photos.markFailed('RP-1', 'HTTP 500');
      final failed = (await photos.getUnsent()).single;
      expect(failed.status, ReconAttachmentStatus.failed);
      expect(failed.retryCount, 1);
      expect(failed.lastError, 'HTTP 500');

      expect(await photos.getUnsent(maxRetries: 1), isEmpty);
    });
  });
}
