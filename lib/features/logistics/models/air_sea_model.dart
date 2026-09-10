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

  String provincialPickUpBy;
  String provincialPickUpAt;
  String provincialInTransitAt;
  String provincialInTransitLocation;
  String provincialDeliveredEndAt;
  String provincialDeliveredLocation;
  String provincialReceiverName;

  String status;
  String remarks;
  String createdBy;
  String createdAt;
  String updatedAt;

  /// Empty for base 'Air / Sea / Land' requests (legacy rows have no value);
  /// FormCategoryIds.airSeaHd for 'Air / Sea / Land HD' requests.
  String formCategoryID;

  /// Mode of shipment chosen on the form: 'Air', 'Sea' or 'Land'
  /// (see ShippingMethods). Empty for rows created before the field existed.
  String shippingMethod;

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
    this.provincialPickUpBy = '',
    this.provincialPickUpAt = '',
    this.provincialInTransitAt = '',
    this.provincialInTransitLocation = '',
    this.provincialDeliveredEndAt = '',
    this.provincialDeliveredLocation = '',
    this.provincialReceiverName = '',
    this.status = '',
    this.remarks = '',
    this.createdBy = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.formCategoryID = '',
    this.shippingMethod = '',
    ClientModel? client,
    List<String>? documentReference,
    CancelRemarksModel? cancelRemarks,
  })  : client = client ?? ClientModel.empty(),
        documentReference = documentReference ?? <String>[],
        cancelRemarks = cancelRemarks ?? CancelRemarksModel.empty;

  /// Convenience empty factory
  static AirSeaModel empty() => AirSeaModel();

  static String _firstPresent(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      if (!map.containsKey(key)) continue;

      final value = map[key];
      if (value == null) continue;

      final normalized = value.toString();
      if (normalized.isNotEmpty) return normalized;
    }

    return fallback;
  }

  static dynamic _firstPresentValue(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (!map.containsKey(key)) continue;

      final value = map[key];
      if (value == null) continue;

      if (value is String && value.trim().isEmpty) continue;

      return value;
    }

    return null;
  }

  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTimeOrNull(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;

    try {
      return DateTime.tryParse(normalized);
    } catch (_) {
      return null;
    }
  }

  static String _normalizeDateTimeString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;
    if (value is DateTime) return value.toUtc().toIso8601String();

    final normalized = value.toString().trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'null') {
      return fallback;
    }

    return normalized;
  }

  /// Legacy compatibility alias. Prefer using [provincialDeliveredEndAt].
  String get provincialDeliveredAt => provincialDeliveredEndAt;

  set provincialDeliveredAt(String value) {
    provincialDeliveredEndAt = _normalizeDateTimeString(value);
  }

  /// Legacy compatibility alias. Prefer using [provincialDeliveredEndAt].
  DateTime? get provincialDeliveredAtDateTime =>
      _parseDateTimeOrNull(provincialDeliveredEndAt);

  set provincialDeliveredAtDateTime(DateTime? value) {
    provincialDeliveredEndAt = _normalizeDateTimeString(value);
  }

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

    String? provincialPickUpBy,
    String? provincialPickUpAt,
    String? provincialInTransitAt,
    String? provincialInTransitLocation,
    String? provincialDeliveredEndAt,
    String? provincialDeliveredLocation,
    String? provincialReceiverName,

    String? status,
    String? remarks,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
    String? formCategoryID,
    String? shippingMethod,
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
      provincialPickUpBy: provincialPickUpBy ?? this.provincialPickUpBy,
      provincialPickUpAt: provincialPickUpAt ?? this.provincialPickUpAt,
      provincialInTransitAt:
          provincialInTransitAt ?? this.provincialInTransitAt,
      provincialInTransitLocation:
          provincialInTransitLocation ?? this.provincialInTransitLocation,
      provincialDeliveredEndAt:
          provincialDeliveredEndAt ?? this.provincialDeliveredEndAt,
      provincialDeliveredLocation:
          provincialDeliveredLocation ?? this.provincialDeliveredLocation,
      provincialReceiverName:
          provincialReceiverName ?? this.provincialReceiverName,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      formCategoryID: formCategoryID ?? this.formCategoryID,
      shippingMethod: shippingMethod ?? this.shippingMethod,
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
      'ProvincialPickUpBy': provincialPickUpBy,
      'ProvincialPickUpAt': provincialPickUpAt,
      'ProvincialInTransitAt': provincialInTransitAt,
      'ProvincialInTransitLocation': provincialInTransitLocation,
      'ProvincialDeliveredEndAt': provincialDeliveredEndAt,
      'ProvincialDeliveredLocation': provincialDeliveredLocation,
      'ProvincialReceiverName': provincialReceiverName,
      'ProvincialDeliveredTo': provincialDeliveredLocation,
      'ProvincialDeliveredAt': provincialDeliveredEndAt,
      'Status': status,
      'Remarks': remarks,
      'CreatedBy': createdBy,
      'CreatedAt': createdAt,
      'UpdatedAt': updatedAt,
      'FormCategoryID': formCategoryID.isEmpty ? null : formCategoryID,
      'ShippingMethod': shippingMethod.isEmpty ? null : shippingMethod,
      'Client': client.toJson(),
      'DocumentReference': documentReference,
    };
  }

  /// Parse from API JSON
  factory AirSeaModel.fromJson(Map<String, dynamic> json) {
    final provincialReceiverNameValue = _firstPresent(json, [
      'ProvincialReceiverName',
      'provincialReceiverName',
      'provincial_receiver_name',
      'ProvincialDeliveredReceiverName',
      'provincialDeliveredReceiverName',
      'provincial_delivered_receiver_name',
    ]);

    final provincialPickUpAtValue = _firstPresentValue(json, [
      'ProvincialPickUpAt',
      'provincialPickUpAt',
      'provincial_pick_up_at',
    ]);
    final provincialInTransitAtValue = _firstPresentValue(json, [
      'ProvincialInTransitAt',
      'provincialInTransitAt',
      'provincial_in_transit_at',
    ]);
    final provincialDeliveredEndAtValue = _firstPresentValue(json, [
      'ProvincialDeliveredEndAt',
      'provincialDeliveredEndAt',
      'provincial_delivered_end_at',
      'ProvincialDeliveredAt',
      'provincialDeliveredAt',
      'provincial_delivered_at',
    ]);
    final provincialDeliveredLocationValue = _firstPresent(json, [
      'ProvincialDeliveredLocation',
      'provincialDeliveredLocation',
      'provincial_delivered_location',
      'ProvincialDeliveredTo',
      'provincialDeliveredTo',
      'provincial_delivered_to',
    ]);

    return AirSeaModel(
      id: _firstPresent(json,
          ['RequestID', 'requestID', 'RequestId', 'requestId', 'Requestid']),
      clientId:
          _firstPresent(json, ['ClientID', 'clientID', 'clientId', 'ClientId']),
      itemCategoryId: _firstPresent(json, [
        'ItemCategoryID',
        'itemCategoryID',
        'ItemCategoryId',
        'itemCategoryId'
      ]),
      mobileId: _parseIntOrNull(
          json['MobileID'] ?? json['mobileID'] ?? json['mobileId']),
      datePickUp: _firstPresent(
          json, ['DatePickUp', 'datePickUp', 'Datepickup', 'datepickup']),
      itemPreparedAt: _firstPresent(json, [
        'ItemPreparedAt',
        'itemPreparedAt',
        'Itempreparedat',
        'itempreparedat'
      ]),
      itemPreparedEndAt: _firstPresent(json, [
        'ItemPreparedEndAt',
        'itemPreparedEndAt',
        'Itempreparedendat',
        'itempreparedendat'
      ]),
      preparedBy: _firstPresent(
          json, ['PreparedBy', 'preparedBy', 'Preparedby', 'preparedby']),
      receivedBy: _firstPresent(
          json, ['ReceivedBy', 'receivedBy', 'Receivedby', 'receivedby']),
      waybillNumber: _firstPresent(json,
          ['WaybillNumber', 'waybillNumber', 'Waybillnumber', 'waybillnumber']),
      receivedAt: _firstPresent(
          json, ['ReceivedAt', 'receivedAt', 'Receivedat', 'receivedat']),
      tripTicketNumber: _firstPresent(json, [
        'TripTicketNumber',
        'tripTicketNumber',
        'Tripticketnumber',
        'tripticketnumber'
      ]),
      driver: _firstPresent(json, ['Driver', 'driver']),
      helper: _firstPresent(json, ['Helper', 'helper']),
      dispatchedAt: _firstPresent(json,
          ['DispatchedAt', 'dispatchedAt', 'Dispatchedat', 'dispatchedat']),
      dropOffAt: _firstPresent(
          json, ['DropOffAt', 'dropOffAt', 'Dropoffat', 'dropoffat']),
      provincialPickUpBy: _firstPresent(json, [
        'ProvincialPickUpBy',
        'provincialPickUpBy',
        'provincial_pick_up_by'
      ]),
      provincialPickUpAt: _normalizeDateTimeString(provincialPickUpAtValue),
      provincialInTransitAt:
          _normalizeDateTimeString(provincialInTransitAtValue),
      provincialInTransitLocation: _firstPresent(json, [
        'ProvincialInTransitLocation',
        'provincialInTransitLocation',
        'provincial_in_transit_location',
      ]),
      provincialDeliveredEndAt:
          _normalizeDateTimeString(provincialDeliveredEndAtValue),
      provincialDeliveredLocation: provincialDeliveredLocationValue,
      provincialReceiverName: provincialReceiverNameValue,
      status: _firstPresent(json, ['Status', 'status']),
      remarks: _firstPresent(json, ['Remarks', 'remarks']),
      createdBy: _firstPresent(
          json, ['CreatedBy', 'createdBy', 'Createdby', 'createdby']),
      createdAt: _firstPresent(
          json, ['CreatedAt', 'createdAt', 'Createdat', 'createdat']),
      updatedAt: _firstPresent(
          json, ['UpdatedAt', 'updatedAt', 'Updatedat', 'updatedat']),
      formCategoryID: _firstPresent(json, [
        'FormCategoryID',
        'formCategoryID',
        'FormCategoryId',
        'formCategoryId',
        'formcategoryid'
      ]),
      // The API emits camelCase on GET and accepts PascalCase on POST.
      shippingMethod: _firstPresent(
          json, ['ShippingMethod', 'shippingMethod', 'shippingmethod']),
      client: json['Client'] != null
          ? ClientModel.fromJson(Map<String, dynamic>.from(json['Client']))
          : ClientModel.empty(),
      documentReference: (json['DocumentReference'] ??
                      json['documentReference']) !=
                  null &&
              (json['DocumentReference'] ?? json['documentReference']) is List
          ? List<String>.from(
              ((json['DocumentReference'] ?? json['documentReference']) as List)
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

    final idValue = (lower['requestid'] ?? lower['id'] ?? '').toString();
    final provincialReceiverNameValue = _firstPresent(lower, [
      'provincialreceivername',
      'provincialdeliveredreceivername',
    ]);

    final provincialPickUpAtValue = lower['provincialpickupat'];

    final provincialInTransitAtValue = lower['provincialintransitat'];
    final provincialDeliveredEndAtValue = _firstPresentValue(lower, [
      'provincialdeliveredendat',
      'provincialdeliveredat',
    ]);
    final provincialDeliveredLocationValue = _firstPresent(lower, [
      'provincialdeliveredlocation',
      'provincialdeliveredto',
    ]);

    return AirSeaModel(
      id: idValue,
      clientId: (lower['clientid'] ?? '').toString(),
      itemCategoryId: (lower['itemcategoryid'] ?? '').toString(),
      mobileId: _parseIntOrNull(lower['mobileid']),
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
      provincialPickUpBy: (lower['provincialpickupby'] ?? '').toString(),
      provincialPickUpAt: _normalizeDateTimeString(provincialPickUpAtValue),
      provincialInTransitAt:
          _normalizeDateTimeString(provincialInTransitAtValue),
      provincialInTransitLocation:
          (lower['provincialintransitlocation'] ?? '').toString(),
      provincialDeliveredEndAt:
          _normalizeDateTimeString(provincialDeliveredEndAtValue),
      provincialDeliveredLocation: provincialDeliveredLocationValue,
      provincialReceiverName: provincialReceiverNameValue.isNotEmpty
          ? provincialReceiverNameValue
          : '',
      status: (lower['status'] ?? '').toString(),
      remarks: (lower['remarks'] ?? '').toString(),
      createdBy: (lower['createdby'] ?? '').toString(),
      createdAt: (lower['createdat'] ?? '').toString(),
      updatedAt: (lower['updatedat'] ?? '').toString(),
      formCategoryID: (lower['formcategoryid'] ?? '').toString(),
      shippingMethod: (lower['shippingmethod'] ?? '').toString(),
      // client, documentReference, and cancelRemarks will be loaded by DAO
    );
  }
}
