import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/document_reference_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DocumentReferenceDao', () {
	late Database db;
	late DocumentReferenceDao dao;

	setUp(() async {
	  db = await openDatabase(
		inMemoryDatabasePath,
		version: 1,
		onCreate: (db, version) async {
		  await db.execute('''
			CREATE TABLE a_tblRequest (
			  RequestID INTEGER PRIMARY KEY
			)
		  ''');
		  await db.execute('''
			CREATE TABLE a_tblRequestDocumentReference (
			  ID INTEGER PRIMARY KEY AUTOINCREMENT,
			  RequestID INTEGER,
			  Reference TEXT,
			  RequestCreatedAt TEXT,
			  UNIQUE(RequestID, Reference),
			  FOREIGN KEY (RequestID) REFERENCES a_tblRequest (RequestID) ON DELETE CASCADE
			)
		  ''');

		  await db.insert('a_tblRequest', {'RequestID': 1});
		},
	  );
	  dao = DocumentReferenceDao(db);
	});

	tearDown(() async {
	  await db.close();
	});

	test('insert ignores duplicate requestId and reference pairs', () async {
	  await dao.insert('1', 'INV-001', '2026-05-15T00:00:00Z');
	  await dao.insert(1, 'INV-001', '2026-05-15T00:01:00Z');

	  final references = await dao.getByRequestId(1);
	  final rows = await db.query('a_tblRequestDocumentReference');

	  expect(references, ['INV-001']);
	  expect(rows.length, 1);
	  expect(rows.first['RequestID'], 1);
	  expect(rows.first['Reference'], 'INV-001');
	});

	test('deleteByRequestId accepts string and removes matching rows', () async {
	  await dao.insert(1, 'INV-002', '2026-05-15T00:00:00Z');

	  await dao.deleteByRequestId('1');

	  final references = await dao.getByRequestId(1);
	  expect(references, isEmpty);
	});
  });
}
