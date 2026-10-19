import 'dart:math' as math;

/// String similarity measures for matching OCR text against known names
/// (Standard Delivery one-scan, plan §4.4).
///
/// Pure and case-sensitive: callers normalize first (see `BNameNormalizer`).
/// Every score is in `0.0..1.0`, where `1.0` means identical.
class BStringSimilarity {
  BStringSimilarity._();

  /// Shortest token length at which [tokensMatch] tolerates one edit.
  static const int fuzzyTokenMinLength = 5;

  /// Edit distance (insertions, deletions, substitutions) between [a] and [b].
  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var previous = List<int>.generate(b.length + 1, (j) => j);
    var current = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      current[0] = i;
      final ca = a.codeUnitAt(i - 1);
      for (var j = 1; j <= b.length; j++) {
        final cost = ca == b.codeUnitAt(j - 1) ? 0 : 1;
        current[j] = math.min(
          math.min(current[j - 1] + 1, previous[j] + 1),
          previous[j - 1] + cost,
        );
      }
      final swap = previous;
      previous = current;
      current = swap;
    }
    return previous[b.length];
  }

  /// Jaro similarity: shared characters within a sliding window, less half
  /// the transpositions.
  static double jaro(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final window = math.max(0, math.max(a.length, b.length) ~/ 2 - 1);
    final aMatched = List<bool>.filled(a.length, false);
    final bMatched = List<bool>.filled(b.length, false);

    var matches = 0;
    for (var i = 0; i < a.length; i++) {
      final start = math.max(0, i - window);
      final end = math.min(b.length - 1, i + window);
      for (var j = start; j <= end; j++) {
        if (bMatched[j] || a.codeUnitAt(i) != b.codeUnitAt(j)) continue;
        aMatched[i] = true;
        bMatched[j] = true;
        matches++;
        break;
      }
    }
    if (matches == 0) return 0.0;

    var outOfOrder = 0;
    var k = 0;
    for (var i = 0; i < a.length; i++) {
      if (!aMatched[i]) continue;
      while (!bMatched[k]) {
        k++;
      }
      if (a.codeUnitAt(i) != b.codeUnitAt(k)) outOfOrder++;
      k++;
    }

    final m = matches.toDouble();
    return (m / a.length + m / b.length + (m - outOfOrder / 2) / m) / 3;
  }

  /// Jaro-Winkler similarity: [jaro] boosted by a shared prefix of up to four
  /// characters, so OCR typos late in a name cost less than early ones.
  static double jaroWinkler(String a, String b) {
    final j = jaro(a, b);
    final limit = math.min(4, math.min(a.length, b.length));
    var prefix = 0;
    while (prefix < limit && a.codeUnitAt(prefix) == b.codeUnitAt(prefix)) {
      prefix++;
    }
    return j + prefix * 0.1 * (1 - j);
  }

  /// Whether two tokens count as the same word: equal, or one edit apart
  /// when both have at least [fuzzyTokenMinLength] characters
  /// (`VETERANS` / `VETERAMS`).
  static bool tokensMatch(String a, String b) {
    if (a == b) return true;
    if (a.length < fuzzyTokenMinLength || b.length < fuzzyTokenMinLength) {
      return false;
    }
    if ((a.length - b.length).abs() > 1) return false;
    return levenshtein(a, b) <= 1;
  }

  /// Order-insensitive token overlap that tolerates missing words.
  ///
  /// Tokens are de-duplicated, then paired one-to-one: exact pairs first,
  /// then [tokensMatch] pairs. The score averages how much of the shorter
  /// list is covered (`1.0` when one name is a subset of the other) with the
  /// Dice overlap of both lists (which still marks the missing words).
  static double tokenSetRatio(Iterable<String> a, Iterable<String> b) {
    final left = a.where((t) => t.isNotEmpty).toSet().toList();
    final right = b.where((t) => t.isNotEmpty).toSet().toList();
    if (left.isEmpty && right.isEmpty) return 1.0;
    if (left.isEmpty || right.isEmpty) return 0.0;

    final unpaired = right.toSet();
    final leftover = <String>[];
    for (final token in left) {
      if (!unpaired.remove(token)) leftover.add(token);
    }
    var matched = left.length - leftover.length;
    for (final token in leftover) {
      final partner = unpaired.firstWhere(
        (candidate) => tokensMatch(token, candidate),
        orElse: () => '',
      );
      if (partner.isEmpty) continue;
      unpaired.remove(partner);
      matched++;
    }

    final coverage = matched / math.min(left.length, right.length);
    final dice = 2 * matched / (left.length + right.length);
    return (coverage + dice) / 2;
  }
}
