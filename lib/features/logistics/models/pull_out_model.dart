// filepath: c:\Users\JayBryanCAbaoag\Documents\VuexJaysWayFile\VuexJaysWayFile\MDMPIMobileApp\mdmpi_mobile_app\lib\features\logistics\models\pull_out_model.dart
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// Pull-out request model.
class PullOutModel {
  // Identifiers and client
  String id;
  String clientId;
  String clientContactPerson;
  String formCategoryId;
  String itemCategoryId;

  // Document/IRRF and reason
  String slipNo;
  String irrfNumber;
  String irrfDate;
  String reasonForReturn;

  // Logistics details
  String releasedBy;
  String pullOutDate;
  String pullOutDateStartAt;
  String pullOutDateEndAt;
  String requestStatus;
  String tripTicketNumber;
  String driver;
  String helper;

  // Audit
  String createdAt;
  String updatedAt;
  String createdBy;
  String requestedBy;

  // Aggregates
  ClientModel client;
  List<String> documentReference;

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
    this.createdBy = '',
    this.requestedBy = '',
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
    String? createdBy,
    String? requestedBy,
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
      createdBy: createdBy ?? this.createdBy,
      requestedBy: requestedBy ?? this.requestedBy,
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
      'CreatedBy': createdBy,
      'RequestedBy': requestedBy,
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
      'CreatedBy': createdBy,
      'RequestedBy': requestedBy,
    };
  }

  /// Parse from API JSON
  factory PullOutModel.fromJson(Map<String, dynamic> json) {
    // Helper to retrieve the first non-null value from a list of possible keys
    String _firstPresent(Map<String, dynamic> m, List<String> keys, {String fallback = ''}) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) return m[k].toString();
      }
      return fallback;
    }

    String _safeListFirst(Map<String, dynamic> m, String key) {
      final v = m.containsKey(key) ? m[key] : null;
      if (v is List && v.isNotEmpty) return v.first?.toString() ?? '';
      return '';
    }

    return PullOutModel(
      id: _firstPresent(json, ['RequestID', 'requestID', 'RequestId', 'requestId', 'Requestid']),
      clientId: _firstPresent(json, ['ClientID', 'clientID', 'clientId', 'ClientId', 'clientId']),
      clientContactPerson: _firstPresent(json, ['ClientContactPerson', 'clientContactPerson', 'ClientContactperson', 'clientcontactperson']),
      formCategoryId: _firstPresent(json, ['FormCategoryID', 'formCategoryID', 'FormCategoryId', 'formCategoryId']),
      itemCategoryId: _firstPresent(json, ['ItemCategoryID', 'itemCategoryID', 'ItemCategoryId', 'itemCategoryId']),
      slipNo: _firstPresent(json, ['SlipNo', 'slipNo', 'Slipno', 'slipno']),
      irrfNumber: _firstPresent(json, ['IRRFNumber', 'irrfNumber', 'IrrfNumber', 'irrfnumber']),
      irrfDate: _firstPresent(json, ['IRRFDate', 'irrfDate', 'IrrfDate', 'irrfdate']),
      reasonForReturn: _firstPresent(json, ['ReasonForReturn', 'reasonForReturn', 'ReasonforReturn', 'reasonforreturn']),
      releasedBy: _firstPresent(json, ['ReleasedBy', 'releasedBy', 'Releasedby', 'releasedby']),
      pullOutDate: _firstPresent(json, ['PullOutDate', 'pullOutDate', 'PulloutDate', 'pulloutDate']),
      pullOutDateStartAt: _firstPresent(json, ['PullOutDateStartAt', 'pullOutDateStartAt', 'PullOutDateStartat', 'pulloutdatestartat']),
      pullOutDateEndAt: _firstPresent(json, ['PullOutDateEndAt', 'pullOutDateEndAt', 'PullOutDateEndat', 'pulloutdateendat']),
      requestStatus: _firstPresent(json, ['RequestStatus', 'requestStatus', 'Requeststatus', 'requeststatus']),
      tripTicketNumber: _firstPresent(json, ['TripTicketNumber', 'tripTicketNumber', 'TripTicketnumber', 'tripticketnumber']),
      driver: _firstPresent(json, ['Driver', 'driver']),
      helper: _firstPresent(json, ['Helper', 'helper']),
      createdAt: _firstPresent(json, ['CreatedAt', 'createdAt', 'Createdat', 'createdat']),
      updatedAt: _firstPresent(json, ['UpdatedAt', 'updatedAt', 'Updatedat', 'updatedat']),
      createdBy: _firstPresent(json, ['CreatedBy', 'createdBy', 'Createdby', 'createdby']),
      requestedBy: _firstPresent(json, ['RequestedBy', 'requestedBy', 'Requestedby', 'requestedby']),
      client: json['Client'] != null ? ClientModel.fromJson(Map<String, dynamic>.from(json['Client'])) : ClientModel.empty(),
      documentReference: json['DocumentReference'] != null && json['DocumentReference'] is List ? List<String>.from((json['DocumentReference'] as List).map((e) => e?.toString() ?? '')) : <String>[],
    );
  }
}
