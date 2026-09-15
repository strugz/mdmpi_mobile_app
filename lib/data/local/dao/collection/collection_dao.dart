import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';

/// DAO for collection item local database operations.
/// Handles CRUD operations and syncing with collection items.
class CollectionDao {
  final Database db;

  CollectionDao(this.db);

  /// Fetch all collection items from local database.
  Future<List<CollectionItemModel>> getCollectionItems() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblCollectionItems',
      orderBy: 'updatedAt DESC',
    );

    if (maps.isEmpty) return [];

    List<CollectionItemModel> items = [];
    for (var map in maps) {
      final item = CollectionItemModel.fromJson(_dbJsonToApiJson(map));

      // Load history for this item
      final history = await _getItemHistory(item.id);
      final itemWithHistory = item.copyWith(history: history);

      items.add(itemWithHistory);
    }

    return items;
  }

  /// Get a single collection item by ID.
  Future<CollectionItemModel?> getCollectionItemById(String id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblCollectionItems',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    final item = CollectionItemModel.fromJson(_dbJsonToApiJson(map));

    // Load history
    final history = await _getItemHistory(id);
    return item.copyWith(history: history);
  }

  /// Get history records for a specific item.
  Future<List<CollectionHistoryModel>> _getItemHistory(String itemId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblCollectionHistory',
      where: 'itemId = ?',
      whereArgs: [itemId],
      orderBy: 'date DESC',
    );

    return maps.map((m) => CollectionHistoryModel.fromJson(_historyDbJsonToApiJson(m))).toList();
  }

  /// Insert a single collection item.
  Future<int> insertCollectionItem(CollectionItemModel item) async {
    final dbJson = _apiJsonToDbJson(item.toJson());

    try {
      await db.insert(
        'a_tblCollectionItems',
        dbJson,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Replace history records (see insertCollectionItems).
      await db.delete(
        'a_tblCollectionHistory',
        where: 'itemId = ?',
        whereArgs: [item.id],
      );
      if (item.history.isNotEmpty) {
        for (var history in item.history) {
          await _insertHistoryRecord(item.id, history);
        }
      }

      return 1;
    } catch (e) {
      return 0;
    }
  }

  /// Insert multiple collection items in batch.
  Future<void> insertCollectionItems(List<CollectionItemModel> items) async {
    Batch batch = db.batch();

    for (var item in items) {
      final dbJson = _apiJsonToDbJson(item.toJson());
      batch.insert(
        'a_tblCollectionItems',
        dbJson,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // History is replaced together with its item. sqflite does not enable
      // foreign keys, so the ON DELETE CASCADE on this table never fires and a
      // re-download used to append a second copy of every history row.
      batch.delete(
        'a_tblCollectionHistory',
        where: 'itemId = ?',
        whereArgs: [item.id],
      );

      // Insert history records
      if (item.history.isNotEmpty) {
        for (var history in item.history) {
          batch.insert(
            'a_tblCollectionHistory',
            {
              'itemId': item.id,
              'date': history.date,
              'collectorName': history.collectorName,
              'status': history.status,
              'remarks': history.remarks,
              'totalCollected': history.totalCollected,
              'bankName': history.bankName,
              'checkNumber': history.checkNumber,
              'checkDate': history.checkDate,
              'purposeOfVisit': history.purposeOfVisit,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    }

    await batch.commit(noResult: true);
  }

  /// Insert a single history record.
  Future<int> _insertHistoryRecord(String itemId, CollectionHistoryModel history) async {
    return await db.insert(
      'a_tblCollectionHistory',
      {
        'itemId': itemId,
        'date': history.date,
        'collectorName': history.collectorName,
        'status': history.status,
        'remarks': history.remarks,
        'totalCollected': history.totalCollected,
        'bankName': history.bankName,
        'checkNumber': history.checkNumber,
        'checkDate': history.checkDate,
        'purposeOfVisit': history.purposeOfVisit,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing collection item.
  Future<void> updateCollectionItem(CollectionItemModel item) async {
    final dbJson = _apiJsonToDbJson(item.toJson());

    await db.update(
      'a_tblCollectionItems',
      dbJson,
      where: 'id = ?',
      whereArgs: [item.id],
    );

    // Clear old history and insert new ones
    await db.delete(
      'a_tblCollectionHistory',
      where: 'itemId = ?',
      whereArgs: [item.id],
    );

    if (item.history.isNotEmpty) {
      for (var history in item.history) {
        await _insertHistoryRecord(item.id, history);
      }
    }
  }

  /// Check if collection items table has any records.
  Future<bool> hasCollectionItems() async {
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM a_tblCollectionItems',
    );
    if (result.isNotEmpty) {
      final count = result.first['count'] as int?;
      return count != null && count > 0;
    }
    return false;
  }

  /// Delete all collection items (for refresh/sync).
  Future<void> deleteAllCollectionItems() async {
    // Explicit: the FK cascade is inert without PRAGMA foreign_keys.
    await db.delete('a_tblCollectionHistory');
    await db.delete('a_tblCollectionItems');
  }

  /// Number of history rows (all items).
  Future<int> getHistoryRowCount() async {
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM a_tblCollectionHistory');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get count of collection items.
  Future<int> getCollectionItemCount() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM a_tblCollectionItems',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // ========================================================================
  // Helper methods for JSON conversion
  // ========================================================================

  /// Convert API JSON to database JSON (add timestamps if missing).
  ///
  /// The nested `Client` object is serialized by [ClientModel.toJson] with ACCMST
  /// keys (ACCMID/ACCMNM/ACCMAD/...); read those, tolerating the plain
  /// id/name/address variants a raw API response might use.
  Map<String, dynamic> _apiJsonToDbJson(Map<String, dynamic> apiJson) {
    final now = DateTime.now().toIso8601String();
    final client = apiJson['Client'] as Map<String, dynamic>?;
    return {
      'id': apiJson['id'],
      'clientId': client?['ACCMID'] ?? client?['id'] ?? '',
      'clientName': client?['ACCMNM'] ?? client?['name'] ?? '',
      'clientAddress': client?['ACCMAD'] ?? client?['address'] ?? '',
      'documentReferences': (apiJson['DocumentReferences'] as List?)?.join(',') ?? '',
      'bankName': apiJson['BankName'] ?? '',
      'toBeCollected': apiJson['ToBeCollected'] ?? 0.0,
      'totalCollected': apiJson['TotalCollected'] ?? 0.0,
      'remarks': apiJson['Remarks'] ?? '',
      'documentDate': apiJson['DocumentDate'] ?? '',
      'bpCode': apiJson['BPCode'] ?? '',
      'postingDate': apiJson['PostingDate'] ?? '',
      'dueDate': apiJson['DueDate'] ?? '',
      'status': apiJson['Status'] ?? '',
      'lastOutcome': apiJson['LastOutcome'],
      'assignedAt': apiJson['AssignedAt'] ?? '',
      'collectorName': apiJson['CollectorName'] ?? '',
      'createdAt': apiJson['CreatedAt'] ?? now,
      'updatedAt': apiJson['UpdatedAt'] ?? now,
    };
  }

  /// Convert database JSON back to API JSON format.
  ///
  /// Emit the nested `Client` with ACCMST keys so [ClientModel.fromJson] maps
  /// every field (including the id via ACCMID) correctly.
  Map<String, dynamic> _dbJsonToApiJson(Map<String, dynamic> dbJson) {
    return {
      'id': dbJson['id'],
      'Client': {
        'ACCMID': dbJson['clientId'],
        'ACCMSC': dbJson['bpCode'] ?? '',
        'ACCMNM': dbJson['clientName'],
        'ACCMAD': dbJson['clientAddress'],
        'ACCMPH': '',
        'ACCMEM': '',
      },
      'DocumentReferences': (dbJson['documentReferences'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      'BankName': dbJson['bankName'],
      'ToBeCollected': dbJson['toBeCollected'],
      'TotalCollected': dbJson['totalCollected'],
      'Remarks': dbJson['remarks'],
      'DocumentDate': dbJson['documentDate'],
      'BPCode': dbJson['bpCode'],
      'PostingDate': dbJson['postingDate'],
      'DueDate': dbJson['dueDate'],
      'Status': dbJson['status'],
      'LastOutcome': dbJson['lastOutcome'],
      'AssignedAt': dbJson['assignedAt'],
      'CollectorName': dbJson['collectorName'],
    };
  }

  /// Convert history DB JSON to API JSON.
  Map<String, dynamic> _historyDbJsonToApiJson(Map<String, dynamic> dbJson) {
    return {
      'Date': dbJson['date'],
      'CollectorName': dbJson['collectorName'],
      'Status': dbJson['status'],
      'Remarks': dbJson['remarks'],
      'TotalCollected': dbJson['totalCollected'],
      'BankName': dbJson['bankName'],
      'CheckNumber': dbJson['checkNumber'],
      'CheckDate': dbJson['checkDate'],
      'PurposeOfVisit': dbJson['purposeOfVisit'],
    };
  }
}

