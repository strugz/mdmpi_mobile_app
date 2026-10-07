import 'package:sqflite/sqflite.dart';

/// Upload state of a reconciliation photo.
abstract final class ReconAttachmentStatus {
  static const pending = 'Pending';
  static const uploaded = 'Uploaded';
  static const failed = 'Failed';
}

/// One photo on a reconciliation step: proof of payment, a document sent or
/// received. The picture is the file at [filePath]; this row says which case
/// and step it belongs to, and whether the server has it.
class ReconAttachmentRecord {
  const ReconAttachmentRecord({
    required this.attachmentId,
    required this.caseId,
    required this.activityId,
    required this.filePath,
    this.contentType = 'image/jpeg',
    this.status = ReconAttachmentStatus.pending,
    this.retryCount = 0,
    this.lastError,
    this.createdAt = '',
  });

  final String attachmentId;
  final String caseId;
  final String activityId;
  final String filePath;
  final String contentType;
  final String status;
  final int retryCount;
  final String? lastError;
  final String createdAt;

  Map<String, Object?> toRow() => {
        'attachmentId': attachmentId,
        'caseId': caseId,
        'activityId': activityId,
        'filePath': filePath,
        'contentType': contentType,
        'status': status,
        'retryCount': retryCount,
        'lastError': lastError,
        'createdAt': createdAt,
      };

  factory ReconAttachmentRecord.fromRow(Map<String, Object?> r) {
    String s(String k) => (r[k] ?? '').toString();
    return ReconAttachmentRecord(
      attachmentId: s('attachmentId'),
      caseId: s('caseId'),
      activityId: s('activityId'),
      filePath: s('filePath'),
      contentType: s('contentType').isEmpty ? 'image/jpeg' : s('contentType'),
      status: s('status').isEmpty ? ReconAttachmentStatus.pending : s('status'),
      retryCount: (r['retryCount'] as num?)?.toInt() ?? 0,
      lastError: r['lastError']?.toString(),
      createdAt: s('createdAt'),
    );
  }
}

/// The photos of reconciliation steps, and their upload outbox.
class ReconAttachmentDao {
  ReconAttachmentDao(this.db);

  final Database db;

  static const table = 'a_tblCollectionReconAttachment';

  /// Photos that have not reached the server, the ones that failed least
  /// often first, then oldest first.
  Future<List<ReconAttachmentRecord>> getUnsent({int maxRetries = 10}) async {
    final rows = await db.query(
      table,
      where: 'status != ? AND retryCount < ?',
      whereArgs: [ReconAttachmentStatus.uploaded, maxRetries],
      orderBy: 'retryCount, createdAt, attachmentId',
    );
    return rows.map(ReconAttachmentRecord.fromRow).toList();
  }

  Future<List<ReconAttachmentRecord>> forActivity(String activityId) async {
    final rows = await db.query(table,
        where: 'activityId = ?',
        whereArgs: [activityId],
        orderBy: 'createdAt, attachmentId');
    return rows.map(ReconAttachmentRecord.fromRow).toList();
  }

  Future<void> insert(ReconAttachmentRecord record) =>
      db.insert(table, record.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> markUploaded(String attachmentId) => db.update(
      table, {'status': ReconAttachmentStatus.uploaded, 'lastError': null},
      where: 'attachmentId = ?', whereArgs: [attachmentId]);

  /// A failed try, with the reason; counts toward giving up.
  Future<void> markFailed(String attachmentId, String error) => db.rawUpdate(
      'UPDATE $table SET status = ?, lastError = ?, retryCount = retryCount + 1 '
      'WHERE attachmentId = ?',
      [ReconAttachmentStatus.failed, error, attachmentId]);

  Future<int> countUnsent() async =>
      Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM $table WHERE status != ?',
          [ReconAttachmentStatus.uploaded])) ??
      0;
}
