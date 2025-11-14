import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

class UserDao {
  final Database db;
  UserDao(this.db);

  Future<void> insertUser(UserModel user) async {
    await db.insert('Users', user.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertUsers(List<UserModel> users) async {
    Batch batch = db.batch();
    for (var user in users) {
      batch.insert('Users', user.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<UserModel>> getUsers() async {
    final List<Map<String, dynamic>> maps = await db.query('Users');
    return maps.map((m) => UserModel.fromJson(m)).toList();
  }

  Future<String> getUserPhoneNumberByUsername(String initial) async {
    final List<Map<String, dynamic>> maps = await db.query('Users', columns: ['PhoneNumber'], where: 'Initial = ?', whereArgs: [initial]);
    if (maps.isEmpty) return '';
    return maps.first['PhoneNumber'] as String;
  }
}
