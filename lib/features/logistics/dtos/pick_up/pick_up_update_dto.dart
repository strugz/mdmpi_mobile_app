class PickUpUpdateDto {
  final String? requestID;
  final String? clientID;
  final dynamic itemCategoryID;
  final List<String>? documentReference;
  final String? preparedBy;
  final String? itemPreparedAt;
  final String? itemPreparedEndAt;
  final String? datePickUp;
  final String? remarks;
  final String? status;
  final String? releasedBy;
  final String? receivedBy;

  PickUpUpdateDto({
    this.requestID,
    this.clientID,
    this.itemCategoryID,
    this.documentReference,
    this.preparedBy,
    this.itemPreparedAt,
    this.itemPreparedEndAt,
    this.datePickUp,
    this.remarks,
    this.status,
    this.releasedBy,
    this.receivedBy,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    void put(String key, dynamic value) {
      if (value != null) data[key] = value;
    }

    put('RequestID', requestID);
    put('ClientID', clientID);
    put('ItemCategoryID', itemCategoryID);
    put('DocumentReference', documentReference);
    put('PreparedBy', preparedBy);
    put('ItemPreparedAt', itemPreparedAt);
    put('ItemPreparedEndAt', itemPreparedEndAt);
    put('DatePickUp', datePickUp);
    put('Remarks', remarks);
    put('Status', status);
    put('ReleasedBy', releasedBy);
    put('ReceivedBy', receivedBy);

    return data;
  }
}

