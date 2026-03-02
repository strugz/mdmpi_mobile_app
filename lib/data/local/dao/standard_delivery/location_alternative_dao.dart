import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/location_alternative_model.dart';

/// Data Access Object for location alternatives (corrected delivery locations)
class LocationAlternativeDAO {
  static const String _tableName = 'a_tblLocationAlternative';

  /// Create the location alternatives table
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        ID INTEGER PRIMARY KEY AUTOINCREMENT,
        RequestID INTEGER NOT NULL,
        Latitude REAL NOT NULL,
        Longitude REAL NOT NULL,
        Address TEXT NOT NULL,
        CreatedAt TEXT NOT NULL,
        Notes TEXT,
        FOREIGN KEY (RequestID) REFERENCES a_tblRequest (RequestID) ON DELETE CASCADE
      )
    ''');
  }

  /// Insert a new location alternative
  static Future<int> insert(Database db, LocationAlternativeModel model) async {
    return await db.insert(
      _tableName,
      model.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all location alternatives for a request
  static Future<List<LocationAlternativeModel>> getByRequestId(
    Database db,
    int requestId,
  ) async {
    final maps = await db.query(
      _tableName,
      where: 'RequestID = ?',
      whereArgs: [requestId],
      orderBy: 'CreatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return LocationAlternativeModel.fromJson(maps[i]);
    });
  }

  /// Get the latest location alternative for a request
  static Future<LocationAlternativeModel?> getLatestByRequestId(
    Database db,
    int requestId,
  ) async {
    final maps = await db.query(
      _tableName,
      where: 'RequestID = ?',
      whereArgs: [requestId],
      orderBy: 'CreatedAt DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return LocationAlternativeModel.fromJson(maps.first);
  }

  /// Delete all location alternatives for a request
  static Future<int> deleteByRequestId(Database db, int requestId) async {
    return await db.delete(
      _tableName,
      where: 'RequestID = ?',
      whereArgs: [requestId],
    );
  }

  /// Delete a specific location alternative
  static Future<int> deleteById(Database db, int id) async {
    return await db.delete(
      _tableName,
      where: 'ID = ?',
      whereArgs: [id],
    );
  }

  /// Count location alternatives for a request
  static Future<int> countByRequestId(Database db, int requestId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE RequestID = ?',
      [requestId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
