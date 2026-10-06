import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_client_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The cached client registry the account picker reads. The picker used to
/// ask the server on every keystroke and sat empty while it waited; it now
/// searches this copy, so the search is instant and works without signal.

ClientModel _c(String code, String name) => ClientModel(
      id: code,
      code: code,
      name: name,
      address: 'Antipolo City',
      contact: '0917',
      emailAddress: '',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late CollectionClientDao dao;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async => ensureCollectionTables(db),
    );
    dao = CollectionClientDao(db);
  });

  tearDown(() async => db.close());

  test('is created with the other Collection tables', () async {
    final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE name = 'a_tblCollectionClient'");
    expect(rows, hasLength(1));
  });

  test('searches name and code, case-insensitively, in name order', () async {
    await dao.replaceAll([
      _c('C-300', 'Accuteqs Diagnostics Corp.'),
      _c('C-100', 'Antipolo Doctors Hospital'),
      _c('C-200', "5'R's Medical Supply"),
    ]);

    expect((await dao.search('ANTI')).map((c) => c.id), ['C-100']);
    expect((await dao.search('c-2')).map((c) => c.id), ['C-200']);
    expect((await dao.search('')).map((c) => c.name), [
      "5'R's Medical Supply",
      'Accuteqs Diagnostics Corp.',
      'Antipolo Doctors Hospital',
    ]);
  });

  test('round-trips a client as the app uses it', () async {
    await dao.replaceAll([_c('C-100', 'Antipolo Doctors Hospital')]);
    final c = (await dao.search('antipolo')).single;
    expect(c.id, 'C-100', reason: 'id and code are both the ClientCode');
    expect(c.code, 'C-100');
    expect(c.address, 'Antipolo City');
    expect(c.contact, '0917');
  });

  test('a refresh replaces the whole copy', () async {
    await dao.replaceAll([_c('C-100', 'Old Name'), _c('C-999', 'Gone')]);
    await dao.replaceAll([_c('C-100', 'Antipolo Doctors Hospital')]);

    expect(await dao.count(), 1);
    expect((await dao.search('')).single.name, 'Antipolo Doctors Hospital');
  });

  test('an empty answer never wipes the copy', () async {
    await dao.replaceAll([_c('C-100', 'Antipolo Doctors Hospital')]);
    await dao.replaceAll(const []);
    expect(await dao.count(), 1);
  });

  test('caps the result size', () async {
    await dao.replaceAll([
      for (var i = 0; i < 80; i++)
        _c('C-${i.toString().padLeft(3, '0')}', 'Client $i'),
    ]);
    expect(await dao.search('client'), hasLength(50));
  });
}
