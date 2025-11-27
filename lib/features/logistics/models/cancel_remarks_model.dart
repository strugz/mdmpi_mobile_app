class CancelRemarksModel {
  final String requestId; // Made final as const objects should be immutable
  final String remarks; // Made final
  final String date; // Made final
  final String userUpdated; // Made final

  // Add a const constructor
  const CancelRemarksModel({
    required this.requestId,
    required this.remarks,
    required this.date,
    required this.userUpdated,
  });

  /// Convert model to Json structure so that you can store data in Firebase
  Map<String, dynamic> toJson() {
    return {
      'RequestID': requestId,
      'Remarks': remarks,
      'Date': date,
      'UserUpdated': userUpdated,
    };
  }

  // Change empty() to be a static const field
  static const CancelRemarksModel empty =
      CancelRemarksModel(requestId: '', remarks: '', date: '', userUpdated: '');

  // Factory constructor for fromJson
  factory CancelRemarksModel.fromJson(Map<String, dynamic> json) {
    return CancelRemarksModel(
      requestId: (json['RequestID']?.toString() ?? ''),
      remarks: (json['Remarks']?.toString() ?? ''),
      date: (json['Date']?.toString() ?? ''),
      userUpdated: (json['UserUpdated']?.toString() ?? ''),
    );
  }

  /// Return a copy with optional overrides
  CancelRemarksModel copyWith({String? requestId, String? remarks, String? date, String? userUpdated}) {
    return CancelRemarksModel(
      requestId: requestId ?? this.requestId,
      remarks: remarks ?? this.remarks,
      date: date ?? this.date,
      userUpdated: userUpdated ?? this.userUpdated,
    );
  }
}
