import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';

class RemarksDao {
  final Database db;
  RemarksDao(this.db);

  Future<void> insertRemark(String requestId, String remarks, String date) async {
    await db.insert('a_tblRequestRemarks', {'RequestID': requestId, 'Remarks': remarks, 'Date': date}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<CancelRemarksModel?> getLatestRemark(String requestId) async {
    final List<Map<String, dynamic>> maps = await db.query('a_tblRequestRemarks', where: 'RequestID = ?', whereArgs: [requestId], orderBy: 'Date DESC', limit: 1);
    if (maps.isEmpty) return null;
    return CancelRemarksModel.fromJson(maps.first);
  }

  Future<bool> exists(String requestId) async {
    final List<Map<String, dynamic>> maps = await db.query('a_tblRequestRemarks', where: 'RequestID = ?', whereArgs: [requestId], limit: 1);
    return maps.isNotEmpty;
  }
}

