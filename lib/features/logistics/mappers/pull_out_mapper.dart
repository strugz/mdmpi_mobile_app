import '../dtos/pull_out_insert_dto.dart';
import '../models/pull_out_model.dart';

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
      slipNo: m.slipNo.isNotEmpty ? m.slipNo : null,
      irrfNumber: m.irrfNumber.isNotEmpty ? m.irrfNumber : null,
      irrfDate: m.irrfDate.isNotEmpty ? m.irrfDate : null,
      reasonForReturn: m.reasonForReturn.isNotEmpty ? m.reasonForReturn : null,
      documentReference: m.documentReference.isNotEmpty ? m.documentReference : null,
      pullOutDate: m.pullOutDate.isNotEmpty ? m.pullOutDate : null,
      requestStatus: m.requestStatus.isNotEmpty ? m.requestStatus : null,
      createdBy: m.createdBy.isNotEmpty ? m.createdBy : null,
      requestedBy: m.requestedBy.isNotEmpty ? m.requestedBy : null,
    );
  }
}

