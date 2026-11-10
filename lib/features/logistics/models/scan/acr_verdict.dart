import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';

/// Why the on-device ACR pass did not finish a scan on its own, so Gemini
/// read it instead.
enum AcrFallbackReason {
  /// The file is not a photo the phone can read (a PDF), or this platform
  /// has no on-device text recognition.
  notReadable,

  /// No row of item table column titles was found.
  noTable,

  /// A table was found, but no item rows survived the filter.
  noItems,

  /// A row is missing a description, a quantity or a unit.
  missingFields,

  /// Too few rows were read cleanly ([AcrVerdict.confidence] under the
  /// threshold).
  lowConfidence,

  /// The page was photographed sideways or is too distorted to crop.
  distorted,
}

/// The ACR pass's reading of a scanned item table after filtering (Add Item
/// scan, ACR first, Gemini fallback).
class AcrVerdict {
  const AcrVerdict({
    this.items = const [],
    this.confidence = 0,
    this.reasons = const [],
    this.droppedRows = 0,
  });

  /// The cleaned items, top to bottom: whitespace normalised, scanner
  /// artifacts trimmed, blank and unreadable rows left out.
  final List<InventoryItemModel> items;

  /// Share of the kept rows read cleanly: every required field present and
  /// nothing the parser was unsure of. 0 when no rows were kept.
  final double confidence;

  /// Empty when ACR alone is good enough; otherwise why Gemini is needed.
  final List<AcrFallbackReason> reasons;

  /// Rows left out as blank, unreadable or corrupted.
  final int droppedRows;

  bool get accepted => reasons.isEmpty;
}
