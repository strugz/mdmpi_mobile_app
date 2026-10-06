import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/cntmst_dao.dart';
import 'package:mdmpi_mobile_app/data/models/cntmst_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// CntmstDao.getAll: the CNTMST side of the user directory (Collection TODO
/// item 14). Every row with a code, active or not; the directory decides.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late CntmstDao dao;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath, version: 1,
        onCreate: (db, version) async {
      // The CNTMST columns the app writes (db_schema.dart).
      await db.execute('''
        CREATE TABLE CNTMST (
          CNTMID TEXT PRIMARY KEY, CNTMLN TEXT, CNTMMN TEXT, CNTMFN TEXT,
          CNTMNN TEXT, CNTNUM TEXT, CNTDPT TEXT, CNTMCN TEXT, CNTMSX TEXT,
          CNTMPF TEXT, CNTMSF TEXT, CNTMBD TEXT, CNTARE TEXT, CNTRTH TEXT,
          CNTLDR TEXT, CNTEPS TEXT, CNTSTS TEXT, CNTSEC TEXT, CNTTGP TEXT,
          CNTEGP TEXT, CNTMGP TEXT, CNTDHD TEXT, CNTFRM TEXT
        )
      ''');
    });
    dao = CntmstDao(db);
  });

  tearDown(() async => db.close());

  test('returns every row with a code, inactive ones included', () async {
    await dao.insertCntmsts([
      CNTMSTModel(
          cntmid: '1',
          cntmnn: 'JCA',
          cntmcn: 'Jay',
          cntnum: '0917',
          cntsts: '1'),
      CNTMSTModel(cntmid: '2', cntmnn: 'OLD', cntmcn: 'Former', cntsts: '0'),
      CNTMSTModel(cntmid: '3', cntmnn: null, cntmcn: 'No Code'),
      CNTMSTModel(cntmid: '4', cntmnn: '   ', cntmcn: 'Blank Code'),
      CNTMSTModel(cntmid: '5', cntmnn: 'COL', cntdpt: 'COLLECTOR'),
    ]);

    final rows = await dao.getAll();

    expect(rows.map((r) => r.cntmnn), unorderedEquals(['JCA', 'OLD', 'COL']),
        reason: 'unlike getRequesters, collectors and inactive rows are kept');
    final jca = rows.firstWhere((r) => r.cntmnn == 'JCA');
    expect(jca.cntmcn, 'Jay');
    expect(jca.cntnum, '0917');
  });

  test('getByCode finds one row, trimmed and case-insensitive', () async {
    await dao.insertCntmsts([
      CNTMSTModel(
          cntmid: '1', cntmnn: 'JCA ', cntmcn: 'Jay', cnttgp: 'EGL/MDD/AJS'),
      CNTMSTModel(cntmid: '2', cntmnn: 'MDD', cntmcn: 'Head'),
    ]);

    expect((await dao.getByCode('jca'))?.cnttgp, 'EGL/MDD/AJS');
    expect((await dao.getByCode(' MDD '))?.cntmcn, 'Head');
    expect(await dao.getByCode('ZZZ'), isNull);
    expect(await dao.getByCode('  '), isNull);
  });
}
