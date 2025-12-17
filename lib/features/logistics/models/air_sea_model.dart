import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';

/// Air/Sea request model.
class AirSeaModel {
  String id;
  String clientId;
  String itemCategoryId;

  int? mobileId;
  String datePickUp;

  // Item preparation phase
  String itemPreparedAt;
  String itemPreparedEndAt;

  String preparedBy;
  // Guard endorsement phase
  String endorsedBy; // Guard name for "Endorsed to Guard" status
  // Receipt phase
  String receivedBy; // Receiver name for "Received" status
  String waybillNumber;
  String receivedAt;

  // Dispatch phase
  String tripTicketNumber;
  String driver;
  String helper;
  String dispatchedAt;
  String dropOffAt;

  String status;
  String remarks;
  String createdBy;
  String createdAt;
  String updatedAt;

  // Aggregates
  ClientModel client;
  List<String> documentReference;
  CancelRemarksModel cancelRemarks;

  AirSeaModel({
    this.id = '',
    this.clientId = '',
    this.itemCategoryId = '',
    this.mobileId,
    this.datePickUp = '',
    this.itemPreparedAt = '',
    this.itemPreparedEndAt = '',
    this.preparedBy = '',
    this.endorsedBy = '',
    this.receivedBy = '',
    this.waybillNumber = '',
    this.receivedAt = '',
    this.tripTicketNumber = '',
    this.driver = '',
    this.helper = '',
    this.dispatchedAt = '',
    this.dropOffAt = '',
    this.status = '',
    this.remarks = '',
    this.createdBy = '',
    this.createdAt = '',
    this.updatedAt = '',
    ClientModel? client,
    List<String>? documentReference,
    CancelRemarksModel? cancelRemarks,
  })  : client = client ?? ClientModel.empty(),
        documentReference = documentReference ?? <String>[],
        cancelRemarks = cancelRemarks ?? CancelRemarksModel.empty;

  /// Convenience empty factory
  static AirSeaModel empty() => AirSeaModel();

  AirSeaModel copyWith({
    String? id,
    String? clientId,
    String? itemCategoryId,
    int? mobileId,
    String? datePickUp,
    String? itemPreparedAt,
    String? itemPreparedEndAt,
    String? preparedBy,
    String? endorsedBy,
    String? receivedBy,
    String? waybillNumber,
    String? receivedAt,
    String? tripTicketNumber,
    String? driver,
    String? helper,
    String? dispatchedAt,
    String? dropOffAt,
    String? status,
    String? remarks,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
    ClientModel? client,
    List<String>? documentReference,
    CancelRemarksModel? cancelRemarks,
  }) {
    return AirSeaModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      itemCategoryId: itemCategoryId ?? this.itemCategoryId,
      mobileId: mobileId ?? this.mobileId,
      datePickUp: datePickUp ?? this.datePickUp,
      itemPreparedAt: itemPreparedAt ?? this.itemPreparedAt,
      itemPreparedEndAt: itemPreparedEndAt ?? this.itemPreparedEndAt,
      preparedBy: preparedBy ?? this.preparedBy,
      endorsedBy: endorsedBy ?? this.endorsedBy,
      receivedBy: receivedBy ?? this.receivedBy,
      waybillNumber: waybillNumber ?? this.waybillNumber,
      receivedAt: receivedAt ?? this.receivedAt,
      tripTicketNumber: tripTicketNumber ?? this.tripTicketNumber,
      driver: driver ?? this.driver,
      helper: helper ?? this.helper,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      dropOffAt: dropOffAt ?? this.dropOffAt,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      client: client ?? this.client,
      documentReference: documentReference ?? this.documentReference,
      cancelRemarks: cancelRemarks ?? this.cancelRemarks,
    );
  }

  /// Serialize to API JSON
  Map<String, dynamic> toJson() {
    return {
      'RequestID': id,
      'ClientID': clientId,
      'ItemCategoryID': itemCategoryId,
      'MobileID': mobileId,
      'DatePickUp': datePickUp,
      'ItemPreparedAt': itemPreparedAt,
      'ItemPreparedEndAt': itemPreparedEndAt,
      'PreparedBy': preparedBy,
      'ReceivedBy': receivedBy,
      'WaybillNumber': waybillNumber,
      'ReceivedAt': receivedAt,
      'TripTicketNumber': tripTicketNumber,
      'Driver': driver,
      'Helper': helper,
      'DispatchedAt': dispatchedAt,
      'DropOffAt': dropOffAt,
      'Status': status,
      'Remarks': remarks,
      'CreatedBy': createdBy,
      'CreatedAt': createdAt,
      'UpdatedAt': updatedAt,
      'Client': client.toJson(),
      'DocumentReference': documentReference,
    };
  }

  /// Parse from API JSON
  factory AirSeaModel.fromJson(Map<String, dynamic> json) {
    String firstPresent(Map<String, dynamic> m, List<String> keys,
        {String fallback = ''}) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) return m[k].toString();
      }
      return fallback;
    }

    int? parseIntOrNull(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return AirSeaModel(
      id: firstPresent(json,
          ['RequestID', 'requestID', 'RequestId', 'requestId', 'Requestid']),
      clientId: firstPresent(
          json, ['ClientID', 'clientID', 'clientId', 'ClientId']),
      itemCategoryId: firstPresent(json, [
        'ItemCategoryID',
        'itemCategoryID',
        'ItemCategoryId',
        'itemCategoryId'
      ]),
      mobileId: parseIntOrNull(
          json['MobileID'] ?? json['mobileID'] ?? json['mobileId']),
      datePickUp: firstPresent(json, [
        'DatePickUp',
        'datePickUp',
        'Datepickup',
        'datepickup'
      ]),
      itemPreparedAt: firstPresent(json, [
        'ItemPreparedAt',
        'itemPreparedAt',
        'Itempreparedat',
        'itempreparedat'
      ]),
      itemPreparedEndAt: firstPresent(json, [
        'ItemPreparedEndAt',
        'itemPreparedEndAt',
        'Itempreparedendat',
        'itempreparedendat'
      ]),
      preparedBy: firstPresent(
          json, ['PreparedBy', 'preparedBy', 'Preparedby', 'preparedby']),
      receivedBy: firstPresent(
          json, ['ReceivedBy', 'receivedBy', 'Receivedby', 'receivedby']),
      waybillNumber: firstPresent(json, [
        'WaybillNumber',
        'waybillNumber',
        'Waybillnumber',
        'waybillnumber'
      ]),
      receivedAt: firstPresent(
          json, ['ReceivedAt', 'receivedAt', 'Receivedat', 'receivedat']),
      tripTicketNumber: firstPresent(json, [
        'TripTicketNumber',
        'tripTicketNumber',
        'Tripticketnumber',
        'tripticketnumber'
      ]),
      driver: firstPresent(json, ['Driver', 'driver']),
      helper: firstPresent(json, ['Helper', 'helper']),
      dispatchedAt: firstPresent(json, [
        'DispatchedAt',
        'dispatchedAt',
        'Dispatchedat',
        'dispatchedat'
      ]),
      dropOffAt: firstPresent(json, [
        'DropOffAt',
        'dropOffAt',
        'Dropoffat',
        'dropoffat'
      ]),
      status: firstPresent(json, ['Status', 'status']),
      remarks: firstPresent(json, ['Remarks', 'remarks']),
      createdBy: firstPresent(
          json, ['CreatedBy', 'createdBy', 'Createdby', 'createdby']),
      createdAt: firstPresent(
          json, ['CreatedAt', 'createdAt', 'Createdat', 'createdat']),
      updatedAt: firstPresent(
          json, ['UpdatedAt', 'updatedAt', 'Updatedat', 'updatedat']),
      client: json['Client'] != null
          ? ClientModel.fromJson(Map<String, dynamic>.from(json['Client']))
          : ClientModel.empty(),
      documentReference:
          json['documentReference'] != null && json['documentReference'] is List
              ? List<String>.from((json['documentReference'] as List)
                  .map((e) => e?.toString() ?? ''))
              : <String>[],
      cancelRemarks: json['CancelRemarks'] != null
          ? CancelRemarksModel.fromJson(
              Map<String, dynamic>.from(json['CancelRemarks']))
          : CancelRemarksModel.empty,
    );
  }

  /// Parse from local database JSON (uses different column naming)
  factory AirSeaModel.fromDbJson(Map<String, dynamic> json) {
    // Normalize keys to lowercase to handle platform/sqlite variations
    final Map<String, dynamic> lower = {};
    json.forEach((k, v) {
      lower[k.toString().toLowerCase()] = v;
    });

    String idValue = (lower['requestid'] ?? lower['id'] ?? '').toString();

    int? parseIntOrNull(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return AirSeaModel(
      id: idValue,
      clientId: (lower['clientid'] ?? '').toString(),
      itemCategoryId: (lower['itemcategoryid'] ?? '').toString(),
      mobileId: parseIntOrNull(lower['mobileid']),
      datePickUp: (lower['datepickup'] ?? '').toString(),
      itemPreparedAt: (lower['itempreparedat'] ?? '').toString(),
      itemPreparedEndAt: (lower['itempreparedendat'] ?? '').toString(),
      preparedBy: (lower['preparedby'] ?? '').toString(),
      endorsedBy: (lower['endorsedby'] ?? '').toString(),
      receivedBy: (lower['receivedby'] ?? '').toString(),
      waybillNumber: (lower['waybillnumber'] ?? '').toString(),
      receivedAt: (lower['receivedat'] ?? '').toString(),
      tripTicketNumber: (lower['tripticketnumber'] ?? '').toString(),
      driver: (lower['driver'] ?? '').toString(),
      helper: (lower['helper'] ?? '').toString(),
      dispatchedAt: (lower['dispatchedat'] ?? '').toString(),
      dropOffAt: (lower['dropoffat'] ?? '').toString(),
      status: (lower['status'] ?? '').toString(),
      remarks: (lower['remarks'] ?? '').toString(),
      createdBy: (lower['createdby'] ?? '').toString(),
      createdAt: (lower['createdat'] ?? '').toString(),
      updatedAt: (lower['updatedat'] ?? '').toString(),
      // client, documentReference, and cancelRemarks will be loaded by DAO
    );
  }
}

