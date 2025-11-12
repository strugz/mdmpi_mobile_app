import 'package:sqflite/sqflite.dart';

class DocumentReferenceDao {
  final Database db;
  DocumentReferenceDao(this.db);

  /// requestId may be int or string; normalize to int when possible to match DB types
  Future<List<String>> getByRequestId(Object requestId) async {
    final dynamic normalized = int.tryParse(requestId.toString() ?? '') ?? requestId;
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblRequestDocumentReference',
      columns: ['Reference'],
      where: 'RequestID = ?',
      whereArgs: [normalized],
    );
    return maps.map((m) => (m['Reference'] ?? '').toString()).toList();
  }

  Future<void> insert(Object requestId, String reference, String createdAt) async {
    final dynamic normalized = int.tryParse(requestId.toString() ?? '') ?? requestId;
    await db.insert('a_tblRequestDocumentReference', {
      'RequestID': normalized,
      'Reference': reference,
      'RequestCreatedAt': createdAt,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteByRequestId(String requestId) async {
    await db.delete('a_tblRequestDocumentReference', where: 'RequestID = ?', whereArgs: [requestId]);
  }
}
