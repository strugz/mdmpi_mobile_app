import '../dtos/pull_out/pull_out_insert_dto.dart';
import '../models/pull_out_model.dart';
import '../../../base/utils/formatters/formatters.dart';

class PullOutMapper {
  static PullOutInsertDto toInsertDto(PullOutModel m) {
    dynamic parseIntIfPossible(String s) {
      if (s.isEmpty) return null;
      final n = int.tryParse(s);
      return n ?? s;
    }

    return PullOutInsertDto(
      clientID: m.clientId.isNotEmpty ? m.clientId : null,
      clientContactPerson: m.clientContactPerson.isNotEmpty ? m.clientContactPerson : null,
      formCategoryID: parseIntIfPossible(m.formCategoryId),
      itemCategoryID: parseIntIfPossible(m.itemCategoryId),
      irrfNumber: m.irrfNumber.isNotEmpty ? m.irrfNumber : null,
      irrfDate: m.irrfDate.isNotEmpty ? m.irrfDate : null,
      reasonForReturn: m.reasonForReturn.isNotEmpty ? m.reasonForReturn : null,
      documentReference: m.documentReference.isNotEmpty ? m.documentReference : null,
      pullOutDate: m.pullOutDate.isNotEmpty ? m.pullOutDate : null,
      mobileID: m.mobileID,
      releasedBy: m.releasedBy.isNotEmpty ? m.releasedBy : null,
      pullOutDateStartAt: BFormatter.normalizeToIsoDatetime(m.pullOutDateStartAt),
      pullOutDateEndAt: BFormatter.normalizeToIsoDatetime(m.pullOutDateEndAt),
      tripTicketNumber: m.tripTicketNumber.isNotEmpty ? m.tripTicketNumber : null,
      driver: m.driver.isNotEmpty ? m.driver : null,
      helper: m.helper.isNotEmpty ? m.helper : null,
      requestStatus: m.requestStatus.isNotEmpty ? m.requestStatus : null,
      createdBy: m.createdBy.isNotEmpty ? m.createdBy : null,
      requestedBy: m.requestedBy.isNotEmpty ? m.requestedBy : null,
    );
  }

  static Map<String, dynamic> toUpdateDto(PullOutModel m) {
    final Map<String, dynamic> data = {};
    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      data[key] = value;
    }

    if (m.id.isNotEmpty) data['RequestID'] = m.id;
    put('MobileID', m.mobileID);
    put('ClientContactPerson', m.clientContactPerson);
    put('ReasonForReturn', m.reasonForReturn);
    put('ReleasedBy', m.releasedBy);
    put('PullOutDateStartAt', BFormatter.normalizeToIsoDatetime(m.pullOutDateStartAt));
    put('PullOutDateEndAt', BFormatter.normalizeToIsoDatetime(m.pullOutDateEndAt));
    put('RequestStatus', m.requestStatus);
    put('TripTicketNumber', m.tripTicketNumber);
    put('Driver', m.driver);
    put('Helper', m.helper);
    put('RequestedBy', m.requestedBy);
    return data;
  }
}
