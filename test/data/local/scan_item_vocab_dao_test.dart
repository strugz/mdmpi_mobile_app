import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/scan_item_vocab_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/scan_vocab_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ScanItemVocabDao dao;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath,
        version: 1, onCreate: (db, v) async => createAllTables(db));
    dao = ScanItemVocabDao(db);
  });

  tearDown(() async => db.close());

  const bottle = ScanVocabEntry(
      itemCode: 'B36868', description: 'Lyse  Bottle', unit: 'BOTTLE', uses: 4);

  test('server rows keep the higher use count; one row per item', () async {
    await dao.saveFromServer([bottle]);
    await dao.saveFromServer([
      const ScanVocabEntry(
          itemCode: 'b36868', description: 'LYSE BOTTLE', unit: 'BOTTLE', uses: 2),
    ]);
    final all = await dao.all();
    expect(all, hasLength(1));
    expect(all.single.uses, 4);
  });

  test('confirmed items add one use', () async {
    await dao.saveFromServer([bottle]);
    await dao.saveConfirmed([bottle]);
    await dao.saveConfirmed([
      const ScanVocabEntry(itemCode: '', description: 'New Item', unit: ''),
    ]);
    final all = {for (final e in await dao.all()) e.description: e.uses};
    expect(all, {'Lyse  Bottle': 5, 'New Item': 1});
  });

  test('empty descriptions are not saved', () async {
    await dao.saveConfirmed(
        [const ScanVocabEntry(itemCode: 'X', description: '', unit: '')]);
    expect(await dao.all(), isEmpty);
  });
}
