// collection_status_colors is intentionally not imported anymore; history entries default to empty status.

/// Represents a single history record for a collection account.
class CollectionHistoryModel {
  final String date;
  final String collectorName;
  final String status;
  final String remarks;
  final double totalCollected;
  final String? bankName;
  final String? checkNumber;
  final String? checkDate;
  final String? purposeOfVisit;

  const CollectionHistoryModel({
    required this.date,
    required this.collectorName,
    // History entries default to an empty status (removed 'On-going')
    this.status = '',
    this.remarks = 'No remarks',
    this.totalCollected = 0,
    this.bankName,
    this.checkNumber,
    this.checkDate,
    this.purposeOfVisit,
  });

  factory CollectionHistoryModel.fromJson(Map<String, dynamic> json) {
    return CollectionHistoryModel(
      date: (json['Date'] ?? 'N/A').toString(),
      collectorName: (json['CollectorName'] ?? 'Unassigned').toString(),
      status: (json['Status'] ?? '').toString(),
      remarks: (json['Remarks'] ?? 'No remarks').toString(),
      totalCollected: (json['TotalCollected'] is num)
          ? (json['TotalCollected'] as num).toDouble()
          : double.tryParse(json['TotalCollected']?.toString() ?? '') ?? 0,
      bankName: json['BankName']?.toString(),
      checkNumber: json['CheckNumber']?.toString(),
      checkDate: json['CheckDate']?.toString(),
      purposeOfVisit: json['PurposeOfVisit']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Date': date,
      'CollectorName': collectorName,
      'Status': status,
      'Remarks': remarks,
      'TotalCollected': totalCollected,
      'BankName': bankName,
      'CheckNumber': checkNumber,
      'CheckDate': checkDate,
      'PurposeOfVisit': purposeOfVisit,
    };
  }
}
