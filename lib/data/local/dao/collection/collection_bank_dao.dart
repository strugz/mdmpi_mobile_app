import 'package:mdmpi_mobile_app/features/collection/models/bank_model.dart';
import 'package:sqflite/sqflite.dart';

/// The cached company bank list.
///
/// Small and slow-changing, so it is replaced wholesale on each successful
/// download rather than diffed.
class CollectionBankDao {
  CollectionBankDao(this.db);

  final Database db;

  static const table = 'a_tblCollectionBank';

  Future<List<BankModel>> getAll() async {
    final rows = await db.query(table, orderBy: 'bank COLLATE NOCASE');
    return rows.map(BankModel.fromDbMap).toList();
  }

  /// Replace the cache with what the server just returned.
  ///
  /// An empty list is ignored rather than written: a server that answers with
  /// nothing should not wipe a list the collector can still use offline.
  Future<void> replaceAll(List<BankModel> banks) async {
    if (banks.isEmpty) return;
    final batch = db.batch();
    batch.delete(table);
    for (final bank in banks) {
      batch.insert(table, bank.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
