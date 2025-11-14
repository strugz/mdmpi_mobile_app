// filepath: c:\Users\JayBryanCAbaoag\Documents\VuexJaysWayFile\VuexJaysWayFile\MDMPIMobileApp\mdmpi_mobile_app\lib\features\logistics\models\pull_out_model.dart
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// Pull-out request model.
///
/// Notes:
/// - Keep date/time fields as String to match API payloads (ISO strings) and avoid
///   premature parsing in UI code.
/// - JSON keys follow backend casing (e.g., `RequestID`, `ClientID`).
class PullOutModel {
  // Identifiers and client
  String id; // maps to JSON 'RequestID'
  String clientId; // maps to JSON 'ClientID'
  String clientContactPerson; // 'ClientContactPerson'
  String formCategoryId; // 'FormCategoryID'
  String itemCategoryId; // 'ItemCategoryID'

  // Document/IRRF and reason
  String slipNo; // 'SlipNo'
  String irrfNumber; // 'IRRFNumber'
  String irrfDate; // 'IRRFDate'
  String reasonForReturn; // 'ReasonForReturn'

  // Logistics details
  String releasedBy; // 'ReleasedBy'
  String pullOutDate; // 'PullOutDate'
  String pullOutDateStartAt; // 'PullOutDateStartAt'
  String pullOutDateEndAt; // 'PullOutDateEndAt'
  String requestStatus; // 'RequestStatus'
  String tripTicketNumber; // 'TripTicketNumber'
  String driver; // 'Driver'
  String helper; // 'Helper'

  // Audit
  String createdAt; // 'CreatedAt'
  String updatedAt; // 'UpdatedAt'

  // Aggregates
  ClientModel client; // 'Client'
  List<String> documentReference; // 'DocumentReference'

  PullOutModel({
    this.id = '',
    this.clientId = '',
    this.clientContactPerson = '',
    this.formCategoryId = '',
    this.itemCategoryId = '',
    this.slipNo = '',
    this.irrfNumber = '',
    this.irrfDate = '',
    this.reasonForReturn = '',
    this.releasedBy = '',
    this.pullOutDate = '',
    this.pullOutDateStartAt = '',
    this.pullOutDateEndAt = '',
    this.requestStatus = '',
    this.tripTicketNumber = '',
    this.driver = '',
    this.helper = '',
    this.createdAt = '',
    this.updatedAt = '',
    ClientModel? client,
    List<String>? documentReference,
  })  : client = client ?? ClientModel.empty(),
        documentReference = documentReference ?? <String>[];

  /// Convenience empty factory
  static PullOutModel empty() => PullOutModel();

  PullOutModel copyWith({
    String? id,
    String? clientId,
    String? clientContactPerson,
    String? formCategoryId,
    String? itemCategoryId,
    String? slipNo,
    String? irrfNumber,
    String? irrfDate,
    String? reasonForReturn,
    String? releasedBy,
    String? pullOutDate,
    String? pullOutDateStartAt,
    String? pullOutDateEndAt,
    String? requestStatus,
    String? tripTicketNumber,
    String? driver,
    String? helper,
    String? createdAt,
    String? updatedAt,
    ClientModel? client,
    List<String>? documentReference,
  }) {
    return PullOutModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientContactPerson: clientContactPerson ?? this.clientContactPerson,
      formCategoryId: formCategoryId ?? this.formCategoryId,
      itemCategoryId: itemCategoryId ?? this.itemCategoryId,
      slipNo: slipNo ?? this.slipNo,
      irrfNumber: irrfNumber ?? this.irrfNumber,
      irrfDate: irrfDate ?? this.irrfDate,
      reasonForReturn: reasonForReturn ?? this.reasonForReturn,
      releasedBy: releasedBy ?? this.releasedBy,
      pullOutDate: pullOutDate ?? this.pullOutDate,
      pullOutDateStartAt: pullOutDateStartAt ?? this.pullOutDateStartAt,
      pullOutDateEndAt: pullOutDateEndAt ?? this.pullOutDateEndAt,
      requestStatus: requestStatus ?? this.requestStatus,
      tripTicketNumber: tripTicketNumber ?? this.tripTicketNumber,
      driver: driver ?? this.driver,
      helper: helper ?? this.helper,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      client: client ?? this.client,
      documentReference: documentReference ?? this.documentReference,
    );
  }

  /// Serialize to API JSON
  Map<String, dynamic> toJson() {
    return {
      'RequestID': id,
      'ClientID': clientId,
      'ClientContactPerson': clientContactPerson,
      'FormCategoryID': formCategoryId,
      'ItemCategoryID': itemCategoryId,
      'SlipNo': slipNo,
      'IRRFNumber': irrfNumber,
      'IRRFDate': irrfDate,
      'ReasonForReturn': reasonForReturn,
      'ReleasedBy': releasedBy,
      'PullOutDate': pullOutDate,
      'PullOutDateStartAt': pullOutDateStartAt,
      'PullOutDateEndAt': pullOutDateEndAt,
      'RequestStatus': requestStatus,
      'TripTicketNumber': tripTicketNumber,
      'Driver': driver,
      'Helper': helper,
      'CreatedAt': createdAt,
      'UpdatedAt': updatedAt,
      'Client': client.toJson(),
      'DocumentReference': documentReference,
    };
  }

  /// Minimal JSON for inserts; adjust to backend-required fields
  Map<String, dynamic> toJsonInsert() {
    return {
      'ClientID': clientId,
      'ClientContactPerson': clientContactPerson,
      'FormCategoryID': formCategoryId,
      'ItemCategoryID': itemCategoryId,
      'SlipNo': slipNo,
      'IRRFNumber': irrfNumber,
      'IRRFDate': irrfDate,
      'ReasonForReturn': reasonForReturn,
      'ReleasedBy': releasedBy,
      'PullOutDate': pullOutDate,
      'RequestStatus': requestStatus,
      'TripTicketNumber': tripTicketNumber,
      'Driver': driver,
      'Helper': helper,
    };
  }

  /// Parse from API JSON
  factory PullOutModel.fromJson(Map<String, dynamic> json) {
    return PullOutModel(
      id: (json['RequestID']?.toString() ?? ''),
      clientId: (json['ClientID']?.toString() ?? ''),
      clientContactPerson: (json['ClientContactPerson']?.toString() ?? ''),
      formCategoryId: (json['FormCategoryID']?.toString() ?? ''),
      itemCategoryId: (json['ItemCategoryID']?.toString() ?? ''),
      slipNo: (json['SlipNo']?.toString() ?? ''),
      irrfNumber: (json['IRRFNumber']?.toString() ?? ''),
      irrfDate: (json['IRRFDate']?.toString() ?? ''),
      reasonForReturn: (json['ReasonForReturn']?.toString() ?? ''),
      releasedBy: (json['ReleasedBy']?.toString() ?? ''),
      pullOutDate: (json['PullOutDate']?.toString() ?? ''),
      pullOutDateStartAt: (json['PullOutDateStartAt']?.toString() ?? ''),
      pullOutDateEndAt: (json['PullOutDateEndAt']?.toString() ?? ''),
      requestStatus: (json['RequestStatus']?.toString() ?? ''),
      tripTicketNumber: (json['TripTicketNumber']?.toString() ?? ''),
      driver: (json['Driver']?.toString() ?? ''),
      helper: (json['Helper']?.toString() ?? ''),
      createdAt: (json['CreatedAt']?.toString() ?? ''),
      updatedAt: (json['UpdatedAt']?.toString() ?? ''),
      client: json['Client'] != null
          ? ClientModel.fromJson(Map<String, dynamic>.from(json['Client']))
          : ClientModel.empty(),
      documentReference: json['DocumentReference'] != null
          ? List<String>.from((json['DocumentReference'] as List).map((e) => e?.toString() ?? ''))
          : <String>[],
    );
  }
}

