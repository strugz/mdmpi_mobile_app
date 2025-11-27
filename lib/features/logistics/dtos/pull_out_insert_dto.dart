class PullOutInsertDto {
  final String? clientID;
  final String? clientContactPerson;
  final dynamic formCategoryID;
  final dynamic itemCategoryID;
  final String? irrfNumber;
  final String? irrfDate;
  final String? reasonForReturn;
  final List<String>? documentReference;
  final String? pullOutDate;
  final int? mobileID;
  final String? releasedBy;
  final String? pullOutDateStartAt;
  final String? pullOutDateEndAt;
  final String? tripTicketNumber;
  final String? driver;
  final String? helper;
  final String? requestStatus;
  final String? createdBy;
  final String? requestedBy;

  PullOutInsertDto({
    this.clientID,
    this.clientContactPerson,
    this.formCategoryID,
    this.itemCategoryID,
    this.irrfNumber,
    this.irrfDate,
    this.reasonForReturn,
    this.documentReference,
    this.pullOutDate,
    this.mobileID,
    this.releasedBy,
    this.pullOutDateStartAt,
    this.pullOutDateEndAt,
    this.tripTicketNumber,
    this.driver,
    this.helper,
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
    put('IRRFNumber', irrfNumber);
    put('IRRFDate', irrfDate);
    put('ReasonForReturn', reasonForReturn);
    put('DocumentReference', documentReference);
    put('PullOutDate', pullOutDate);
    put('MobileID', mobileID);
    put('ReleasedBy', releasedBy);
    put('PullOutDateStartAt', pullOutDateStartAt);
    put('PullOutDateEndAt', pullOutDateEndAt);
    put('TripTicketNumber', tripTicketNumber);
    put('Driver', driver);
    put('Helper', helper);
    put('RequestStatus', requestStatus);
    put('CreatedBy', createdBy);
    put('RequestedBy', requestedBy);

    return data;
  }
}
