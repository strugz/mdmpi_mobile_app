import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mdmpi_mobile_app/data/models/item_category_model.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/item_category_dao.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize ffi for desktop testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ItemCategoryDao', () {
    late Database db;
    late ItemCategoryDao dao;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE a_tblItemCategory (
              ItemCategoryID TEXT PRIMARY KEY,
              ItemCategoryName TEXT
            )
          ''');
        },
      );
      dao = ItemCategoryDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('insertItemCategories and getAll should work', () async {
      final categories = [
        const ItemCategoryModel(id: '1', name: 'Electronics'),
        const ItemCategoryModel(id: '2', name: 'Furniture'),
        const ItemCategoryModel(id: '3', name: 'Office Supplies'),
      ];

      await dao.insertItemCategories(categories);
      final result = await dao.getAll();

      expect(result.length, 3);
      expect(result[0].id, '1');
      expect(result[0].name, 'Electronics');
      expect(result[1].id, '2');
      expect(result[1].name, 'Furniture');
    });

    test('getById should return correct category', () async {
      final categories = [
        const ItemCategoryModel(id: '1', name: 'Electronics'),
        const ItemCategoryModel(id: '2', name: 'Furniture'),
      ];

      await dao.insertItemCategories(categories);
      final result = await dao.getById('2');

      expect(result, isNotNull);
      expect(result!.id, '2');
      expect(result.name, 'Furniture');
    });

    test('getById should return null for non-existent id', () async {
      final result = await dao.getById('999');
      expect(result, isNull);
    });

    test('hasData should return true when data exists', () async {
      final categories = [
        const ItemCategoryModel(id: '1', name: 'Electronics'),
      ];

      await dao.insertItemCategories(categories);
      final result = await dao.hasData();

      expect(result, true);
    });

    test('hasData should return false when no data exists', () async {
      final result = await dao.hasData();
      expect(result, false);
    });

    test('deleteAll should remove all records', () async {
      final categories = [
        const ItemCategoryModel(id: '1', name: 'Electronics'),
        const ItemCategoryModel(id: '2', name: 'Furniture'),
      ];

      await dao.insertItemCategories(categories);
      await dao.deleteAll();
      final result = await dao.getAll();

      expect(result.length, 0);
    });

    test('insert with conflicting key should replace existing record', () async {
      final category1 = const ItemCategoryModel(id: '1', name: 'Electronics');
      final category2 = const ItemCategoryModel(id: '1', name: 'Updated Electronics');

      await dao.insertItemCategories([category1]);
      await dao.insertItemCategories([category2]);
      final result = await dao.getAll();

      expect(result.length, 1);
      expect(result[0].name, 'Updated Electronics');
    });
  });
}

