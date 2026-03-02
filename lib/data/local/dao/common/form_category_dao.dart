import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/data/models/form_category_model.dart';

/// DAO for FormCategory local persistence.
class FormCategoryDao {
  final Database db;
  FormCategoryDao(this.db);

  Future<void> insertFormCategories(List<FormCategoryModel> forms) async {
    Batch batch = db.batch();
    for (var form in forms) {
      batch.insert(
        'a_tblFormCategory',
        form.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<FormCategoryModel>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query('a_tblFormCategory');
    return maps.map((m) => FormCategoryModel.fromJson(m)).toList();
  }

  Future<FormCategoryModel?> getById(String id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblFormCategory',
      where: 'FormCategoryID = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return FormCategoryModel.fromJson(maps.first);
    return null;
  }

  Future<bool> hasData() async {
    final List<Map<String, dynamic>> maps = await db.query('a_tblFormCategory', limit: 1);
    return maps.isNotEmpty;
  }

  Future<void> deleteAll() async => await db.delete('a_tblFormCategory');
}

