import 'package:sqflite/sqflite.dart';

/// Account-level history: the reason an account was released back to the bucket
/// (Deferred Engagement, process flow §7.4 B). Not tied to a single invoice.
class CollectionAccountHistoryRecord {
  final int? id;
  final String clientId;
  final String date;
  /// Follow Up | Customer Unavailable | Refused to Pay | Others
  final String reason;
  final String remarks;
  final String collectorName;

  const CollectionAccountHistoryRecord({
    this.id,
    required this.clientId,
    required this.date,
    required this.reason,
    this.remarks = '',
    required this.collectorName,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'clientId': clientId,
        'date': date,
        'reason': reason,
        'remarks': remarks,
        'collectorName': collectorName,
      };

  factory CollectionAccountHistoryRecord.fromJson(Map<String, dynamic> m) =>
      CollectionAccountHistoryRecord(
        id: m['id'] as int?,
        clientId: (m['clientId'] ?? '').toString(),
        date: (m['date'] ?? '').toString(),
        reason: (m['reason'] ?? '').toString(),
        remarks: (m['remarks'] ?? '').toString(),
        collectorName: (m['collectorName'] ?? '').toString(),
      );
}

class CollectionAccountHistoryDao {
  final Database db;
  CollectionAccountHistoryDao(this.db);

  static const table = 'a_tblCollectionAccountHistory';

  Future<int> insert(CollectionAccountHistoryRecord record) =>
      db.insert(table, record.toJson());

  Future<List<CollectionAccountHistoryRecord>> getAll() async {
    final rows = await db.query(table, orderBy: 'date DESC, id DESC');
    return rows.map(CollectionAccountHistoryRecord.fromJson).toList();
  }

  /// Replace everything (used after a server download).
  Future<void> replaceAll(List<CollectionAccountHistoryRecord> records) async {
    final batch = db.batch();
    batch.delete(table);
    for (final r in records) {
      batch.insert(table, r.toJson());
    }
    await batch.commit(noResult: true);
  }

  Future<void> clear() => db.delete(table);
}
