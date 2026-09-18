import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A DB version bump must not discard work the device captured but has not
/// uploaded yet.
///
/// `_recreateAllTables` drops and rebuilds the cache-backed tables on every
/// version bump. Receiver signatures and the proof-image outbox used to be in
/// that drop list, so a routine app update silently destroyed a driver's
/// pending signatures and photos — data that exists nowhere else once the
/// picker temp file is gone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('destructive rebuild table lists', () {
    test('never drops a table that holds un-uploaded work', () {
      for (final table in DatabaseHelper.preservedOnUpgradeTables) {
        expect(
          DatabaseHelper.cacheBackedTables,
          isNot(contains(table)),
          reason: '$table holds data that exists nowhere else; dropping it on '
              'a version bump loses it permanently',
        );
      }
    });

    test('still drops the server-backed caches', () {
      expect(DatabaseHelper.cacheBackedTables, contains('a_tblRequest'));
      expect(
          DatabaseHelper.cacheBackedTables, contains('a_tblRequestPickUp'));
      expect(
          DatabaseHelper.cacheBackedTables, contains('a_tblRequestAirSea'));
    });
  });

  group('rebuild against a real database', () {
    late Database db;

    /// Mirrors what `_recreateAllTables` does on a version bump.
    Future<void> rebuild() async {
      for (final table in DatabaseHelper.cacheBackedTables) {
        await db.execute('DROP TABLE IF EXISTS $table');
      }
      await createAllTables(db);
    }

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath,
          version: 1, onCreate: (db, v) async => createAllTables(db));
    });

    tearDown(() async => db.close());

    test('pending proof images survive a rebuild', () async {
      await db.insert('a_tblRequestImageOutbox', {
        'RequestID': '4213',
        'ImageType': 'Proof',
        'ImageLookupKey': 'proof-1',
        'RequestImage': 'base64data',
        'ApiStatus': 'Pending',
        'CapturedAt': '2026-09-18T08:00:00Z',
      });

      await rebuild();

      final rows = await db.query('a_tblRequestImageOutbox');
      expect(rows, hasLength(1));
      expect(rows.single['RequestImage'], 'base64data');
      expect(rows.single['ApiStatus'], 'Pending');
    });

    test('captured signatures survive a rebuild', () async {
      await db.insert('a_tblRequestReceiverSignature', {
        'RequestID': 4213,
        'RequestReceiverSignature': 'signature-base64',
        'ApiStatus': 'Pending',
      });

      await rebuild();

      final rows = await db.query('a_tblRequestReceiverSignature');
      expect(rows, hasLength(1));
      expect(rows.single['RequestReceiverSignature'], 'signature-base64');
    });

    test('server-backed caches are still cleared by a rebuild', () async {
      await db.insert('a_tblRequest', {'RequestID': 4213});

      await rebuild();

      expect(await db.query('a_tblRequest'), isEmpty);
    });

    test('creating the schema twice is safe', () async {
      await db.insert('a_tblRequestImageOutbox', {
        'RequestID': '1',
        'ImageType': 'Proof',
        'ImageLookupKey': 'k',
        'RequestImage': 'x',
      });

      await ensureProofUploadTables(db);

      expect(await db.query('a_tblRequestImageOutbox'), hasLength(1));
    });
  });
}
