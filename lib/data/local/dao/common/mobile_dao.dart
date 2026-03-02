import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/data/models/mobile_model.dart';

class MobileDao {
  final Database db;
  MobileDao(this.db);

  Future<void> insertMobiles(List<Mobile> mobiles) async {
    Batch batch = db.batch();
    for (var mobile in mobiles) {
      batch.insert(
        'a_tblMobile',
        {'MobileID': int.parse(mobile.mobileID), 'MobileName': mobile.mobileName},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Mobile>> getMobiles() async {
    final List<Map<String, dynamic>> maps = await db.query('a_tblMobile');
    return maps.map((m) => Mobile.fromJson(m)).toList();
  }

  Future<void> deleteAll() async => await db.delete('a_tblMobile');
}
