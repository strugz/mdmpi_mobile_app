import '../models/air_sea_status_stages_model.dart';
import '../../../base/utils/formatters/formatters.dart';
import '../dtos/air_sea/air_sea_new_request_history_dto.dart';
import '../dtos/air_sea/air_sea_getting_supplies_ready_history_dto.dart';
import '../dtos/air_sea/air_sea_item_packed_history_dto.dart';
import '../dtos/air_sea/air_sea_endorsed_to_guard_history_dto.dart';

/// Mapper for converting between [AirSeaStatusStagesModel] and Map/JSON
/// representations used by the API / local DB.
///
/// This is an initial implementation — the user indicated they'll update
/// mapping rules later. The mapper currently provides conservative helpers
/// that reuse the model's existing `fromJson` / `toJson` but filter out
/// empty strings and nulls when producing maps for API/DB calls.
class AirSeaStatusStagesMapper {
  static String? _nonEmptyOrNull(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  static String? _normalizeDateTime(String? value) {
    // If already provided as non-empty string, attempt to normalize to ISO.
    if (value == null || value.trim().isEmpty) return null;
    return BFormatter.normalizeToIsoDatetime(value, toUtc: true);
  }

  /// Create model from a JSON/map. Delegates to model's factory.
  static AirSeaStatusStagesModel fromJson(Map<String, dynamic> json) {
    return AirSeaStatusStagesModel.fromJson(json);
  }

  /// Convert model to a plain Map suitable for transmission or DB insertion.
  ///
  /// This will omit null or empty-string fields to produce a compact map.
  static Map<String, dynamic> toMap(AirSeaStatusStagesModel m) {
    final Map<String, dynamic> data = {};

    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      data[key] = value;
    }

    put('historyID', m.historyID == 0 ? null : m.historyID);
    put('actionType', _nonEmptyOrNull(m.actionType));
    put('changedAt', _normalizeDateTime(m.changedAt) ?? _nonEmptyOrNull(m.changedAt));
    put('changedBy', _nonEmptyOrNull(m.changedBy));
    put('requestID', m.requestID == 0 ? null : m.requestID);
    put('clientID', _nonEmptyOrNull(m.clientID));
    put('itemCategoryID', m.itemCategoryID == 0 ? null : m.itemCategoryID);
    put('receivedBy', _nonEmptyOrNull(m.receivedBy));
    put('waybillNumber', _nonEmptyOrNull(m.waybillNumber));
    put('tripTicketNumber', _nonEmptyOrNull(m.tripTicketNumber));
    put('driver', _nonEmptyOrNull(m.driver));
    put('helper', _nonEmptyOrNull(m.helper));
    put('mobileID', m.mobileID);
    put('datePickUp', _normalizeDateTime(m.datePickUp) ?? _nonEmptyOrNull(m.datePickUp));
    put('itemPreparedAt', _normalizeDateTime(m.itemPreparedAt) ?? _nonEmptyOrNull(m.itemPreparedAt));
    put('itemPreparedEndAt', _normalizeDateTime(m.itemPreparedEndAt) ?? _nonEmptyOrNull(m.itemPreparedEndAt));
    put('dispatchedAt', _normalizeDateTime(m.dispatchedAt) ?? _nonEmptyOrNull(m.dispatchedAt));
    put('dropOffAt', _normalizeDateTime(m.dropOffAt) ?? _nonEmptyOrNull(m.dropOffAt));
    put('preparedBy', _nonEmptyOrNull(m.preparedBy));
    put('status', _nonEmptyOrNull(m.status));
    put('remarks', _nonEmptyOrNull(m.remarks));
    put('createdBy', _nonEmptyOrNull(m.createdBy));
    put('createdAt', _normalizeDateTime(m.createdAt) ?? _nonEmptyOrNull(m.createdAt));
    put('updatedAt', _normalizeDateTime(m.updatedAt) ?? _nonEmptyOrNull(m.updatedAt));

    return data;
  }

  /// Convert a JSON/map (from DB/API) into model list.
  static List<AirSeaStatusStagesModel> listFromJson(List<dynamic>? jsonList) {
    if (jsonList == null) return <AirSeaStatusStagesModel>[];
    return jsonList
        .where((e) => e != null)
        .map((e) => AirSeaStatusStagesModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Produce a status-specific DTO map for a given history model.
  ///
  /// This helper returns a compact Map (via the DTO's `toJson`) and
  /// ensures null/empty fields are omitted. It's intentionally conservative
  /// and can be extended when the backend requires different payloads
  /// for each status.
  static AirSeaNewRequestHistoryDto toNewRequestDto(AirSeaStatusStagesModel m) {
    return AirSeaNewRequestHistoryDto(
      historyID: m.historyID == 0 ? null : m.historyID,
      actionType: _nonEmptyOrNull(m.actionType),
      changedAt: _normalizeDateTime(m.changedAt) ?? _nonEmptyOrNull(m.changedAt),
      changedBy: _nonEmptyOrNull(m.changedBy),
      requestID: m.requestID == 0 ? null : m.requestID,
      clientID: _nonEmptyOrNull(m.clientID),
      itemCategoryID: m.itemCategoryID == 0 ? null : m.itemCategoryID,
      datePickUp: _normalizeDateTime(m.datePickUp) ?? _nonEmptyOrNull(m.datePickUp),
      status: _nonEmptyOrNull(m.status),
      createdBy: _nonEmptyOrNull(m.createdBy),
      createdAt: _normalizeDateTime(m.createdAt) ?? _nonEmptyOrNull(m.createdAt),
    );
  }

  static AirSeaGettingSuppliesReadyHistoryDto toGettingSuppliesReadyDto(AirSeaStatusStagesModel m) {
    return AirSeaGettingSuppliesReadyHistoryDto(
      historyID: m.historyID == 0 ? null : m.historyID,
      actionType: _nonEmptyOrNull(m.actionType),
      changedAt: _normalizeDateTime(m.changedAt) ?? _nonEmptyOrNull(m.changedAt),
      changedBy: _nonEmptyOrNull(m.changedBy),
      requestID: m.requestID == 0 ? null : m.requestID,
      clientID: _nonEmptyOrNull(m.clientID),
      itemCategoryID: m.itemCategoryID == 0 ? null : m.itemCategoryID,
      receivedBy: _nonEmptyOrNull(m.receivedBy),
      itemPreparedAt: _normalizeDateTime(m.itemPreparedAt) ?? _nonEmptyOrNull(m.itemPreparedAt),
      preparedBy: _nonEmptyOrNull(m.preparedBy),
      status: _nonEmptyOrNull(m.status),
      createdBy: _nonEmptyOrNull(m.createdBy),
      createdAt: _normalizeDateTime(m.createdAt) ?? _nonEmptyOrNull(m.createdAt),
    );
  }

  static AirSeaItemPackedHistoryDto toItemPackedDto(AirSeaStatusStagesModel m) {
    return AirSeaItemPackedHistoryDto(
      historyID: m.historyID == 0 ? null : m.historyID,
      actionType: _nonEmptyOrNull(m.actionType),
      changedAt: _normalizeDateTime(m.changedAt) ?? _nonEmptyOrNull(m.changedAt),
      changedBy: _nonEmptyOrNull(m.changedBy),
      requestID: m.requestID == 0 ? null : m.requestID,
      clientID: _nonEmptyOrNull(m.clientID),
      itemCategoryID: m.itemCategoryID == 0 ? null : m.itemCategoryID,
      receivedBy: _nonEmptyOrNull(m.receivedBy),
      itemPreparedAt: _normalizeDateTime(m.itemPreparedAt) ?? _nonEmptyOrNull(m.itemPreparedAt),
      itemPreparedEndAt: _normalizeDateTime(m.itemPreparedEndAt) ?? _nonEmptyOrNull(m.itemPreparedEndAt),
      preparedBy: _nonEmptyOrNull(m.preparedBy),
      status: _nonEmptyOrNull(m.status),
      createdBy: _nonEmptyOrNull(m.createdBy),
      createdAt: _normalizeDateTime(m.createdAt) ?? _nonEmptyOrNull(m.createdAt),
    );
  }

  static AirSeaEndorsedToGuardHistoryDto toEndorsedToGuardDto(AirSeaStatusStagesModel m) {
    return AirSeaEndorsedToGuardHistoryDto(
      historyID: m.historyID == 0 ? null : m.historyID,
      actionType: _nonEmptyOrNull(m.actionType),
      changedAt: _normalizeDateTime(m.changedAt) ?? _nonEmptyOrNull(m.changedAt),
      changedBy: _nonEmptyOrNull(m.changedBy),
      requestID: m.requestID == 0 ? null : m.requestID,
      clientID: _nonEmptyOrNull(m.clientID),
      itemCategoryID: m.itemCategoryID == 0 ? null : m.itemCategoryID,
      receivedBy: _nonEmptyOrNull(m.receivedBy),
      status: _nonEmptyOrNull(m.status),
      updatedAt: _normalizeDateTime(m.updatedAt) ?? _nonEmptyOrNull(m.updatedAt),
      createdBy: _nonEmptyOrNull(m.createdBy),
      createdAt: _normalizeDateTime(m.createdAt) ?? _nonEmptyOrNull(m.createdAt),
    );
  }
}


