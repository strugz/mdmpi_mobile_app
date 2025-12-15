/// DTO for inserting a new Air/Sea request
class AirSeaInsertDto {
  final dynamic itemCategoryID;
  final String? clientID;
  final List<String>? documentReference;
  final String? datePickUp;
  final String? status;

  AirSeaInsertDto({
    this.itemCategoryID,
    this.clientID,
    this.documentReference,
    this.datePickUp,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    void put(String key, dynamic value) {
      if (value != null) data[key] = value;
    }

    put('ItemCategoryID', itemCategoryID);
    put('ClientID', clientID);
    put('DocumentReference', documentReference);
    put('DatePickUp', datePickUp);
    put('Status', status);

    return data;
  }
}

