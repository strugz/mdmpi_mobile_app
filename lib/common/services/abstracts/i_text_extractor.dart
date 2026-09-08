abstract class ITextExtractor {
  List<String> extractPatterns(String inputText);
}

/// Extracts document reference numbers (SI / DR / IT / GI / PO / SIS) from
/// OCR text.
///
/// OCR output is noisy: the value is often on the next line and indented,
/// `I` is read as `l` or `1`, `O` as `0`, and "No." as "Na.". The label
/// patterns tolerate all of that; the result is always normalized to the
/// canonical form the app has stored historically, e.g. `GINo.:760006528`.
class DocumentReferenceExtractor implements ITextExtractor {
  // "No." / "Na." / "N0." followed by an optional colon and any whitespace
  // (including a line break plus indentation) before the value.
  static const String _noSep = r'\s*N[oaO0]\.?\s*:?\s*';

  // Numeric value, optionally preceded by one letters-only garbage line
  // (e.g. "GO" from a form border, or "GOODS ISS" / "INVENTORY TRANSFER" from
  // the header that OCR interleaves between the label and its value).
  // The value must start with a real digit but may contain digit look-alikes
  // ("76000G528"), which [_normalizeDigits] maps back to digits.
  static const String _digits =
      r'(?:[A-Za-z][A-Za-z ]{0,40}\s*\n\s*)?(\d[0-9OoIlGSB]*)';

  static const Map<String, String> _digitLookAlikes = {
    'O': '0',
    'o': '0',
    'I': '1',
    'l': '1',
    'G': '6',
    'S': '5',
    'B': '8',
  };

  static String _normalizeDigits(String value) =>
      value.split('').map((c) => _digitLookAlikes[c] ?? c).join();

  // A getter (not a static final) so pattern edits take effect on hot reload;
  // static values survive reload and silently keep the old regexes.
  static List<_LabelPattern> get _labelPatterns => [
    _LabelPattern('SINo.:', RegExp(r'\bS[Il1]' + _noSep + _digits),
        numeric: true),
    _LabelPattern('DRNo.:', RegExp(r'\bDR' + _noSep + _digits),
        numeric: true),
    // The "I" is thin and often dropped by OCR entirely ("T No.:", "G No.:").
    _LabelPattern('ITNo.:', RegExp(r'\b[Il1]?T' + _noSep + _digits),
        numeric: true),
    _LabelPattern('GINo.:', RegExp(r'\bG[Il1]?' + _noSep + _digits),
        numeric: true),
    _LabelPattern('PONo.:', RegExp(r'\bP[O0]' + _noSep + r'([A-Za-z0-9-]+)')),
    _LabelPattern('SIS#:', RegExp(r'\bS[Il1]S\s*#\s*:?\s*(\d{5})')),
  ];

  // Bare reference codes such as "AB12-34567".
  static final RegExp _bareCode = RegExp(r'[A-Z]{2}\d{2}-\d{3,}');

  @override
  List<String> extractPatterns(String inputText) {
    final List<String> matchList = [];

    for (final pattern in _labelPatterns) {
      final Match? match = pattern.regExp.firstMatch(inputText);
      final String? raw = match?.group(1);
      if (raw != null && raw.isNotEmpty) {
        final value = pattern.numeric ? _normalizeDigits(raw) : raw;
        matchList.add('${pattern.label}$value');
      }
    }

    final Match? bare = _bareCode.firstMatch(inputText);
    if (bare != null) {
      matchList.add(bare.group(0)!);
    }

    return matchList;
  }
}

class _LabelPattern {
  const _LabelPattern(this.label, this.regExp, {this.numeric = false});

  final String label;
  final RegExp regExp;

  /// Whether the captured value is a number whose OCR look-alike letters
  /// should be normalized back to digits.
  final bool numeric;
}
