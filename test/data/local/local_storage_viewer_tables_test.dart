import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The Local Storage Data Viewer's table list.
///
/// It was a hand-written array and had drifted behind the schema: the
/// engagement archive, the bank cache and the proof-image outbox were all
/// missing, so the one tool for answering "what is actually on this device"
/// was blind to three tables — including the newest, which is the one anybody
/// debugging stale data goes looking for. Reading the list from SQLite is what
/// makes drift impossible.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath,
        version: 1, onCreate: (db, _) async => createAllTables(db));
  });

  tearDown(() async => db.close());

  test('holds every table the schema creates', () async {
    final tables = await listUserTables(db);

    expect(
      tables,
      containsAll(<String>[
        'a_tblCollectionEngagement',
        'a_tblCollectionBank',
        'a_tblRequestImageOutbox',
      ]),
      reason: 'the three the typed-out list had missed',
    );
  });

  test('picks up a table added after the list was first read', () async {
    final before = await listUserTables(db);
    await db.execute('CREATE TABLE a_tblSomethingNew (id INTEGER PRIMARY KEY)');

    final after = await listUserTables(db);
    expect(before, isNot(contains('a_tblSomethingNew')));
    expect(after, contains('a_tblSomethingNew'));
  });

  test('leaves SQLite\'s own bookkeeping alone', () async {
    // AUTOINCREMENT makes SQLite create sqlite_sequence. Offering it for
    // browsing is noise; offering it for clearing corrupts the database.
    await db.execute(
        'CREATE TABLE a_tblCounted (id INTEGER PRIMARY KEY AUTOINCREMENT)');
    await db.rawInsert('INSERT INTO a_tblCounted (id) VALUES (NULL)');

    final tables = await listUserTables(db);
    expect(tables, isNot(contains('sqlite_sequence')));
    expect(tables, contains('a_tblCounted'));
  });

  test('is in name order, so a table can be found by eye', () async {
    final tables = await listUserTables(db);
    final sorted = [...tables]..sort();
    expect(tables, sorted);
  });
}
