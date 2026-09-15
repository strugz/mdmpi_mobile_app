import 'package:sqflite/sqflite.dart';

/// An Advanced Payment: money received before an invoice exists (process flow
/// §7.5). [externalRef] is the device-generated id (AP-<millis>) that the server
/// stores as `payment.externalref`, so the later assign can reference it across
/// uploads without a server-id round-trip.
class CollectionAdvanceRecord {
  final String externalRef;
  final String clientId;
  final String clientName;
  final double amount;
  final String date;
  final String remarks;
  final String collectorName;
  /// Set once assigned to an invoice; null = still waiting under Advanced Payment.
  final String? assignedDocumentId;

  const CollectionAdvanceRecord({
    required this.externalRef,
    required this.clientId,
    required this.clientName,
    required this.amount,
    required this.date,
    this.remarks = '',
    required this.collectorName,
    this.assignedDocumentId,
  });

  bool get isUnassigned => assignedDocumentId == null || assignedDocumentId!.isEmpty;

  Map<String, dynamic> toJson() => {
        'externalRef': externalRef,
        'clientId': clientId,
        'clientName': clientName,
        'amount': amount,
        'date': date,
        'remarks': remarks,
        'collectorName': collectorName,
        'assignedDocumentId': assignedDocumentId,
      };

  factory CollectionAdvanceRecord.fromJson(Map<String, dynamic> m) =>
      CollectionAdvanceRecord(
        externalRef: (m['externalRef'] ?? '').toString(),
        clientId: (m['clientId'] ?? '').toString(),
        clientName: (m['clientName'] ?? '').toString(),
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        date: (m['date'] ?? '').toString(),
        remarks: (m['remarks'] ?? '').toString(),
        collectorName: (m['collectorName'] ?? '').toString(),
        assignedDocumentId: m['assignedDocumentId']?.toString(),
      );
}

class CollectionAdvanceDao {
  final Database db;
  CollectionAdvanceDao(this.db);

  static const table = 'a_tblCollectionAdvance';

  Future<void> upsert(CollectionAdvanceRecord record) =>
      db.insert(table, record.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<CollectionAdvanceRecord>> getAll() async {
    final rows = await db.query(table, orderBy: 'date DESC');
    return rows.map(CollectionAdvanceRecord.fromJson).toList();
  }

  Future<List<CollectionAdvanceRecord>> getUnassigned() async {
    final rows = await db.query(
      table,
      where: "assignedDocumentId IS NULL OR assignedDocumentId = ''",
      orderBy: 'date DESC',
    );
    return rows.map(CollectionAdvanceRecord.fromJson).toList();
  }

  Future<void> markAssigned(String externalRef, String documentId) => db.update(
        table,
        {'assignedDocumentId': documentId},
        where: 'externalRef = ?',
        whereArgs: [externalRef],
      );

  /// Replace everything (used after a server download).
  Future<void> replaceAll(List<CollectionAdvanceRecord> records) async {
    final batch = db.batch();
    batch.delete(table);
    for (final r in records) {
      batch.insert(table, r.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> clear() => db.delete(table);
}
