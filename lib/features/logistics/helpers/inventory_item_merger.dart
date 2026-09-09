import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';

/// Pure merge logic for scanned inventory items.
///
/// Kept out of the controller so it can be unit tested without GetX bindings.
class InventoryItemMerger {
  const InventoryItemMerger._();

  /// Folds [incoming] into [existing] and returns the resulting list.
  ///
  /// Two lines are the same physical unit only when their
  /// [InventoryItemModel.mergeKey] matches, that is when part number, item
  /// code and serial number all agree. Matching lines have their quantities
  /// summed and their batches merged by batch serial. A line sharing a part
  /// number but carrying a different serial number is a different unit and is
  /// appended as its own row.
  ///
  /// Neither input list is mutated.
  static List<InventoryItemModel> merge({
    required List<InventoryItemModel> existing,
    required List<InventoryItemModel> incoming,
  }) {
    final result = List<InventoryItemModel>.from(existing);

    // Keep whatever the existing row already has, filling blanks from the
    // incoming row.
    String prefer(String a, String b) => a.isNotEmpty ? a : b;

    for (final inc in incoming) {
      final idx = result.indexWhere((it) => it.mergeKey == inc.mergeKey);
      if (idx == -1) {
        result.add(inc);
        continue;
      }

      final current = result[idx];

      // Merge batches by appending and de-duplicating by batchSerial.
      final Map<String, InventoryBatchModel> batchMap = {
        for (final b in current.batches) b.batchSerial: b
      };
      for (final b in inc.batches) {
        batchMap[b.batchSerial] = b;
      }

      result[idx] = current.copyWith(
        description: prefer(current.description, inc.description),
        qty: current.qty + inc.qty,
        unit: prefer(current.unit, inc.unit),
        ptn: prefer(current.ptn, inc.ptn),
        batches: batchMap.values.toList(),
      );
    }

    return result;
  }
}
