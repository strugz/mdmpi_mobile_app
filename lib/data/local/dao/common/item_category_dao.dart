import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/data/models/item_category_model.dart';

/// DAO for ItemCategory local persistence.
class ItemCategoryDao {
  final Database db;
  ItemCategoryDao(this.db);

  Future<void> insertItemCategories(List<ItemCategoryModel> items) async {
    Batch batch = db.batch();
    for (var item in items) {
      batch.insert(
        'a_tblItemCategory',
        item.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ItemCategoryModel>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query('a_tblItemCategory');
    return maps.map((m) => ItemCategoryModel.fromJson(m)).toList();
  }

  Future<ItemCategoryModel?> getById(String id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblItemCategory',
      where: 'ItemCategoryID = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return ItemCategoryModel.fromJson(maps.first);
    return null;
  }

  Future<bool> hasData() async {
    final List<Map<String, dynamic>> maps =
        await db.query('a_tblItemCategory', limit: 1);
    return maps.isNotEmpty;
  }

  Future<void> deleteAll() async => await db.delete('a_tblItemCategory');
}
