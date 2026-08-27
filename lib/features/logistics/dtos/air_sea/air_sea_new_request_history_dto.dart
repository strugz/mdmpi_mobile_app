/// DTO for "New Request" history entries.
class AirSeaNewRequestHistoryDto {
  final int? historyID;
  final String? actionType;
  final String? changedAt;
  final String? changedBy;
  final int? requestID;
  final String? clientID;
  final int? itemCategoryID;
  final String? datePickUp;
  final String? status;
  final String? createdBy;
  final String? createdAt;

  AirSeaNewRequestHistoryDto({
    this.historyID,
    this.actionType,
    this.changedAt,
    this.changedBy,
    this.requestID,
    this.clientID,
    this.itemCategoryID,
    this.datePickUp,
    this.status,
    this.createdBy,
    this.createdAt,
  });

  factory AirSeaNewRequestHistoryDto.fromJson(Map<String, dynamic> json) {
    return AirSeaNewRequestHistoryDto(
      historyID: json['historyID'] as int?,
      actionType: json['actionType'] as String?,
      changedAt: json['changedAt'] as String?,
      changedBy: json['changedBy'] as String?,
      requestID: json['requestID'] is int ? json['requestID'] as int : (json['requestID'] != null ? int.tryParse(json['requestID'].toString()) : null),
      clientID: json['clientID'] as String?,
      itemCategoryID: json['itemCategoryID'] is int ? json['itemCategoryID'] as int : (json['itemCategoryID'] != null ? int.tryParse(json['itemCategoryID'].toString()) : null),
      datePickUp: json['datePickUp'] as String?,
      status: json['status'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  /// Convert to Map but omit null values.
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
    put('datePickUp', datePickUp);
    put('status', status);
    put('createdBy', createdBy);
    put('createdAt', createdAt);

    return data;
  }
}

