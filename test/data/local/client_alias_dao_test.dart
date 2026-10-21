import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/client_alias_dao.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ClientAliasDao dao;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath,
        version: 1, onCreate: (db, v) async => createAllTables(db));
    dao = ClientAliasDao(db);
  });

  tearDown(() async => db.close());

  test('upsert, find and replace', () async {
    expect(await dao.findByAlias('GALINATO CLINIC AND HOSPITAL'), isNull);

    await dao.upsert('GALINATO CLINIC AND HOSPITAL', 'C-1');
    expect(await dao.findByAlias('GALINATO CLINIC AND HOSPITAL'), 'C-1');

    await dao.upsert('GALINATO CLINIC AND HOSPITAL', 'C-2');
    expect(await dao.findByAlias('GALINATO CLINIC AND HOSPITAL'), 'C-2');
    expect(await db.query(ClientAliasDao.table), hasLength(1));
  });

  test('delete by alias and by client', () async {
    await dao.upsert('A', 'C-1');
    await dao.upsert('B', 'C-1');
    await dao.upsert('C', 'C-2');

    await dao.deleteAlias('C');
    expect(await dao.findByAlias('C'), isNull);

    expect(await dao.deleteForClient('C-1'), 2);
    expect(await db.query(ClientAliasDao.table), isEmpty);
  });

  test('aliases survive the version-bump rebuild', () async {
    await dao.upsert('CLINICA MANILA', 'C-9');

    for (final table in DatabaseHelper.cacheBackedTables) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }
    await createAllTables(db);

    expect(await dao.findByAlias('CLINICA MANILA'), 'C-9');
    expect(DatabaseHelper.preservedOnUpgradeTables, contains('CLIENT_ALIAS_'));
    expect(DatabaseHelper.cacheBackedTables, isNot(contains('CLIENT_ALIAS_')));
  });

  test('the schema has the per-request delivery address', () async {
    final columns = await db.rawQuery('PRAGMA table_info(a_tblRequest)');
    expect(columns.map((c) => c['name']), contains('RequestDeliveryAddress'));

    await ensureOneScanTables(db); // idempotent
  });
}
