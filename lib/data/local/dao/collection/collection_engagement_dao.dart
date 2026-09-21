import 'package:sqflite/sqflite.dart';

/// One engagement the collector recorded, kept for good.
///
/// The sibling records (`CollectionActivityRecord`, `CollectionHistoryModel`)
/// describe what the server currently believes. This one describes what the
/// collector did, and nothing in the download path may rewrite it. See the
/// table comment in `db_schema.dart` for why that distinction exists.
class CollectionEngagementRecord {
  /// 'kind|subjectId|engagedAt'. See [buildLocalRef].
  final String localRef;

  /// Who did the work, as a stable key. Filtered on, never displayed.
  final String collectorCode;

  /// Who did the work, as a person reads it. Displayed, never filtered on.
  final String collectorName;

  /// 'INVOICE' | 'ACCOUNT' | 'OFFICE' | 'ADVANCE'
  final String kind;

  final String itemId;
  final String clientId;
  final String clientName;

  /// Local ISO-8601, no zone designator: 2026-09-17T16:43:37.123456
  final String engagedAt;

  /// The local calendar day of [engagedAt], as yyyy-MM-dd.
  final String engagedOn;

  final String status;
  final String remarks;
  final double amount;
  final String? bankName;
  final String? checkNumber;
  final String? checkDate;
  final String? purposeOfVisit;
  final List<String> documentIds;
  final String createdAt;

  /// [sourceLocal] or [sourceServer]. See the column comment in db_schema.
  final String source;

  /// Recorded on this device. Permanent.
  static const String sourceLocal = 'LOCAL';

  /// Copied from the server's own account of this collector's history by
  /// [CollectionRepository.backfillOwnEngagements]. Refreshed with the
  /// download rather than kept.
  static const String sourceServer = 'SERVER';

  bool get isLocal => source != sourceServer;

  const CollectionEngagementRecord({
    required this.localRef,
    required this.collectorCode,
    this.collectorName = '',
    required this.kind,
    this.itemId = '',
    this.clientId = '',
    this.clientName = '',
    required this.engagedAt,
    required this.engagedOn,
    this.status = '',
    this.remarks = '',
    this.amount = 0,
    this.bankName,
    this.checkNumber,
    this.checkDate,
    this.purposeOfVisit,
    this.documentIds = const [],
    required this.createdAt,
    this.source = sourceLocal,
  });

  /// The key that makes a re-save idempotent.
  ///
  /// Derived from the engagement itself, so saving the same one twice — a
  /// retry, a re-sync, a double tap, a second run of the backfill — replaces
  /// one row instead of adding a second. This only holds while [engagedAt] is
  /// stamped once per engagement and threaded through, which is why the
  /// repository is the only writer.
  static String buildLocalRef({
    required String kind,
    required String subjectId,
    required String engagedAt,
  }) =>
      '$kind|$subjectId|$engagedAt';

  Map<String, dynamic> toJson() => {
        'localRef': localRef,
        'collectorCode': collectorCode,
        'collectorName': collectorName,
        'kind': kind,
        'itemId': itemId,
        'clientId': clientId,
        'clientName': clientName,
        'engagedAt': engagedAt,
        'engagedOn': engagedOn,
        'status': status,
        'remarks': remarks,
        'amount': amount,
        'bankName': bankName,
        'checkNumber': checkNumber,
        'checkDate': checkDate,
        'purposeOfVisit': purposeOfVisit,
        'documentIds': documentIds.join(','),
        'createdAt': createdAt,
        'source': source,
      };

  factory CollectionEngagementRecord.fromJson(Map<String, dynamic> m) =>
      CollectionEngagementRecord(
        localRef: (m['localRef'] ?? '').toString(),
        collectorCode: (m['collectorCode'] ?? '').toString(),
        collectorName: (m['collectorName'] ?? '').toString(),
        kind: (m['kind'] ?? '').toString(),
        itemId: (m['itemId'] ?? '').toString(),
        clientId: (m['clientId'] ?? '').toString(),
        clientName: (m['clientName'] ?? '').toString(),
        engagedAt: (m['engagedAt'] ?? '').toString(),
        engagedOn: (m['engagedOn'] ?? '').toString(),
        status: (m['status'] ?? '').toString(),
        remarks: (m['remarks'] ?? '').toString(),
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        bankName: m['bankName']?.toString(),
        checkNumber: m['checkNumber']?.toString(),
        checkDate: m['checkDate']?.toString(),
        purposeOfVisit: m['purposeOfVisit']?.toString(),
        documentIds: ((m['documentIds'] ?? '') as String)
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList(),
        createdAt: (m['createdAt'] ?? '').toString(),
        // Rows written before the column existed are the collector's own
        // work, so the absent value reads as LOCAL.
        source: (m['source'] ?? sourceLocal).toString(),
      );
}

/// Reads and writes the engagement archive.
///
/// Deliberately has no `clear()` and no `replaceAll()`. Every sibling DAO has
/// both, and `_replaceAccountLevelData` calls them on all four on every
/// download — so the absence of the method is what guarantees no download path
/// can truncate this table. The guarantee is in the type, not in a comment.
///
/// [clearServerCopied] is narrow on purpose and keeps that guarantee: it can
/// only reach rows the backfill wrote, never an engagement this device
/// recorded. [purgeOlderThan] is dated, and nothing calls it yet.
class CollectionEngagementDao {
  final Database db;
  CollectionEngagementDao(this.db);

  static const table = 'a_tblCollectionEngagement';

  Future<void> upsert(CollectionEngagementRecord record) => db.insert(
        table,
        record.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  /// One transaction for a batch engagement, which can cover a whole account.
  Future<void> upsertAll(List<CollectionEngagementRecord> records) async {
    if (records.isEmpty) return;
    final batch = db.batch();
    for (final r in records) {
      batch.insert(table, r.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<CollectionEngagementRecord>> getAll(String collectorCode) async {
    final rows = await db.query(
      table,
      where: 'collectorCode = ?',
      whereArgs: [collectorCode],
      orderBy: 'engagedOn DESC, engagedAt DESC',
    );
    return rows.map(CollectionEngagementRecord.fromJson).toList();
  }

  Future<List<CollectionEngagementRecord>> getForDayRange({
    required String collectorCode,
    required String fromDay,
    required String toDay,
  }) async {
    final rows = await db.query(
      table,
      where: 'collectorCode = ? AND engagedOn BETWEEN ? AND ?',
      whereArgs: [collectorCode, fromDay, toDay],
      orderBy: 'engagedOn DESC, engagedAt DESC',
    );
    return rows.map(CollectionEngagementRecord.fromJson).toList();
  }

  /// [yearMonth] is yyyy-MM. A plain string range is safe because engagedOn is
  /// fixed-width, and it uses the (collectorCode, engagedOn) index.
  Future<List<CollectionEngagementRecord>> getForMonth({
    required String collectorCode,
    required String yearMonth,
  }) =>
      getForDayRange(
        collectorCode: collectorCode,
        fromDay: '$yearMonth-01',
        toDay: '$yearMonth-31',
      );

  /// How many engagements fall on each day of [yearMonth]. The calendar grid
  /// needs only this, which is what keeps forty-two cells cheap.
  Future<Map<String, int>> countsByDay({
    required String collectorCode,
    required String yearMonth,
  }) async {
    final rows = await db.rawQuery(
      'SELECT engagedOn, COUNT(*) AS n FROM $table '
      'WHERE collectorCode = ? AND engagedOn BETWEEN ? AND ? '
      'GROUP BY engagedOn',
      [collectorCode, '$yearMonth-01', '$yearMonth-31'],
    );
    return {
      for (final r in rows)
        (r['engagedOn'] ?? '').toString(): (r['n'] as num?)?.toInt() ?? 0,
    };
  }

  Future<int> countAll() async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM $table');
    return (rows.first['n'] as num?)?.toInt() ?? 0;
  }

  /// Drop the copied half of the archive, so it can be rebuilt from what the
  /// server says now.
  ///
  /// Scoped to [CollectionEngagementRecord.sourceServer] by the WHERE clause,
  /// which is the only reason a delete is allowed on this table at all. An
  /// engagement this device recorded is out of reach of this method.
  Future<int> clearServerCopied() => db.delete(
        table,
        where: 'source = ?',
        whereArgs: [CollectionEngagementRecord.sourceServer],
      );

  /// Retention lever. Unused today; the archive is small and grows slowly.
  Future<int> purgeOlderThan(String day) =>
      db.delete(table, where: 'engagedOn < ?', whereArgs: [day]);
}
