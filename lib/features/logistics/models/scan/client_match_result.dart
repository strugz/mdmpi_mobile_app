import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// How a scanned customer name was tied to a client (plan §4.4).
enum ClientMatchKind { alias, exact, fuzzy, none }

/// One client offered on the review sheet.
class ClientCandidate {
  const ClientCandidate({
    required this.client,
    required this.score,
    required this.kind,
    this.clearLead = false,
  });

  /// Looked up fresh from the client list at scan time.
  final ClientModel client;

  /// 0..1; alias and exact hits are 1.
  final double score;

  final ClientMatchKind kind;

  /// The best fuzzy candidate, at least [ClientMatchResult.strongLead]
  /// ahead of the next one. A close race is never Strong, whatever the score.
  final bool clearLead;

  /// Alias, exact name, or a high fuzzy score with a clear lead.
  bool get isStrong =>
      kind == ClientMatchKind.alias ||
      kind == ClientMatchKind.exact ||
      (clearLead && score >= ClientMatchResult.strongScore);

  /// The tag shown next to the name.
  String get label => switch (kind) {
        ClientMatchKind.alias => 'Used before',
        ClientMatchKind.exact => 'Exact name',
        _ => isStrong ? 'Strong' : 'Possible',
      };
}

/// The clients a scan suggests, best first. **Never a selection:** the user
/// always taps one to confirm it (decision 2026-10-09).
class ClientMatchResult {
  const ClientMatchResult({
    required this.kind,
    this.ocrName,
    this.candidates = const [],
  });

  static const none = ClientMatchResult(kind: ClientMatchKind.none);

  /// At or above this, the top candidates are listed; below it the normal
  /// search opens pre-filled with [ocrName]. Start value, tuned on device.
  static const double listScore = 0.60;
  static const double strongScore = 0.80;

  /// How far the best fuzzy candidate must lead the next to be Strong.
  static const double strongLead = 0.10;
  static const int maxCandidates = 5;

  final ClientMatchKind kind;

  /// The name as read off the document (prefix removed).
  final String? ocrName;

  /// Up to [maxCandidates], best first.
  final List<ClientCandidate> candidates;

  /// Whether the review sheet lists [candidates] rather than opening the
  /// search pre-filled.
  bool get showList =>
      candidates.isNotEmpty &&
      (kind == ClientMatchKind.alias ||
          kind == ClientMatchKind.exact ||
          candidates.first.score >= listScore);
}
