import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';

/// The item table read off a scanned delivery document by on-device OCR
/// (Standard Delivery one-scan, plan §4.5).
class ItemTableReading {
  const ItemTableReading({
    this.headerFound = false,
    this.items = const [],
    this.unsure = const {},
    this.tableTexts = const [],
    this.dropped = const [],
  });

  static const none = ItemTableReading();

  /// Whether a row of known column titles was found. False means "No item
  /// table found": the user adds items with the existing Add Item.
  final bool headerFound;

  /// One item per table row, top to bottom.
  final List<InventoryItemModel> items;

  /// Indexes into [items] the user should check: quantity missing or
  /// unreadable (set to 1), a very short description, a row read as one
  /// run of text across several columns, or an item code that looks misread.
  final Set<int> unsure;

  /// The text of every line inside the table body. Property tags in here
  /// (`FA26-0609`) are not document references.
  final List<String> tableTexts;

  /// Description-only rows far from any item (`SR: JRQ`), left out.
  final List<String> dropped;

  bool isUnsure(int index) => unsure.contains(index);

  /// The items to check, by item code (description when there is none), in
  /// table order, so the review sheet can name them.
  List<String> get unsureLabels => [
        for (final i in unsure.toList()..sort())
          if (i < items.length)
            items[i].itemCode.isNotEmpty
                ? items[i].itemCode
                : items[i].description,
      ];
}
