import 'dart:convert';

/// Model representing a single inventory item returned by the OCR API.
class InventoryItemModel {
  final String itemCode;
  final String description;
  final double qty;
  final String unit;

  InventoryItemModel({
    required this.itemCode,
    required this.description,
    required this.qty,
    required this.unit,
  });

  /// Flexible factory that tolerates numbers provided as int/double or string.
  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    final itemCode = json['Item Code']?.toString() ?? '';
    final description = json['Description']?.toString() ?? '';

    final rawQty = json['Qty'];
    double qty = 0.0;
    if (rawQty != null) {
      if (rawQty is num) {
        qty = rawQty.toDouble();
      } else {
        qty = double.tryParse(rawQty.toString()) ?? 0.0;
      }
    }

    final unit = json['Unit']?.toString() ?? '';

    return InventoryItemModel(
      itemCode: itemCode,
      description: description,
      qty: qty,
      unit: unit,
    );
  }

  Map<String, dynamic> toJson() => {
        'Item Code': itemCode,
        'Description': description,
        'Qty': qty,
        'Unit': unit,
      };

  @override
  String toString() => jsonEncode(toJson());
}
