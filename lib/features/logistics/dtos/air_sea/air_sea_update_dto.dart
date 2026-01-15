/// DTO for updating an existing Air/Sea request
class AirSeaUpdateDto {
  final String? requestID;
  final int? mobileID;
  final String? riderName;
  final String? itemPreparedAt;
  final String? itemPreparedEndAt;
  final String? preparedBy;
  final String? receivedBy;
  final String? waybillNumber;
  final String? tripTicketNumber;
  final String? driver;
  final String? helper;
  final String? dispatchedAt;
  final String? dropOffAt;
  final String? status;
  final String? remarks;

  AirSeaUpdateDto({
    this.requestID,
    this.mobileID,
    this.riderName,
    this.itemPreparedAt,
    this.itemPreparedEndAt,
    this.preparedBy,
    this.receivedBy,
    this.waybillNumber,
    this.tripTicketNumber,
    this.driver,
    this.helper,
    this.dispatchedAt,
    this.dropOffAt,
    this.status,
    this.remarks,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    void put(String key, dynamic value) {
      if (value != null) data[key] = value;
    }

    put('RequestID', requestID);
    put('MobileID', mobileID);
    put('RiderName', riderName);
    put('ItemPreparedAt', itemPreparedAt);
    put('ItemPreparedEndAt', itemPreparedEndAt);
    put('PreparedBy', preparedBy);
    put('ReceivedBy', receivedBy);
    put('WaybillNumber', waybillNumber);
    put('TripTicketNumber', tripTicketNumber);
    put('Driver', driver);
    put('Helper', helper);
    put('DispatchedAt', dispatchedAt);
    put('DropOffAt', dropOffAt);
    put('Status', status);
    put('Remarks', remarks);

    return data;
  }
}

