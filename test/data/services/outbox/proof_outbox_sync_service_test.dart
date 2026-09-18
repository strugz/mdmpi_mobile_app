import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/services/outbox/proof_outbox_sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The outboxes must drain themselves. Until this service existed, a proof
/// captured offline sat in SQLite until someone opened Settings > Developer
/// Tools and pressed Retry.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late List<String> uploadedKeys;
  late bool online;
  late Result<void> Function(String key) respond;

  ProofOutboxSyncService buildService() => ProofOutboxSyncService(
        database: () async => db,
        isConnected: () async => online,
        upload: ({
          required String requestId,
          required String base64Image,
          required String type,
        }) async {
          final key = '$requestId/$type';
          uploadedKeys.add(key);
          return respond(key);
        },
        observeLifecycle: false,
        watchConnectivity: false,
        startupDelay: const Duration(days: 1), // never fires in tests
      );

  Future<void> seedImage(String id, {String status = 'Pending'}) => db.insert(
        'a_tblRequestImageOutbox',
        {
          'RequestID': id,
          'ImageType': 'Proof',
          'ImageLookupKey': 'k$id',
          'RequestImage': 'img$id',
          'ApiStatus': status,
        },
      );

  Future<void> seedSignature(String id, {String status = 'Pending'}) =>
      db.insert('a_tblRequestReceiverSignature', {
        'RequestID': int.parse(id),
        'RequestReceiverSignature': 'sig$id',
        'ApiStatus': status,
      });

  Future<int> imageRows() async =>
      (await db.query('a_tblRequestImageOutbox')).length;
  Future<int> signatureRows() async =>
      (await db.query('a_tblRequestReceiverSignature')).length;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath,
        version: 1, onCreate: (db, v) async => createAllTables(db));
    uploadedKeys = [];
    online = true;
    respond = (_) => Result.success(null);
  });

  tearDown(() async => db.close());

  test('uploads every pending image and signature, then removes the rows',
      () async {
    await seedImage('1');
    await seedImage('2', status: 'Failed');
    await seedSignature('3');

    final summary = await buildService().flush(reason: 'test');

    expect(summary.ran, isTrue);
    expect(summary.attempted, 3);
    expect(summary.uploaded, 3);
    expect(uploadedKeys, containsAll(['1/Proof', '2/Proof', '3/Signature']));
    expect(await imageRows(), 0);
    expect(await signatureRows(), 0);
  });

  test('a failed upload keeps the row and marks it Failed', () async {
    await seedImage('1');
    respond = (_) => Result.failure('500');

    final summary = await buildService().flush(reason: 'test');

    expect(summary.attempted, 1);
    expect(summary.uploaded, 0);
    final rows = await db.query('a_tblRequestImageOutbox');
    expect(rows, hasLength(1));
    expect(rows.single['ApiStatus'], 'Failed');
    expect(rows.single['RequestImage'], 'img1',
        reason: 'the payload must survive so a later pass can retry it');
  });

  test('one failure does not stop the others', () async {
    await seedImage('1');
    await seedImage('2');
    respond = (key) =>
        key == '1/Proof' ? Result.failure('boom') : Result.success(null);

    final summary = await buildService().flush(reason: 'test');

    expect(summary.attempted, 2);
    expect(summary.uploaded, 1);
    expect(await imageRows(), 1);
  });

  test('does nothing while offline', () async {
    await seedImage('1');
    online = false;

    final summary = await buildService().flush(reason: 'test');

    expect(summary.ran, isFalse);
    expect(summary.skippedReason, 'offline');
    expect(uploadedKeys, isEmpty);
    expect(await imageRows(), 1);
  });

  test('already-synced rows are left alone', () async {
    await seedImage('1', status: 'Synced');

    final summary = await buildService().flush(reason: 'test');

    expect(summary.attempted, 0);
    expect(uploadedKeys, isEmpty);
  });

  test('automatic passes are throttled, manual ones are not', () async {
    await seedImage('1');
    respond = (_) => Result.failure('down');
    final service = buildService();

    final first = await service.flush(reason: 'auto');
    expect(first.ran, isTrue);
    expect(service.nextAllowedAt, isNotNull);

    final second = await service.flush(reason: 'auto');
    expect(second.skippedReason, 'throttled');

    final manual = await service.flushNow();
    expect(manual.ran, isTrue);
    expect(uploadedKeys, hasLength(2));
  });

  test('a pass where everything failed backs off longer', () async {
    await seedImage('1');
    respond = (_) => Result.failure('down');
    final service = buildService();
    final before = DateTime.now();

    await service.flush(reason: 'auto');

    final gap = service.nextAllowedAt!.difference(before);
    expect(gap, greaterThanOrEqualTo(service.retryDelayAfterTotalFailure));
  });

  test('a pass with a success only waits the minimum interval', () async {
    await seedImage('1');
    final service = buildService();
    final before = DateTime.now();

    await service.flush(reason: 'auto');

    final gap = service.nextAllowedAt!.difference(before);
    expect(gap, greaterThanOrEqualTo(service.minInterval));
    expect(gap, lessThan(service.retryDelayAfterTotalFailure));
  });

  test('an uploader that throws is treated as a failure', () async {
    await seedSignature('9');
    respond = (_) => throw StateError('network');

    final summary = await buildService().flush(reason: 'test');

    expect(summary.attempted, 1);
    expect(summary.uploaded, 0);
    final rows = await db.query('a_tblRequestReceiverSignature');
    expect(rows.single['ApiStatus'], 'Failed');
  });
}
