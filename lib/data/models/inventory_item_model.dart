import 'dart:convert';

/// Model representing a single inventory item returned by the OCR API.
class InventoryItemModel {
  final String itemCode;
  final String description;
  final double qty;
  final String unit;
  final List<InventoryBatchModel> batches;

  InventoryItemModel({
    required this.itemCode,
    required this.description,
    required this.qty,
    required this.unit,
    this.batches = const [],
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

    // Parse batch / batches if present. The OCR may return a List<Map> under
    // the key 'batch' (lowercase) or other variants. Be tolerant to:
    // - batch: List<Map>
    // - batch: JSON-encoded String
    // - batches: List<Map>
    List<InventoryBatchModel> batchList = [];
    try {
      dynamic rawBatch = json['batch'] ?? json['batches'] ?? json['Batch'] ?? json['batchList'];
      if (rawBatch != null) {
        if (rawBatch is String) {
          // try decode stringified JSON
          final decoded = jsonDecode(rawBatch);
          if (decoded is List) rawBatch = decoded;
        }

        if (rawBatch is List) {
          batchList = rawBatch
              .whereType<dynamic>()
              .map((e) {
                if (e is Map<String, dynamic>) return InventoryBatchModel.fromJson(e);
                if (e is Map) return InventoryBatchModel.fromJson(Map<String, dynamic>.from(e));
                return null;
              })
              .whereType<InventoryBatchModel>()
              .toList();
        }
      }
    } catch (_) {
      // ignore parse errors and leave batchList empty
    }

    return InventoryItemModel(
      itemCode: itemCode,
      description: description,
      qty: qty,
      unit: unit,
      batches: batchList,
    );
  }

  Map<String, dynamic> toJson() => {
        'Item Code': itemCode,
        'Description': description,
        'Qty': qty,
        'Unit': unit,
        'batch': batches.map((e) => e.toJson()).toList(),
      };

  @override
  String toString() => jsonEncode(toJson());
}

/// Model representing a single batch/serial entry for an inventory item.
class InventoryBatchModel {
  final String batchSerial;
  final double batchQuantity;
  final String expiryDate;

  InventoryBatchModel({
    required this.batchSerial,
    required this.batchQuantity,
    required this.expiryDate,
  });

  factory InventoryBatchModel.fromJson(Map<String, dynamic> json) {
    final serial = json['Batch/Serial #']?.toString() ?? json['batchSerial']?.toString() ?? json['serial']?.toString() ?? '';

    final rawQty = json['Batch Quantity'] ?? json['batch_quantity'] ?? json['BatchQuantity'] ?? json['quantity'];
    double batchQuantity = 0.0;
    if (rawQty != null) {
      if (rawQty is num) batchQuantity = rawQty.toDouble();
      else batchQuantity = double.tryParse(rawQty.toString()) ?? 0.0;
    }

    final expiry = json['Expiry Date']?.toString() ?? json['expiry_date']?.toString() ?? json['expiry']?.toString() ?? '';

    return InventoryBatchModel(
      batchSerial: serial,
      batchQuantity: batchQuantity,
      expiryDate: expiry,
    );
  }

  Map<String, dynamic> toJson() => {
        'Batch/Serial #': batchSerial,
        'Batch Quantity': batchQuantity,
        'Expiry Date': expiryDate,
      };

  @override
  String toString() => jsonEncode(toJson());
}
