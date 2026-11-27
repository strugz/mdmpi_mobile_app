import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/scan_item_vocab_dao.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/scan_vocab_entry.dart';

/// Known items for correcting scanned item descriptions: the local
/// `SCAN_ITEM_VOCAB_` table first, the server's past requests
/// (`GET /api4/Item/vocabulary`) only for what the table does not know.
/// Server answers are saved locally, so each word is asked for once.
class ScanItemVocabularyRepository extends GetxController {
  ScanItemVocabularyRepository({
    Future<ScanItemVocabDao> Function()? dao,
    Future<http.Response> Function(Uri uri)? get,
  })  : _dao = dao ?? (() => DatabaseHelper.instance.scanItemVocabDao),
        _get = get ?? ((uri) => http.get(uri));

  final Future<ScanItemVocabDao> Function() _dao;
  final Future<http.Response> Function(Uri uri) _get;

  /// Short: the scan waits on it. Offline or slow, the scan goes on with
  /// what the phone knows.
  static const Duration serverTimeout = Duration(seconds: 6);

  Future<Result<List<ScanVocabEntry>>> local() async {
    try {
      return Result.success(await (await _dao()).all());
    } catch (e) {
      logDebug('[OneScan] vocabulary read failed: $e');
      return Result.failure('Could not read the item vocabulary: $e');
    }
  }

  /// Asks the server for past items with one of [codes] or containing one of
  /// [words], and saves what comes back. Returns the rows saved.
  Future<Result<List<ScanVocabEntry>>> fetchFromServer({
    required Iterable<String> codes,
    required Iterable<String> words,
  }) async {
    final query = <String, String>{
      if (codes.isNotEmpty) 'codes': codes.join(','),
      if (words.isNotEmpty) 'words': words.join(','),
    };
    if (query.isEmpty) return Result.success(const []);
    try {
      final resp = await _get(BApiEnvironment.api4Uri('/api4/Item/vocabulary', query))
          .timeout(serverTimeout);
      if (resp.statusCode != 200) {
        return Result.failure('Server returned ${resp.statusCode}');
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! List) return Result.success(const []);
      final entries = [
        for (final e in decoded)
          if (e is Map)
            ScanVocabEntry.fromApi(Map<String, dynamic>.from(e)),
      ].where((e) => e.description.isNotEmpty).toList();
      await (await _dao()).saveFromServer(entries);
      return Result.success(entries);
    } catch (e) {
      logDebug('[OneScan] vocabulary server lookup failed: $e');
      return Result.failure('Could not reach the item vocabulary: $e');
    }
  }

  /// Remembers items the user put on the form from a scan.
  Future<Result<void>> learn(List<InventoryItemModel> items) async {
    try {
      await (await _dao()).saveConfirmed([
        for (final i in items)
          if (i.description.trim().isNotEmpty)
            ScanVocabEntry(
              itemCode: i.itemCode.trim(),
              description: i.description.trim(),
              unit: i.unit.trim(),
            ),
      ]);
      return Result.success(null);
    } catch (e) {
      logDebug('[OneScan] vocabulary save failed: $e');
      return Result.failure('Could not save the item vocabulary: $e');
    }
  }
}
