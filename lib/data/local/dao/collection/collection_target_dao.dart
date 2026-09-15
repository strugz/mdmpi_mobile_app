import 'package:sqflite/sqflite.dart';

/// The collector's monthly collection target (process flow §7.7), keyed by
/// `yyyy-MM`. Previously held only in memory and lost on restart.
class CollectionTargetDao {
  final Database db;
  CollectionTargetDao(this.db);

  static const table = 'a_tblCollectionTarget';

  Future<double?> get(String yearMonth) async {
    final rows = await db.query(
      table,
      columns: ['amount'],
      where: 'yearMonth = ?',
      whereArgs: [yearMonth],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (rows.first['amount'] as num?)?.toDouble();
  }

  Future<void> set(String yearMonth, double amount) => db.insert(
        table,
        {'yearMonth': yearMonth, 'amount': amount},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<Map<String, double>> getAll() async {
    final rows = await db.query(table);
    return {
      for (final r in rows)
        (r['yearMonth'] ?? '').toString(): (r['amount'] as num?)?.toDouble() ?? 0,
    };
  }

  /// Replace everything (used after a server download).
  Future<void> replaceAll(Map<String, double> targets) async {
    final batch = db.batch();
    batch.delete(table);
    targets.forEach((ym, amount) {
      batch.insert(table, {'yearMonth': ym, 'amount': amount},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await batch.commit(noResult: true);
  }

  Future<void> clear() => db.delete(table);
}
