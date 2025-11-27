import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/data/models/item_category_model.dart';

/// Pick-up request model.
class PickUpModel {
  String id;
  String clientId;
  String itemCategoryId;
  String preparedBy;
  String itemPreparedAt;
  String itemPreparedEndAt;
  String datePickUp;
  String remarks;
  String status;
  String releasedBy;
  String receivedBy;
  String createdAt;
  String updatedAt;

  // Aggregates
  ClientModel client;
  ItemCategoryModel itemCategory;
  List<String> documentReference;

  PickUpModel({
    this.id = '',
    this.clientId = '',
    this.itemCategoryId = '',
    this.preparedBy = '',
    this.itemPreparedAt = '',
    this.itemPreparedEndAt = '',
    this.datePickUp = '',
    this.remarks = '',
    this.status = '',
    this.releasedBy = '',
    this.receivedBy = '',
    this.createdAt = '',
    this.updatedAt = '',
    ClientModel? client,
    ItemCategoryModel? itemCategory,
    List<String>? documentReference,
  })  : client = client ?? ClientModel.empty(),
        itemCategory = itemCategory ?? ItemCategoryModel.empty(),
        documentReference = documentReference ?? <String>[];

  /// Convenience empty factory
  static PickUpModel empty() => PickUpModel();

  PickUpModel copyWith({
    String? id,
    String? clientId,
    String? itemCategoryId,
    String? preparedBy,
    String? itemPreparedAt,
    String? itemPreparedEndAt,
    String? datePickUp,
    String? remarks,
    String? status,
    String? releasedBy,
    String? receivedBy,
    String? createdAt,
    String? updatedAt,
    ClientModel? client,
    ItemCategoryModel? itemCategory,
    List<String>? documentReference,
  }) {
    return PickUpModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      itemCategoryId: itemCategoryId ?? this.itemCategoryId,
      preparedBy: preparedBy ?? this.preparedBy,
      itemPreparedAt: itemPreparedAt ?? this.itemPreparedAt,
      itemPreparedEndAt: itemPreparedEndAt ?? this.itemPreparedEndAt,
      datePickUp: datePickUp ?? this.datePickUp,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      releasedBy: releasedBy ?? this.releasedBy,
      receivedBy: receivedBy ?? this.receivedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      client: client ?? this.client,
      itemCategory: itemCategory ?? this.itemCategory,
      documentReference: documentReference ?? this.documentReference,
    );
  }

  /// Serialize to API JSON
  Map<String, dynamic> toJson() {
    return {
      'RequestID': id,
      'ClientID': clientId,
      'ItemCategoryID': itemCategoryId,
      'PreparedBy': preparedBy,
      'ItemPreparedAt': itemPreparedAt,
      'ItemPreparedEndAt': itemPreparedEndAt,
      'DatePickUp': datePickUp,
      'Remarks': remarks,
      'Status': status,
      'ReleasedBy': releasedBy,
      'ReceivedBy': receivedBy,
      'CreatedAt': createdAt,
      'UpdatedAt': updatedAt,
      'Client': client.toJson(),
      'ItemCategory': itemCategory.toJson(),
      'DocumentReference': documentReference,
    };
  }

  /// Parse from API JSON
  factory PickUpModel.fromJson(Map<String, dynamic> json) {
    String firstPresent(Map<String, dynamic> m, List<String> keys,
        {String fallback = ''}) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) return m[k].toString();
      }
      return fallback;
    }

    return PickUpModel(
      id: firstPresent(json,
          ['RequestID', 'requestID', 'RequestId', 'requestId', 'Requestid']),
      clientId: firstPresent(
          json, ['ClientID', 'clientID', 'clientId', 'ClientId']),
      itemCategoryId: firstPresent(json, [
        'ItemCategoryID',
        'itemCategoryID',
        'ItemCategoryId',
        'itemCategoryId'
      ]),
      preparedBy: firstPresent(
          json, ['PreparedBy', 'preparedBy', 'Preparedby', 'preparedby']),
      itemPreparedAt: firstPresent(json, [
        'ItemPreparedAt',
        'itemPreparedAt',
        'ItemPreparedat',
        'itempreparedat'
      ]),
      itemPreparedEndAt: firstPresent(json, [
        'ItemPreparedEndAt',
        'itemPreparedEndAt',
        'ItemPreparedEndat',
        'itempreparedendat'
      ]),
      datePickUp: firstPresent(
          json, ['DatePickUp', 'datePickUp', 'DatePickup', 'datepickup']),
      remarks: firstPresent(json, ['Remarks', 'remarks']),
      status: firstPresent(json, ['Status', 'status']),
      releasedBy: firstPresent(
          json, ['ReleasedBy', 'releasedBy', 'Releasedby', 'releasedby']),
      receivedBy: firstPresent(
          json, ['ReceivedBy', 'receivedBy', 'Receivedby', 'receivedby']),
      createdAt: firstPresent(
          json, ['CreatedAt', 'createdAt', 'Createdat', 'createdat']),
      updatedAt: firstPresent(
          json, ['UpdatedAt', 'updatedAt', 'Updatedat', 'updatedat']),
      client: json['Client'] != null
          ? ClientModel.fromJson(Map<String, dynamic>.from(json['Client']))
          : ClientModel.empty(),
      itemCategory: json['ItemCategory'] != null
          ? ItemCategoryModel.fromJson(
              Map<String, dynamic>.from(json['ItemCategory']))
          : ItemCategoryModel.empty(),
      documentReference:
          json['DocumentReference'] != null && json['DocumentReference'] is List
              ? List<String>.from((json['DocumentReference'] as List)
                  .map((e) => e?.toString() ?? ''))
              : <String>[],
    );
  }
}

