import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:sqflite/sqflite.dart';

/// The cached client registry (a copy of the server's a_tblcollectionclient).
///
/// What the activity forms' account picker searches, so the search is
/// instant and works without signal. Replaced wholesale on each refresh.
class CollectionClientDao {
  CollectionClientDao(this.db);

  final Database db;

  static const table = 'a_tblCollectionClient';

  /// Clients whose name or code contains [term], name order, up to [limit].
  /// An empty term lists the first [limit] by name.
  Future<List<ClientModel>> search(String term, {int limit = 50}) async {
    final q = term.trim();
    final rows = await db.query(
      table,
      where: q.isEmpty
          ? null
          : 'clientName LIKE ? COLLATE NOCASE OR clientCode LIKE ? COLLATE NOCASE',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%'],
      orderBy: 'clientName COLLATE NOCASE, clientCode',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  Future<int> count() async =>
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $table')) ??
      0;

  /// Replace the cache with the registry the server just returned.
  ///
  /// An empty list is ignored rather than written: a server that answers
  /// with nothing should not wipe a list the collector can still use offline.
  Future<void> replaceAll(List<ClientModel> clients) async {
    if (clients.isEmpty) return;
    await db.transaction((txn) async {
      await txn.delete(table);
      final batch = txn.batch();
      for (final c in clients) {
        batch.insert(table, _toRow(c),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  static Map<String, Object?> _toRow(ClientModel c) => {
        'clientCode': c.id,
        'clientName': c.name,
        'clientAddress': c.address,
        'clientContact': c.contact,
        'clientEmail': c.emailAddress,
      };

  /// In this app a Collection client's id and code are both the registry's
  /// ClientCode, so a cached client uploads like any other.
  static ClientModel _fromRow(Map<String, Object?> r) {
    String s(String k) => (r[k]?.toString() ?? '').trim();
    final code = s('clientCode');
    final name = s('clientName');
    return ClientModel(
      id: code,
      code: code,
      name: name.isEmpty ? code : name,
      address: s('clientAddress'),
      contact: s('clientContact'),
      emailAddress: s('clientEmail'),
    );
  }
}
