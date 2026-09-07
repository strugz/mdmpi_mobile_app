/// A backloaded item recorded against a Standard Delivery / Hotline Direct
/// request: an item listed on the request that the client did NOT receive at
/// drop off, with the courier's remarks. Identified by RequestID + ItemCode
/// (server table `a_tblbackloaditem`). Distinct from the whole-request
/// backload event (`a_tblrequestbackload` / BackLoad status).
class BackloadItemModel {
  final String requestId;
  final String itemCode;
  final String remarks;

  BackloadItemModel({
    this.requestId = '',
    required this.itemCode,
    required this.remarks,
  });

  factory BackloadItemModel.fromJson(Map<String, dynamic> json) {
    return BackloadItemModel(
      requestId: json['RequestID']?.toString() ?? '',
      itemCode: json['Item Code']?.toString() ?? '',
      remarks: json['Remarks']?.toString() ?? '',
    );
  }

  /// Payload shape for `POST /api4/BackloadItem/request/{id}` (InsertBackloadItemDto).
  Map<String, dynamic> toInsertJson() => {
        'Item Code': itemCode,
        'Remarks': remarks,
      };
}
