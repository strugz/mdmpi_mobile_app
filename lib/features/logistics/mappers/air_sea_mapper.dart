import '../dtos/air_sea/air_sea_insert_dto.dart';
import '../dtos/air_sea/air_sea_update_dto.dart';
import '../models/air_sea_model.dart';
import '../../../base/utils/formatters/formatters.dart';

/// Mapper class for converting AirSeaModel to DTOs for API operations.
class AirSeaMapper {
  /// Maps AirSeaModel to AirSeaInsertDto for API insert operations
  static AirSeaInsertDto toInsertDto(AirSeaModel m) {
    dynamic parseIntIfPossible(String s) {
      if (s.isEmpty) return null;
      final n = int.tryParse(s);
      return n ?? s;
    }

    return AirSeaInsertDto(
      clientID: m.clientId.isNotEmpty ? m.clientId : null,
      itemCategoryID: parseIntIfPossible(m.itemCategoryId),
      documentReference:
          m.documentReference.isNotEmpty ? m.documentReference : null,
      datePickUp: m.datePickUp.isNotEmpty ? m.datePickUp : null,
      status: m.status.isNotEmpty ? m.status : null,
      createdBy: m.createdBy.isNotEmpty ? m.createdBy : null,
      updatedBy: m.createdBy.isNotEmpty ? m.createdBy : null,
    );
  }

  /// Maps AirSeaModel to AirSeaUpdateDto for API update operations
  static AirSeaUpdateDto toUpdateDto(AirSeaModel m, String updatedBy) {
    return AirSeaUpdateDto(
      requestID: m.id.isNotEmpty ? m.id : null,
      mobileID: m.mobileId,
      preparedBy: m.preparedBy.isNotEmpty ? m.preparedBy : null,
      itemPreparedAt: BFormatter.normalizeToIsoDatetime(m.itemPreparedAt),
      itemPreparedEndAt: BFormatter.normalizeToIsoDatetime(m.itemPreparedEndAt),
      remarks: m.remarks.isNotEmpty ? m.remarks : null,
      status: m.status.isNotEmpty ? m.status : null,
      receivedBy: m.receivedBy.isNotEmpty ? m.receivedBy : null,
      waybillNumber: m.waybillNumber.isNotEmpty ? m.waybillNumber : null,
      tripTicketNumber: m.tripTicketNumber.isNotEmpty ? m.tripTicketNumber : null,
      driver: m.driver.isNotEmpty ? m.driver : null,
      helper: m.helper.isNotEmpty ? m.helper : null,
      dispatchedAt: BFormatter.normalizeToIsoDatetime(m.dispatchedAt),
      dropOffAt: BFormatter.normalizeToIsoDatetime(m.dropOffAt),
      provincialReceiverName: m.provincialReceiverName.isNotEmpty ? m.provincialReceiverName : null,
      provincialPickUpAt: BFormatter.normalizeToIsoDatetime(m.provincialPickUpAt),
      provincialDeliveredTo: m.provincialDeliveredTo.isNotEmpty ? m.provincialDeliveredTo : null,
      provincialDeliveredAt: BFormatter.normalizeToIsoDatetime(m.provincialDeliveredAt),
      provincialRemarks: m.provincialRemarks.isNotEmpty ? m.provincialRemarks : null,
      updatedBy: updatedBy.isNotEmpty ? updatedBy : null,
    );
  }

  /// Maps AirSeaModel to update Map for API update operations (alternative)
  static Map<String, dynamic> toUpdateMap(AirSeaModel m) {
    final Map<String, dynamic> data = {};
    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      data[key] = value;
    }

    if (m.id.isNotEmpty) data['RequestID'] = m.id;
    put('MobileID', m.mobileId);
    put('PreparedBy', m.preparedBy);
    put('ItemPreparedAt', BFormatter.normalizeToIsoDatetime(m.itemPreparedAt));
    put('ItemPreparedEndAt',
        BFormatter.normalizeToIsoDatetime(m.itemPreparedEndAt));
    put('EndorsedBy', m.endorsedBy);
    put('ReceivedBy', m.receivedBy);
    put('WaybillNumber', m.waybillNumber);
    put('TripTicketNumber', m.tripTicketNumber);
    put('Driver', m.driver);
    put('Helper', m.helper);
    put('DispatchedAt', BFormatter.normalizeToIsoDatetime(m.dispatchedAt));
    put('DropOffAt', BFormatter.normalizeToIsoDatetime(m.dropOffAt));
    put('ProvincialReceiverName', m.provincialReceiverName);
    put('ProvincialPickUpAt', BFormatter.normalizeToIsoDatetime(m.provincialPickUpAt));
    put('ProvincialDeliveredTo', m.provincialDeliveredTo);
    put('ProvincialDeliveredAt', BFormatter.normalizeToIsoDatetime(m.provincialDeliveredAt));
    put('ProvincialRemarks', m.provincialRemarks);
    put('Remarks', m.remarks);
    put('Status', m.status);

    return data;
  }
}
