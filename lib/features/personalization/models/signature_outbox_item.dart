/// Typed view model for a locally persisted receiver signature awaiting upload.
class SignatureOutboxItem {
  const SignatureOutboxItem({
    required this.requestId,
    required this.signatureBase64,
    required this.apiStatus,
    this.capturedAt,
  });

  final String requestId;
  final String signatureBase64;
  final String apiStatus;
  final DateTime? capturedAt;

  bool get isSynced => apiStatus.toLowerCase() == 'synced';
  bool get canRetry => requestId.isNotEmpty && signatureBase64.isNotEmpty;

  factory SignatureOutboxItem.fromMap(Map<String, dynamic> map) {
    return SignatureOutboxItem(
      requestId: map['RequestID']?.toString() ?? '',
      signatureBase64: map['RequestReceiverSignature']?.toString() ?? '',
      apiStatus: _normalizeStatus(map['ApiStatus']?.toString()),
      capturedAt: _parseCapturedAt(map),
    );
  }

  static String _normalizeStatus(String? rawStatus) {
    final normalized = rawStatus?.trim().toLowerCase();
    switch (normalized) {
      case 'synced':
        return 'Synced';
      case 'failed':
        return 'Failed';
      case 'uploaded':
        return 'Failed';
      case 'pending':
      case '':
      case null:
        return 'Pending';
      default:
        return rawStatus!.trim();
    }
  }

  static DateTime? _parseCapturedAt(Map<String, dynamic> map) {
    const candidateKeys = [
      'CapturedAt',
      'CreatedAt',
      'RequestCreatedAt',
      'UpdatedAt',
    ];

    for (final key in candidateKeys) {
      final rawValue = map[key]?.toString().trim();
      if (rawValue == null || rawValue.isEmpty) {
        continue;
      }

      final parsed = DateTime.tryParse(rawValue);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }
}

