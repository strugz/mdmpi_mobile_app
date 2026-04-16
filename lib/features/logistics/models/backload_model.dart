/// Model for the BackLoad record stored in `a_tblRequestBackload`.
///
/// Each entry records a single back-load event for a request.
/// A request may have multiple BackLoad entries over time.
class BackLoadModel {
  final String backLoadId;
  final String requestId;
  final String remarks;
  final String dateReported;
  final String deliveryDate;

  const BackLoadModel(
      {required this.backLoadId,
      required this.requestId,
      required this.remarks,
      required this.dateReported,
      required this.deliveryDate});

  /// Empty sentinel used as default / fallback.
  static const BackLoadModel empty = BackLoadModel(
      backLoadId: '',
      requestId: '',
      remarks: '',
      dateReported: '',
      deliveryDate: '');

  bool get isEmpty => backLoadId.isEmpty && requestId.isEmpty;

  /// Parse from API JSON.
  factory BackLoadModel.fromJson(Map<String, dynamic> json) {
    return BackLoadModel(
      backLoadId: (json['BackLoadID']?.toString() ?? ''),
      requestId: (json['RequestID']?.toString() ?? ''),
      remarks: (json['Remarks']?.toString() ?? ''),
      dateReported: (json['DateReported']?.toString() ?? ''),
      deliveryDate: (json['DeliveryDate']?.toString() ?? ''),
    );
  }

  /// Parse from local DB row (lowercase-safe).
  factory BackLoadModel.fromDbJson(Map<String, dynamic> json) {
    final Map<String, dynamic> lower = {};
    json.forEach((k, v) => lower[k.toString().toLowerCase()] = v);
    return BackLoadModel(
      backLoadId: (lower['backloadid']?.toString() ?? ''),
      requestId: (lower['requestid']?.toString() ?? ''),
      remarks: (lower['remarks']?.toString() ?? ''),
      dateReported: (lower['datereported']?.toString() ?? ''),
      deliveryDate: (lower['deliveryDate']?.toString() ?? ''),
    );
  }

  /// Serialize to JSON for API payloads.
  Map<String, dynamic> toJson() {
    return {
      'BackLoadID': backLoadId,
      'RequestID': requestId,
      'Remarks': remarks,
      'DateReported': dateReported,
      'DeliveryDate': deliveryDate,
    };
  }

  /// Serialize to DB-friendly map (insert).
  Map<String, dynamic> toDbJson() {
    return {
      'BackLoadID': backLoadId,
      'RequestID': requestId,
      'Remarks': remarks,
      'DateReported': dateReported,
      'DeliveryDate': deliveryDate,
    };
  }

  BackLoadModel copyWith({
    String? backLoadId,
    String? requestId,
    String? remarks,
    String? dateReported,
    String? deliveryDate,
  }) {
    return BackLoadModel(
      backLoadId: backLoadId ?? this.backLoadId,
      requestId: requestId ?? this.requestId,
      remarks: remarks ?? this.remarks,
      dateReported: dateReported ?? this.dateReported,
      deliveryDate: deliveryDate ?? this.deliveryDate,
    );
  }
}
