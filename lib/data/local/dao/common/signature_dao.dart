import 'package:sqflite/sqflite.dart';

/// DAO for receiver signature outbox rows (a_tblRequestReceiverSignature)
class SignatureDao {
  final Database db;

  SignatureDao(this.db);

  /// Return the base64 signature string stored for a request, or null if none.
  Future<String?> getReceiverSignatureByRequestId(dynamic requestID) async {
    final parsedId = int.tryParse(requestID.toString()) ?? requestID;
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblRequestReceiverSignature',
      columns: ['RequestReceiverSignature'],
      where: 'RequestID = ?',
      whereArgs: [parsedId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final value = maps.first['RequestReceiverSignature'] as String?;
    return value == null || value.isEmpty ? null : value;
  }

  /// Return all receiver signature rows (full map including ApiStatus)
  Future<List<Map<String, dynamic>>> getAllReceiverSignatures() async {
    final List<Map<String, dynamic>> maps = await db.query('a_tblRequestReceiverSignature');
    return maps;
  }

  /// Insert or replace a receiver signature row with ApiStatus.
  Future<void> insertReceiverSignature({required dynamic requestID, required String signature, String apiStatus = 'Pending'}) async {
    final parsedId = int.tryParse(requestID.toString()) ?? requestID;
    final Map<String, dynamic> row = {
      'RequestID': parsedId,
      'RequestReceiverSignature': signature,
      'ApiStatus': apiStatus,
    };
    await db.insert(
      'a_tblRequestReceiverSignature',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete receiver signature row by RequestID. Returns number of rows deleted.
  Future<int> deleteReceiverSignatureByRequestId(dynamic requestID) async {
    final parsedId = int.tryParse(requestID.toString()) ?? requestID;
    return await db.delete('a_tblRequestReceiverSignature', where: 'RequestID = ?', whereArgs: [parsedId]);
  }
}

