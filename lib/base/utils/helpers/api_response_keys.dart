/// Helpers for reading values out of loosely-typed `/api4` JSON responses.
class BApiResponse {
  BApiResponse._();

  /// Request-id keys a create response may use.
  ///
  /// The backend returns the inserted entity serialized with ASP.NET's default
  /// camelCase policy, so `RequestID` arrives as `requestID`. Both spellings
  /// are accepted so a serializer change cannot silently break ID parsing
  /// again.
  static const List<String> requestIdKeys = <String>[
    'requestID',
    'RequestID',
    'requestId',
    'Requestid',
    'id',
  ];

  /// Returns the created request's id from a decoded create response, or null
  /// when the payload carries no recognisable id.
  ///
  /// A null result means the caller cannot attach child records (items,
  /// images) and must rely on a refetch, so callers should log it rather than
  /// continue silently.
  static String? requestId(dynamic decoded) {
    if (decoded is! Map) return null;

    for (final key in requestIdKeys) {
      final value = decoded[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }

    return null;
  }

  /// Commute-id keys a `POST /api4/CommuteId` response may use (the backend
  /// pins `CommuteID`; camelCase is accepted for the same reason as above).
  static const List<String> commuteIdKeys = <String>['CommuteID', 'commuteID', 'commuteId'];

  /// Returns the issued Commute ID from a decoded response, or null.
  static String? commuteId(dynamic decoded) {
    if (decoded is! Map) return null;

    for (final key in commuteIdKeys) {
      final text = decoded[key]?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }

    return null;
  }
}
