import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// A single collection item representing a client document for collection.
///
/// Items start in the **bucket** (unassigned). When the user selects items
/// from the bucket they are moved into the **activity** list and assigned
/// to the current user.
class CollectionItemModel {
  /// Unique identifier (from API or local sequence).
  final String id;

  /// Client details — reuses the existing [ClientModel].
  final ClientModel client;

  /// Document references attached to this collection (e.g. cheque numbers).
  final List<String> documentReferences;

  /// Bank name associated with the collection.
  final String bankName;

  /// Amount to collect.
  final double amount;

  /// Optional remarks / notes.
  final String remarks;

  /// Date the document was created / issued.
  final String documentDate;

  /// Current status of the item.
  /// Bucket items default to `'Unassigned'`.
  /// After selection they become `'Pending'`, then `'Completed'` / `'Overdue'`.
  final String status;

  /// Timestamp when the item was picked from the bucket (empty while in bucket).
  final String assignedAt;

  const CollectionItemModel({
    required this.id,
    required this.client,
    this.documentReferences = const [],
    this.bankName = '',
    this.amount = 0,
    this.remarks = '',
    this.documentDate = '',
    this.status = 'Unassigned',
    this.assignedAt = '',
  });

  /// Empty / placeholder model.
  static CollectionItemModel empty() => CollectionItemModel(
        id: '',
        client: ClientModel.empty(),
      );

  /// Create a copy with updated fields.
  CollectionItemModel copyWith({
    String? id,
    ClientModel? client,
    List<String>? documentReferences,
    String? bankName,
    double? amount,
    String? remarks,
    String? documentDate,
    String? status,
    String? assignedAt,
  }) {
    return CollectionItemModel(
      id: id ?? this.id,
      client: client ?? this.client,
      documentReferences: documentReferences ?? this.documentReferences,
      bankName: bankName ?? this.bankName,
      amount: amount ?? this.amount,
      remarks: remarks ?? this.remarks,
      documentDate: documentDate ?? this.documentDate,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
    );
  }

  /// Parse from API JSON.
  factory CollectionItemModel.fromJson(Map<String, dynamic> json) {
    return CollectionItemModel(
      id: (json['id'] ?? json['ID'] ?? '').toString(),
      client: json['Client'] != null
          ? ClientModel.fromJson(Map<String, dynamic>.from(json['Client']))
          : ClientModel.empty(),
      documentReferences: json['DocumentReferences'] != null &&
              json['DocumentReferences'] is List
          ? List<String>.from(
              (json['DocumentReferences'] as List).map((e) => e.toString()))
          : <String>[],
      bankName: (json['BankName'] ?? '').toString(),
      amount: (json['Amount'] is num)
          ? (json['Amount'] as num).toDouble()
          : double.tryParse(json['Amount']?.toString() ?? '') ?? 0,
      remarks: (json['Remarks'] ?? '').toString(),
      documentDate: (json['DocumentDate'] ?? '').toString(),
      status: (json['Status'] ?? 'Unassigned').toString(),
      assignedAt: (json['AssignedAt'] ?? '').toString(),
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Client': client.toJson(),
      'DocumentReferences': documentReferences,
      'BankName': bankName,
      'Amount': amount,
      'Remarks': remarks,
      'DocumentDate': documentDate,
      'Status': status,
      'AssignedAt': assignedAt,
    };
  }
}

