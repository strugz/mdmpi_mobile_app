class PullOutInsertDto {
  final String? clientID;
  final String? clientContactPerson;
  final dynamic formCategoryID;
  final dynamic itemCategoryID;
  final String? slipNo;
  final String? irrfNumber;
  final String? irrfDate;
  final String? reasonForReturn;
  final List<String>? documentReference;
  final String? pullOutDate;
  final String? requestStatus;
  final String? createdBy;
  final String? requestedBy;

  PullOutInsertDto({
    this.clientID,
    this.clientContactPerson,
    this.formCategoryID,
    this.itemCategoryID,
    this.slipNo,
    this.irrfNumber,
    this.irrfDate,
    this.reasonForReturn,
    this.documentReference,
    this.pullOutDate,
    this.requestStatus,
    this.createdBy,
    this.requestedBy,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    void put(String key, dynamic value) {
      if (value != null) data[key] = value;
    }

    put('ClientID', clientID);
    put('ClientContactPerson', clientContactPerson);
    put('FormCategoryID', formCategoryID);
    put('ItemCategoryID', itemCategoryID);
    put('SlipNo', slipNo);
    put('IRRFNumber', irrfNumber);
    put('IRRFDate', irrfDate);
    put('ReasonForReturn', reasonForReturn);
    put('DocumentReference', documentReference);
    put('PullOutDate', pullOutDate);
    put('RequestStatus', requestStatus);
    put('CreatedBy', createdBy);
    put('RequestedBy', requestedBy);

    return data;
  }
}
