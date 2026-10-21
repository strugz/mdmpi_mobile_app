import 'package:mdmpi_mobile_app/base/utils/b_ocr_orientation.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_extractor.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/ocr_rows.dart';

/// Document references the one-scan reads on top of the shared
/// `DocumentReferenceExtractor` (plan §4.2), which stays untouched so the
/// per-field scanner behaves exactly as before.
///
/// Output uses the form's existing label style (`DRNo.:690014535`).
class OneScanReferencePatterns {
  OneScanReferencePatterns._();

  static final List<_Pattern> _patterns = [
    // Sales Invoice: "Delivery Receipt: DR 690014535" (no "No."); OCR reads
    // i as l at times ("Dellvery Recelpt:").
    _Pattern('DRNo.:',
        RegExp(r'Del[il1]very\s*Rece[il1]pt\s*:?\s*DR\s*#?\s*(\d{5,})',
            caseSensitive: false)),
    // Inventory Transfer Request: "ITR No.:" with the value on a later line.
    _Pattern('ITRNo.:',
        RegExp(r'\bITR\s*N[oO0]\.?\s*:?[^\d]{0,80}?(\d{6,})')),
    // Inventory Transfer that names its request: "Transfer Request No.: ITR 810003436".
    _Pattern('ITRNo.:', RegExp(r'\bITR\s+(\d{6,})')),
    // Stock Issue Slip: the red "No. 00611" under the title, without "SIS".
    _Pattern('SIS#:',
        RegExp(r'STOCK\s+ISSUE\s+SLIP[\s\S]{0,60}?\bN[oO0]\.?\s*:?\s*(\d{5})\b',
            caseSensitive: false)),
    // SI / DR whose number sits a line or two below, after other labels
    // ("DR No.:  Posting Date:  Due Date:  690014676"), which the shared
    // extractor's one-line allowance misses.
    _Pattern('SINo.:',
        RegExp(r'\bS[Il1]\s*N[oO0]\.?\s*:?[^\d]{0,60}?(\d{6,})')),
    _Pattern('DRNo.:',
        RegExp(r'\bDR\s*N[oO0]\.?\s*:?[^\d]{0,60}?(\d{6,})')),
    // "PO No.:" with "PO Date:" printed beside it: the first value that
    // has a digit (40405A), not the word after the label.
    _Pattern('PONo.:',
        RegExp(r'\bP[O0]\s*N[oO0]\.?\s*:?[^\d]{0,40}?\b([A-Z0-9-]*\d[A-Z0-9-]*)\b')),
    // Goods Issue: "Reference No.: IT750005302".
    _Pattern('ITNo.:',
        RegExp(r'Reference\s*N[oO0]\.?\s*:?\s*IT\s*-?\s*(\d{6,})', caseSensitive: false)),
  ];

  /// A bare reference code such as `AR26-240`, as the shared extractor
  /// returns it.
  static final RegExp _bareCode = RegExp(r'^[A-Z]{2}\d{2}-\d{3,}$');

  /// The one-scan references for [text]: [existing] (what the shared
  /// extractor found) cleaned, plus this class's patterns, de-duplicated,
  /// existing order first.
  ///
  /// A bare code is dropped when every place it occurs in [text] is glued to
  /// a letter before it (`CS26-09742` read out of `ACS26-09742`), or when it
  /// appears in one of [excludeTexts] (the item table rows: property tags
  /// such as `FA26-0609` are not document references).
  static List<String> extract(
    String text,
    List<String> existing, {
    Iterable<String> excludeTexts = const [],
  }) {
    final excluded = excludeTexts.join('\n');
    final out = <String>[];

    void add(String value) {
      if (value.isEmpty) return;
      if (out.any((v) => _sameRef(v, value))) return;
      out.add(value);
    }

    for (final ref in existing) {
      if (_bareCode.hasMatch(ref) && _isFalseBareCode(ref, text, excluded)) {
        continue;
      }
      // A value with no digit is a neighbouring label, not a number
      // ("PONo.:PO" read from "PO No.:" over "PO Date:").
      final colon = ref.indexOf(':');
      if (colon > 0 && !RegExp(r'\d').hasMatch(ref.substring(colon + 1))) {
        continue;
      }
      add(ref);
    }
    for (final p in _patterns) {
      final m = p.regExp.firstMatch(text);
      final value = m?.group(1);
      if (value != null) add('${p.label}$value');
    }
    return out;
  }

  static bool _isFalseBareCode(String code, String text, String excluded) {
    if (excluded.contains(code)) return true;
    final occurrences = RegExp(RegExp.escape(code)).allMatches(text).toList();
    if (occurrences.isEmpty) return false;
    return occurrences.every((m) =>
        m.start > 0 && RegExp(r'[A-Za-z]').hasMatch(text[m.start - 1]));
  }

  /// The one-scan references for a page's [lines]: the shared extractor and
  /// this class's patterns, run on ML Kit's block order and on the page's
  /// reading order ([OcrRows.readingText]), merged. Reading order puts
  /// "Delivery Receipt:" beside "DR 690014771"; block order keeps what the
  /// shared extractor has always found.
  static List<String> fromLines(
    List<OcrLine> lines,
    ITextExtractor extractor, {
    Iterable<String> excludeTexts = const [],
  }) {
    final blockText = lines.map((l) => l.text).join('\n');
    final readingText = OcrRows.readingText(lines);
    final out = <String>[];
    for (final text in [blockText, readingText]) {
      for (final ref in extract(text, extractor.extractPatterns(text),
          excludeTexts: excludeTexts)) {
        if (!out.any((v) => _sameRef(v, ref))) out.add(ref);
      }
    }
    final straight = BOcrOrientation.deskew(lines);
    for (final (label, re) in _labelsAbove) {
      if (out.any((v) => v.startsWith(label))) continue;
      final value = _valueBelow(straight, re);
      if (value != null) out.add('$label$value');
    }
    return out;
  }

  /// Labels whose number is printed under them, a few lines down, with
  /// other columns' text in between. On the Inventory Transfer Request the
  /// rows between "ITR No.:" and 810003448 hold the client's TIN and phone,
  /// whose digits stop the text patterns (device run 2026-10-15).
  static final List<(String, RegExp)> _labelsAbove = [
    ('ITRNo.:', RegExp(r'(?<![A-Za-z])[I|l1]TR\s*N[oO0]\b')),
  ];

  /// Six or more digits starting the line; OCR reads a bold 8 as B and 0 as
  /// O at times (`B1OOO3448`).
  static final RegExp _numberFirst = RegExp(r'^\s*([0-9BO][0-9O]{5,})\b');

  static String _digits(String raw) =>
      raw.replaceAll('B', '8').replaceAll('O', '0');

  /// The number under the label matching [label]: the nearest line below
  /// it, within five line heights, roughly in its column, that starts with
  /// six or more digits.
  static String? _valueBelow(List<OcrLine> lines, RegExp label) {
    for (final l in lines.where((l) => label.hasMatch(l.text))) {
      final h = l.box.height;
      final w = l.box.width;
      OcrLine? best;
      for (final m in lines) {
        if (m.box.center.dy <= l.box.bottom) continue;
        if (m.box.top - l.box.bottom > 5 * h) continue;
        final x = m.box.center.dx;
        if (x < l.box.left - 2 * w || x > l.box.right + 2 * w) continue;
        final n = _numberFirst.firstMatch(m.text)?.group(1);
        if (n == null || RegExp(r'\d').allMatches(n).length < 6) continue;
        if (best == null || m.box.top < best.box.top) best = m;
      }
      if (best != null) {
        return _digits(_numberFirst.firstMatch(best.text)!.group(1)!);
      }
    }
    return null;
  }

  /// Same reference regardless of case and spacing.
  static bool _sameRef(String a, String b) =>
      a.replaceAll(' ', '').toUpperCase() == b.replaceAll(' ', '').toUpperCase();
}

class _Pattern {
  const _Pattern(this.label, this.regExp);

  final String label;
  final RegExp regExp;
}
