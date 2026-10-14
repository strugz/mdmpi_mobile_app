import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_engagement_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_pending_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_attachment_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_case_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/reconciliation_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/pending_discard_plan.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// "Discard all" puts the phone back to the server's copy: what the
/// discarded changes created here goes with them, and nothing already
/// uploaded is touched.

PendingChange _change(String op, String itemId,
        [Map<String, dynamic>? fields]) =>
    PendingChange(
      operation: op,
      itemId: itemId,
      payload: jsonEncode({'Operation': op, 'ItemId': itemId, ...?fields}),
      createdAt: '2026-10-14T09:00:00',
    );

CollectionEngagementRecord _engagement(String engagedAt,
        {String code = 'JCA',
        String source = 'LOCAL',
        String item = 'INV-1'}) =>
    CollectionEngagementRecord(
      localRef: CollectionEngagementRecord.buildLocalRef(
          kind: 'INVOICE', subjectId: item, engagedAt: engagedAt),
      collectorCode: code,
      kind: 'INVOICE',
      itemId: item,
      engagedAt: engagedAt,
      engagedOn: BFormatter.localDayKey(engagedAt)!,
      createdAt: engagedAt,
      source: source,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('plan', () {
    test('reads the stamps, cases and steps from the queue', () {
      final plan = PendingDiscardPlan.from([
        _change('SAVE_ACTIVITY', 'INV-1',
            {'EngagementDate': '2026-10-14T08:00:00.000'}),
        _change('CLAIM', 'INV-2', {'EngagementDate': '2026-10-14T08:05:00'}),
        _change('RECONCILIATION', 'ACT-1',
            {'EngagementDate': '2026-10-14T08:10:00'}),
        _change('RECON_OPEN_CASE', 'RC-JCA-1',
            {'EngagementDate': '2026-10-14T08:10:01'}),
        _change('RECON_ACTIVITY', 'RA-JCA-1', {'CaseId': 'RC-JCA-9'}),
        _change('SAVE_ACTIVITY', 'INV-3'), // no stamp: nothing to match
        PendingChange(
            operation: 'SAVE_ACTIVITY',
            payload: 'not json',
            createdAt: '2026-10-14T09:00:00'),
      ]);
      expect(plan.engagedAts, {
        '2026-10-14T08:00:00.000',
        '2026-10-14T08:05:00',
        '2026-10-14T08:10:00',
      });
      expect(plan.caseIds, {'RC-JCA-1'});
      expect(plan.activityIds, {'RA-JCA-1'});
      expect(plan.isEmpty, isFalse);
    });

    test('an empty queue has nothing to remove', () {
      expect(PendingDiscardPlan.from(const []).isEmpty, isTrue);
    });
  });

  group('engagements', () {
    late Database db;
    late CollectionEngagementDao dao;

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath,
          version: 1, onCreate: (db, _) async => ensureCollectionTables(db));
      dao = CollectionEngagementDao(db);
    });
    tearDown(() => db.close());

    test('only my own rows at the discarded stamps go', () async {
      await dao.upsertAll([
        _engagement('2026-10-14T08:00:00'), // discarded
        _engagement('2026-10-13T15:00:00', item: 'INV-9'), // uploaded
        _engagement('2026-10-14T08:00:00',
            code: 'MAR', item: 'INV-7'), // a teammate's
        _engagement('2026-10-14T08:00:00', // the server's copy
            source: 'SERVER',
            item: 'INV-8'),
      ]);
      final removed = await dao.deleteDiscarded(
          collectorCode: 'JCA', engagedAts: {'2026-10-14T08:00:00'});
      expect(removed, 1);
      final left = await db.query(CollectionEngagementDao.table,
          columns: ['collectorCode', 'itemId', 'source']);
      expect(left, hasLength(3));
      expect(
          left.any(
              (r) => r['itemId'] == 'INV-1' && r['collectorCode'] == 'JCA'),
          isFalse);
    });

    test('many stamps at once', () async {
      final stamps = [
        for (var i = 0; i < 950; i++)
          DateTime(2026, 10, 14, 8).add(Duration(seconds: i)).toIso8601String()
      ];
      await dao.upsertAll([for (final s in stamps) _engagement(s)]);
      expect(
          await dao.deleteDiscarded(collectorCode: 'JCA', engagedAts: stamps),
          950);
    });
  });

  group('reconciliation', () {
    late Database db;
    late Directory photos;
    late ReconciliationRepository repo;
    var clock = DateTime.parse('2026-10-14T09:00:00+08:00');

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath,
          version: 1, onCreate: (db, _) async => ensureCollectionTables(db));
      photos = await Directory.systemTemp.createTemp('discard_photos_');
      repo = ReconciliationRepository(
        caseDao: () async => ReconCaseDao(db),
        attachmentDao: () async => ReconAttachmentDao(db),
        queue: (_, __, ___) async {},
        collectorCode: () => 'JCA',
        collectorName: () => 'Jay',
        now: () => clock = clock.add(const Duration(seconds: 1)),
        attachmentDirectory: () async => photos,
      );
    });
    tearDown(() async {
      await db.close();
      if (await photos.exists()) await photos.delete(recursive: true);
    });

    Future<String> open(String client, String invoice) async =>
        (await repo.openCase(
                clientCode: client,
                clientName: client,
                invoices: [ReconCaseInvoice(invoiceNo: invoice, amount: 100)]))
            .value
            .caseId;

    test('a discarded case goes with its steps, photos and files', () async {
      final caseId = await open('NLN-115', '700013392');
      final step = (await repo.appendActivity(
              caseId: caseId,
              type: ReconActivityType.soaSent,
              photos: [
            Uint8List.fromList([1, 2, 3])
          ]))
          .value;
      final file = File('${photos.path}/${step.attachmentRefs.single}.jpg');
      expect(await file.exists(), isTrue);

      final r = await repo.discardLocal(caseIds: {caseId});
      expect(r.isSuccess, isTrue);
      expect((await repo.loadCase(caseId)).isFailure, isTrue);
      expect(await file.exists(), isFalse);
      expect(await ReconAttachmentDao(db).countUnsent(), 0);
      expect(
          await db.query(ReconCaseDao.invoiceTable,
              where: 'caseId = ?', whereArgs: [caseId]),
          isEmpty);
    });

    test('a discarded step goes; the case and its other steps stay', () async {
      final caseId = await open('NLN-115', '700013392');
      final kept = (await repo.appendActivity(
              caseId: caseId, type: ReconActivityType.soaSent))
          .value;
      final dropped = (await repo.appendActivity(
              caseId: caseId, type: ReconActivityType.followUp))
          .value;
      await repo.discardLocal(activityIds: {dropped.activityId});
      final left = (await repo.loadCase(caseId)).value.activities;
      expect(left.map((a) => a.activityId), [kept.activityId]);
    });

    test("the server's copy of a case is never removed", () async {
      await ReconCaseDao(db).replaceServerCopies([
        ReconCaseBundle(
          reconCase: const ReconCase(
              caseId: 'RC-SRV-1',
              clientCode: 'NCR-1',
              clientName: 'Server Co',
              collectorCode: 'JCA',
              dateOpened: '2026-10-01T09:00:00'),
          invoices: const [ReconCaseInvoice(invoiceNo: 'INV-S', amount: 1)],
          activities: const [],
          source: ReconSource.server,
        ),
      ], (b) => b.evaluate(now: clock));
      await repo.discardLocal(caseIds: {'RC-SRV-1'});
      expect((await repo.loadCase('RC-SRV-1')).isSuccess, isTrue);
    });

    test('the Tracker is told to reload', () async {
      final before = repo.version.value;
      await repo.discardLocal(caseIds: {'RC-NONE'});
      expect(repo.version.value, greaterThan(before));
    });
  });
}
