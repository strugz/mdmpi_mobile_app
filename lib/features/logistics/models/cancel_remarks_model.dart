class CancelRemarksModel {
  final String requestId; // Made final as const objects should be immutable
  final String remarks; // Made final
  final String date; // Made final

  // Add a const constructor
  const CancelRemarksModel({
    required this.requestId,
    required this.remarks,
    required this.date,
  });

  /// Convert model to Json structure so that you can store data in Firebase
  Map<String, dynamic> toJson() {
    return {
      'RequestID': requestId,
      'Remarks': remarks,
      'Date': date,
    };
  }

  // Change empty() to be a static const field
  static const CancelRemarksModel empty =
      CancelRemarksModel(requestId: '', remarks: '', date: '');

  // Factory constructor for fromJson
  factory CancelRemarksModel.fromJson(Map<String, dynamic> json) {
    return CancelRemarksModel(
      requestId: json['RequestID'],
      remarks: json['Remarks'],
      date: json['Date'],
    );
  }
}
