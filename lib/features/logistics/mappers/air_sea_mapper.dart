import '../dtos/air_sea/air_sea_insert_dto.dart';
import '../dtos/air_sea/air_sea_update_dto.dart';
import '../models/air_sea_model.dart';
import '../../../base/utils/formatters/formatters.dart';

/// Mapper class for converting AirSeaModel to DTOs for API operations.
class AirSeaMapper {
  static String? _nonEmptyOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _normalizeDateTimeValue(DateTime? dateTime, String? fallback) {
    if (dateTime != null) {
      return dateTime.toUtc().toIso8601String();
    }

    return BFormatter.normalizeToIsoDatetime(fallback, toUtc: true);
  }

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
      preparedBy: _nonEmptyOrNull(m.preparedBy),
      itemPreparedAt: BFormatter.normalizeToIsoDatetime(m.itemPreparedAt),
      itemPreparedEndAt: BFormatter.normalizeToIsoDatetime(m.itemPreparedEndAt),
      remarks: _nonEmptyOrNull(m.remarks),
      status: _nonEmptyOrNull(m.status),
      receivedBy: _nonEmptyOrNull(m.receivedBy),
      waybillNumber: _nonEmptyOrNull(m.waybillNumber),
      tripTicketNumber: _nonEmptyOrNull(m.tripTicketNumber),
      driver: _nonEmptyOrNull(m.driver),
      helper: _nonEmptyOrNull(m.helper),
      dispatchedAt: BFormatter.normalizeToIsoDatetime(m.dispatchedAt),
      dropOffAt: BFormatter.normalizeToIsoDatetime(m.dropOffAt),
      provincialReceiverName: _nonEmptyOrNull(m.provincialReceiverName),
      provincialPickUpBy: _nonEmptyOrNull(m.provincialPickUpBy),
      provincialPickUpAt: _normalizeDateTimeValue(m.provincialPickUpAt, null),
      provincialInTransitAt:
          _normalizeDateTimeValue(m.provincialInTransitAt, null),
      provincialInTransitLocation: _nonEmptyOrNull(m.provincialInTransitLocation),
      provincialDeliveredEndAt:
          _normalizeDateTimeValue(m.provincialDeliveredEndAt, null),
      provincialDeliveredLocation:
          _nonEmptyOrNull(m.provincialDeliveredLocation),
      updatedBy: _nonEmptyOrNull(updatedBy),
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
    put('provincial_receiver_name', m.provincialReceiverName);
    put('provincial_pick_up_by', m.provincialPickUpBy);
    put('provincial_pick_up_at',
        _normalizeDateTimeValue(m.provincialPickUpAt, null));
    put('provincial_in_transit_at',
        _normalizeDateTimeValue(m.provincialInTransitAt, null));
    put('provincial_in_transit_location', m.provincialInTransitLocation);
    put('provincial_delivered_end_at',
        _normalizeDateTimeValue(m.provincialDeliveredEndAt, null));
    put('provincial_delivered_location', m.provincialDeliveredLocation);
    put('Remarks', m.remarks);
    put('Status', m.status);

    return data;
  }
}
