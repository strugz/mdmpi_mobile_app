/// Data Transfer Object for Collection Items API responses.
/// 
/// Maps between API JSON format and internal domain model.
/// Use this when API field names differ from the domain model.
class CollectionItemDto {
  final String id;
  final Map<String, dynamic> client;
  final List<String> documentReferences;
  final String bankName;
  final double toBeCollected;
  final double totalCollected;
  final String remarks;
  final String documentDate;
  final String bpCode;
  final String postingDate;
  final String dueDate;
  final String status;
  final String? lastOutcome;
  final String assignedAt;
  final String collectorName;
  final List<Map<String, dynamic>> history;

  CollectionItemDto({
    required this.id,
    required this.client,
    required this.documentReferences,
    required this.bankName,
    required this.toBeCollected,
    required this.totalCollected,
    required this.remarks,
    required this.documentDate,
    required this.bpCode,
    required this.postingDate,
    required this.dueDate,
    required this.status,
    this.lastOutcome,
    required this.assignedAt,
    required this.collectorName,
    required this.history,
  });

  /// Convert DTO to JSON for API requests.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Client': client,
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
      'History': history,
    };
  }

  /// Create DTO from API JSON response.
  factory CollectionItemDto.fromJson(Map<String, dynamic> json) {
    return CollectionItemDto(
      id: json['id']?.toString() ?? '',
      client: json['Client'] is Map ? Map<String, dynamic>.from(json['Client']) : {},
      documentReferences: json['DocumentReferences'] is List
          ? List<String>.from(json['DocumentReferences'].map((e) => e.toString()))
          : [],
      bankName: json['BankName']?.toString() ?? 'N/A',
      toBeCollected: (json['ToBeCollected'] is num ? (json['ToBeCollected'] as num).toDouble() : 0.0),
      totalCollected: (json['TotalCollected'] is num ? (json['TotalCollected'] as num).toDouble() : 0.0),
      remarks: json['Remarks']?.toString() ?? 'No remarks',
      documentDate: json['DocumentDate']?.toString() ?? 'N/A',
      bpCode: json['BPCode']?.toString() ?? 'N/A',
      postingDate: json['PostingDate']?.toString() ?? 'N/A',
      dueDate: json['DueDate']?.toString() ?? 'N/A',
      status: json['Status']?.toString() ?? '',
      lastOutcome: json['LastOutcome']?.toString(),
      assignedAt: json['AssignedAt']?.toString() ?? '',
      collectorName: json['CollectorName']?.toString() ?? 'Unassigned',
      history: json['History'] is List ? List<Map<String, dynamic>>.from(json['History']) : [],
    );
  }

  /// Create a DTO for saving activity (POST/PATCH payload).
  factory CollectionItemDto.fromSaveActivityPayload({
    required String id,
    required String status,
    required String remarks,
    double? totalCollected,
    String? bankName,
    String? checkNumber,
    String? checkDate,
    String? purposeOfVisit,
  }) {
    return CollectionItemDto(
      id: id,
      client: {},
      documentReferences: [],
      bankName: bankName ?? '',
      toBeCollected: 0,
      totalCollected: totalCollected ?? 0,
      remarks: remarks,
      documentDate: '',
      bpCode: '',
      postingDate: '',
      dueDate: '',
      status: status,
      lastOutcome: status,
      assignedAt: '',
      collectorName: '',
      history: [
        {
          'status': status,
          'remarks': remarks,
          'totalCollected': totalCollected ?? 0,
          'bankName': bankName,
          'checkNumber': checkNumber,
          'checkDate': checkDate,
          'purposeOfVisit': purposeOfVisit,
        }
      ],
    );
  }
}

