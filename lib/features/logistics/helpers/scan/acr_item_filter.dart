import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/acr_verdict.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/item_table_reading.dart';

/// The ACR (on-device text recognition) filter for the Add Item scan: cleans
/// what [ItemTableParser] read and decides whether that is enough, or whether
/// Gemini must read the table. Pure, so it is tested with hand-made readings.
///
/// Noise removal (headers, footers, form metadata, signatures) and the
/// extraction scope (the item table only) come from [ItemTableParser], which
/// reads nothing above the column titles or past the body's end. This class
/// does the rest: whitespace and artifact clean-up, dropping blank or
/// unreadable rows, and the required-field and confidence checks.
class AcrItemFilter {
  AcrItemFilter._();

  /// Every kept row must be read cleanly unless `.env` lowers it
  /// (`ACR_MIN_CONFIDENCE`): a row the parser was unsure of usually has its
  /// quantity defaulted to 1, and the Add Item list has no review step.
  static const double defaultMinConfidence = 1.0;

  /// `ACR_MIN_CONFIDENCE` from [env] (0 to 1), else [defaultMinConfidence].
  static double minConfidenceFrom(Map<String, String> env) {
    final value = double.tryParse(env['ACR_MIN_CONFIDENCE']?.trim() ?? '');
    if (value == null || value.isNaN) return defaultMinConfidence;
    return value.clamp(0.0, 1.0);
  }

  static AcrVerdict evaluate(
    ItemTableReading reading, {
    double minConfidence = defaultMinConfidence,
  }) {
    if (!reading.headerFound) {
      return const AcrVerdict(reasons: [AcrFallbackReason.noTable]);
    }

    final items = <InventoryItemModel>[];
    var dropped = 0;
    var clean = 0;
    var missing = false;
    for (final (i, raw) in reading.items.indexed) {
      final item = _cleaned(raw);
      if (_isBlank(item)) {
        dropped++;
        continue;
      }
      items.add(item);
      final complete = _hasText(item.description) &&
          item.qty > 0 &&
          item.unit.isNotEmpty;
      if (!complete) missing = true;
      if (complete && !reading.isUnsure(i)) clean++;
    }

    if (items.isEmpty) {
      return AcrVerdict(
          droppedRows: dropped, reasons: const [AcrFallbackReason.noItems]);
    }
    final confidence = clean / items.length;
    return AcrVerdict(
      items: items,
      confidence: confidence,
      droppedRows: dropped,
      reasons: [
        if (missing) AcrFallbackReason.missingFields,
        if (confidence < minConfidence) AcrFallbackReason.lowConfidence,
      ],
    );
  }

  /// Scanner artifacts at either end of a cell: ruling lines read as `|`,
  /// `!`, `[`, `]` or `_`, bullets, stray `~`, `*`, `:`, `;` and `=`. A
  /// trailing `.` or `"` stays (`Assy.`, `3.5"`).
  static final RegExp _edgeJunk = RegExp(
      r'^[\s|!_~`•·*:;=\[\],.\-]+|[\s|!_~`•·*:;=\[\],\-]+$');

  /// Whitespace collapsed to single spaces, control characters removed and
  /// [_edgeJunk] trimmed.
  static String normalize(String text) => text
      .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(_edgeJunk, '')
      .trim();

  static bool _hasText(String s) => RegExp(r'[A-Za-z0-9]').hasMatch(s);

  /// Nothing readable anywhere that identifies the item.
  static bool _isBlank(InventoryItemModel item) => ![
        item.description,
        item.itemCode,
        item.partNo,
        item.serialNo,
      ].any(_hasText);

  static InventoryItemModel _cleaned(InventoryItemModel item) =>
      InventoryItemModel(
        itemCode: normalize(item.itemCode),
        description: normalize(item.description),
        qty: item.qty,
        unit: normalize(item.unit),
        partNo: normalize(item.partNo),
        serialNo: normalize(item.serialNo),
        ptn: normalize(item.ptn),
        batches: item.batches,
      );
}
