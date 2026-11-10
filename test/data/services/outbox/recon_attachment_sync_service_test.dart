import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_attachment_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/services/outbox/recon_attachment_sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The reconciliation photo outbox: what reaches the server is marked, a
/// photo whose case is not uploaded yet waits without counting as a failure,
/// and a refused one is retried a limited number of times.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ReconAttachmentDao dao;
  late Directory dir;
  late List<String> sent;
  late Map<String, ReconAttachmentUploadOutcome> answer;
  late bool online;

  ReconAttachmentSyncService service() => ReconAttachmentSyncService(
        dao: () async => dao,
        isConnected: () async => online,
        upload: (a, bytes) async {
          sent.add('${a.attachmentId}:${bytes.length}');
          final outcome =
              answer[a.attachmentId] ?? ReconAttachmentUploadOutcome.uploaded;
          return (
            outcome: outcome,
            error: outcome == ReconAttachmentUploadOutcome.failed
                ? 'HTTP 500'
                : null,
          );
        },
        startupDelay: const Duration(days: 1),
        observeLifecycle: false,
        watchConnectivity: false,
        maxRetries: 2,
      );

  Future<void> photo(String id, {bool withFile = true}) async {
    final file = File('${dir.path}/$id.jpg');
    if (withFile) await file.writeAsBytes([1, 2, 3]);
    await dao.insert(ReconAttachmentRecord(
        attachmentId: id,
        caseId: 'RC-1',
        activityId: 'RA-1',
        filePath: file.path,
        createdAt: id));
  }

  Future<String> statusOf(String id) async => (await dao.forActivity('RA-1'))
      .firstWhere((a) => a.attachmentId == id)
      .status;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath,
        version: 1, onCreate: (db, _) async => ensureCollectionTables(db));
    dao = ReconAttachmentDao(db);
    dir = await Directory.systemTemp.createTemp('recon_outbox_');
    sent = [];
    answer = {};
    online = true;
  });

  tearDown(() async {
    await db.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('uploads every unsent photo and marks it', () async {
    await photo('RP-1');
    await photo('RP-2');
    final s = service()..onInit();
    expect(await s.flush(reason: 'test'), 2);
    expect(sent, ['RP-1:3', 'RP-2:3']);
    expect(await statusOf('RP-1'), ReconAttachmentStatus.uploaded);
    expect(s.unsent.value, 0);

    sent.clear();
    await s.flush(reason: 'again');
    expect(sent, isEmpty, reason: 'nothing is sent twice');
    s.onClose();
  });

  test('a photo whose case is not on the server yet waits, uncounted',
      () async {
    await photo('RP-1');
    answer['RP-1'] = ReconAttachmentUploadOutcome.waitForCase;
    final s = service();
    for (var i = 0; i < 5; i++) {
      await s.flush(reason: 'try $i');
    }
    final row = (await dao.getUnsent()).single;
    expect(row.status, ReconAttachmentStatus.pending);
    expect(row.retryCount, 0);
    expect(s.unsent.value, 1);

    answer.remove('RP-1');
    expect(await s.flush(reason: 'case uploaded'), 1);
  });

  test('a refused photo is retried up to the limit, then left alone', () async {
    await photo('RP-1');
    answer['RP-1'] = ReconAttachmentUploadOutcome.failed;
    final s = service();
    await s.flush(reason: '1');
    await s.flush(reason: '2');
    await s.flush(reason: '3');
    expect(sent, hasLength(2), reason: 'maxRetries is 2');
    final row = (await dao.forActivity('RA-1')).single;
    expect(row.status, ReconAttachmentStatus.failed);
    expect(row.lastError, 'HTTP 500');
    expect(row.retryCount, 2);
  });

  test('a photo whose file is gone is marked, not sent', () async {
    await photo('RP-1', withFile: false);
    await service().flush(reason: 'test');
    expect(sent, isEmpty);
    final row = (await dao.forActivity('RA-1')).single;
    expect(row.status, ReconAttachmentStatus.failed);
    expect(row.lastError, 'The photo file is missing');
  });

  test('offline: nothing is tried', () async {
    await photo('RP-1');
    online = false;
    expect(await service().flush(reason: 'offline'), 0);
    expect(sent, isEmpty);
    expect(await statusOf('RP-1'), ReconAttachmentStatus.pending);
  });
}
