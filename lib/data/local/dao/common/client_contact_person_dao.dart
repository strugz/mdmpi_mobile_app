import 'package:sqflite/sqflite.dart';
import '../../../models/client_contact_person_model.dart';

/// DAO for managing client contact person autocomplete data.
class ClientContactPersonDao {
  final Database db;

  ClientContactPersonDao(this.db);

  static const String tableName = 'a_tblClientContactPerson';

  /// Create the table schema
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        usageCount INTEGER DEFAULT 1,
        lastUsedAt TEXT NOT NULL
      )
    ''');
  }

  /// Insert or update a contact person name.
  /// If the name exists, increment usage count and update lastUsedAt.
  Future<int> upsert(String name) async {
    if (name.trim().isEmpty) return 0;

    final normalizedName = name.trim();
    final now = DateTime.now().toIso8601String();

    // Check if the name already exists
    final existing = await db.query(
      tableName,
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [normalizedName],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Update existing record: increment usage count and update timestamp
      final id = existing.first['id'] as int;
      final currentCount = existing.first['usageCount'] as int? ?? 1;

      return await db.update(
        tableName,
        {
          'usageCount': currentCount + 1,
          'lastUsedAt': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      // Insert new record
      return await db.insert(
        tableName,
        {
          'name': normalizedName,
          'usageCount': 1,
          'lastUsedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Search for contact persons by name prefix.
  /// Returns results ordered by usage count (descending) and lastUsedAt (descending).
  Future<List<ClientContactPersonModel>> search(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) {
      // Return most frequently used if no query
      return await getMostUsed(limit: limit);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'LOWER(name) LIKE LOWER(?)',
      whereArgs: ['%${query.trim()}%'],
      orderBy: 'usageCount DESC, lastUsedAt DESC',
      limit: limit,
    );

    return maps.map((map) => ClientContactPersonModel.fromJson(map)).toList();
  }

  /// Get most frequently used contact persons
  Future<List<ClientContactPersonModel>> getMostUsed({int limit = 10}) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'usageCount DESC, lastUsedAt DESC',
      limit: limit,
    );

    return maps.map((map) => ClientContactPersonModel.fromJson(map)).toList();
  }

  /// Get all contact persons
  Future<List<ClientContactPersonModel>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'name ASC',
    );

    return maps.map((map) => ClientContactPersonModel.fromJson(map)).toList();
  }

  /// Delete a contact person by ID
  Future<int> delete(int id) async {
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all contact persons
  Future<int> deleteAll() async {
    return await db.delete(tableName);
  }
}

