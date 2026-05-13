import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

class ClientDao {
  final Database db;
  ClientDao(this.db);

  Future<int> insertClient(ClientModel client) async {
    return await db.insert('ACCMST_', client.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertClients(List<ClientModel> clients) async {
    Batch batch = db.batch();
    for (var c in clients) {
      batch.insert('ACCMST_', c.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAll() async {
    await db.delete('ACCMST_');
  }

  /// Try to fetch client by id from ACCMST_ first, then fallback to DLRMST.
  Future<ClientModel?> getById(String id) async {
    final List<Map<String, dynamic>> maps = await db.query('ACCMST_', where: 'ACCMID = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return ClientModel.fromJson(maps.first);

    // Fallback to DLRMST if not found in ACCMST_
    final List<Map<String, dynamic>> dlrMaps = await db.query('DLRMST', where: 'DLRMID = ?', whereArgs: [id]);
    if (dlrMaps.isNotEmpty) return ClientModel.fromJson(dlrMaps.first);

    return null;
  }

  Future<List<ClientModel>> search(String query) async {
    final List<Map<String, dynamic>> maps = await db.query('ACCMST_', where: 'ACCMNM LIKE ? OR ACCMSC LIKE ?', whereArgs: ['%$query%', '%$query%']);
    return maps.map((m) => ClientModel.fromJson(m)).toList();
  }

  Future<bool> hasData() async {
    final List<Map<String, dynamic>> maps = await db.query('ACCMST_', limit: 1);
    return maps.isNotEmpty;
  }
}
