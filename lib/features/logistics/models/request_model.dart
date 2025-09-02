import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

class RequestModel {
  String requestID;
  String clientID;
  String shippingMethod;
  String deliveryTerms;
  String targetDate;
  String preference;
  String status;
  String requestedBy;
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
  String mobileID;
  String mobileName;
  String helper;
  String receiver;
  String signature;
  String image;
  String tripTicketNumber;

  RequestModel(
      {this.requestID = '',
      required this.clientID,
      required this.shippingMethod,
      required this.deliveryTerms,
      required this.targetDate,
      required this.preference,
      required this.status,
      required this.requestedBy,
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
      this.mobileID = '',
      this.mobileName = '',
      this.helper = '',
      this.receiver = '',
      this.signature = '',
      this.image = '',
      this.tripTicketNumber = ''});

  // --- copyWith METHOD ---
  RequestModel copyWith({
    String? requestID,
    String? clientId,
    String? shippingMethod,
    String? deliveryTerms,
    String? targetDate,
    String? requestedBy,
    List<String>? documentReference,
    String? preference,
    ClientModel? client, // Nullable if you want to allow clearing it
    String? createdBy,
    String? createdAt,
    String? itemPreparedBy, // Nullable for clearing
    String? itemPreparedAt, // Nullable for clearing
    String? itemPreparedEndAt, // Nullable for clearing
    String? deliveredBy, // Nullable for clearing
    String? deliveredAt, // Nullable for clearing
    String? deliveredEndAt, // Nullable for clearing
    String? locationStartedAt,
    String? locationEndAt,
    String? status,
    String? helper,
    String? receiver,
    String? signature,
    String? mobileID,
    String? image,
    String? tripTicketNumber,
  }) {
    return RequestModel(
        requestID: requestID ?? this.requestID,
        clientID: clientId ?? clientID,
        shippingMethod: shippingMethod ?? this.shippingMethod,
        deliveryTerms: deliveryTerms ?? this.deliveryTerms,
        targetDate: targetDate ?? this.targetDate,
        requestedBy: requestedBy ?? this.requestedBy,
        documentReference: documentReference ?? this.documentReference,
        preference: preference ?? this.preference,
        client:
            client ?? this.client, // Handle potential null assignment carefully
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        itemPreparedBy: itemPreparedBy ?? this.itemPreparedBy,
        itemPreparedAt: itemPreparedAt ?? this.itemPreparedAt,
        itemPreparedEndAt: itemPreparedEndAt ?? this.itemPreparedEndAt,
        deliveredBy: deliveredBy ?? this.deliveredBy,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        deliveredEndAt: deliveredEndAt ?? this.deliveredEndAt,
        locationStartedAt: locationStartedAt ?? this.locationStartedAt,
        locationEndAt: locationEndAt ?? this.locationEndAt,
        status: status ?? this.status,
        helper: helper ?? this.helper,
        receiver: receiver ?? this.receiver,
        signature: signature ?? this.signature,
        mobileID: mobileID ?? this.mobileID,
        image: image ?? this.image,
        tripTicketNumber: tripTicketNumber ?? this.tripTicketNumber);
  }

  /// Create Empty func to clean code
  static RequestModel empty() => RequestModel(
      requestID: '',
      clientID: '',
      shippingMethod: '',
      deliveryTerms: '',
      targetDate: '',
      requestedBy: '',
      documentReference: [],
      preference: '',
      client: ClientModel.empty(),
      status: '',
      createdBy: '',
      deliveredBy: '',
      itemPreparedBy: '',
      itemPreparedAt: '',
      itemPreparedEndAt: '',
      deliveredAt: '',
      deliveredEndAt: '',
      createdAt: '',
      locationStartedAt: '',
      locationEndAt: '',
      mobileID: '',
      mobileName: '',
      helper: '',
      receiver: '',
      signature: '',
      image: '');

  /// Json Format
  Map<String, dynamic> toJson() {
    return {
      'ID': requestID,
      'ClientID': clientID,
      'ShippingMethod': shippingMethod,
      'DeliveryTerms': deliveryTerms,
      'DeliveryDate': targetDate,
      'RequestBy': requestedBy,
      'Preference': preference,
      'Status': status,
      'DocumentReference': documentReference,
      'Client': client.toJson(),
      'CreatedBy': createdBy,
      'DeliveredBy': deliveredBy,
      'ItemPreparedBy': itemPreparedBy,
      'ItemPreparedAt': itemPreparedAt,
      'ItemPreparedEndAt': itemPreparedEndAt,
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
      'TripTicketNumber': tripTicketNumber
    };
  }

  /// Json Format to Insert
  Map<String, dynamic> toJsonInsert() {
    return {
      'ClientID': clientID,
      'ShippingMethod': shippingMethod,
      'DeliveryTerms': deliveryTerms,
      'DeliveryDate': targetDate,
      'RequestBy': requestedBy,
      'Preference': preference,
      'Status': status,
    };
  }

  /// Map Json oriented from API to Model
  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      requestID: json['ID'],
      clientID: json['ClientID'],
      shippingMethod: json['ShippingMethod'],
      deliveryTerms: json['DeliveryTerms'],
      targetDate: json['DeliveryDate'],
      requestedBy: json['RequestBy'],
      documentReference: List<String>.from(json['DocumentReference']),
      preference: json['Preference'],
      client: ClientModel.fromJson(json['Client']),
      status: json['Status'],
      createdBy: json['CreatedBy'] ?? '',
      itemPreparedBy: json['ItemPreparedBy'] ?? '',
      deliveredBy: json['DeliveredBy'] ?? '',
      itemPreparedAt: json['ItemPreparedAt'] ?? '',
      itemPreparedEndAt: json['ItemPreparedEndAt'] ?? '',
      deliveredAt: json['DeliveredAt'] ?? '',
      deliveredEndAt: json['DeliveredEndAt'] ?? '',
      createdAt: json['CreatedAt'] ?? '',
      locationStartedAt: json['LocationStartedAt'] ?? '',
      locationEndAt: json['LocationEndAt'] ?? '',
      mobileID: json['MobileID'] ?? '',
      mobileName: json['MobileName'] ?? '',
      helper: json['Helper'] ?? '',
      receiver: json['Receiver'] ?? '',
      tripTicketNumber: json['TripTicketNumber'] ?? '',
    );
  }

  factory RequestModel.fromDbJson(Map<String, dynamic> json) {
    try {
      // Attempt to parse RequestID as an int.
      // If json['RequestID'] is already an int, it will be fine.
      // If it's a String, int.tryParse will attempt to convert it.
      // If it's null or not a valid integer string, it will result in an error
      // or return null depending on how you want to handle it.
      // For simplicity, this example assumes it will be a valid representation or you want an error.
      String requestIdValue;
      String requestMobileID;

      if (json['MobileID'] is int) {
        requestMobileID = json['MobileID'].toString();
      } else if (json['MobileID'] is String) {
        // Ensure it's a string representation of an int before assigning
        // You might want to add more robust validation if needed
        int.parse(
            json['MobileID']); // This will throw if not a valid int string
        requestMobileID = json['MobileID'];
      } else {
        // Handle cases where RequestID is null or not a String/int
        // You could throw an error, or assign a default, or make requestID nullable
        // For this example, let's throw an error if it's not what we expect
        throw FormatException(
            "RequestID is not a valid integer or string representation of an integer.");
      }
      if (json['RequestID'] is int) {
        requestIdValue = json['RequestID'].toString();
      } else if (json['RequestID'] is String) {
        // Ensure it's a string representation of an int before assigning
        // You might want to add more robust validation if needed
        int.parse(
            json['RequestID']); // This will throw if not a valid int string
        requestIdValue = json['RequestID'];
      } else {
        // Handle cases where RequestID is null or not a String/int
        // You could throw an error, or assign a default, or make requestID nullable
        // For this example, let's throw an error if it's not what we expect
        throw FormatException(
            "RequestID is not a valid integer or string representation of an integer.");
      }
      return RequestModel(
          requestID: requestIdValue,
          clientID: json['RequestClientID'],
          shippingMethod: json['RequestShippingMethod'],
          deliveryTerms: json['RequestDeliveryTerms'],
          targetDate: json['RequestDeliveryDate'],
          requestedBy: json['RequestBy'],
          preference: json['RequestPreference'],
          status: json['RequestStatus'],
          createdBy: json['RequestCreatedBy'] ?? '',
          itemPreparedBy: json['RequestItemPreparedBy'] ?? '',
          deliveredBy: json['RequestDeliveredBy'] ?? '',
          itemPreparedAt: json['RequestItemPreparedAt'] ?? '',
          itemPreparedEndAt: json['RequestItemPreparedEndAt'] ?? '',
          deliveredAt: json['RequestDeliveredAt'] ?? '',
          deliveredEndAt: json['RequestDeliveredEndAt'] ?? '',
          createdAt: json['RequestCreatedAt'] ?? '',
          locationStartedAt: json['LocationStartedAt'] ?? '',
          locationEndAt: json['LocationEndAt'] ?? '',
          mobileID: requestMobileID,
          mobileName: json['MobileName'] ?? '',
          helper: json['RequestDriverHelper'] ?? '',
          receiver: json['Receiver'] ?? '',
          signature: json['Signature'] ?? '',
          client: ClientModel.empty(),
          documentReference: [],
          image: json['Image'] ?? '',
          tripTicketNumber: json['TripTicketNumber'] ?? '');
    } catch (e) {
      return RequestModel.empty();
    }
  }

  factory RequestModel.fromFormInputs({
    required String? clientId,
    required String shippingMethod,
    required String deliveryTerms,
    required String targetDate,
    required String requestedBy,
    required List<String> documentReference,
    required String preference,
    required ClientModel? client,
    required String createdBy,
  }) {
    if (clientId == null || client == null) {
      // Or handle this more gracefully, perhaps by returning null or throwing a specific validation error
      throw ArgumentError('Client ID and Client information cannot be null.');
    }
    return RequestModel(
      clientID: clientId,
      shippingMethod: shippingMethod,
      deliveryTerms: deliveryTerms,
      targetDate: targetDate,
      requestedBy: requestedBy,
      documentReference: documentReference,
      preference: preference,
      client: client, // The full ClientModel object
      status: 'New Request', // Default status for new requests
      createdBy: createdBy,
      createdAt: DateTime.now().toString(),
      // Initialize other fields with default or empty values as needed
      // e.g., requestID, itemPreparedBy, deliveredBy etc. might be null or empty initially
    );
  }
}
