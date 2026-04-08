import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';

/// Represents a single history record for a collection account.
class CollectionHistoryModel {
  final String date;
  final String collectorName;
  final String coreStatus;
  final String delayStatus;
  final String outcomeStatus;
  final String administrativeStatus;
  final String remarks;

  const CollectionHistoryModel({
    required this.date,
    required this.collectorName,
    this.coreStatus = CollectionStatusColors.statusOngoing,
    this.delayStatus = CollectionStatusColors.statusOnSchedule,
    this.outcomeStatus = CollectionStatusColors.statusNone,
    this.administrativeStatus = CollectionStatusColors.statusForVerification,
    this.remarks = '',
  });

  factory CollectionHistoryModel.fromJson(Map<String, dynamic> json) {
    return CollectionHistoryModel(
      date: (json['Date'] ?? '').toString(),
      collectorName: (json['CollectorName'] ?? '').toString(),
      coreStatus: (json['CoreStatus'] ?? CollectionStatusColors.statusOngoing).toString(),
      delayStatus: (json['DelayStatus'] ?? CollectionStatusColors.statusOnSchedule).toString(),
      outcomeStatus: (json['OutcomeStatus'] ?? CollectionStatusColors.statusNone).toString(),
      administrativeStatus: (json['AdministrativeStatus'] ?? CollectionStatusColors.statusForVerification).toString(),
      remarks: (json['Remarks'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Date': date,
      'CollectorName': collectorName,
      'CoreStatus': coreStatus,
      'DelayStatus': delayStatus,
      'OutcomeStatus': outcomeStatus,
      'AdministrativeStatus': administrativeStatus,
      'Remarks': remarks,
    };
  }
}
