import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/backload_model.dart';

/// Data-access object for the `a_tblRequestBackload` table.
class BackLoadDao {
  final Database db;
  BackLoadDao(this.db);

  /// Insert a single BackLoad record.
  Future<int> insert(BackLoadModel model) async {
    return await db.insert(
      'a_tblRequestBackload',
      model.toDbJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert a batch of BackLoad records (used during app init sync).
  Future<void> insertAll(List<BackLoadModel> models) async {
    final batch = db.batch();
    for (final m in models) {
      batch.insert(
        'a_tblRequestBackload',
        m.toDbJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Get all BackLoad entries for a given request, ordered newest first.
  Future<List<BackLoadModel>> getByRequestId(String requestId) async {
    final rows = await db.query(
      'a_tblRequestBackload',
      where: 'RequestID = ?',
      whereArgs: [requestId],
      orderBy: 'DateReported DESC',
    );
    return rows.map((r) => BackLoadModel.fromDbJson(r)).toList();
  }

  /// Get the most recent BackLoad entry for a request, or null.
  Future<BackLoadModel?> getLatestByRequestId(String requestId) async {
    final rows = await db.query(
      'a_tblRequestBackload',
      where: 'RequestID = ?',
      whereArgs: [requestId],
      orderBy: 'DateReported DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BackLoadModel.fromDbJson(rows.first);
  }

  /// Get all BackLoad records.
  Future<List<BackLoadModel>> getAll() async {
    final rows = await db.query(
      'a_tblRequestBackload',
      orderBy: 'DateReported DESC',
    );
    return rows.map((r) => BackLoadModel.fromDbJson(r)).toList();
  }

  /// Delete all BackLoad records (for refresh).
  Future<int> deleteAll() async {
    return await db.delete('a_tblRequestBackload');
  }
}

