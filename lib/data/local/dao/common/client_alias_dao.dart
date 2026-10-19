import 'package:sqflite/sqflite.dart';

/// `CLIENT_ALIAS_`: a normalized scanned customer name → the client
/// (`ACCMID`) the user confirmed for it (Standard Delivery one-scan, plan
/// §4.4 "Learning").
class ClientAliasDao {
  ClientAliasDao(this.db);

  final Database db;

  static const String table = 'CLIENT_ALIAS_';

  /// The client confirmed for [alias], or null.
  Future<String?> findByAlias(String alias) async {
    final rows = await db.query(table,
        columns: ['ACCMID'], where: 'ALIAS = ?', whereArgs: [alias], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['ACCMID']?.toString();
  }

  /// Saves [alias] → [clientId], replacing an earlier client for it.
  Future<void> upsert(String alias, String clientId, {DateTime? at}) async {
    await db.insert(
      table,
      {
        'ALIAS': alias,
        'ACCMID': clientId,
        'UPDATED_AT': (at ?? DateTime.now()).toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteAlias(String alias) =>
      db.delete(table, where: 'ALIAS = ?', whereArgs: [alias]);

  /// Removes every alias pointing at [clientId] (a client gone after a sync).
  Future<int> deleteForClient(String clientId) =>
      db.delete(table, where: 'ACCMID = ?', whereArgs: [clientId]);
}
