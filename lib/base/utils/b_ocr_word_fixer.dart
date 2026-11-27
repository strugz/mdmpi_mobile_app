/// Undoes OCR letter/digit slips in free text such as an item description
/// (`8ottle` → `Bottle`, `C0NTROL` → `CONTROL`, `1O0mL` → `100mL`).
///
/// Each token (a run of letters and digits) is first judged a number or a
/// word, and only the look-alikes that do not fit are swapped:
///
/// * **Number**: starts with a digit and, apart from a known unit at the end
///   (`mL`, `mg`, `pcs`), holds only digits and `O`/`o`/`I`/`l`. Those
///   letters become `0`/`1`: `1O0mL` → `100mL`, `5OO` → `500`.
/// * **Word**: at least three letters for every digit, every digit a
///   look-alike (`0 1 5 8`), and one letter case (`BOTTLE`, `bottle`,
///   `Bottle`); all capitals need five letters. Digits inside it, or at its
///   start, become letters. A digit at the end is kept (`TUBE1`, `COVID19`).
///
/// Anything else is a code or a chemistry name (`HbA1c`, `H2O`, `5DIFF`,
/// `MP1K`, `AU480`, `4x15mL`) and is left as read.
class BOcrWordFixer {
  BOcrWordFixer._();

  /// Units printed right after a quantity on the documents.
  static const Set<String> units = {
    'ml', 'l', 'ul', 'µl', 'dl', 'g', 'mg', 'ug', 'µg', 'kg', 'iu', 'u',
    'mm', 'cm', 'm', 'pcs', 'pc', 's', 'x', 't', 'mmol', 'umol', 'mol',
    'st', 'nd', 'rd', 'th', // ordinals: 1st, 2nd
  };

  static final RegExp _token = RegExp(r'[A-Za-z0-9µ]+');
  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _letter = RegExp(r'[A-Za-z]');
  static final RegExp _numberPart = RegExp(r'^(\d[0-9OoIl]*)([A-Za-zµ]*)$');
  static final RegExp _nonLookAlikeDigit = RegExp(r'[234679]');

  /// [text] with each token's look-alikes fixed; spacing and punctuation
  /// are kept.
  static String fix(String text) =>
      text.replaceAllMapped(_token, (m) => fixToken(m.group(0)!));

  /// One token, fixed as a number or a word, or unchanged.
  static String fixToken(String token) =>
      _asNumber(token) ?? _asWord(token) ?? token;

  /// A unit (`8OTTLE`, `PC5`, `B0X`): no digits belong in a unit word, so
  /// each look-alike in a token of two or more letters becomes a letter. A
  /// quantity read into the column with its unit (`1PC`) is kept.
  static String fixUnit(String unit) =>
      unit.replaceAllMapped(_token, (m) {
        final token = m.group(0)!;
        if (_letter.allMatches(token).length < 2) return token;
        // A real quantity is all digits: `8OX` is `8O` + `X` only on paper.
        final number = _numberPart.firstMatch(token);
        if (number != null &&
            RegExp(r'^\d+$').hasMatch(number.group(1)!) &&
            units.contains(number.group(2)!.toLowerCase())) {
          return token;
        }
        if (_nonLookAlikeDigit.hasMatch(token)) return token;
        final upper = !token.contains(RegExp('[a-z]'));
        return token.replaceAllMapped(RegExp('[0158]'),
            (d) => _letterFor(d.group(0)!, upper: upper, first: d.start == 0));
      });

  static String? _asNumber(String token) {
    final m = _numberPart.firstMatch(token);
    if (m == null) return null;
    var numeric = m.group(1)!;
    var unit = m.group(2)!;
    // "5OO" ends in look-alikes, not a unit; "1Ol" keeps "l" as litres.
    final tail = RegExp(r'[OoIl]+$').firstMatch(numeric);
    if (unit.isEmpty && tail != null && !RegExp(r'[OoIl]').hasMatch(numeric.substring(0, tail.start))) {
      // Only letters after the digits: "1l" is 1 litre, "1O" is 10.
      if (RegExp(r'^[Il]+$').hasMatch(tail.group(0)!)) {
        unit = tail.group(0)!;
        numeric = numeric.substring(0, tail.start);
      }
    }
    if (unit.isNotEmpty && !units.contains(unit.toLowerCase())) return null;
    if (!RegExp('[OoIl]').hasMatch(numeric)) return null;
    final fixed = numeric
        .replaceAll(RegExp('[Oo]'), '0')
        .replaceAll(RegExp('[Il]'), '1');
    return '$fixed$unit';
  }

  static String? _asWord(String token) {
    final digits = _digit.allMatches(token).length;
    if (digits == 0) return null;
    if (_nonLookAlikeDigit.hasMatch(token)) return null;
    final letters = _letter.allMatches(token).length;
    if (letters < 3 * digits || letters < 3) return null;

    final rest = token.substring(1).replaceAll(_digit, '');
    final upper = !RegExp('[a-z]').hasMatch(token);
    final lower = !RegExp('[A-Z]').hasMatch(rest);
    if (!upper && !lower) return null; // mixed case: HbA1c, MgSO

    // A digit at the end may be real (TUBE1); only interior or leading ones
    // are swapped. All capitals need five letters: shorter ones are model
    // codes (MP1K, 5DIFF, 3PART).
    final lastLetter = token.lastIndexOf(_letter);
    if (upper && letters < 5) return null;
    final out = StringBuffer();
    for (var i = 0; i < token.length; i++) {
      final c = token[i];
      if (_digit.hasMatch(c) && i < lastLetter) {
        out.write(_letterFor(c, upper: upper, first: i == 0));
      } else {
        out.write(c);
      }
    }
    final result = out.toString();
    return result == token ? null : result;
  }

  static String _letterFor(String digit, {required bool upper, required bool first}) {
    final capital = upper || first;
    return switch (digit) {
      '0' => capital ? 'O' : 'o',
      '1' => capital ? 'I' : 'l',
      '5' => capital ? 'S' : 's',
      '8' => 'B',
      _ => digit,
    };
  }
}
