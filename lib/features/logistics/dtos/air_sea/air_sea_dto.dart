import 'package:mdmpi_mobile_app/features/logistics/dtos/client_dto.dart';
import 'package:mdmpi_mobile_app/features/logistics/dtos/signature_dto.dart';

/// Complete Air/Sea request DTO returned from API
class AirSeaDto {
  final String requestID;
  final dynamic itemCategoryID;
  final String? clientID;
  final List<String>? documentReference;
  final int? mobileID;
  final String? riderName;
  final String? datePickUp;
  final String? itemPreparedAt;
  final String? itemPreparedEndAt;
  final String? preparedBy;
  final String? receivedBy;
  final String? waybillNumber;
  final String? receivedAt;
  final String? tripTicketNumber;
  final String? driver;
  final String? helper;
  final String? dispatchedAt;
  final String? dropOffAt;
  final String? provincialReceiverName;
  final String? provincialPickUpBy;
  final String? provincialPickUpAt;
  final String? provincialInTransitAt;
  final String? provincialInTransitLocation;
  final String? provincialDeliveredEndAt;
  final String? provincialDeliveredLocation;

  final String? status;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;
  final String? updatedBy;
  final SignatureDto? signature;
  final ClientDto? client;

  AirSeaDto({
    required this.requestID,
    this.itemCategoryID,
    this.clientID,
    this.documentReference,
    this.mobileID,
    this.riderName,
    this.datePickUp,
    this.itemPreparedAt,
    this.itemPreparedEndAt,
    this.preparedBy,
    this.receivedBy,
    this.waybillNumber,
    this.receivedAt,
    this.tripTicketNumber,
    this.driver,
    this.helper,
    this.dispatchedAt,
    this.dropOffAt,
    this.provincialReceiverName,
    this.provincialPickUpBy,
    this.provincialPickUpAt,
    this.provincialInTransitAt,
    this.provincialInTransitLocation,
    this.provincialDeliveredEndAt,
    this.provincialDeliveredLocation,
    this.status,
    this.remarks,
    this.createdAt,
    this.updatedAt,
    this.updatedBy,
    this.signature,
    this.client,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    void put(String key, dynamic value) {
      if (value != null) data[key] = value;
    }

    data['RequestID'] = requestID;
    put('ItemCategoryID', itemCategoryID);
    put('ClientID', clientID);
    put('DocumentReference', documentReference);
    put('MobileID', mobileID);
    put('RiderName', riderName);
    put('DatePickUp', datePickUp);
    put('ItemPreparedAt', itemPreparedAt);
    put('ItemPreparedEndAt', itemPreparedEndAt);
    put('PreparedBy', preparedBy);
    put('ReceivedBy', receivedBy);
    put('WaybillNumber', waybillNumber);
    put('ReceivedAt', receivedAt);
    put('TripTicketNumber', tripTicketNumber);
    put('Driver', driver);
    put('Helper', helper);
    put('DispatchedAt', dispatchedAt);
    put('DropOffAt', dropOffAt);
    put('provincial_receiver_name', provincialReceiverName);
    put('provincial_pick_up_by', provincialPickUpBy);
    put('provincial_pick_up_at', provincialPickUpAt);
    put('provincial_in_transit_at', provincialInTransitAt);
    put('provincial_in_transit_location', provincialInTransitLocation);
    put('provincial_delivered_end_at', provincialDeliveredEndAt);
    put('provincial_delivered_location', provincialDeliveredLocation);
    put('Status', status);
    put('Remarks', remarks);
    put('CreatedAt', createdAt);
    put('UpdatedAt', updatedAt);
    put('UpdatedBy', updatedBy);
    put('Signature', signature?.toJson());
    put('Client', client?.toJson());

    return data;
  }

  factory AirSeaDto.fromJson(Map<String, dynamic> json) {
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

    return AirSeaDto(
      requestID: firstPresent(json,
          ['RequestID', 'requestID', 'RequestId', 'requestId', 'Requestid']),
      itemCategoryID: json['ItemCategoryID'] ??
          json['itemCategoryID'] ??
          json['ItemCategoryId'] ??
          json['itemCategoryId'],
      clientID: json['ClientID'] ?? json['clientID'] ?? json['clientId'],
      documentReference:
          json['DocumentReference'] != null && json['DocumentReference'] is List
              ? List<String>.from((json['DocumentReference'] as List)
                  .map((e) => e?.toString() ?? ''))
              : null,
      mobileID: parseIntOrNull(
          json['MobileID'] ?? json['mobileID'] ?? json['mobileId']),
      riderName: json['RiderName'] ?? json['riderName'],
      datePickUp: json['DatePickUp'] ?? json['datePickUp'],
      itemPreparedAt: json['ItemPreparedAt'] ?? json['itemPreparedAt'],
      itemPreparedEndAt: json['ItemPreparedEndAt'] ?? json['itemPreparedEndAt'],
      preparedBy: json['PreparedBy'] ?? json['preparedBy'],
      receivedBy: firstPresent(json, ['ReceivedBy', 'receivedBy']),
      waybillNumber: firstPresent(json, ['WaybillNumber', 'waybillNumber']),
      receivedAt: firstPresent(json, ['ReceivedAt', 'receivedAt']),
      tripTicketNumber:
          firstPresent(json, ['TripTicketNumber', 'tripTicketNumber']),
      driver: firstPresent(json, ['Driver', 'driver']),
      helper: firstPresent(json, ['Helper', 'helper']),
      dispatchedAt: firstPresent(json, ['DispatchedAt', 'dispatchedAt']),
      dropOffAt: firstPresent(json, ['DropOffAt', 'dropOffAt']),
      provincialReceiverName: firstPresent(json, [
        'ProvincialReceiverName',
        'provincialReceiverName',
        'provincial_receiver_name',
        'ProvincialDeliveredReceiverName',
        'provincialDeliveredReceiverName',
        'provincial_delivered_receiver_name',
      ]),
      provincialPickUpBy: firstPresent(json, [
        'ProvincialPickUpBy',
        'provincialPickUpBy',
        'provincial_pick_up_by',
      ]),
      provincialPickUpAt: firstPresent(json, [
        'ProvincialPickUpAt',
        'provincialPickUpAt',
        'provincial_pick_up_at',
      ]),
      provincialInTransitAt: firstPresent(json, [
        'ProvincialInTransitAt',
        'provincialInTransitAt',
        'provincial_in_transit_at',
      ]),
      provincialInTransitLocation: firstPresent(json, [
        'ProvincialInTransitLocation',
        'provincialInTransitLocation',
        'provincial_in_transit_location',
      ]),
      provincialDeliveredEndAt: firstPresent(json, [
        'ProvincialDeliveredEndAt',
        'provincialDeliveredEndAt',
        'provincial_delivered_end_at',
        'ProvincialDeliveredAt',
        'provincialDeliveredAt',
        'provincial_delivered_at',
      ]),
      provincialDeliveredLocation: firstPresent(json, [
        'ProvincialDeliveredLocation',
        'provincialDeliveredLocation',
        'provincial_delivered_location',
        'ProvincialDeliveredTo',
        'provincialDeliveredTo',
        'provincial_delivered_to',
      ]),
      status: json['Status'] ?? json['status'],
      remarks: json['Remarks'] ?? json['remarks'],
      createdAt: json['CreatedAt'] ?? json['createdAt'],
      updatedAt: json['UpdatedAt'] ?? json['updatedAt'],
      updatedBy: json['UpdatedBy'] ?? json['updatedBy'],
      signature: json['Signature'] != null
          ? SignatureDto.fromJson(Map<String, dynamic>.from(json['Signature']))
          : null,
      client: json['Client'] != null
          ? ClientDto.fromJson(Map<String, dynamic>.from(json['Client']))
          : null,
    );
  }
}
