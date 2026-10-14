import 'package:sqflite/sqflite.dart';

/// Where a voucher page waiting for an online re-read stands.
abstract final class VoucherRereadStatus {
  static const pending = 'Pending';
  static const done = 'Done';
  static const failed = 'Failed';
}

/// One voucher page read on the phone (offline, or Scan with camera), kept
/// so the AI can read it again once there is a connection. The picture is
/// the file at [pagePath]; [offlineIds] are the invoices the phone's reading
/// already found, so only what it missed is reported.
class VoucherRereadRecord {
  const VoucherRereadRecord({
    required this.rereadId,
    required this.clientId,
    this.clientName = '',
    required this.pagePath,
    this.offlineIds = const [],
    this.status = VoucherRereadStatus.pending,
    this.retryCount = 0,
    this.foundIds = const [],
    this.notFound = const [],
    this.seen = false,
    this.lastError,
    this.createdAt = '',
  });

  final String rereadId;
  final String clientId;
  final String clientName;
  final String pagePath;
  final List<String> offlineIds;
  final String status;
  final int retryCount;

  /// Open invoices of the account the AI found that the phone missed.
  final List<String> foundIds;

  /// Invoice numbers the AI read that are no invoice of the account.
  final List<String> notFound;

  /// The collector has seen (selected or dismissed) what it found.
  final bool seen;
  final String? lastError;
  final String createdAt;

  static String _join(List<String> v) => v.join(',');
  static List<String> _split(Object? v) => (v ?? '')
      .toString()
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Map<String, Object?> toRow() => {
        'rereadId': rereadId,
        'clientId': clientId,
        'clientName': clientName,
        'pagePath': pagePath,
        'offlineIds': _join(offlineIds),
        'status': status,
        'retryCount': retryCount,
        'foundIds': _join(foundIds),
        'notFound': _join(notFound),
        'seen': seen ? 1 : 0,
        'lastError': lastError,
        'createdAt': createdAt,
      };

  factory VoucherRereadRecord.fromRow(Map<String, Object?> r) {
    String s(String k) => (r[k] ?? '').toString();
    return VoucherRereadRecord(
      rereadId: s('rereadId'),
      clientId: s('clientId'),
      clientName: s('clientName'),
      pagePath: s('pagePath'),
      offlineIds: _split(r['offlineIds']),
      status: s('status').isEmpty ? VoucherRereadStatus.pending : s('status'),
      retryCount: (r['retryCount'] as num?)?.toInt() ?? 0,
      foundIds: _split(r['foundIds']),
      notFound: _split(r['notFound']),
      seen: (r['seen'] as num?)?.toInt() == 1,
      lastError: r['lastError']?.toString(),
      createdAt: s('createdAt'),
    );
  }
}

/// Voucher pages waiting for an online re-read, and what the re-read found.
class VoucherRereadDao {
  VoucherRereadDao(this.db);

  final Database db;

  static const table = 'a_tblCollectionVoucherReread';

  Future<void> insert(VoucherRereadRecord r) =>
      db.insert(table, r.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);

  /// Pages still to re-read, oldest first; ones that failed too often stop.
  Future<List<VoucherRereadRecord>> getPending({int maxRetries = 10}) async {
    final rows = await db.query(table,
        where: 'status = ? AND retryCount < ?',
        whereArgs: [VoucherRereadStatus.pending, maxRetries],
        orderBy: 'createdAt, rereadId');
    return rows.map(VoucherRereadRecord.fromRow).toList();
  }

  Future<void> markDone(String id,
          {required List<String> foundIds, required List<String> notFound}) =>
      db.update(
          table,
          {
            'status': VoucherRereadStatus.done,
            'foundIds': foundIds.join(','),
            'notFound': notFound.join(','),
            'lastError': null,
            // Nothing new: nothing for the collector to see.
            'seen': foundIds.isEmpty ? 1 : 0,
          },
          where: 'rereadId = ?',
          whereArgs: [id]);

  /// One more failed try; after [maxRetries] the page is given up.
  Future<void> markRetry(String id, String error, {int maxRetries = 10}) =>
      db.rawUpdate(
          'UPDATE $table SET retryCount = retryCount + 1, lastError = ?, '
          'status = CASE WHEN retryCount + 1 >= ? THEN ? ELSE status END '
          'WHERE rereadId = ?',
          [error, maxRetries, VoucherRereadStatus.failed, id]);

  /// Finished re-reads that found invoices the collector has not seen yet.
  Future<List<VoucherRereadRecord>> getUnseen() async {
    final rows = await db.query(table,
        where: "status = ? AND seen = 0 AND foundIds != ''",
        whereArgs: [VoucherRereadStatus.done],
        orderBy: 'createdAt');
    return rows.map(VoucherRereadRecord.fromRow).toList();
  }

  Future<void> markSeen(Iterable<String> ids) async {
    for (final id in ids) {
      await db.update(table, {'seen': 1},
          where: 'rereadId = ?', whereArgs: [id]);
    }
  }

  /// Rows created before [cutoff] (ISO text); returns their page paths so the
  /// caller can delete the files.
  Future<List<String>> deleteOlderThan(String cutoff) async {
    final rows = await db.query(table,
        columns: ['pagePath'], where: 'createdAt < ?', whereArgs: [cutoff]);
    await db.delete(table, where: 'createdAt < ?', whereArgs: [cutoff]);
    return [for (final r in rows) (r['pagePath'] ?? '').toString()];
  }

  Future<int> countPending() async =>
      Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM $table WHERE status = ?',
          [VoucherRereadStatus.pending])) ??
      0;
}
