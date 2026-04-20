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

  // Provincial delivery phase
  // Backwards-compatible textual fields (kept for existing callers)
  String provincialReceiverName;
  String provincialPickUpAt;
  String provincialDeliveredTo;
  String provincialDeliveredAt;
  String provincialRemarks;
  String provincialProofImagePath;

  // New structured fields (preferred) — timestamps as DateTime and extra metadata
  DateTime? provincialPickUpAtDateTime;
  DateTime? provincialInTransitAt;
  DateTime? provincialDeliveredAtDateTime;

  /// Name or id of the provincial actor who performed the pick-up
  String provincialPickUpBy;

  /// Explicit receiver name captured at delivery (more explicit than legacy provincialReceiverName)
  String provincialDeliveredReceiverName;

  // Proof/signature files are uploaded via ImageRepository and must not be
  // stored as DB blobs or included in the main request DTO.

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
    this.provincialReceiverName = '',
    this.provincialPickUpAt = '',
    this.provincialDeliveredTo = '',
    this.provincialDeliveredAt = '',
    this.provincialRemarks = '',
    this.provincialProofImagePath = '',
    this.provincialPickUpAtDateTime,
    this.provincialInTransitAt,
    this.provincialDeliveredAtDateTime,
    this.provincialPickUpBy = '',
    this.provincialDeliveredReceiverName = '',
    // Local proof/signature paths are intentionally not part of the model ctor
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
    String? provincialReceiverName,
    String? provincialPickUpAt,
    String? provincialDeliveredTo,
    String? provincialDeliveredAt,
    String? provincialRemarks,
    String? provincialProofImagePath,
    DateTime? provincialPickUpAtDateTime,
    DateTime? provincialInTransitAt,
    DateTime? provincialDeliveredAtDateTime,
    String? provincialPickUpBy,
    String? provincialDeliveredReceiverName,
    // Local proof/signature path parameters removed; upload handled separately
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
      provincialReceiverName: provincialReceiverName ?? this.provincialReceiverName,
      provincialPickUpAt: provincialPickUpAt ?? this.provincialPickUpAt,
      provincialDeliveredTo: provincialDeliveredTo ?? this.provincialDeliveredTo,
      provincialDeliveredAt: provincialDeliveredAt ?? this.provincialDeliveredAt,
      provincialRemarks: provincialRemarks ?? this.provincialRemarks,
      provincialProofImagePath: provincialProofImagePath ?? this.provincialProofImagePath,
      provincialPickUpAtDateTime: provincialPickUpAtDateTime ?? this.provincialPickUpAtDateTime,
      provincialInTransitAt: provincialInTransitAt ?? this.provincialInTransitAt,
      provincialDeliveredAtDateTime: provincialDeliveredAtDateTime ?? this.provincialDeliveredAtDateTime,
      provincialPickUpBy: provincialPickUpBy ?? this.provincialPickUpBy,
      provincialDeliveredReceiverName: provincialDeliveredReceiverName ?? this.provincialDeliveredReceiverName,
      // Local proof/signature path assignments removed; use ImageRepository for uploads
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
      'ProvincialReceiverName': provincialReceiverName,
      // Prefer structured ISO8601 timestamps when available, fall back to legacy string
      'ProvincialPickUpAt': provincialPickUpAtDateTime != null
          ? provincialPickUpAtDateTime!.toUtc().toIso8601String()
          : provincialPickUpAt,
      'ProvincialInTransitAt': provincialInTransitAt != null
          ? provincialInTransitAt!.toUtc().toIso8601String()
          : null,
      'ProvincialDeliveredTo': provincialDeliveredTo,
      'ProvincialDeliveredAt': provincialDeliveredAtDateTime != null
          ? provincialDeliveredAtDateTime!.toUtc().toIso8601String()
          : provincialDeliveredAt,
      'ProvincialDeliveredReceiverName': provincialDeliveredReceiverName,
      'ProvincialPickUpBy': provincialPickUpBy,
      // Proof/signature paths are transient local paths; include them in payloads when needed
      // Note: do NOT include local file paths for proofs/signatures in the
      // main DTO. These are uploaded separately via ImageRepository.
      'ProvincialRemarks': provincialRemarks,
      'ProvincialProofImagePath': provincialProofImagePath,
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

    // DateTime parsing for DB values is done inline below to avoid helper scope issues

    DateTime? parseDateTimeOrNull(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.tryParse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    // (parseDateTimeOrNull defined above)

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
      provincialReceiverName: firstPresent(json, [
        'ProvincialReceiverName',
        'provincialReceiverName',
      ]),
      provincialPickUpAt: firstPresent(json, [
        'ProvincialPickUpAt',
        'provincialPickUpAt',
      ]),
      provincialPickUpAtDateTime: parseDateTimeOrNull(firstPresent(json, [
        'ProvincialPickUpAt',
        'provincialPickUpAt',
        'provincial_pick_up_at',
      ])),
      provincialInTransitAt: parseDateTimeOrNull(firstPresent(json, [
        'ProvincialInTransitAt',
        'provincialInTransitAt',
        'provincial_in_transit_at',
      ])),
      provincialDeliveredTo: firstPresent(json, [
        'ProvincialDeliveredTo',
        'provincialDeliveredTo',
      ]),
      provincialDeliveredAt: firstPresent(json, [
        'ProvincialDeliveredAt',
        'provincialDeliveredAt',
      ]),
      provincialRemarks: firstPresent(json, [
        'ProvincialRemarks',
        'provincialRemarks',
      ]),
      provincialProofImagePath: firstPresent(json, [
        'ProvincialProofImagePath',
        'provincialProofImagePath',
      ]),
      // Image/signature local paths are not parsed into model; uploads handled separately
      provincialPickUpBy: firstPresent(json, [
        'ProvincialPickUpBy',
        'provincialPickUpBy',
        'provincial_pick_up_by'
      ]),
      provincialDeliveredReceiverName: firstPresent(json, [
        'ProvincialDeliveredReceiverName',
        'provincialDeliveredReceiverName',
        'provincial_delivered_receiver_name'
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
      provincialReceiverName: (lower['provincialreceivername'] ?? '').toString(),
      provincialPickUpAt: (lower['provincialpickupat'] ?? '').toString(),
      provincialDeliveredTo: (lower['provincialdeliveredto'] ?? '').toString(),
      provincialDeliveredAt: (lower['provincialdeliveredat'] ?? '').toString(),
      provincialRemarks: (lower['provincialremarks'] ?? '').toString(),
      provincialProofImagePath: (lower['provincialproofimagepath'] ?? '').toString(),
      provincialPickUpAtDateTime: (lower['provincialpickupat'] ?? '').toString().isNotEmpty
          ? DateTime.tryParse((lower['provincialpickupat'] ?? '').toString())
          : null,
      provincialInTransitAt: (lower['provincialintransitat'] ?? '').toString().isNotEmpty
          ? DateTime.tryParse((lower['provincialintransitat'] ?? '').toString())
          : null,
      provincialDeliveredAtDateTime: (lower['provincialdeliveredat'] ?? '').toString().isNotEmpty
          ? DateTime.tryParse((lower['provincialdeliveredat'] ?? '').toString())
          : null,
      provincialPickUpBy: (lower['provincialpickupby'] ?? '').toString(),
      provincialDeliveredReceiverName: (lower['provincialdeliveredreceivername'] ?? '').toString(),
      // Local image/signature paths omitted here; repository handles uploads separately
      status: (lower['status'] ?? '').toString(),
      remarks: (lower['remarks'] ?? '').toString(),
      createdBy: (lower['createdby'] ?? '').toString(),
      createdAt: (lower['createdat'] ?? '').toString(),
      updatedAt: (lower['updatedat'] ?? '').toString(),
      // client, documentReference, and cancelRemarks will be loaded by DAO
    );
  }
}

