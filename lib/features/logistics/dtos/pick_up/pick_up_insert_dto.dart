class PickUpInsertDto {
  final String? clientID;
  final dynamic itemCategoryID;

  /// All selected categories (primary one first) — multi-select support.
  final List<int>? itemCategoryIDs;

  final List<String>? documentReference;
  final String? datePickUp;
  final String? status;
  final String? createdBy;

  PickUpInsertDto({
    this.clientID,
    this.itemCategoryID,
    this.itemCategoryIDs,
    this.documentReference,
    this.datePickUp,
    this.status,
    this.createdBy,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    void put(String key, dynamic value) {
      if (value != null) data[key] = value;
    }

    put('ClientID', clientID);
    put('ItemCategoryID', itemCategoryID);
    put('ItemCategoryIDs', itemCategoryIDs);
    put('DocumentReference', documentReference);
    put('DatePickUp', datePickUp);
    put('Status', status);
    put('CreatedBy', createdBy);

    return data;
  }
}

