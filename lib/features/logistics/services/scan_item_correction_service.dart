import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/repositories/inventory/scan_item_vocabulary_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/scan_item_corrector.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/item_table_reading.dart';

/// Corrects scanned items against known items: the phone's table first; for
/// codes and words it does not know, one server lookup, saved to the table,
/// then a second pass. Each unknown term is asked for once per app run.
class ScanItemCorrectionService {
  ScanItemCorrectionService(this._repository);

  final ScanItemVocabularyRepository _repository;
  final Set<String> _asked = {};
  ScanVocabulary? _cached;

  /// Terms per server call, as the endpoint accepts.
  static const int maxTerms = 30;

  /// The corrected reading, and whether the server was needed but could not
  /// be reached.
  Future<(ItemTableReading, bool serverMissed)> correct(
      ItemTableReading reading) async {
    if (reading.items.isEmpty) return (reading, false);
    var vocab = await _vocabulary();
    var pass = ScanItemCorrector.correct(reading, vocab);
    if (!pass.hasUnknowns) return _done(pass, 'local');

    final codes = pass.unknownCodes.where(_asked.add).take(maxTerms).toList();
    final words = pass.unknownWords.where(_asked.add).take(maxTerms).toList();
    if (codes.isEmpty && words.isEmpty) return _done(pass, 'local');

    final fetched =
        await _repository.fetchFromServer(codes: codes, words: words);
    if (fetched.isFailure) {
      // Ask again on the next scan: the phone may be back online.
      _asked
        ..removeAll(codes)
        ..removeAll(words);
      return (_done(pass, 'offline').$1, true);
    }
    if (fetched.value.isEmpty) return _done(pass, 'server-none');
    _cached = null;
    vocab = await _vocabulary();
    pass = ScanItemCorrector.correct(reading, vocab);
    return _done(pass, 'server');
  }

  /// Saves items the user put on the form, so the next scan knows them.
  Future<void> learn(List<InventoryItemModel> items) async {
    final saved = await _repository.learn(items);
    if (saved.isSuccess) _cached = null;
  }

  Future<ScanVocabulary> _vocabulary() async {
    if (_cached != null) return _cached!;
    final local = await _repository.local();
    return _cached = ScanVocabulary(local.isSuccess ? local.value : const []);
  }

  (ItemTableReading, bool) _done(ScanItemCorrection pass, String source) {
    logDebug('[OneScan] item vocabulary ($source): '
        '${pass.changed} item(s) corrected');
    return (pass.reading, false);
  }
}
