import 'dart:ui' show Rect;

import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';

/// A number read off a page without the AI, and what the page says it is.
class OfflineCandidate {
  const OfflineCandidate(this.text, {required this.labelled});

  final String text;

  /// The page labels it an invoice: it follows "SI", "Invoice" or "Sales
  /// Invoice" on its line, or sits in a column under such a header.
  final bool labelled;
}

/// What [VoucherLayoutReader.read] found on a page.
class OfflineReading {
  const OfflineReading({
    this.labelled = const [],
    this.unlabelled = const [],
    this.excluded = const [],
  });

  /// Numbers the page labels as invoices.
  final List<String> labelled;

  /// Numbers with no label either way (a bare list of SIs, or noise).
  final List<String> unlabelled;

  /// Numbers the page labels as something else: P.O., check, CV, OR/AR,
  /// DR, TIN, account. Never invoices.
  final List<String> excluded;
}

/// Reads a voucher's layout from the phone's own text recognition, line by
/// line with positions, applying offline the same rules the AI prompt gives:
/// a number counts as an invoice when it follows an SI / Invoice / Sales
/// Invoice label on its line, or sits in the column under such a header; a
/// number after a P.O., check, CV, OR/AR, DR, TIN or account label never
/// does. Pure, so it is tested with hand-made lines.
class VoucherLayoutReader {
  VoucherLayoutReader._();

  /// "SI", "S.I.", "SI#", "SI No.", "Sales Invoice", "Invoice No.", "Inv #".
  /// A bare "SI" or "Inv" must be followed by a number, a "No." or a "#",
  /// so ordinary words never count.
  static final _invoiceLabel = RegExp(
    r'(?<![A-Za-z])(?:sales\s*inv(?:oice)?\.?|invoice|s\.?\s?i\.?(?=\s*(?:no\b|#|:|-|\d))|inv\.?(?=\s*(?:no\b|#|:|-|\d)))'
    r'(?:\s*(?:no\.?|number|#|:))*',
    caseSensitive: false,
  );

  /// Labels whose number is never an invoice. The two-letter receipt codes
  /// (OR, AR, DR, CV, PO) must be capitals or dotted, so the words "or" and
  /// "dr." in running text do not count.
  static final _otherLabel = RegExp(
    r'(?<![A-Za-z])(?:(?:[Pp]\.\s?[Oo]\.?|PO|purchase\s+order|[Cc]heck|[Cc]heque|[Cc]hk\.?|C\.?V\.?|[Vv]oucher|O\.R\.?|OR|A\.R\.?|AR|D\.R\.?|DR|TIN|[Aa]cct\.?|[Aa]ccount)'
    r'(?=\s*(?:[Nn]o\b|[Nn]umber|#|:|-|\d)))(?:\s*(?:[Nn]o\.?|[Nn]umber|#|:))*',
  );

  /// Words that keep a label's reach going: "SI No. 1 / 2, 3 and 4".
  static final _connector =
      RegExp(r'^(?:/|,|&|-|and|no\.?|nos\.?|#|:)$', caseSensitive: false);

  static final _amount = RegExp(
      r'^[-(]?(?:₱|P|PHP)?\d{1,3}(?:,\d{3})+(?:\.\d+)?\)?$|^[-(]?(?:₱|P|PHP)?\d+\.\d{2}\)?$');
  static final _date = RegExp(r'^\d{1,4}[/.-]\d{1,2}[/.-]\d{1,4}$');

  /// A column header that names something else beside "Invoice" (its date,
  /// amount, terms) is not a column of invoice numbers.
  static final _notAnIdColumn =
      RegExp(r'date|amount|amt|total|balance|terms|due', caseSensitive: false);

  static OfflineReading read(List<OcrLine> lines) {
    final sorted = [...lines]..sort((a, b) {
        final byTop = a.box.top.compareTo(b.box.top);
        return byTop != 0 ? byTop : a.box.left.compareTo(b.box.left);
      });

    final labelled = <String>[];
    final unlabelled = <String>[];
    final excluded = <String>[];
    void add(List<String> to, String t) {
      if (!labelled.contains(t) && !excluded.contains(t) && !to.contains(t)) {
        to.add(t);
      }
    }

    // Headers of invoice-number columns, by where they sit.
    final headers = <Rect>[
      for (final l in sorted)
        if (_isInvoiceHeader(l.text)) l.box,
    ];
    bool underAHeader(Rect box) => headers.any((h) {
          final pad = h.width * 0.25 + 8;
          final centre = box.center.dx;
          return box.top >= h.top + h.height * 0.5 &&
              centre >= h.left - pad &&
              centre <= h.right + pad;
        });

    for (final line in sorted) {
      final text = line.text;
      final labels = [
        for (final m in _invoiceLabel.allMatches(text)) (m: m, invoice: true),
        for (final m in _otherLabel.allMatches(text)) (m: m, invoice: false),
      ]..sort((a, b) => a.m.start.compareTo(b.m.start));
      final inColumn = underAHeader(line.box);

      // What the words since the last label are: an invoice's (true), some
      // other number's (false), or nobody's (null). Any ordinary word ends
      // a label's reach.
      bool? scope;
      void take(String raw) {
        final token =
            raw.replaceAll(RegExp(r'^[^A-Za-z0-9]+|[^A-Za-z0-9]+$'), '');
        if (token.isEmpty) return;
        if (!token.contains(RegExp(r'\d'))) {
          if (!_connector.hasMatch(raw.trim())) scope = null;
          return;
        }
        if (_amount.hasMatch(token) || _date.hasMatch(token)) {
          scope = null; // an amount or a date column: the label is behind
          return;
        }
        // "240009288/240009608" written without spaces.
        final parts = token.contains('/')
            ? token.split('/').where((p) => p.isNotEmpty)
            : [token];
        for (final part in parts) {
          final id = _stripLabelPrefix(part);
          if (!id.contains(RegExp(r'\d'))) continue;
          if (scope == false) {
            add(excluded, id);
          } else if (scope == true || inColumn) {
            add(labelled, id);
          } else {
            add(unlabelled, id);
          }
        }
      }

      for (final w in RegExp(r'\S+').allMatches(text)) {
        final label =
            labels.where((l) => l.m.start < w.end && l.m.end > w.start);
        if (label.isEmpty) {
          if (_connector.hasMatch(w.group(0)!)) continue;
          take(w.group(0)!);
          continue;
        }
        // The word holds a label ("SI#240004614", "No.", "P.O."): its kind
        // opens a reach; whatever follows the label in the word is read.
        final l = label.last;
        scope = l.invoice;
        if (l.m.end < w.end) take(text.substring(l.m.end, w.end));
      }
    }
    return OfflineReading(
        labelled: labelled, unlabelled: unlabelled, excluded: excluded);
  }

  static bool _isInvoiceHeader(String text) =>
      _invoiceLabel.hasMatch(text) &&
      !RegExp(r'\d').hasMatch(text) &&
      !_notAnIdColumn.hasMatch(text) &&
      text.trim().split(RegExp(r'\s+')).length <= 4;

  /// "SI#700013390" → "700013390", "INV-97339" → "97339"; an id that is
  /// letters by nature ("AP-1790…") keeps them, matched later as a whole.
  static String _stripLabelPrefix(String token) {
    final m =
        RegExp(r'^(?:SI|S\.I\.|INV|INVOICE)[#\-:.]?', caseSensitive: false)
            .firstMatch(token);
    return m == null ? token : token.substring(m.end);
  }
}
