/// Model for Air/Sea request status stage history entries.
class AirSeaStatusStagesModel {
  final int historyID;
  final String actionType;
  final String changedAt;
  final String changedBy;
  final int requestID;
  final String clientID;
  final int itemCategoryID;
  final String receivedBy;
  final String waybillNumber;
  final String tripTicketNumber;
  final String driver;
  final String helper;
  final int? mobileID;
  final String datePickUp;
  final String itemPreparedAt;
  final String itemPreparedEndAt;
  final String dispatchedAt;
  final String dropOffAt;
  final String preparedBy;
  final String status;
  final String remarks;
  final String createdBy;
  final String createdAt;
  final String updatedAt;

  const AirSeaStatusStagesModel({
    required this.historyID,
    required this.actionType,
    required this.changedAt,
    required this.changedBy,
    required this.requestID,
    required this.clientID,
    required this.itemCategoryID,
    required this.receivedBy,
    required this.waybillNumber,
    required this.tripTicketNumber,
    required this.driver,
    required this.helper,
    required this.mobileID,
    required this.datePickUp,
    required this.itemPreparedAt,
    required this.itemPreparedEndAt,
    required this.dispatchedAt,
    required this.dropOffAt,
    required this.preparedBy,
    required this.status,
    required this.remarks,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Empty sentinel used as a safe fallback.
  static const AirSeaStatusStagesModel empty = AirSeaStatusStagesModel(
    historyID: 0,
    actionType: '',
    changedAt: '',
    changedBy: '',
    requestID: 0,
    clientID: '',
    itemCategoryID: 0,
    receivedBy: '',
    waybillNumber: '',
    tripTicketNumber: '',
    driver: '',
    helper: '',
    mobileID: null,
    datePickUp: '',
    itemPreparedAt: '',
    itemPreparedEndAt: '',
    dispatchedAt: '',
    dropOffAt: '',
    preparedBy: '',
    status: '',
    remarks: '',
    createdBy: '',
    createdAt: '',
    updatedAt: '',
  );

  bool get isEmpty => historyID == 0 && requestID == 0;

  bool get isNotEmpty => !isEmpty;

  static Map<String, dynamic> _normalizeKeys(Map<String, dynamic> json) {
    final Map<String, dynamic> lower = <String, dynamic>{};
    json.forEach((key, value) {
      lower[key.toString().toLowerCase()] = value;
    });
    return lower;
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }

      return value.toString();
    }

    return fallback;
  }

  static int _readInt(
    Map<String, dynamic> json,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }

      if (value is int) {
        return value;
      }

      final parsed = int.tryParse(value.toString());
      if (parsed != null) {
        return parsed;
      }
    }

    return fallback;
  }

  static int? _readNullableInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }

      if (value is int) {
        return value;
      }

      return int.tryParse(value.toString());
    }

    return null;
  }

  factory AirSeaStatusStagesModel.fromJson(Map<String, dynamic> json) {
    final lower = _normalizeKeys(json);

    return AirSeaStatusStagesModel(
      historyID: _readInt(lower, ['historyid']),
      actionType: _readString(lower, ['actiontype']),
      changedAt: _readString(lower, ['changedat']),
      changedBy: _readString(lower, ['changedby']),
      requestID: _readInt(lower, ['requestid']),
      clientID: _readString(lower, ['clientid']),
      itemCategoryID: _readInt(lower, ['itemcategoryid']),
      receivedBy: _readString(lower, ['receivedby']),
      waybillNumber: _readString(lower, ['waybillnumber']),
      tripTicketNumber: _readString(lower, ['tripticketnumber']),
      driver: _readString(lower, ['driver']),
      helper: _readString(lower, ['helper']),
      mobileID: _readNullableInt(lower, ['mobileid']),
      datePickUp: _readString(lower, ['datepickup']),
      itemPreparedAt: _readString(lower, ['itempreparedat']),
      itemPreparedEndAt: _readString(lower, ['itempreparedendat']),
      dispatchedAt: _readString(lower, ['dispatchedat']),
      dropOffAt: _readString(lower, ['dropoffat']),
      preparedBy: _readString(lower, ['preparedby']),
      status: _readString(lower, ['status']),
      remarks: _readString(lower, ['remarks']),
      createdBy: _readString(lower, ['createdby']),
      createdAt: _readString(lower, ['createdat']),
      updatedAt: _readString(lower, ['updatedat']),
    );
  }

  factory AirSeaStatusStagesModel.fromDbJson(Map<String, dynamic> json) {
    return AirSeaStatusStagesModel.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'historyID': historyID,
      'actionType': actionType,
      'changedAt': changedAt,
      'changedBy': changedBy,
      'requestID': requestID,
      'clientID': clientID,
      'itemCategoryID': itemCategoryID,
      'receivedBy': receivedBy,
      'waybillNumber': waybillNumber,
      'tripTicketNumber': tripTicketNumber,
      'driver': driver,
      'helper': helper,
      'mobileID': mobileID,
      'datePickUp': datePickUp,
      'itemPreparedAt': itemPreparedAt,
      'itemPreparedEndAt': itemPreparedEndAt,
      'dispatchedAt': dispatchedAt,
      'dropOffAt': dropOffAt,
      'preparedBy': preparedBy,
      'status': status,
      'remarks': remarks,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toDbJson() => toJson();

  AirSeaStatusStagesModel copyWith({
    int? historyID,
    String? actionType,
    String? changedAt,
    String? changedBy,
    int? requestID,
    String? clientID,
    int? itemCategoryID,
    String? receivedBy,
    String? waybillNumber,
    String? tripTicketNumber,
    String? driver,
    String? helper,
    int? mobileID,
    bool setMobileIdToNull = false,
    String? datePickUp,
    String? itemPreparedAt,
    String? itemPreparedEndAt,
    String? dispatchedAt,
    String? dropOffAt,
    String? preparedBy,
    String? status,
    String? remarks,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
  }) {
    return AirSeaStatusStagesModel(
      historyID: historyID ?? this.historyID,
      actionType: actionType ?? this.actionType,
      changedAt: changedAt ?? this.changedAt,
      changedBy: changedBy ?? this.changedBy,
      requestID: requestID ?? this.requestID,
      clientID: clientID ?? this.clientID,
      itemCategoryID: itemCategoryID ?? this.itemCategoryID,
      receivedBy: receivedBy ?? this.receivedBy,
      waybillNumber: waybillNumber ?? this.waybillNumber,
      tripTicketNumber: tripTicketNumber ?? this.tripTicketNumber,
      driver: driver ?? this.driver,
      helper: helper ?? this.helper,
      mobileID: setMobileIdToNull ? null : mobileID ?? this.mobileID,
      datePickUp: datePickUp ?? this.datePickUp,
      itemPreparedAt: itemPreparedAt ?? this.itemPreparedAt,
      itemPreparedEndAt: itemPreparedEndAt ?? this.itemPreparedEndAt,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      dropOffAt: dropOffAt ?? this.dropOffAt,
      preparedBy: preparedBy ?? this.preparedBy,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
