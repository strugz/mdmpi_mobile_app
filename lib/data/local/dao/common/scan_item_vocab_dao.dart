import 'dart:math' as math;

import 'package:mdmpi_mobile_app/features/logistics/models/scan/scan_vocab_entry.dart';
import 'package:sqflite/sqflite.dart';

/// `SCAN_ITEM_VOCAB_`: items known from past requests and confirmed scans,
/// used to correct scanned item descriptions.
class ScanItemVocabDao {
  ScanItemVocabDao(this.db);

  final Database db;

  static const String table = 'SCAN_ITEM_VOCAB_';

  Future<List<ScanVocabEntry>> all() async =>
      (await db.query(table)).map(ScanVocabEntry.fromRow).toList();

  /// Server rows: the use count is the server's when it is higher.
  Future<void> saveFromServer(List<ScanVocabEntry> entries) =>
      _save(entries, (old, e) => math.max(old, e.uses));

  /// Items the user confirmed on a scan: one more use each.
  Future<void> saveConfirmed(List<ScanVocabEntry> entries) =>
      _save(entries, (old, e) => old + 1);

  Future<void> _save(
    List<ScanVocabEntry> entries,
    int Function(int old, ScanVocabEntry e) uses,
  ) async {
    if (entries.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      for (final e in entries) {
        if (e.description.isEmpty) continue;
        final existing = await txn.query(table,
            columns: ['USES'],
            where: 'ITEM_KEY = ?',
            whereArgs: [e.key],
            limit: 1);
        final old = existing.isEmpty ? 0 : (existing.first['USES'] as int? ?? 0);
        await txn.insert(
          table,
          {
            'ITEM_KEY': e.key,
            'ITEM_CODE': e.itemCode,
            'DESCRIPTION': e.description,
            'UNIT': e.unit,
            'USES': existing.isEmpty ? math.max(1, e.uses) : uses(old, e),
            'UPDATED_AT': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
