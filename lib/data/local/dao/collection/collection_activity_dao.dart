import 'package:sqflite/sqflite.dart';

/// An office activity recorded on the device: Deposit, CWT Pick-up or
/// Reconciliation (process flow §7.5). Persisted so it survives an app restart
/// and can be uploaded at end of day.
class CollectionActivityRecord {
  final int? id;
  /// 'Deposit' | 'CWT Pick-up' | 'Reconciliation'
  final String type;
  final String clientId;
  final String clientName;
  final String date;
  final double amount;
  final String? bankName;
  final String? checkNumber;
  final String remarks;
  /// Invoices covered (deposited / reconciled).
  final List<String> documentIds;
  final String collectorName;
  /// Stable key used as the upload queue ItemId (unique per activity).
  final String localRef;

  const CollectionActivityRecord({
    this.id,
    required this.type,
    required this.clientId,
    required this.clientName,
    required this.date,
    this.amount = 0,
    this.bankName,
    this.checkNumber,
    this.remarks = '',
    this.documentIds = const [],
    required this.collectorName,
    required this.localRef,
  });

  CollectionActivityRecord copyWith({int? id}) => CollectionActivityRecord(
        id: id ?? this.id,
        type: type,
        clientId: clientId,
        clientName: clientName,
        date: date,
        amount: amount,
        bankName: bankName,
        checkNumber: checkNumber,
        remarks: remarks,
        documentIds: documentIds,
        collectorName: collectorName,
        localRef: localRef,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'type': type,
        'clientId': clientId,
        'clientName': clientName,
        'date': date,
        'amount': amount,
        'bankName': bankName,
        'checkNumber': checkNumber,
        'remarks': remarks,
        'documentIds': documentIds.join(','),
        'collectorName': collectorName,
        'localRef': localRef,
      };

  factory CollectionActivityRecord.fromJson(Map<String, dynamic> m) =>
      CollectionActivityRecord(
        id: m['id'] as int?,
        type: (m['type'] ?? '').toString(),
        clientId: (m['clientId'] ?? '').toString(),
        clientName: (m['clientName'] ?? '').toString(),
        date: (m['date'] ?? '').toString(),
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        bankName: m['bankName']?.toString(),
        checkNumber: m['checkNumber']?.toString(),
        remarks: (m['remarks'] ?? '').toString(),
        documentIds: ((m['documentIds'] ?? '') as String)
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList(),
        collectorName: (m['collectorName'] ?? '').toString(),
        localRef: (m['localRef'] ?? '').toString(),
      );
}

class CollectionActivityDao {
  final Database db;
  CollectionActivityDao(this.db);

  static const table = 'a_tblCollectionActivity';

  Future<int> insert(CollectionActivityRecord record) =>
      db.insert(table, record.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<CollectionActivityRecord>> getAll() async {
    final rows = await db.query(table, orderBy: 'date DESC, id DESC');
    return rows.map(CollectionActivityRecord.fromJson).toList();
  }

  /// Replace everything (used after a server download).
  Future<void> replaceAll(List<CollectionActivityRecord> records) async {
    final batch = db.batch();
    batch.delete(table);
    for (final r in records) {
      batch.insert(table, r.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> clear() => db.delete(table);
}
