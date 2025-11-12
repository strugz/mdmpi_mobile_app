import 'dart:convert';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';

class StandardDeliveryModel {
  String id; // maps to JSON 'ID'
  String clientId; // maps to JSON 'ClientID'
  String shippingMethod;
  String deliveryTerms;
  String deliveryDate; // keep as String for flexibility (API returns ISO string)
  String preference;
  String status;
  String requestBy;
  String createdBy;
  String itemPreparedBy;
  String deliveredBy;
  String itemPreparedAt;
  String itemPreparedEndAt;
  String deliveredAt;
  String deliveredEndAt;
  List<String> documentReference;
  ClientModel client;
  String createdAt;
  String locationStartedAt;
  String locationEndAt;
  int? mobileID; // numeric when available
  String mobileName;
  String helper; // driver helper
  String receiver;
  String signature;
  String image;
  String tripTicketNumber;
  CancelRemarksModel cancelRemarks;

  StandardDeliveryModel({
    this.id = '',
    required this.clientId,
    required this.shippingMethod,
    required this.deliveryTerms,
    required this.deliveryDate,
    required this.preference,
    required this.status,
    required this.requestBy,
    required this.createdBy,
    this.itemPreparedBy = '',
    this.deliveredBy = '',
    this.itemPreparedAt = '',
    this.itemPreparedEndAt = '',
    this.deliveredAt = '',
    this.deliveredEndAt = '',
    required this.documentReference,
    required this.client,
    required this.createdAt,
    this.locationStartedAt = '',
    this.locationEndAt = '',
    this.mobileID,
    this.mobileName = '',
    this.helper = '',
    this.receiver = '',
    this.signature = '',
    this.image = '',
    this.tripTicketNumber = '',
    this.cancelRemarks = CancelRemarksModel.empty,
  });

  StandardDeliveryModel copyWith({
    String? id,
    String? clientId,
    String? shippingMethod,
    String? deliveryTerms,
    String? deliveryDate,
    String? preference,
    String? status,
    String? requestBy,
    String? createdBy,
    String? itemPreparedBy,
    String? itemPreparedAt,
    String? itemPreparedEndAt,
    String? deliveredBy,
    String? deliveredAt,
    String? deliveredEndAt,
    List<String>? documentReference,
    ClientModel? client,
    String? createdAt,
    String? locationStartedAt,
    String? locationEndAt,
    int? mobileID,
    String? mobileName,
    String? helper,
    String? receiver,
    String? signature,
    String? image,
    String? tripTicketNumber,
    CancelRemarksModel? cancelRemarks,
  }) {
    return StandardDeliveryModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      deliveryTerms: deliveryTerms ?? this.deliveryTerms,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      preference: preference ?? this.preference,
      status: status ?? this.status,
      requestBy: requestBy ?? this.requestBy,
      createdBy: createdBy ?? this.createdBy,
      itemPreparedBy: itemPreparedBy ?? this.itemPreparedBy,
      itemPreparedAt: itemPreparedAt ?? this.itemPreparedAt,
      itemPreparedEndAt: itemPreparedEndAt ?? this.itemPreparedEndAt,
      deliveredBy: deliveredBy ?? this.deliveredBy,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      deliveredEndAt: deliveredEndAt ?? this.deliveredEndAt,
      documentReference: documentReference ?? this.documentReference,
      client: client ?? this.client,
      createdAt: createdAt ?? this.createdAt,
      locationStartedAt: locationStartedAt ?? this.locationStartedAt,
      locationEndAt: locationEndAt ?? this.locationEndAt,
      mobileID: mobileID ?? this.mobileID,
      mobileName: mobileName ?? this.mobileName,
      helper: helper ?? this.helper,
      receiver: receiver ?? this.receiver,
      signature: signature ?? this.signature,
      image: image ?? this.image,
      tripTicketNumber: tripTicketNumber ?? this.tripTicketNumber,
      cancelRemarks: cancelRemarks ?? this.cancelRemarks,
    );
  }

  // Backwards-compatible aliases for legacy RequestModel field names
  String get requestID => id;
  set requestID(String v) => id = v;

  String get targetDate => deliveryDate;
  set targetDate(String v) => deliveryDate = v;

  String get requestedBy => requestBy;
  set requestedBy(String v) => requestBy = v;

  String get requestCreatedBy => createdBy;
  set requestCreatedBy(String v) => createdBy = v;

  String get requestItemPreparedBy => itemPreparedBy;
  set requestItemPreparedBy(String v) => itemPreparedBy = v;

  String get requestDriverHelper => helper;
  set requestDriverHelper(String v) => helper = v;

  // Some older code expects cancelRemarks to be non-nullable and access fields directly
  CancelRemarksModel get cancelRemarksSafe => cancelRemarks;

  /// Create Empty func to clean code
  static StandardDeliveryModel empty() => StandardDeliveryModel(
        id: '',
        clientId: '',
        shippingMethod: '',
        deliveryTerms: '',
        deliveryDate: '',
        preference: '',
        status: '',
        requestBy: '',
        documentReference: [],
        client: ClientModel.empty(),
        createdBy: '',
        itemPreparedBy: '',
        itemPreparedAt: '',
        itemPreparedEndAt: '',
        deliveredBy: '',
        deliveredAt: '',
        deliveredEndAt: '',
        createdAt: '',
        locationStartedAt: '',
        locationEndAt: '',
        mobileID: null,
        mobileName: '',
        helper: '',
        receiver: '',
        signature: '',
        image: '',
        tripTicketNumber: '',
        cancelRemarks: CancelRemarksModel.empty,
      );

  /// Json Format
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
      'DocumentReference': documentReference,
      'Client': client.toJson(),
      'ItemPreparedBy': itemPreparedBy,
      'ItemPreparedAt': itemPreparedAt,
      'ItemPreparedEndAt': itemPreparedEndAt,
      'DeliveredBy': deliveredBy,
      'DeliveredAt': deliveredAt,
      'DeliveredEndAt': deliveredEndAt,
      'CreatedAt': createdAt,
      'LocationStartedAt': locationStartedAt,
      'LocationEndAt': locationEndAt,
      'MobileID': mobileID,
      'MobileName': mobileName,
      'Helper': helper,
      'Receiver': receiver,
      'Signature': signature,
      'Image': image,
      'TripTicketNumber': tripTicketNumber,
      'CancelRemarks': cancelRemarks.toJson(),
    };
  }

  /// Json Format to Insert
  Map<String, dynamic> toJsonInsert() {
    return {
      'ClientID': clientId,
      'ShippingMethod': shippingMethod,
      'DeliveryTerms': deliveryTerms,
      'DeliveryDate': deliveryDate,
      'RequestBy': requestBy,
      'Preference': preference,
      'Status': status,
    };
  }

  /// Map Json oriented from API to Model
  factory StandardDeliveryModel.fromJson(Map<String, dynamic> json) {
    return StandardDeliveryModel(
      id: (json['ID']?.toString() ?? ''),
      clientId: (json['ClientID']?.toString() ?? ''),
      shippingMethod: (json['ShippingMethod']?.toString() ?? ''),
      deliveryTerms: (json['DeliveryTerms']?.toString() ?? ''),
      deliveryDate: (json['DeliveryDate']?.toString() ?? ''),
      preference: (json['Preference']?.toString() ?? ''),
      status: (json['Status']?.toString() ?? ''),
      requestBy: (json['RequestBy']?.toString() ?? ''),
      documentReference: json['DocumentReference'] != null
          ? List<String>.from((json['DocumentReference'] as List).map((e) => e?.toString() ?? ''))
          : [],
      client: json['Client'] != null
          ? ClientModel.fromJson(Map<String, dynamic>.from(json['Client']))
          : ClientModel.empty(),
      createdBy: (json['CreatedBy']?.toString() ?? ''),
      itemPreparedBy: (json['ItemPreparedBy']?.toString() ?? ''),
      deliveredBy: (json['DeliveredBy']?.toString() ?? ''),
      itemPreparedAt: (json['ItemPreparedAt']?.toString() ?? ''),
      itemPreparedEndAt: (json['ItemPreparedEndAt']?.toString() ?? ''),
      deliveredAt: (json['DeliveredAt']?.toString() ?? ''),
      deliveredEndAt: (json['DeliveredEndAt']?.toString() ?? ''),
      createdAt: (json['CreatedAt']?.toString() ?? ''),
      locationStartedAt: (json['LocationStartedAt']?.toString() ?? ''),
      locationEndAt: (json['LocationEndAt']?.toString() ?? ''),
      mobileID: json['MobileID'] is int
          ? json['MobileID']
          : (json['MobileID'] != null
              ? int.tryParse(json['MobileID'].toString())
              : null),
      mobileName: (json['MobileName']?.toString() ?? ''),
      helper: (json['Helper']?.toString() ?? ''),
      receiver: (json['Receiver']?.toString() ?? ''),
      signature: (json['Signature']?.toString() ?? ''),
      image: (json['Image']?.toString() ?? ''),
      tripTicketNumber: (json['TripTicketNumber']?.toString() ?? ''),
      cancelRemarks: json['CancelRemarks'] != null
          ? CancelRemarksModel.fromJson(
              Map<String, dynamic>.from(json['CancelRemarks']))
          : CancelRemarksModel.empty,
    );
  }

  factory StandardDeliveryModel.fromDbJson(Map<String, dynamic> json) {
    try {
      // Normalize keys to lowercase to handle platform/sqlite variations
      final Map<String, dynamic> lower = {};
      json.forEach((k, v) {
        lower[k.toString().toLowerCase()] = v;
      });

      // attempt to parse mobile id and id if they're numeric strings
      int? parsedMobileId;
      final mobileRaw = lower['mobileid'];
      if (mobileRaw is int) parsedMobileId = mobileRaw;
      if (mobileRaw is String) parsedMobileId = int.tryParse(mobileRaw);

      String idValue = (lower['requestid'] ?? lower['id'] ?? '').toString();

      // Parse embedded client JSON if present in the `Client` column
      ClientModel clientModel = ClientModel.empty();
      final clientRaw = lower['client'];
      if (clientRaw != null) {
        try {
          if (clientRaw is String && clientRaw.isNotEmpty) {
            final Map<String, dynamic> clientMap = jsonDecode(clientRaw);
            clientModel = ClientModel.fromJson(clientMap);
          } else if (clientRaw is Map) {
            clientModel = ClientModel.fromJson(Map<String, dynamic>.from(clientRaw));
          }
        } catch (_) {
          // fallback to trying ACCMST_ lookup elsewhere; keep empty client
          clientModel = ClientModel.empty();
        }
      }

      return StandardDeliveryModel(
        id: idValue,
        clientId: (lower['requestclientid'] ?? lower['clientid'] ?? '').toString(),
        shippingMethod: (lower['requestshippingmethod'] ?? lower['shippingmethod'] ?? '').toString(),
        deliveryTerms: (lower['requestdeliveryterms'] ?? lower['deliveryterms'] ?? '').toString(),
        deliveryDate: (lower['requestdeliverydate'] ?? lower['deliverydate'] ?? '').toString(),
        requestBy: (lower['requestby'] ?? lower['requestby'] ?? '').toString(),
        preference: (lower['requestpreference'] ?? lower['preference'] ?? '').toString(),
        status: (lower['requeststatus'] ?? lower['status'] ?? '').toString(),
        createdBy: (lower['requestcreatedby'] ?? lower['createdby'] ?? '').toString(),
        itemPreparedBy: (lower['requestitempreparedby'] ?? lower['itempreparedby'] ?? '').toString(),
        deliveredBy: (lower['requestdeliveredby'] ?? lower['deliveredby'] ?? '').toString(),
        itemPreparedAt: (lower['requestitempreparedat'] ?? lower['itempreparedat'] ?? '').toString(),
        itemPreparedEndAt: (lower['requestitempreparedendat'] ?? lower['itempreparedendat'] ?? '').toString(),
        deliveredAt: (lower['requestdeliveredat'] ?? lower['deliveredat'] ?? '').toString(),
        deliveredEndAt: (lower['requestdeliveredendat'] ?? lower['deliveredendat'] ?? '').toString(),
        createdAt: (lower['requestcreatedat'] ?? lower['createdat'] ?? '').toString(),
        locationStartedAt: (lower['locationstartedat'] ?? '').toString(),
        locationEndAt: (lower['locationendat'] ?? '').toString(),
        mobileID: parsedMobileId,
        mobileName: (lower['mobilename'] ?? '').toString(),
        helper: (lower['requestdriverhelper'] ?? lower['helper'] ?? '').toString(),
        receiver: (lower['receiver'] ?? '').toString(),
        signature: (lower['signature'] ?? '').toString(),
        client: clientModel,
        documentReference: [],
        image: (lower['image'] ?? '').toString(),
        tripTicketNumber: (lower['tripticketnumber'] ?? '').toString(),
        cancelRemarks: CancelRemarksModel.empty,
      );
    } catch (e) {
      return StandardDeliveryModel.empty();
    }
  }

  factory StandardDeliveryModel.fromFormInputs({
    required String? clientId,
    required String shippingMethod,
    required String deliveryTerms,
    required String deliveryDate,
    required String requestBy,
    required List<String> documentReference,
    required String preference,
    required ClientModel? client,
    required String createdBy,
  }) {
    if (clientId == null || client == null) {
      throw ArgumentError('Client ID and Client information cannot be null.');
    }
    return StandardDeliveryModel(
      clientId: clientId,
      shippingMethod: shippingMethod,
      deliveryTerms: deliveryTerms,
      deliveryDate: deliveryDate,
      requestBy: requestBy,
      documentReference: documentReference,
      preference: preference,
      client: client,
      status: 'New Request',
      createdBy: createdBy,
      createdAt: DateTime.now().toString(),
    );
  }
}
