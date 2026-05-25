import 'package:sqflite/sqflite.dart';

/// DAO for failed/pending proof image upload rows.
class ImageOutboxDao {
  ImageOutboxDao(this.db);

  final Database db;

  Future<List<Map<String, dynamic>>> getPendingImageOutboxItems() async {
    return db.query(
      'a_tblRequestImageOutbox',
      where: "LOWER(COALESCE(ApiStatus, 'Pending')) != ?",
      whereArgs: ['synced'],
      orderBy:
          "CASE LOWER(COALESCE(ApiStatus, 'Pending')) WHEN 'failed' THEN 0 WHEN 'pending' THEN 1 ELSE 2 END, CapturedAt DESC",
    );
  }

  Future<void> insertImageOutboxItem({
    required String requestId,
    required String imageType,
    required String imageLookupKey,
    required String imageBase64,
    String apiStatus = 'Pending',
    String? capturedAt,
  }) async {
    await db.insert(
      'a_tblRequestImageOutbox',
      {
        'RequestID': requestId,
        'ImageType': imageType,
        'ImageLookupKey': imageLookupKey,
        'RequestImage': imageBase64,
        'ApiStatus': apiStatus,
        'CapturedAt': capturedAt ?? DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteImageOutboxItem({
    required String requestId,
    required String imageType,
    required String imageLookupKey,
  }) {
    return db.delete(
      'a_tblRequestImageOutbox',
      where: 'RequestID = ? AND ImageType = ? AND ImageLookupKey = ?',
      whereArgs: [requestId, imageType, imageLookupKey],
    );
  }

  Future<int> clearImageOutbox() {
    return db.delete('a_tblRequestImageOutbox');
  }
}
