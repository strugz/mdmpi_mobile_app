import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async => db = await openDatabase(inMemoryDatabasePath));
  tearDown(() async => db.close());

  Future<List<Object?>> columns() async =>
      (await db.rawQuery('PRAGMA table_info(a_tblRequestAirSea)'))
          .map((c) => c['name'])
          .toList();

  test('a phone with the old Air/Sea table gets DepartureAt, rows kept',
      () async {
    await db.execute(
        'CREATE TABLE a_tblRequestAirSea (RequestID TEXT, DropOffAt TEXT)');
    await db.insert('a_tblRequestAirSea', {'RequestID': '1'});

    await ensureAirSeaColumns(db);
    await ensureAirSeaColumns(db); // every open: must not fail the second time

    expect(await columns(), contains('DepartureAt'));
    final row = (await db.query('a_tblRequestAirSea')).single;
    expect(row['RequestID'], '1');
    expect(row['DepartureAt'], isNull);
  });

  test('a fresh install already has it', () async {
    await createAllTables(db);
    await ensureAirSeaColumns(db);
    expect(await columns(), contains('DepartureAt'));
  });

  test('no Air/Sea table yet: nothing happens, no error', () async {
    await ensureAirSeaColumns(db);
    expect(await columns(), isEmpty);
  });
}
