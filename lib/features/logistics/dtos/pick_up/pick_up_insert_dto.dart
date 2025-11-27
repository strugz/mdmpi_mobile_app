class PickUpInsertDto {
  final String? clientID;
  final dynamic itemCategoryID;
  final List<String>? documentReference;
  final String? datePickUp;
  final String? status;

  PickUpInsertDto({
    this.clientID,
    this.itemCategoryID,
    this.documentReference,
    this.datePickUp,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    void put(String key, dynamic value) {
      if (value != null) data[key] = value;
    }

    put('ClientID', clientID);
    put('ItemCategoryID', itemCategoryID);
    put('DocumentReference', documentReference);
    put('DatePickUp', datePickUp);
    put('Status', status);

    return data;
  }
}

