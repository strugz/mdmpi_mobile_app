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
      documentReference: m.documentReference.isNotEmpty ? m.documentReference : null,
      datePickUp: m.datePickUp.isNotEmpty ? m.datePickUp : null,
      status: m.status.isNotEmpty ? m.status : null,
    );
  }

  /// Maps AirSeaModel to AirSeaUpdateDto for API update operations
  static AirSeaUpdateDto toUpdateDto(AirSeaModel m) {
    return AirSeaUpdateDto(
      requestID: m.id.isNotEmpty ? m.id : null,
      mobileID: m.mobileId,
            preparedBy: m.preparedBy.isNotEmpty ? m.preparedBy : null,
      itemPreparedAt: BFormatter.normalizeToIsoDatetime(m.itemPreparedAt),
      itemPreparedEndAt: BFormatter.normalizeToIsoDatetime(m.itemPreparedEndAt),
      remarks: m.remarks.isNotEmpty ? m.remarks : null,
      status: m.status.isNotEmpty ? m.status : null,
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
    put('ItemPreparedEndAt', BFormatter.normalizeToIsoDatetime(m.itemPreparedEndAt));
    put('Remarks', m.remarks);
    put('Status', m.status);

    return data;
  }
}

