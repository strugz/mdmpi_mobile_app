import 'dart:convert';

/// Model representing a single inventory item returned by the OCR API.
///
/// The field set mirrors one line of the paper Stock Issue Slip:
/// QTY, UM, PART NO., ITEM DESCRIPTION, SERIAL NO. and PTN.
///
/// The slip's REMARKS column is deliberately not represented here. The
/// database keeps its `remarks` column for the backend to populate, but the
/// mobile client neither captures, sends nor displays it.
class InventoryItemModel {
  final String itemCode;
  final String description;
  final double qty;
  final String unit;

  /// PART NO. column on the slip. Distinct from [itemCode].
  final String partNo;

  /// SERIAL NO. column on the slip (one serial per line).
  final String serialNo;

  /// PTN column on the slip.
  final String ptn;

  final List<InventoryBatchModel> batches;

  InventoryItemModel({
    required this.itemCode,
    required this.description,
    required this.qty,
    required this.unit,
    this.partNo = '',
    this.serialNo = '',
    this.ptn = '',
    this.batches = const [],
  });

  /// Returns a copy with the provided fields replaced.
  InventoryItemModel copyWith({
    String? itemCode,
    String? description,
    double? qty,
    String? unit,
    String? partNo,
    String? serialNo,
    String? ptn,
    List<InventoryBatchModel>? batches,
  }) {
    return InventoryItemModel(
      itemCode: itemCode ?? this.itemCode,
      description: description ?? this.description,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      partNo: partNo ?? this.partNo,
      serialNo: serialNo ?? this.serialNo,
      ptn: ptn ?? this.ptn,
      batches: batches ?? this.batches,
    );
  }

  /// Human-facing identifier for this line.
  ///
  /// The printed slip carries a part number and no item code, so the part
  /// number is what people read, and a line entered from a slip can
  /// legitimately have an empty [itemCode]. Older records have the reverse.
  ///
  /// Anything that labels or keys an item by a single code must use this
  /// rather than [itemCode], otherwise several slip lines collapse onto the
  /// empty string.
  String get referenceCode => partNo.isNotEmpty ? partNo : itemCode;

  /// Identity used to decide whether two scanned lines describe the same
  /// physical unit. Two lines only match when part number, item code and
  /// serial number all agree — a shared part number with different serials
  /// is two different units and must not be merged.
  String get mergeKey =>
      '${partNo.trim().toLowerCase()}|${itemCode.trim().toLowerCase()}|${serialNo.trim().toLowerCase()}';

  /// Flexible factory that tolerates numbers provided as int/double or string.
  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    /// Returns the first non-empty value found among [keys].
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return '';
    }

    final itemCode = pick(['Item Code', 'itemCode', 'itemcode']);
    final description = pick(['Description', 'description']);

    final rawQty = json['Qty'] ?? json['qty'];
    double qty = 0.0;
    if (rawQty != null) {
      if (rawQty is num) {
        qty = rawQty.toDouble();
      } else {
        qty = double.tryParse(rawQty.toString()) ?? 0.0;
      }
    }

    final unit = pick(['Unit', 'unit', 'UM', 'um']);
    final partNo =
        pick(['Part No.', 'Part No', 'Part Number', 'partNo', 'partno']);
    final serialNo = pick([
      'Serial No.',
      'Serial No',
      'Serial Number',
      'serialNo',
      'serialno',
    ]);
    final ptn = pick(['PTN', 'Ptn', 'ptn']);

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
      partNo: partNo,
      serialNo: serialNo,
      ptn: ptn,
      batches: batchList,
    );
  }

  Map<String, dynamic> toJson() => {
        'Item Code': itemCode,
        'Description': description,
        'Qty': qty,
        'Unit': unit,
        'Part No.': partNo,
        'Serial No.': serialNo,
        'PTN': ptn,
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
