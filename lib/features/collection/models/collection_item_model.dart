import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// A single collection item representing a client document for collection.
class CollectionItemModel {
  final String id;
  final ClientModel client;
  final List<String> documentReferences;
  final String bankName;
  final double toBeCollected;
  final double totalCollected;
  final String remarks;
  final String documentDate;
  final String bpCode;
  final String postingDate;
  final String dueDate;
  
  /// Consolidated status field (Pending, On-going, Collected).
  final String status;

  /// The outcome of the last activity (Failed, Partially Collected, etc.).
  final String? lastOutcome;

  final String assignedAt;
  final String collectorName;
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
    this.status = CollectionStatusColors.statusPending,
    this.lastOutcome,
    this.assignedAt = '',
    this.collectorName = 'Unassigned',
    this.history = const [],
  });

  static CollectionItemModel empty() => CollectionItemModel(
        id: '',
        client: ClientModel.empty(),
      );

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
    String? status,
    String? lastOutcome,
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
      status: status ?? this.status,
      lastOutcome: lastOutcome ?? this.lastOutcome,
      assignedAt: assignedAt ?? this.assignedAt,
      collectorName: collectorName ?? this.collectorName,
      history: history ?? this.history,
    );
  }

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
      status: (json['Status'] ?? json['CoreStatus'] ?? CollectionStatusColors.statusPending).toString(),
      lastOutcome: json['LastOutcome']?.toString(),
      assignedAt: (json['AssignedAt'] ?? 'N/A').toString(),
      collectorName: (json['CollectorName'] ?? 'Unassigned').toString(),
      history: json['History'] != null && json['History'] is List
          ? List<CollectionHistoryModel>.from(
              (json['History'] as List).map((e) => CollectionHistoryModel.fromJson(e)))
          : [],
    );
  }

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
      'Status': status,
      'LastOutcome': lastOutcome,
      'AssignedAt': assignedAt,
      'CollectorName': collectorName,
      'History': history.map((e) => e.toJson()).toList(),
    };
  }
}
