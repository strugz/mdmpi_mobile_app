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
  int? mobileID;
  String mobileName;

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
    this.mobileID,
    this.mobileName = '',
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
    int? mobileID,
    String? mobileName,
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
      mobileID: mobileID ?? this.mobileID,
      mobileName: mobileName ?? this.mobileName,
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
      'MobileID': mobileID,
      'MobileName': mobileName,
      'CreatedAt': createdAt,
      'UpdatedAt': updatedAt,
      'CreatedBy': createdBy,
      'RequestedBy': requestedBy,
      'Client': client.toJson(),
      'DocumentReference': documentReference,
    };
  }

  /// Parse from API JSON
  factory PullOutModel.fromJson(Map<String, dynamic> json) {
    String firstPresent(Map<String, dynamic> m, List<String> keys,
        {String fallback = ''}) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) return m[k].toString();
      }
      return fallback;
    }

    int? firstPresentInt(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) {
          final v = m[k];
          if (v is int) return v;
          final parsed = int.tryParse(v.toString());
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    return PullOutModel(
      id: firstPresent(json,
          ['RequestID', 'requestID', 'RequestId', 'requestId', 'Requestid']),
      clientId: firstPresent(
          json, ['ClientID', 'clientID', 'clientId', 'ClientId', 'clientId']),
      clientContactPerson: firstPresent(json, [
        'ClientContactPerson',
        'clientContactPerson',
        'ClientContactperson',
        'clientcontactperson'
      ]),
      formCategoryId: firstPresent(json, [
        'FormCategoryID',
        'formCategoryID',
        'FormCategoryId',
        'formCategoryId'
      ]),
      itemCategoryId: firstPresent(json, [
        'ItemCategoryID',
        'itemCategoryID',
        'ItemCategoryId',
        'itemCategoryId'
      ]),
      slipNo: firstPresent(json, ['SlipNo', 'slipNo', 'Slipno', 'slipno']),
      irrfNumber: firstPresent(
          json, ['IRRFNumber', 'irrfNumber', 'IrrfNumber', 'irrfnumber']),
      irrfDate:
          firstPresent(json, ['IRRFDate', 'irrfDate', 'IrrfDate', 'irrfdate']),
      reasonForReturn: firstPresent(json, [
        'ReasonForReturn',
        'reasonForReturn',
        'ReasonforReturn',
        'reasonforreturn'
      ]),
      releasedBy: firstPresent(
          json, ['ReleasedBy', 'releasedBy', 'Releasedby', 'releasedby']),
      pullOutDate: firstPresent(
          json, ['PullOutDate', 'pullOutDate', 'PulloutDate', 'pulloutDate']),
      pullOutDateStartAt: firstPresent(json, [
        'PullOutDateStartAt',
        'pullOutDateStartAt',
        'PullOutDateStartat',
        'pulloutdatestartat'
      ]),
      pullOutDateEndAt: firstPresent(json, [
        'PullOutDateEndAt',
        'pullOutDateEndAt',
        'PullOutDateEndat',
        'pulloutdateendat'
      ]),
      requestStatus: firstPresent(json,
          ['RequestStatus', 'requestStatus', 'Requeststatus', 'requeststatus']),
      tripTicketNumber: firstPresent(json, [
        'TripTicketNumber',
        'tripTicketNumber',
        'TripTicketnumber',
        'tripticketnumber'
      ]),
      driver: firstPresent(json, ['Driver', 'driver']),
      helper: firstPresent(json, ['Helper', 'helper']),
      mobileID: firstPresentInt(json, ['MobileID', 'mobileID', 'Mobileid', 'mobileid']),
      mobileName: firstPresent(json, ['MobileName', 'mobileName', 'Mobile', 'mobile']),
      createdAt: firstPresent(
          json, ['CreatedAt', 'createdAt', 'Createdat', 'createdat']),
      updatedAt: firstPresent(
          json, ['UpdatedAt', 'updatedAt', 'Updatedat', 'updatedat']),
      createdBy: firstPresent(
          json, ['CreatedBy', 'createdBy', 'Createdby', 'createdby']),
      requestedBy: firstPresent(
          json, ['RequestedBy', 'requestedBy', 'Requestedby', 'requestedby']),
      client: json['Client'] != null
          ? ClientModel.fromJson(Map<String, dynamic>.from(json['Client']))
          : ClientModel.empty(),
      documentReference:
          json['DocumentReference'] != null && json['DocumentReference'] is List
              ? List<String>.from((json['DocumentReference'] as List)
                  .map((e) => e?.toString() ?? ''))
              : <String>[],
    );
  }
}
