import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_actual_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Actual Collection as the office posts it (revisions list item 11), cached
/// from the workspace download. The server's list is the record: each
/// download replaces the copy outright.

CollectionActualRecord _a(
  int id,
  String date,
  double amount, {
  String ref = 'OR 100',
  String remarks = '',
  String createdAt = '',
}) =>
    CollectionActualRecord(
      actualId: id,
      collectionDate: date,
      amount: amount,
      referenceNo: ref,
      remarks: remarks,
      postedBy: 'Ana',
      createdAt: createdAt,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late CollectionActualDao dao;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async => ensureCollectionTables(db),
    );
    dao = CollectionActualDao(db);
  });

  tearDown(() async => db.close());

  test('is created with the other Collection tables, indexed by date',
      () async {
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE name = 'a_tblCollectionActual'");
    expect(tables, hasLength(1));
    final index = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE name = 'idx_collection_actual_date'");
    expect(index, hasLength(1));
  });

  test('creating the tables again is harmless (runs on every open)', () async {
    await dao.replaceAll([_a(1, '2026-09-01', 10)]);
    await ensureCollectionTables(db);
    expect(await dao.count(), 1);
  });

  test('round-trips every field', () async {
    await dao.replaceAll([
      const CollectionActualRecord(
        actualId: 41,
        collectionDate: '2026-09-12',
        amount: 15250.5,
        referenceNo: 'OR 12345',
        remarks: 'BDO deposit slip',
        postedBy: 'Ana (Office)',
        createdAt: '2026-09-12T09:30:00',
        updatedAt: '2026-09-13T08:00:00',
        updatedBy: 'Ben',
      ),
    ]);
    final a = (await dao.getAll()).single;
    expect(a.actualId, 41);
    expect(a.collectionDate, '2026-09-12');
    expect(a.amount, 15250.5);
    expect(a.referenceNo, 'OR 12345');
    expect(a.remarks, 'BDO deposit slip');
    expect(a.postedBy, 'Ana (Office)');
    expect(a.createdAt, '2026-09-12T09:30:00');
    expect(a.updatedAt, '2026-09-13T08:00:00');
    expect(a.updatedBy, 'Ben');
  });

  test('forMonth reads only that month, newest first', () async {
    await dao.replaceAll([
      _a(1, '2026-09-03', 100, createdAt: '2026-09-03T08:00:00'),
      _a(2, '2026-09-20', 200),
      _a(3, '2026-08-31', 300),
      _a(4, '2026-10-01', 400),
      _a(5, '2026-09-03', 500, createdAt: '2026-09-03T15:00:00'),
    ]);

    final sept = await dao.forMonth('2026-09');
    expect(sept.map((a) => a.actualId), [2, 5, 1]);
    expect((await dao.forMonth('2026-08')).single.actualId, 3);
    expect(await dao.forMonth('2025-09'), isEmpty);
  });

  test('a download replaces the whole copy, an empty one included', () async {
    await dao.replaceAll([_a(1, '2026-09-01', 10), _a(2, '2026-09-02', 20)]);
    await dao.replaceAll([_a(2, '2026-09-02', 25, ref: 'OR 200')]);

    final all = await dao.getAll();
    expect(all.single.actualId, 2);
    expect(all.single.amount, 25);
    expect(all.single.referenceNo, 'OR 200');

    // The office deleted its last entry: the phone must follow.
    await dao.replaceAll(const []);
    expect(await dao.count(), 0);
  });
}
