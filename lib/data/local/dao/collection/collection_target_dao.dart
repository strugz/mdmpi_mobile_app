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

  // ---- per area (update checklist items 3 and 5) ----------------------------

  /// The office's targets area by area: (yearMonth, area) -> amount, area ''
  /// being one set for the team as a whole. [table] keeps the month's sum.
  static const areaTable = 'a_tblCollectionAreaTarget';

  /// [area]'s target for [yearMonth]; null when none is set.
  Future<double?> getArea(String yearMonth, String area) async {
    final rows = await db.query(
      areaTable,
      columns: ['amount'],
      where: 'yearMonth = ? AND area = ?',
      whereArgs: [yearMonth, area.trim().toUpperCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (rows.first['amount'] as num?)?.toDouble();
  }

  /// Replace every area target with the server's (used after a download).
  Future<void> replaceAreas(List<CollectionAreaTarget> targets) async {
    await db.transaction((txn) async {
      await txn.delete(areaTable);
      final batch = txn.batch();
      for (final t in targets) {
        batch.insert(
          areaTable,
          {
            'yearMonth': t.yearMonth,
            'area': t.area,
            'amount': t.amount,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }
}

/// One month's target for one area ('' = the team as a whole), as the office
/// set it on the admin web.
class CollectionAreaTarget {
  final String yearMonth;
  final String area;
  final double amount;

  const CollectionAreaTarget({
    required this.yearMonth,
    required this.area,
    required this.amount,
  });
}
