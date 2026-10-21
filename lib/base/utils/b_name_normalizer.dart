/// Puts client names (and addresses) read by OCR and stored in `ACCMST_` into
/// one comparable form (Standard Delivery one-scan, plan §4.4).
///
/// Apply it to **both** sides of a comparison: the rules are only meant to be
/// consistent, not to restore the exact spelling. The display name is never
/// replaced by the normalized one.
class BNameNormalizer {
  BNameNormalizer._();

  /// OCR digit-for-letter slips, undone inside tokens that contain a letter
  /// (`H0SPITAL`, `C1TY`, `LUKE5`). All-digit tokens such as `8` in
  /// `Project 8` are left alone. Same idea as `VoucherSiMatcher`, reversed:
  /// there the value is a number, here it is mostly letters.
  static const Map<String, String> ocrDigitToLetter = {
    '0': 'O',
    '1': 'I',
    '5': 'S',
    '8': 'B',
  };

  /// Abbreviations expanded to the word stored most often in `ACCMNM`.
  /// `ST` is not expanded: it is Saint in names and Street in addresses.
  static const Map<String, String> abbreviations = {
    'DEPT': 'DEPARTMENT',
    'MED': 'MEDICAL',
    'CTR': 'CENTER',
    'CNTR': 'CENTER',
    'CENTRE': 'CENTER',
    'HOSP': 'HOSPITAL',
    'UNIV': 'UNIVERSITY',
    'GEN': 'GENERAL',
    'PHIL': 'PHILIPPINES',
    'PHILS': 'PHILIPPINES',
    'STO': 'SANTO',
    'STA': 'SANTA',
    'CORP': 'CORPORATION',
    'CO': 'COMPANY',
    'INCORPORATED': 'INC',
    'ASSN': 'ASSOCIATION',
    'ASSOC': 'ASSOCIATION',
  };

  /// Words that carry no identity, dropped by [scoringTokens] only.
  static const Set<String> stopWords = {
    'INC',
    'CORPORATION',
    'COMPANY',
    'LTD',
    'THE',
    'OF',
    'AND',
    'PHILIPPINES',
  };

  // Dotted acronyms (`U.S.`, `U.S.A`) lose their dots and stay one word.
  static final RegExp _dottedAcronym = RegExp(r'\b(?:[A-Z]\.){1,}[A-Z]\b\.?');
  static final RegExp _apostrophe = RegExp(r"['‘’`]");
  static final RegExp _nonWord = RegExp(r'[^A-Z0-9]+');
  static final RegExp _hasLetter = RegExp(r'[A-Z]');

  /// Upper case, `&` → `AND`, punctuation removed, OCR digit slips fixed in
  /// word tokens, abbreviations expanded, spaces collapsed.
  ///
  /// `U.S. Dept. of Veterans Affairs` → `US DEPARTMENT OF VETERANS AFFAIRS`.
  /// Stop words are kept, so the result can serve as an alias key.
  static String normalize(String raw) => _tokens(raw).join(' ');

  /// The [normalize]d tokens without [stopWords], for scoring. When a name
  /// is nothing but stop words, they are kept rather than returning nothing.
  static List<String> scoringTokens(String raw) {
    final tokens = _tokens(raw);
    final significant = tokens.where((t) => !stopWords.contains(t)).toList();
    return significant.isEmpty ? tokens : significant;
  }

  /// [scoringTokens] joined by single spaces, for whole-string measures such
  /// as Jaro-Winkler.
  static String scoringKey(String raw) => scoringTokens(raw).join(' ');

  static List<String> _tokens(String raw) {
    var text = raw.toUpperCase();
    text = text.replaceAllMapped(
      _dottedAcronym,
      (m) => m.group(0)!.replaceAll('.', ''),
    );
    text = text.replaceAll('&', ' AND ').replaceAll(_apostrophe, '');
    return text
        .split(_nonWord)
        .where((t) => t.isNotEmpty)
        .map(_fixOcrDigits)
        .map((t) => abbreviations[t] ?? t)
        .toList();
  }

  static String _fixOcrDigits(String token) {
    if (!_hasLetter.hasMatch(token)) return token;
    return token
        .split('')
        .map((c) => ocrDigitToLetter[c] ?? c)
        .join();
  }
}
