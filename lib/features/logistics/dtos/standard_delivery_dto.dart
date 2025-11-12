import 'client_dto.dart';
import 'remarks_dto.dart';
import 'image_dto.dart';
import 'signature_dto.dart';

class StandardDeliveryDto {
  final String? id;
  final String? clientId;
  final String? shippingMethod;
  final String? deliveryTerms;
  final String? deliveryDate;
  final String? preference;
  final String? status;
  final String? requestBy;
  final String? createdBy;
  final String? createdAt;
  final String? itemPreparedBy;
  final String? deliveredBy;
  final String? itemPreparedAt;
  final String? itemPreparedEndAt;
  final String? deliveredAt;
  final String? deliveredEndAt;
  final int? mobileID;
  final String? mobileName;
  final String? helper;
  final String? receiver;
  final String? tripTicketNumber;
  final String? locationStartedAt;
  final String? locationEndAt;
  final ClientDto? client;
  final List<String>? documentReference;
  final RemarksDto? cancelRemarks;
  final ImageDto? image;
  final SignatureDto? signature;

  StandardDeliveryDto({
    this.id,
    this.clientId,
    this.shippingMethod,
    this.deliveryTerms,
    this.deliveryDate,
    this.preference,
    this.status,
    this.requestBy,
    this.createdBy,
    this.createdAt,
    this.itemPreparedBy,
    this.deliveredBy,
    this.itemPreparedAt,
    this.itemPreparedEndAt,
    this.deliveredAt,
    this.deliveredEndAt,
    this.mobileID,
    this.mobileName,
    this.helper,
    this.receiver,
    this.tripTicketNumber,
    this.locationStartedAt,
    this.locationEndAt,
    this.client,
    this.documentReference,
    this.cancelRemarks,
    this.image,
    this.signature,
  });

  factory StandardDeliveryDto.fromJson(Map<String, dynamic> json) {
    return StandardDeliveryDto(
      id: json['ID']?.toString(),
      clientId: json['ClientID']?.toString(),
      shippingMethod: json['ShippingMethod']?.toString(),
      deliveryTerms: json['DeliveryTerms']?.toString(),
      deliveryDate: json['DeliveryDate']?.toString(),
      preference: json['Preference']?.toString(),
      status: json['Status']?.toString(),
      requestBy: json['RequestBy']?.toString(),
      createdBy: json['CreatedBy']?.toString(),
      createdAt: json['CreatedAt']?.toString(),
      itemPreparedBy: json['ItemPreparedBy']?.toString(),
      deliveredBy: json['DeliveredBy']?.toString(),
      itemPreparedAt: json['ItemPreparedAt']?.toString(),
      itemPreparedEndAt: json['ItemPreparedEndAt']?.toString(),
      deliveredAt: json['DeliveredAt']?.toString(),
      deliveredEndAt: json['DeliveredEndAt']?.toString(),
      mobileID: json['MobileID'] is int
          ? json['MobileID']
          : (json['MobileID'] != null ? int.tryParse(json['MobileID'].toString()) : null),
      mobileName: json['MobileName']?.toString(),
      helper: json['Helper']?.toString(),
      receiver: json['Receiver']?.toString(),
      tripTicketNumber: json['TripTicketNumber']?.toString(),
      locationStartedAt: json['LocationStartedAt']?.toString(),
      locationEndAt: json['LocationEndAt']?.toString(),
      client: json['Client'] != null ? ClientDto.fromJson(Map<String, dynamic>.from(json['Client'])) : null,
      documentReference: json['DocumentReference'] != null ? List<String>.from(json['DocumentReference']) : null,
      cancelRemarks: json['CancelRemarks'] != null ? RemarksDto.fromJson(Map<String, dynamic>.from(json['CancelRemarks'])) : null,
      image: json['Image'] != null ? ImageDto.fromJson(Map<String, dynamic>.from(json['Image'])) : null,
      signature: json['Signature'] != null ? SignatureDto.fromJson(Map<String, dynamic>.from(json['Signature'])) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'ClientID': clientId,
      'ShippingMethod': shippingMethod,
      'DeliveryTerms': deliveryTerms,
      'DeliveryDate': deliveryDate,
      'Preference': preference,
      'Status': status,
      'RequestBy': requestBy,
      'CreatedBy': createdBy,
      'CreatedAt': createdAt,
      'ItemPreparedBy': itemPreparedBy,
      'DeliveredBy': deliveredBy,
      'ItemPreparedAt': itemPreparedAt,
      'ItemPreparedEndAt': itemPreparedEndAt,
      'DeliveredAt': deliveredAt,
      'DeliveredEndAt': deliveredEndAt,
      'MobileID': mobileID,
      'MobileName': mobileName,
      'Helper': helper,
      'Receiver': receiver,
      'TripTicketNumber': tripTicketNumber,
      'LocationStartedAt': locationStartedAt,
      'LocationEndAt': locationEndAt,
      'Client': client?.toJson(),
      'DocumentReference': documentReference,
      'CancelRemarks': cancelRemarks?.toJson(),
      'Image': image?.toJson(),
      'Signature': signature?.toJson(),
    };
  }
}
