import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
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

  /// Amount to be collected.
  final double toBeCollected;

  /// Total amount already collected.
  final double totalCollected;

  /// Optional remarks / notes.
  final String remarks;

  /// Date the document was created / issued.
  final String documentDate;

  /// Business Partner Code (Customer Code).
  final String bpCode;

  /// Date the invoice was filed.
  final String postingDate;

  /// Due date of the invoice.
  final String dueDate;

  /// Current statuses of the item across 4 categories.
  final String coreStatus;
  final String delayStatus;
  final String outcomeStatus;
  final String administrativeStatus;

  /// Timestamp when the item was picked from the bucket (empty while in bucket).
  final String assignedAt;

  /// Collector name (Assigned to).
  final String collectorName;

  /// History of actions on this account.
  final List<CollectionHistoryModel> history;

  const CollectionItemModel({
    required this.id,
    required this.client,
    this.documentReferences = const [],
    this.bankName = 'N/A',
    this.toBeCollected = 0,
    this.totalCollected = 0,
    this.remarks = 'No remarks',
    this.documentDate = 'N/A',
    this.bpCode = 'N/A',
    this.postingDate = 'N/A',
    this.dueDate = 'N/A',
    this.coreStatus = CollectionStatusColors.statusUnassigned,
    this.delayStatus = CollectionStatusColors.statusOnSchedule,
    this.outcomeStatus = CollectionStatusColors.statusNone,
    this.administrativeStatus = CollectionStatusColors.statusForVerification,
    this.assignedAt = '',
    this.collectorName = 'Unassigned',
    this.history = const [],
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
    double? toBeCollected,
    double? totalCollected,
    String? remarks,
    String? documentDate,
    String? bpCode,
    String? postingDate,
    String? dueDate,
    String? coreStatus,
    String? delayStatus,
    String? outcomeStatus,
    String? administrativeStatus,
    String? assignedAt,
    String? collectorName,
    List<CollectionHistoryModel>? history,
  }) {
    return CollectionItemModel(
      id: id ?? this.id,
      client: client ?? this.client,
      documentReferences: documentReferences ?? this.documentReferences,
      bankName: bankName ?? this.bankName,
      toBeCollected: toBeCollected ?? this.toBeCollected,
      totalCollected: totalCollected ?? this.totalCollected,
      remarks: remarks ?? this.remarks,
      documentDate: documentDate ?? this.documentDate,
      bpCode: bpCode ?? this.bpCode,
      postingDate: postingDate ?? this.postingDate,
      dueDate: dueDate ?? this.dueDate,
      coreStatus: coreStatus ?? this.coreStatus,
      delayStatus: delayStatus ?? this.delayStatus,
      outcomeStatus: outcomeStatus ?? this.outcomeStatus,
      administrativeStatus: administrativeStatus ?? this.administrativeStatus,
      assignedAt: assignedAt ?? this.assignedAt,
      collectorName: collectorName ?? this.collectorName,
      history: history ?? this.history,
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
      bankName: (json['BankName'] ?? 'N/A').toString(),
      toBeCollected: (json['ToBeCollected'] is num)
          ? (json['ToBeCollected'] as num).toDouble()
          : (json['Amount'] is num)
              ? (json['Amount'] as num).toDouble()
              : double.tryParse((json['ToBeCollected'] ?? json['Amount'])?.toString() ?? '') ?? 0,
      totalCollected: (json['TotalCollected'] is num)
          ? (json['TotalCollected'] as num).toDouble()
          : double.tryParse(json['TotalCollected']?.toString() ?? '') ?? 0,
      remarks: (json['Remarks'] ?? 'No remarks').toString(),
      documentDate: (json['DocumentDate'] ?? 'N/A').toString(),
      bpCode: (json['BPCode'] ?? json['CustomerCode'] ?? 'N/A').toString(),
      postingDate: (json['PostingDate'] ?? 'N/A').toString(),
      dueDate: (json['DueDate'] ?? 'N/A').toString(),
      coreStatus: (json['CoreStatus'] ?? json['Status'] ?? CollectionStatusColors.statusUnassigned).toString(),
      delayStatus: (json['DelayStatus'] ?? CollectionStatusColors.statusOnSchedule).toString(),
      outcomeStatus: (json['OutcomeStatus'] ?? CollectionStatusColors.statusNone).toString(),
      administrativeStatus: (json['AdministrativeStatus'] ?? CollectionStatusColors.statusForVerification).toString(),
      assignedAt: (json['AssignedAt'] ?? 'N/A').toString(),
      collectorName: (json['CollectorName'] ?? 'Unassigned').toString(),
      history: json['History'] != null && json['History'] is List
          ? List<CollectionHistoryModel>.from(
              (json['History'] as List).map((e) => CollectionHistoryModel.fromJson(e)))
          : [],
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Client': client.toJson(),
      'DocumentReferences': documentReferences,
      'BankName': bankName,
      'ToBeCollected': toBeCollected,
      'TotalCollected': totalCollected,
      'Remarks': remarks,
      'DocumentDate': documentDate,
      'BPCode': bpCode,
      'PostingDate': postingDate,
      'DueDate': dueDate,
      'CoreStatus': coreStatus,
      'DelayStatus': delayStatus,
      'OutcomeStatus': outcomeStatus,
      'AdministrativeStatus': administrativeStatus,
      'AssignedAt': assignedAt,
      'CollectorName': collectorName,
      'History': history.map((e) => e.toJson()).toList(),
    };
  }
}

