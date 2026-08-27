import 'package:mdmpi_mobile_app/data/models/contact_model.dart';
import 'package:sqflite/sqflite.dart';

class ContactDao {
  final Database db;

  ContactDao(this.db);

  Future<int> insert(ContactModel contact) async {
    final payload = contact.toJson()..remove('id');
    return db.insert(
      'contacts',
      payload,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ContactModel>> getAll() async {
    final rows = await db.query(
      'contacts',
      orderBy: 'created_at DESC',
    );

    return rows.map(ContactModel.fromJson).toList();
  }

  Future<List<String>> getAllPhoneNumbers() async {
    final rows = await db.query(
      'contacts',
      columns: ['contact_number'],
      orderBy: 'created_at DESC',
    );

    return rows
        .map((row) => (row['contact_number'] ?? '').toString().trim())
        .where((phoneNumber) => phoneNumber.isNotEmpty)
        .toList();
  }

  Future<int> deleteById(int id) async {
    return db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
