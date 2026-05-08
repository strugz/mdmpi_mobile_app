// collection_status_colors is intentionally not imported anymore; history entries default to empty status.

/// Represents a single history record for a collection account.
class CollectionHistoryModel {
  final String date;
  final String collectorName;
  final String status;
  final String remarks;
  final double totalCollected;

  const CollectionHistoryModel({
    required this.date,
    required this.collectorName,
    // History entries default to an empty status (removed 'On-going')
    this.status = '',
    this.remarks = 'No remarks',
    this.totalCollected = 0,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Date': date,
      'CollectorName': collectorName,
      'Status': status,
      'Remarks': remarks,
      'TotalCollected': totalCollected,
    };
  }
}
