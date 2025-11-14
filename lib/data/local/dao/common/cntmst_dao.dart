import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/data/models/cnstmst_model.dart';

class CntmstDao {
  final Database db;
  CntmstDao(this.db);

  Future<void> insertCntmsts(List<CNTMSTModel> list) async {
    Batch batch = db.batch();
    for (var itm in list) {
      batch.insert('CNTMST', itm.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<CNTMSTModel>> getRequesters() async {
    final List<Map<String, dynamic>> maps = await db.query('CNTMST', orderBy: 'CNTDPT', where: 'CNTMNN IS NOT NULL AND CNTMNN != ? AND CNTDPT IS NOT ? AND CNTSTS IS NOT ?', whereArgs: ['', 'COLLECTOR', '0']);
    return maps.map((m) => CNTMSTModel.fromJson(m)).toList();
  }

  /// Return user's phone and their managers' phone numbers based on CNTTGP hierarchy
  Future<List<String>> getUserAndManagerPhoneNumbers(String cntmnn) async {
    List<String> phoneNumbers = [];

    final List<Map<String, dynamic>> userMaps = await db.query(
      'CNTMST',
      columns: ['CNTNUM', 'CNTTGP'],
      where: 'CNTMNN = ?',
      whereArgs: [cntmnn],
    );

    if (userMaps.isEmpty) return [];

    final Map<String, dynamic> userRecord = userMaps.first;
    final String? userPhoneNumber = userRecord['CNTNUM'] as String?;
    if (userPhoneNumber != null && userPhoneNumber.isNotEmpty) {
      phoneNumbers.add(userPhoneNumber);
    }

    final String? managerHierarchy = userRecord['CNTTGP'] as String?;
    if (managerHierarchy == null || managerHierarchy.isEmpty) return phoneNumbers;

    final List<String> hierarchySegments = managerHierarchy.split('/');
    for (final managers in hierarchySegments) {
      if (managers != 'EGL') {
        final List<Map<String, dynamic>> managerMaps = await db.query(
          'CNTMST',
          columns: ['CNTNUM'],
          where: 'CNTMNN = ?',
          whereArgs: [managers],
        );
        if (managerMaps.isNotEmpty) {
          final String? mgrPhone = managerMaps.first['CNTNUM'] as String?;
          if (mgrPhone != null && mgrPhone.isNotEmpty) phoneNumbers.add(mgrPhone);
        }
      }
    }

    return phoneNumbers;
  }

  /// Return the display/full name for a CNTMNN
  Future<String> getUserFullName(String cntmnn) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'CNTMST',
      columns: ['CNTMCN'],
      where: 'CNTMNN = ?',
      whereArgs: [cntmnn],
    );
    if (maps.isEmpty) return '';
    return maps.first['CNTMCN'] as String? ?? '';
  }
}
