/// DTO for "Endorsed to Guard" history entries.
class AirSeaEndorsedToGuardHistoryDto {
  final int? historyID;
  final String? actionType;
  final String? changedAt;
  final String? changedBy;
  final int? requestID;
  final String? clientID;
  final int? itemCategoryID;
  final String? receivedBy;
  final String? status;
  final String? updatedAt;
  final String? createdBy;
  final String? createdAt;

  AirSeaEndorsedToGuardHistoryDto({
    this.historyID,
    this.actionType,
    this.changedAt,
    this.changedBy,
    this.requestID,
    this.clientID,
    this.itemCategoryID,
    this.receivedBy,
    this.status,
    this.updatedAt,
    this.createdBy,
    this.createdAt,
  });

  factory AirSeaEndorsedToGuardHistoryDto.fromJson(Map<String, dynamic> json) {
    return AirSeaEndorsedToGuardHistoryDto(
      historyID: json['historyID'] as int?,
      actionType: json['actionType'] as String?,
      changedAt: json['changedAt'] as String?,
      changedBy: json['changedBy'] as String?,
      requestID: json['requestID'] is int ? json['requestID'] as int : (json['requestID'] != null ? int.tryParse(json['requestID'].toString()) : null),
      clientID: json['clientID'] as String?,
      itemCategoryID: json['itemCategoryID'] is int ? json['itemCategoryID'] as int : (json['itemCategoryID'] != null ? int.tryParse(json['itemCategoryID'].toString()) : null),
      receivedBy: json['receivedBy'] as String?,
      status: json['status'] as String?,
      updatedAt: json['updatedAt'] as String?,
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
    put('status', status);
    put('updatedAt', updatedAt);
    put('createdBy', createdBy);
    put('createdAt', createdAt);

    return data;
  }
}

