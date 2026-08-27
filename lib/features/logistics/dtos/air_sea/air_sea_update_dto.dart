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

  final String? provincialReceiverName;
  final String? provincialPickUpBy;
  final String? provincialPickUpAt;
  final String? provincialInTransitAt;
  final String? provincialInTransitLocation;
  final String? provincialDeliveredEndAt;
  final String? provincialDeliveredLocation;

  final String? status;
  final String? remarks;
  final String? updatedBy;

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
    this.provincialReceiverName,
    this.provincialPickUpBy,
    this.provincialPickUpAt,
    this.provincialInTransitAt,
    this.provincialInTransitLocation,
    this.provincialDeliveredEndAt,
    this.provincialDeliveredLocation,
    this.status,
    this.remarks,
    this.updatedBy,
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
    put('ProvincialReceiverName', provincialReceiverName);
    put('ProvincialPickUpBy', provincialPickUpBy);
    put('ProvincialPickUpAt', provincialPickUpAt);
    put('ProvincialInTransitAt', provincialInTransitAt);
    put('ProvincialInTransitLocation', provincialInTransitLocation);
    put('ProvincialDeliveredEndAt', provincialDeliveredEndAt);
    put('ProvincialDeliveredLocation', provincialDeliveredLocation);
    put('Status', status);
    put('Remarks', remarks);
    put('UpdatedBy', updatedBy);

    return data;
  }
}

