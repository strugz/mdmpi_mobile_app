import 'package:sqflite/sqflite.dart';

/// One Actual Collection entry as the office posted it on the Collection web:
/// one deposit slip / OR reference (revisions list item 11). It is the team's
/// figure, not a collector's: every collector's download carries the same list.
///
/// A copy of what the workspace download returned. The server's list is the
/// record; the device never edits these.
class CollectionActualRecord {
  final int actualId;

  /// yyyy-MM-dd
  final String collectionDate;
  final double amount;
  final String referenceNo;
  final String remarks;
  final String postedBy;
  final String createdAt;
  final String? updatedAt;
  final String? updatedBy;

  const CollectionActualRecord({
    required this.actualId,
    required this.collectionDate,
    required this.amount,
    required this.referenceNo,
    this.remarks = '',
    this.postedBy = '',
    this.createdAt = '',
    this.updatedAt,
    this.updatedBy,
  });

  Map<String, Object?> toRow() => {
        'actualId': actualId,
        'collectionDate': collectionDate,
        'amount': amount,
        'referenceNo': referenceNo,
        'remarks': remarks,
        'postedBy': postedBy,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'updatedBy': updatedBy,
      };

  factory CollectionActualRecord.fromRow(Map<String, Object?> r) {
    String s(String k) => (r[k] ?? '').toString();
    return CollectionActualRecord(
      actualId: (r['actualId'] as num?)?.toInt() ?? 0,
      collectionDate: s('collectionDate'),
      amount: (r['amount'] as num?)?.toDouble() ?? 0,
      referenceNo: s('referenceNo'),
      remarks: s('remarks'),
      postedBy: s('postedBy'),
      createdAt: s('createdAt'),
      updatedAt: r['updatedAt']?.toString(),
      updatedBy: r['updatedBy']?.toString(),
    );
  }
}

/// The team's posted Actual Collection, as the last download said.
class CollectionActualDao {
  CollectionActualDao(this.db);

  final Database db;

  static const table = 'a_tblCollectionActual';

  static const _newestFirst = 'collectionDate DESC, createdAt DESC, actualId DESC';

  Future<List<CollectionActualRecord>> getAll() async {
    final rows = await db.query(table, orderBy: _newestFirst);
    return rows.map(CollectionActualRecord.fromRow).toList();
  }

  /// Entries whose collectionDate falls in [yearMonth] (yyyy-MM), newest
  /// first.
  Future<List<CollectionActualRecord>> forMonth(String yearMonth) async {
    final rows = await db.query(
      table,
      where: 'collectionDate LIKE ?',
      whereArgs: ['$yearMonth-%'],
      orderBy: _newestFirst,
    );
    return rows.map(CollectionActualRecord.fromRow).toList();
  }

  /// Replace everything with the server's list. Unlike the client registry an
  /// empty list IS written: the server's list is authoritative, and an entry
  /// the office deleted must leave the phone too. (The caller skips this
  /// entirely when an older server did not send the list at all.)
  Future<void> replaceAll(List<CollectionActualRecord> records) async {
    await db.transaction((txn) async {
      await txn.delete(table);
      final batch = txn.batch();
      for (final r in records) {
        batch.insert(table, r.toRow(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<int> count() async =>
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $table')) ??
      0;
}
