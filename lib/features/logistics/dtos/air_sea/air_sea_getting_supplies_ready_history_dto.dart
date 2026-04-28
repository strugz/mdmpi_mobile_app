/// DTO for "Getting supplies ready" history entries.
class AirSeaGettingSuppliesReadyHistoryDto {
  final int? historyID;
  final String? actionType;
  final String? changedAt;
  final String? changedBy;
  final int? requestID;
  final String? clientID;
  final int? itemCategoryID;
  final String? receivedBy;
  final String? itemPreparedAt;
  final String? preparedBy;
  final String? status;
  final String? createdBy;
  final String? createdAt;

  AirSeaGettingSuppliesReadyHistoryDto({
    this.historyID,
    this.actionType,
    this.changedAt,
    this.changedBy,
    this.requestID,
    this.clientID,
    this.itemCategoryID,
    this.receivedBy,
    this.itemPreparedAt,
    this.preparedBy,
    this.status,
    this.createdBy,
    this.createdAt,
  });

  factory AirSeaGettingSuppliesReadyHistoryDto.fromJson(Map<String, dynamic> json) {
    return AirSeaGettingSuppliesReadyHistoryDto(
      historyID: json['historyID'] as int?,
      actionType: json['actionType'] as String?,
      changedAt: json['changedAt'] as String?,
      changedBy: json['changedBy'] as String?,
      requestID: json['requestID'] is int ? json['requestID'] as int : (json['requestID'] != null ? int.tryParse(json['requestID'].toString()) : null),
      clientID: json['clientID'] as String?,
      itemCategoryID: json['itemCategoryID'] is int ? json['itemCategoryID'] as int : (json['itemCategoryID'] != null ? int.tryParse(json['itemCategoryID'].toString()) : null),
      receivedBy: json['receivedBy'] as String?,
      itemPreparedAt: json['itemPreparedAt'] as String?,
      preparedBy: json['preparedBy'] as String?,
      status: json['status'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      data[key] = value;
    }

    put('historyID', historyID);
    put('actionType', actionType);
    put('changedAt', changedAt);
    put('changedBy', changedBy);
    put('requestID', requestID);
    put('clientID', clientID);
    put('itemCategoryID', itemCategoryID);
    put('receivedBy', receivedBy);
    put('itemPreparedAt', itemPreparedAt);
    put('preparedBy', preparedBy);
    put('status', status);
    put('createdBy', createdBy);
    put('createdAt', createdAt);

    return data;
  }
}

