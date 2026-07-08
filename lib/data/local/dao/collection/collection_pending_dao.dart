import 'package:sqflite/sqflite.dart';

/// Model for a pending change awaiting sync to server.
class PendingChange {
  final int? id;
  final String operation; // 'CREATE', 'UPDATE', 'CLAIM', 'SAVE_ACTIVITY'
  final String payload; // JSON string
  final String? itemId;
  final String createdAt;
  final int retryCount;
  final String? lastRetryAt;

  PendingChange({
    this.id,
    required this.operation,
    required this.payload,
    this.itemId,
    required this.createdAt,
    this.retryCount = 0,
    this.lastRetryAt,
  });

  /// Convert to JSON for database storage.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'operation': operation,
      'payload': payload,
      'itemId': itemId,
      'createdAt': createdAt,
      'retryCount': retryCount,
      'lastRetryAt': lastRetryAt,
    };
  }

  /// Create from database row.
  factory PendingChange.fromJson(Map<String, dynamic> json) {
    return PendingChange(
      id: json['id'],
      operation: json['operation'],
      payload: json['payload'],
      itemId: json['itemId'],
      createdAt: json['createdAt'],
      retryCount: json['retryCount'] ?? 0,
      lastRetryAt: json['lastRetryAt'],
    );
  }

  /// Copy with method for creating modified instances.
  PendingChange copyWith({
    int? id,
    String? operation,
    String? payload,
    String? itemId,
    String? createdAt,
    int? retryCount,
    String? lastRetryAt,
  }) {
    return PendingChange(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      itemId: itemId ?? this.itemId,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }
}

/// DAO for pending collection changes awaiting server sync.
class CollectionPendingDao {
  final Database db;

  CollectionPendingDao(this.db);

  /// Get all pending changes.
  Future<List<PendingChange>> getPendingChanges() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblCollectionPending',
      orderBy: 'createdAt ASC',
    );

    return maps.map((m) => PendingChange.fromJson(m)).toList();
  }

  /// Get pending changes for a specific item.
  Future<List<PendingChange>> getPendingChangesForItem(String itemId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblCollectionPending',
      where: 'itemId = ?',
      whereArgs: [itemId],
      orderBy: 'createdAt ASC',
    );

    return maps.map((m) => PendingChange.fromJson(m)).toList();
  }

  /// Add a pending change.
  Future<int> addPendingChange(PendingChange change) async {
    return await db.insert(
      'a_tblCollectionPending',
      change.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update a pending change (e.g., increment retry count).
  Future<void> updatePendingChange(PendingChange change) async {
    await db.update(
      'a_tblCollectionPending',
      change.toJson(),
      where: 'id = ?',
      whereArgs: [change.id],
    );
  }

  /// Remove a pending change (after successful sync).
  Future<void> removePendingChange(int id) async {
    await db.delete(
      'a_tblCollectionPending',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Remove all pending changes for an item.
  Future<void> removePendingChangesForItem(String itemId) async {
    await db.delete(
      'a_tblCollectionPending',
      where: 'itemId = ?',
      whereArgs: [itemId],
    );
  }

  /// Clear all pending changes.
  Future<void> clearAllPendingChanges() async {
    await db.delete('a_tblCollectionPending');
  }

  /// Get count of pending changes.
  Future<int> getPendingChangeCount() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM a_tblCollectionPending',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Check if there are any pending changes.
  Future<bool> hasPendingChanges() async {
    final count = await getPendingChangeCount();
    return count > 0;
  }
}

