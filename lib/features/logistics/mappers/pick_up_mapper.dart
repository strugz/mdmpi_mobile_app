import '../dtos/pick_up/pick_up_insert_dto.dart';
import '../dtos/pick_up/pick_up_update_dto.dart';
import '../models/pick_up_model.dart';
import '../../../base/utils/formatters/formatters.dart';

class PickUpMapper {
  /// Maps PickUpModel to PickUpInsertDto for API insert operations
  static PickUpInsertDto toInsertDto(PickUpModel m) {
    dynamic parseIntIfPossible(String s) {
      if (s.isEmpty) return null;
      final n = int.tryParse(s);
      return n ?? s;
    }

    final categoryIds = m.itemCategoryIds
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toList();

    return PickUpInsertDto(
      clientID: m.clientId.isNotEmpty ? m.clientId : null,
      itemCategoryID: parseIntIfPossible(m.itemCategoryId),
      itemCategoryIDs: categoryIds.isNotEmpty ? categoryIds : null,
      documentReference: m.documentReference.isNotEmpty ? m.documentReference : null,
      datePickUp: m.datePickUp.isNotEmpty ? m.datePickUp : null,
      status: m.status.isNotEmpty ? m.status : null,
      createdBy: m.createdBy.isNotEmpty ? m.createdBy : null,
    );
  }

  /// Maps PickUpModel to PickUpUpdateDto for API update operations
  static PickUpUpdateDto toUpdateDto(PickUpModel m) {
    dynamic parseIntIfPossible(String s) {
      if (s.isEmpty) return null;
      final n = int.tryParse(s);
      return n ?? s;
    }

    return PickUpUpdateDto(
      requestID: m.id.isNotEmpty ? m.id : null,
      clientID: m.clientId.isNotEmpty ? m.clientId : null,
      itemCategoryID: parseIntIfPossible(m.itemCategoryId),
      documentReference: m.documentReference.isNotEmpty ? m.documentReference : null,
      preparedBy: m.preparedBy.isNotEmpty ? m.preparedBy : null,
      itemPreparedAt: BFormatter.normalizeToIsoDatetime(m.itemPreparedAt),
      itemPreparedEndAt: BFormatter.normalizeToIsoDatetime(m.itemPreparedEndAt),
      datePickUp: m.datePickUp.isNotEmpty ? m.datePickUp : null,
      remarks: m.remarks.isNotEmpty ? m.remarks : null,
      status: m.status.isNotEmpty ? m.status : null,
      releasedBy: m.releasedBy.isNotEmpty ? m.releasedBy : null,
      receivedBy: m.receivedBy.isNotEmpty ? m.receivedBy : null,
    );
  }

  /// Maps PickUpModel to update Map for API update operations (alternative)
  static Map<String, dynamic> toUpdateMap(PickUpModel m) {
    final Map<String, dynamic> data = {};
    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      data[key] = value;
    }

    if (m.id.isNotEmpty) data['RequestID'] = m.id;
    put('ClientID', m.clientId);
    put('PreparedBy', m.preparedBy);
    put('ItemPreparedAt', BFormatter.normalizeToIsoDatetime(m.itemPreparedAt));
    put('ItemPreparedEndAt', BFormatter.normalizeToIsoDatetime(m.itemPreparedEndAt));
    put('DatePickUp', m.datePickUp);
    put('Remarks', m.remarks);
    put('Status', m.status);
    put('ReleasedBy', m.releasedBy);
    put('ReceivedBy', m.receivedBy);

    return data;
  }
}

