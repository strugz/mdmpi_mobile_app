import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_activity_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_account_history_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_engagement_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The engagement archive. What these protect: a collector's own record of
/// their field work survives the refresh that replaces every other collection
/// table, lands on the day they were standing in front of the customer, and is
/// grouped for the calendar once rather than once per visible cell.

CollectionEngagementRecord _row(
  String engagedAt, {
  String kind = 'INVOICE',
  String itemId = 'INV-1',
  String collectorCode = 'jay',
  double amount = 100,
  String status = 'Collected',
  String source = CollectionEngagementRecord.sourceLocal,
  String clientId = 'C1',
  String clientName = 'Alexis Yu Best Care Pharmacy',
  List<String> documentIds = const [],
}) =>
    CollectionEngagementRecord(
      localRef: CollectionEngagementRecord.buildLocalRef(
          kind: kind,
          subjectId: kind == 'ACCOUNT' ? clientId : itemId,
          engagedAt: engagedAt),
      collectorCode: collectorCode,
      collectorName: 'Jay Bryan Abaoag',
      kind: kind,
      itemId: itemId,
      clientId: clientId,
      clientName: clientName,
      engagedAt: engagedAt,
      engagedOn: BFormatter.localDayKey(engagedAt) ?? '',
      status: status,
      amount: amount,
      documentIds: documentIds,
      createdAt: engagedAt,
      source: source,
    );

/// A deferral of the account: one ACCOUNT row, no invoice of its own, listing
/// the invoices it released (empty for rows copied from the server).
CollectionEngagementRecord _deferral(String engagedAt,
        {String status = 'Refused to Pay',
        String clientId = 'C1',
        String clientName = 'Alexis Yu Best Care Pharmacy',
        List<String> documentIds = const []}) =>
    _row(engagedAt,
        kind: 'ACCOUNT',
        itemId: '',
        status: status,
        amount: 0,
        clientId: clientId,
        clientName: clientName,
        documentIds: documentIds);

class _Activity extends CollectionActivityController {
  @override
  void onInit() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('the archive table', () {
    late Database db;
    late CollectionEngagementDao dao;

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath, version: 1,
          onCreate: (db, _) async {
        await ensureCollectionTables(db);
      });
      dao = CollectionEngagementDao(db);
    });

    tearDown(() async => db.close());

    test('is created, with both of its indexes', () async {
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'a_tblCollection%'");
      expect(
          tables.map((r) => r['name']), contains('a_tblCollectionEngagement'));

      final indexes = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_collection_engagement%'");
      expect(
        indexes.map((r) => r['name'] as String).toSet(),
        containsAll(<String>{
          'idx_collection_engagement_day',
          'idx_collection_engagement_client',
        }),
      );
    });

    test('can be ensured twice, because it is ensured on every open', () async {
      await ensureCollectionTables(db);
      await ensureCollectionTables(db);
      expect(await dao.countAll(), 0);
    });

    test('files the same engagement once, however many times it is saved',
        () async {
      final row = _row('2026-09-17T10:15:00');
      await dao.upsert(row);
      await dao.upsert(row);
      await dao.upsertAll([row, row]);
      expect(await dao.countAll(), 1);
    });

    test('survives the refresh that empties every other collection table',
        () async {
      await dao.upsert(_row('2026-09-17T10:15:00'));
      await dao.upsert(_row('2026-09-16T09:00:00', itemId: 'INV-2'));
      expect(await dao.countAll(), 2);

      // Exactly what a workspace download does.
      await CollectionDao(db).deleteAllCollectionItems();
      await CollectionActivityDao(db).replaceAll([]);
      await CollectionAccountHistoryDao(db).replaceAll([]);

      expect(await dao.countAll(), 2,
          reason: 'the archive is the one table a download may not rewrite');
    });

    test('reads back only the collector asked for, and only their month',
        () async {
      await dao.upsert(_row('2026-09-17T10:15:00'));
      await dao.upsert(_row('2026-08-31T10:15:00', itemId: 'INV-2'));
      await dao.upsert(
          _row('2026-09-02T10:15:00', itemId: 'INV-3', collectorCode: 'mara'));

      final mine =
          await dao.getForMonth(collectorCode: 'jay', yearMonth: '2026-09');
      expect(mine.map((e) => e.itemId), ['INV-1']);

      final counts =
          await dao.countsByDay(collectorCode: 'jay', yearMonth: '2026-09');
      expect(counts, {'2026-09-17': 1});
    });
  });

  /// Why the archive has an origin at all: it holds two different things. What
  /// the collector did on this device is a record and may never be rewritten.
  /// What the backfill copied out of the cache is a picture of what the server
  /// said, and when the server's data goes, the picture has to go with it —
  /// otherwise a deleted month keeps being reported by a total that nothing
  /// left on the device can account for.
  group('where a row came from', () {
    late Database db;
    late CollectionEngagementDao dao;

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath, version: 1,
          onCreate: (db, _) async {
        await ensureCollectionTables(db);
      });
      dao = CollectionEngagementDao(db);
    });

    tearDown(() async => db.close());

    test('is the collector, unless the row says otherwise', () async {
      await dao.upsert(_row('2026-09-17T10:15:00'));
      final saved = (await dao.getAll('jay')).single;
      expect(saved.source, CollectionEngagementRecord.sourceLocal);
      expect(saved.isLocal, isTrue);
    });

    test('decides what a refresh may throw away', () async {
      await dao.upsert(_row('2026-09-17T10:15:00'));
      await dao.upsert(_row('2026-09-16T09:00:00',
          itemId: 'INV-2', source: CollectionEngagementRecord.sourceServer));
      await dao.upsert(_row('2026-09-15T09:00:00',
          itemId: 'INV-3', source: CollectionEngagementRecord.sourceServer));

      expect(await dao.clearServerCopied(), 2);

      final left = await dao.getAll('jay');
      expect(left.map((e) => e.itemId), ['INV-1'],
          reason: 'a refresh may drop the copies and nothing else');
    });

    // A download rebuilds the copies. Deleting them and then writing the new
    // ones left a moment with none, and "Collected this Month" read ₱0.00
    // until the rebuild caught up. The swap is one transaction now.
    test('swaps the copies in one step and keeps the collector\'s own',
        () async {
      await dao.upsert(_row('2026-09-17T10:15:00'));
      await dao.upsert(_row('2026-09-16T09:00:00',
          itemId: 'INV-2', source: CollectionEngagementRecord.sourceServer));

      final removed = await dao.replaceServerCopies([
        _row('2026-09-15T09:00:00',
            itemId: 'INV-3', source: CollectionEngagementRecord.sourceServer),
        _row('2026-09-14T09:00:00',
            itemId: 'INV-4', source: CollectionEngagementRecord.sourceServer),
      ]);

      expect(removed, 1);
      final left = await dao.getAll('jay');
      expect(left.map((e) => e.itemId), ['INV-1', 'INV-3', 'INV-4'],
          reason: 'old copy out, new copies in, own work untouched');
    });

    test('never shows a reader the copies missing mid-swap', () async {
      await dao.upsert(_row('2026-09-16T09:00:00',
          itemId: 'INV-2', source: CollectionEngagementRecord.sourceServer));

      // A read queued while the swap runs waits for the transaction, so it
      // sees the old copy or the new one — never an empty archive.
      final swap = dao.replaceServerCopies([
        _row('2026-09-16T09:00:00',
            itemId: 'INV-2', source: CollectionEngagementRecord.sourceServer),
      ]);
      final during = dao.getAll('jay');
      await swap;
      expect((await during).map((e) => e.itemId), ['INV-2']);
    });

    test('a swap to nothing still reports what it dropped', () async {
      await dao.upsert(_row('2026-09-16T09:00:00',
          itemId: 'INV-2', source: CollectionEngagementRecord.sourceServer));
      expect(await dao.replaceServerCopies(const []), 1);
      expect(await dao.countAll(), 0);
    });

    test('cannot be used to reach the collector\'s own work', () async {
      await dao.upsert(_row('2026-09-17T10:15:00'));
      await dao.upsert(_row('2026-09-16T09:00:00', itemId: 'INV-2'));

      expect(await dao.clearServerCopied(), 0);
      expect(await dao.countAll(), 2);
    });

    test('is added to a database that predates the column', () async {
      // An install upgrading into this change: the table is already there,
      // without the column, holding rows. Rebuilt in place rather than in a
      // second database, because every ':memory:' handle in an isolate is the
      // same database.
      await db.execute('DROP TABLE a_tblCollectionEngagement');
      await db.execute('''
          CREATE TABLE a_tblCollectionEngagement (
            localRef       TEXT PRIMARY KEY,
            collectorCode  TEXT NOT NULL,
            collectorName  TEXT NOT NULL DEFAULT '',
            kind           TEXT NOT NULL,
            itemId         TEXT NOT NULL DEFAULT '',
            clientId       TEXT NOT NULL DEFAULT '',
            clientName     TEXT NOT NULL DEFAULT '',
            engagedAt      TEXT NOT NULL,
            engagedOn      TEXT NOT NULL,
            status         TEXT NOT NULL DEFAULT '',
            remarks        TEXT NOT NULL DEFAULT '',
            amount         REAL NOT NULL DEFAULT 0,
            bankName       TEXT,
            checkNumber    TEXT,
            checkDate      TEXT,
            purposeOfVisit TEXT,
            documentIds    TEXT NOT NULL DEFAULT '',
            createdAt      TEXT NOT NULL
          )
        ''');
      await db.insert('a_tblCollectionEngagement', {
        'localRef': 'INVOICE|INV-9|2026-09-01T08:00:00',
        'collectorCode': 'jay',
        'kind': 'INVOICE',
        'itemId': 'INV-9',
        'engagedAt': '2026-09-01T08:00:00',
        'engagedOn': '2026-09-01',
        'amount': 500.0,
        'createdAt': '2026-09-01T08:00:00',
      });

      await ensureCollectionTables(db);
      await ensureCollectionTables(db); // every open, so it must not throw

      final upgraded = CollectionEngagementDao(db);
      final row = (await upgraded.getAll('jay')).single;
      // Treated as the collector's own. Nothing on the device can say where a
      // row written before the column came from, and guessing "a copy" would
      // let a refresh delete field work that was never anywhere else.
      expect(row.source, CollectionEngagementRecord.sourceLocal);
      expect(await upgraded.clearServerCopied(), 0);
      expect(await upgraded.countAll(), 1);
    });
  });

  group('the day an engagement is filed under', () {
    test('is the local day, not the UTC one', () {
      // A stamp that falls on one day in UTC and another where the collector
      // is standing. Reading the UTC fields is what put the early morning on
      // the day before.
      final utc = DateTime.utc(2026, 9, 16, 18, 0);
      final local = utc.toLocal();
      final expected = '${local.year.toString().padLeft(4, '0')}-'
          '${local.month.toString().padLeft(2, '0')}-'
          '${local.day.toString().padLeft(2, '0')}';
      expect(BFormatter.localDayKey(utc.toIso8601String()), expected);
    });

    test('is null for the sentinels the old rows carry', () {
      // 'N/A' is what CollectionHistoryModel defaults a missing date to; '' is
      // what the DAOs default to. Both used to vanish into a bare catch.
      expect(BFormatter.localDayKey('N/A'), isNull);
      expect(BFormatter.localDayKey(''), isNull);
      expect(BFormatter.localDayKey(null), isNull);
    });
  });

  group('the calendar grouping', () {
    tearDown(Get.reset);

    _Activity seeded(List<CollectionEngagementRecord> rows) {
      final c = _Activity();
      Get.put<CollectionActivityController>(c);
      c.startAggregateTracking();
      c.ownEngagements.assignAll(rows);
      return c;
    }

    test('groups an engagement under the day it happened', () {
      final c = seeded([
        _row('2026-09-17T10:15:00'),
        _row('2026-09-17T14:00:00', itemId: 'INV-2'),
        _row('2026-09-12T09:00:00', itemId: 'INV-3'),
      ]);

      final byDate = c.activitiesByDate;
      expect(byDate[DateTime(2026, 9, 17)]?.length, 2);
      expect(byDate[DateTime(2026, 9, 12)]?.length, 1);
    });

    test('regroups when the engagements change, and not before', () {
      final c = seeded([_row('2026-09-17T10:15:00')]);

      final first = c.activitiesByDate;
      for (var i = 0; i < 100; i++) {
        expect(identical(c.activitiesByDate, first), isTrue,
            reason: 'table_calendar asks once per visible cell; regrouping '
                'the whole history on each ask is what made a month expensive');
      }

      c.ownEngagements.add(_row('2026-09-18T10:15:00', itemId: 'INV-2'));
      expect(identical(c.activitiesByDate, first), isFalse);
      expect(c.activitiesByDate.length, 2);
    });

    test('leaves reconciliation off the calendar, as the activity list does',
        () {
      final c = seeded([
        _row('2026-09-17T10:15:00',
            kind: 'OFFICE', itemId: '', status: 'Reconciliation'),
        _row('2026-09-17T11:00:00', kind: 'OFFICE', status: 'Deposit'),
      ]);
      expect(c.activitiesByDate[DateTime(2026, 9, 17)]?.length, 1);
    });

    test('shows an open reconciliation through its invoice row', () {
      // The OFFICE row is hidden above; the INVOICE row the repository now
      // writes for each reconciled invoice is what the collector sees while
      // nothing has finished it.
      final c = seeded([
        _row('2026-09-17T10:15:00',
            kind: 'OFFICE', itemId: '', status: 'Reconciliation'),
        _row('2026-09-17T10:15:00', status: 'Reconciliation'),
      ]);

      final day17 = c.activitiesByDate[DateTime(2026, 9, 17)]!;
      final history = day17.single['history'] as CollectionHistoryModel;
      expect(history.status, 'Reconciliation');
      expect(day17.single['invoiceId'], 'INV-1');
      expect(day17.single['reconciledOn'], isNull);
    });

    test(
        'a finished reconciliation is told once, on the outcome that '
        'finished it', () {
      final c = seeded([
        _row('2026-09-17T10:15:00',
            kind: 'OFFICE', itemId: '', status: 'Reconciliation'),
        _row('2026-09-17T10:15:00', status: 'Reconciliation'),
        _row('2026-09-19T09:30:00', status: 'Collected'),
      ]);

      // The reconciliation's own day no longer lists it...
      expect(c.activitiesByDate[DateTime(2026, 9, 17)], isNull);

      // ...the collection carries it instead, even though the invoice has
      // settled and left the cache.
      final day19 = c.activitiesByDate[DateTime(2026, 9, 19)]!;
      final history = day19.single['history'] as CollectionHistoryModel;
      expect(history.status, 'Collected');
      expect(day19.single['reconciledOn'], '2026-09-17T10:15:00');
    });

    test('a refusal finishes a reconciliation the same way', () {
      final c = seeded([
        _row('2026-09-17T10:15:00', status: 'Reconciliation'),
        _row('2026-09-19T09:30:00', status: 'Refused to Pay', amount: 0),
      ]);

      expect(c.activitiesByDate[DateTime(2026, 9, 17)], isNull);
      final day19 = c.activitiesByDate[DateTime(2026, 9, 19)]!;
      expect((day19.single['history'] as CollectionHistoryModel).status,
          'Refused to Pay');
      expect(day19.single['reconciledOn'], '2026-09-17T10:15:00');
    });

    test('a deferral of the account finishes the reconciliations it released',
        () {
      // 06:23 invoice reconciled, 06:24 the account refused to pay. One card,
      // "Reconciliation Refused to Pay", covering the released invoice.
      final c = seeded([
        _row('2026-09-22T06:23:00', status: 'Reconciliation'),
        _deferral('2026-09-22T06:24:00', documentIds: ['INV-1']),
      ]);

      final day = c.activitiesByDate[DateTime(2026, 9, 22)]!;
      expect(day.length, 1);
      final only = day.single;
      expect(
          (only['history'] as CollectionHistoryModel).status, 'Refused to Pay');
      expect(only['reconciledOn'], '2026-09-22T06:23:00');
      expect(only['invoiceId'], isNull);
      expect(only['invoiceCount'], 1);
      expect(only['accountName'], 'Alexis Yu Best Care Pharmacy');
    });

    test('a deferral only reaches the invoices it lists', () {
      final c = seeded([
        _row('2026-09-22T06:23:00', status: 'Reconciliation'),
        _row('2026-09-22T06:23:30', itemId: 'INV-2', status: 'Reconciliation'),
        _deferral('2026-09-22T06:24:00', documentIds: ['INV-2']),
      ]);

      final day = c.activitiesByDate[DateTime(2026, 9, 22)]!;
      expect(day.length, 2, reason: 'INV-1 is still open and still shown');
      final statuses = day
          .map((e) => (e['history'] as CollectionHistoryModel).status)
          .toSet();
      expect(statuses, {'Reconciliation', 'Refused to Pay'});
      final refusal = day.singleWhere((e) =>
          (e['history'] as CollectionHistoryModel).status == 'Refused to Pay');
      expect(refusal['reconciledOn'], '2026-09-22T06:23:30');
      expect(refusal['invoiceCount'], 1);
    });

    test(
        'a deferral copied from the server, with no invoice list, falls back '
        'to every open reconciliation of the client', () {
      final c = seeded([
        _row('2026-09-22T06:23:00', status: 'Reconciliation'),
        _row('2026-09-22T06:23:30', itemId: 'INV-2', status: 'Reconciliation'),
        _deferral('2026-09-22T06:24:00', status: 'Customer Unavailable'),
      ]);

      final day = c.activitiesByDate[DateTime(2026, 9, 22)]!;
      expect(day.length, 1);
      expect(day.single['reconciledOn'], '2026-09-22T06:23:30');
      expect(day.single['invoiceCount'], isNull);
    });

    test(
        "another client's deferral does not finish this client's "
        'reconciliation', () {
      final c = seeded([
        _row('2026-09-22T06:23:00', status: 'Reconciliation'),
        _deferral('2026-09-22T06:24:00', clientId: 'C2', documentIds: ['X']),
      ]);

      final day = c.activitiesByDate[DateTime(2026, 9, 22)]!;
      expect(day.length, 2);
      expect(day.every((e) => e['reconciledOn'] == null), isTrue);
    });

    test('a deferral before the reconciliation does not reach forward', () {
      final c = seeded([
        _deferral('2026-09-22T06:20:00', documentIds: ['INV-1']),
        _row('2026-09-22T06:23:00', status: 'Reconciliation'),
      ]);

      final day = c.activitiesByDate[DateTime(2026, 9, 22)]!;
      expect(day.length, 2);
      expect(day.every((e) => e['reconciledOn'] == null), isTrue);
    });

    test('a collection with no reconciliation before it is not marked', () {
      final c = seeded([
        _row('2026-09-19T09:30:00', status: 'Collected'),
        // A later reconciliation of the same invoice does not reach back,
        // and stays on the calendar as an open one.
        _row('2026-09-21T10:15:00', status: 'Reconciliation'),
        // Another invoice's reconciliation is not this invoice's.
        _row('2026-09-17T10:15:00', itemId: 'INV-2', status: 'Reconciliation'),
      ]);

      expect(c.activitiesByDate[DateTime(2026, 9, 19)]!.single['reconciledOn'],
          isNull);
      expect(c.activitiesByDate[DateTime(2026, 9, 21)]?.length, 1);
      expect(c.activitiesByDate[DateTime(2026, 9, 17)]?.length, 1);
    });

    test('names the account on a deferral row that arrived without a name', () {
      // The server's account-history table has no name column, so a deferral
      // copied from it is archived with clientName ''. The card was showing a
      // blank headline and the day's filter had no chip for it. The master
      // account list knows the name.
      final c = seeded([
        _deferral('2026-09-22T06:24:00', clientName: ''),
      ]);
      c.masterAccountList.add(ClientModel(
          id: 'C1',
          name: 'Amrox Medical Systems',
          address: '',
          contact: '',
          emailAddress: ''));
      c.ownEngagements.refresh();

      final day = c.activitiesByDate[DateTime(2026, 9, 22)]!;
      expect(day.single['accountName'], 'Amrox Medical Systems');
    });

    test(
        'names the account from another archive row of the same client '
        'when the list does not know it either', () {
      final c = seeded([
        _row('2026-09-20T10:00:00'),
        _deferral('2026-09-22T06:24:00', clientName: ''),
      ]);

      final day = c.activitiesByDate[DateTime(2026, 9, 22)]!;
      expect(day.single['accountName'], 'Alexis Yu Best Care Pharmacy');
    });

    test('keeps an engagement whose invoice has already settled and gone', () {
      // Nothing in bucketItems or activityItems: the invoice was paid off and
      // the server stopped returning it. The visit still happened.
      final c = seeded([_row('2026-09-17T10:15:00')]);

      final entries = c.activitiesByDate[DateTime(2026, 9, 17)]!;
      expect(entries.single['item'], isNull);
      expect(entries.single['accountName'], 'Alexis Yu Best Care Pharmacy');
    });
  });
}
