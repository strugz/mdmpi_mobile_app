/// DTO for inserting a new Air/Sea request
class AirSeaInsertDto {
  final dynamic itemCategoryID;
  final String? clientID;
  final List<String>? documentReference;
  final String? datePickUp;
  final String? status;
  final String? createdBy;
  final String? updatedBy;
  final dynamic formCategoryID;
  final String? shippingMethod;

  AirSeaInsertDto({
    this.itemCategoryID,
    this.clientID,
    this.documentReference,
    this.datePickUp,
    this.status,
    this.createdBy,
    this.updatedBy,
    this.formCategoryID,
    this.shippingMethod,
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
    put('CreatedBy', createdBy);
    put('UpdatedBy', updatedBy);
    put('FormCategoryID', formCategoryID);
    put('ShippingMethod', shippingMethod);

    return data;
  }
}

