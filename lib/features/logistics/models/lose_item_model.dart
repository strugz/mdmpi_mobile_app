/// A lost item recorded against a Pull Out / Return request: an item that
/// was listed on the request but NOT actually pulled out, with the courier's
/// remarks. Identified by RequestID + ItemCode (server table `a_tblLoseItem`).
class LoseItemModel {
  final String requestId;
  final String itemCode;
  final String remarks;

  LoseItemModel({
    this.requestId = '',
    required this.itemCode,
    required this.remarks,
  });

  factory LoseItemModel.fromJson(Map<String, dynamic> json) {
    return LoseItemModel(
      requestId: json['RequestID']?.toString() ?? '',
      itemCode: json['Item Code']?.toString() ?? '',
      remarks: json['Remarks']?.toString() ?? '',
    );
  }

  /// Payload shape for `POST /api4/LoseItem/request/{id}` (InsertLoseItemDto).
  Map<String, dynamic> toInsertJson() => {
        'Item Code': itemCode,
        'Remarks': remarks,
      };
}
