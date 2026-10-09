import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/voucher_reread_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/services/outbox/voucher_reread_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/voucher_si_matcher.dart';
import 'package:mdmpi_mobile_app/features/collection/models/scanned_invoice.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Voucher pages read on the phone are read again by the AI once online;
/// only what the phone missed is reported.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late VoucherRereadDao dao;
  late Directory dir;
  late File page;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath,
        version: 1,
        onCreate: (db, _) async => ensureVoucherRereadTables(db));
    dao = VoucherRereadDao(db);
    dir = await Directory.systemTemp.createTemp('reread_test');
    page = await File('${dir.path}/page.jpg').writeAsBytes([1, 2, 3]);
  });
  tearDown(() async {
    await db.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  group('dao', () {
    test('pending, retries up to failed, done with findings, seen', () async {
      await dao.insert(const VoucherRereadRecord(
          rereadId: 'a', clientId: '1', pagePath: 'x', createdAt: '2026-10-09'));
      expect((await dao.getPending()).single.rereadId, 'a');

      await dao.markRetry('a', 'offline', maxRetries: 2);
      expect((await dao.getPending(maxRetries: 2)).single.retryCount, 1);
      await dao.markRetry('a', 'offline', maxRetries: 2);
      expect(await dao.getPending(maxRetries: 2), isEmpty);

      await dao.insert(const VoucherRereadRecord(
          rereadId: 'b', clientId: '1', pagePath: 'y', createdAt: '2026-10-09'));
      await dao.markDone('b', foundIds: ['240009288'], notFound: ['999']);
      final unseen = await dao.getUnseen();
      expect(unseen.single.foundIds, ['240009288']);
      expect(unseen.single.notFound, ['999']);
      await dao.markSeen(['b']);
      expect(await dao.getUnseen(), isEmpty);
    });

    test('a re-read that found nothing new is never shown', () async {
      await dao.insert(const VoucherRereadRecord(
          rereadId: 'c', clientId: '1', pagePath: 'z', createdAt: '2026-10-09'));
      await dao.markDone('c', foundIds: const [], notFound: const []);
      expect(await dao.getUnseen(), isEmpty);
    });

    test('old rows go, with their page paths', () async {
      await dao.insert(const VoucherRereadRecord(
          rereadId: 'old', clientId: '1', pagePath: 'p1',
          createdAt: '2026-09-01T00:00:00'));
      await dao.insert(const VoucherRereadRecord(
          rereadId: 'new', clientId: '1', pagePath: 'p2',
          createdAt: '2026-10-09T00:00:00'));
      expect(await dao.deleteOlderThan('2026-10-02T00:00:00'), ['p1']);
      expect((await dao.getPending()).single.rereadId, 'new');
    });
  });

  group('service', () {
    var online = true;
    var aiPages = <List<VoucherInvoiceLine>?>[];
    final notified = <VoucherRereadRecord>[];
    ScannedInvoiceClassifier? classifier;

    VoucherRereadService service() => VoucherRereadService(
          dao: () async => dao,
          readWithAi: (_) async {
            final next = aiPages.removeAt(0);
            return next == null
                ? Result.failure('AI service error: 503')
                : Result.success(next);
          },
          classifierFor: (_) => classifier,
          notify: (r) async => notified.add(r),
          isConnected: () async => online,
          pagesDirectory: () async => Directory('${dir.path}/kept'),
          now: () => DateTime(2026, 10, 9, 15),
          observeLifecycle: false,
          watchConnectivity: false,
          startupDelay: const Duration(days: 1),
        );

    setUp(() {
      online = true;
      aiPages = [];
      notified.clear();
      classifier = const ScannedInvoiceClassifier(
          knownIds: ['240009288', '240009608', '240010232']);
    });

    test('online: what the phone missed is found, reported and kept for '
        'the banner; the page copy is deleted', () async {
      final s = service();
      aiPages.add(const [
        VoucherInvoiceLine(invoiceNo: '240009288'),
        VoucherInvoiceLine(invoiceNo: '240009608'),
        VoucherInvoiceLine(invoiceNo: '700099999'),
      ]);
      await s.enqueue(
          clientId: '1',
          clientName: 'Rite-Tech',
          page: page,
          offlineIds: const ['240009288']);
      await s.flush(reason: 'test');

      expect(notified.single.foundIds, ['240009608']);
      expect(notified.single.clientName, 'Rite-Tech');
      expect(s.unseenFor('1').single.foundIds, ['240009608']);
      expect(s.unseenFor('1').single.notFound, ['700099999']);
      expect(Directory('${dir.path}/kept').listSync(), isEmpty);
      expect(await page.exists(), isTrue, reason: 'the original is not ours');

      await s.markSeen(s.unseenFor('1'));
      expect(s.unseen, isEmpty);
      expect(await dao.getUnseen(), isEmpty);
      s.onClose();
    });

    test('offline, the AI down, or invoices not loaded: the page waits',
        () async {
      final s = service();
      online = false;
      await s.enqueue(
          clientId: '1', page: page, offlineIds: const ['240009288']);
      await s.flush(reason: 'offline');
      expect(s.pending.value, 1);

      online = true;
      classifier = null;
      await s.flush(reason: 'not loaded');
      expect(s.pending.value, 1);

      classifier = const ScannedInvoiceClassifier(knownIds: ['240009288']);
      aiPages.add(null);
      await s.flush(reason: 'AI down');
      expect((await dao.getPending()).single.retryCount, 1);

      aiPages.add(const [VoucherInvoiceLine(invoiceNo: '240009288')]);
      await s.flush(reason: 'back');
      expect(s.pending.value, 0);
      expect(notified, isEmpty, reason: 'nothing the phone had not found');
      s.onClose();
    });

    test('a near miss by the AI still counts', () async {
      final s = service();
      aiPages.add(const [VoucherInvoiceLine(invoiceNo: '240010282')]);
      await s.enqueue(clientId: '1', page: page, offlineIds: const []);
      await s.flush(reason: 'test');
      expect(notified.single.foundIds, ['240010232']);
      s.onClose();
    });
  });
}
