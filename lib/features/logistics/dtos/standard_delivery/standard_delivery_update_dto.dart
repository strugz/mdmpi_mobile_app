class StandardDeliveryUpdateDto {
  final String? requestID;
  final String? requestStatus;
  final String? requestItemPreparedBy;
  final String? requestDeliveredBy;
  final String? requestDriverHelper;
  final int? mobileID;
  final String? receiver;
  final String? requestTripTicketNumber;
  final String? requestItemPreparedAt;
  final String? requestItemPreparedEndAt;
  final String? requestDeliveredAt;
  final String? requestDeliveredEndAt;
  final String? locationStartedAt;
  final String? locationEndAt;
  final Map<String, dynamic>? image;
  final Map<String, dynamic>? signature;
  final Map<String, dynamic>? remarks;
  final String? itemCategoryID;
  final String? formCategoryID;
  final String? updatedBy;

  const StandardDeliveryUpdateDto({
    this.requestID,
    this.requestStatus,
    this.requestItemPreparedBy,
    this.requestDeliveredBy,
    this.requestDriverHelper,
    this.mobileID,
    this.receiver,
    this.requestTripTicketNumber,
    this.requestItemPreparedAt,
    this.requestItemPreparedEndAt,
    this.requestDeliveredAt,
    this.requestDeliveredEndAt,
    this.locationStartedAt,
    this.locationEndAt,
    this.image,
    this.signature,
    this.remarks,
    this.itemCategoryID,
    this.formCategoryID,
    this.updatedBy,
  });

  /// Convert to JSON map for API. Omits null values to keep payload small.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    void put(String key, dynamic value) {
      if (value != null) data[key] = value;
    }

    put('requestID', requestID);
    put('requestStatus', requestStatus);
    put('requestItemPreparedBy', requestItemPreparedBy);
    put('requestDeliveredBy', requestDeliveredBy);
    put('requestDriverHelper', requestDriverHelper);
    put('mobileID', mobileID);
    put('receiver', receiver);
    put('requestTripTicketNumber', requestTripTicketNumber);
    put('requestItemPreparedAt', requestItemPreparedAt);
    put('requestItemPreparedEndAt', requestItemPreparedEndAt);
    put('requestDeliveredAt', requestDeliveredAt);
    put('requestDeliveredEndAt', requestDeliveredEndAt);
    put('locationStartedAt', locationStartedAt);
    put('locationEndAt', locationEndAt);
    put('itemCategoryID', itemCategoryID);
    put('formCategoryID', formCategoryID);
    put('updatedBy', updatedBy);

    // Only include nested objects if they contain meaningful values. This
    // ensures keys like `signature` aren't sent when empty or null.
    if (image != null) {
      final img = <String, dynamic>{};
      if (image!.containsKey('requestImage') && (image!['requestImage']?.toString().isNotEmpty ?? false)) {
        img['requestImage'] = image!['requestImage'];
      }
      // requestID may be numeric 0; include requestID if present
      if (image!.containsKey('requestID')) img['requestID'] = image!['requestID'];
      if (img.isNotEmpty) data['image'] = img;
    }

    if (signature != null) {
      final sig = <String, dynamic>{};
      if (signature!.containsKey('requestReceiverSignature') && (signature!['requestReceiverSignature']?.toString().isNotEmpty ?? false)) {
        sig['requestReceiverSignature'] = signature!['requestReceiverSignature'];
      }
      if (signature!.containsKey('requestID')) sig['requestID'] = signature!['requestID'];
      if (sig.isNotEmpty) data['signature'] = sig;
    }

    if (remarks != null) {
      final rem = <String, dynamic>{};
      if (remarks!.containsKey('remarks') && (remarks!['remarks']?.toString().isNotEmpty ?? false)) {
        rem['remarks'] = remarks!['remarks'];
      }
      if (remarks!.containsKey('date') && (remarks!['date']?.toString().isNotEmpty ?? false)) {
        rem['date'] = remarks!['date'];
      }
      if (remarks!.containsKey('requestID')) rem['requestID'] = remarks!['requestID'];
      if (rem.isNotEmpty) data['remarks'] = rem;
    }

    return data;
  }
}
