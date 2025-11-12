class StandardDeliveryInsertDto {
  final String? requestClientID;
  final String? requestShippingMethod;
  final String? requestDeliveryTerms;
  final String? requestDeliveryDate;
  final String? requestPreference;
  final String? requestStatus;
  final String? requestBy;
  final String? requestCreatedBy;
  final List<String>? documentReference;

  StandardDeliveryInsertDto({
    this.requestClientID,
    this.requestShippingMethod,
    this.requestDeliveryTerms,
    this.requestDeliveryDate,
    this.requestPreference,
    this.requestStatus,
    this.requestBy,
    this.requestCreatedBy,
    this.documentReference,
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
    put('documentReference', documentReference);

    return data;
  }
}
