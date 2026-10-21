import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';

class StandardDeliveryInsertDto {
  final String? requestClientID;
  final String? requestShippingMethod;
  final String? requestDeliveryTerms;
  final String? requestDeliveryDate;
  final String? requestPreference;
  final String? requestStatus;
  final String? requestBy;
  final String? requestCreatedBy;
  final String? updatedBy;
  final String? recipientContactDetails;
  final String? recipientName;
  final List<String>? documentReference;
  final List<InventoryItemModel>? items;
  final int? itemCategoryID;  // Changed to int
  final int? formCategoryID;  // Changed to int

  /// The scanned delivery address, set only when a one-scan used it because
  /// the client's saved address was missing (plan §4.4b). Null otherwise, so
  /// the JSON is exactly what it was before.
  final String? requestDeliveryAddress;

  StandardDeliveryInsertDto({
    this.requestClientID,
    this.requestShippingMethod,
    this.requestDeliveryTerms,
    this.requestDeliveryDate,
    this.requestPreference,
    this.requestStatus,
    this.requestBy,
    this.requestCreatedBy,
    this.updatedBy,
    this.recipientContactDetails,
    this.recipientName,
    this.documentReference,
    this.items,
    this.itemCategoryID,
    this.formCategoryID,
    this.requestDeliveryAddress,
  });

  Map<String, dynamic> toJson() {
    // Use lowerCamel keys to match the API contract
    final Map<String, dynamic> data = {};
    void put(String key, dynamic value) {
      if (value != null) data[key] = value;
    }

    put('requestClientID', requestClientID);
    put('requestShippingMethod', requestShippingMethod);
    put('requestDeliveryTerms', requestDeliveryTerms);
    put('requestDeliveryDate', requestDeliveryDate);
    put('requestPreference', requestPreference);
    put('requestStatus', requestStatus);
    put('requestBy', requestBy);
    put('requestCreatedBy', requestCreatedBy);
    put('updatedBy', updatedBy);
    put('recipientContactDetails', recipientContactDetails);
    put('recipientName', recipientName);
    put('documentReference', documentReference);
    if (items != null) {
      put('items', items!.map((e) => e.toJson()).toList());
    } else {
      put('items', []);
    }
    put('itemCategoryID', itemCategoryID);
    put('formCategoryID', formCategoryID);
    put('requestDeliveryAddress', requestDeliveryAddress);
    return data;
  }
}
