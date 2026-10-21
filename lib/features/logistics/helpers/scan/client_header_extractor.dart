import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:mdmpi_mobile_app/base/utils/b_ocr_orientation.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/ocr_rows.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/scanned_client_header.dart';

/// Reads the customer name and address off a scanned delivery document,
/// from the phone's own text recognition, line by line with positions
/// (Standard Delivery one-scan, plan §4.3).
///
/// The value of a label is read from the same OCR line (`Customer: X`), from
/// the parts to its right on the same row (`DELIVERED TO:   X`), or from the
/// row below (`Business Partner:` / `DLR-190   X`). Our own header (Marsman
/// Drysdale, the Makati address) is never read as the customer, and
/// nothing is read from Comments or Remarks. Pure, so it is tested with
/// hand-made lines.
class ClientHeaderExtractor {
  ClientHeaderExtractor._();

  /// Customer labels, longest first so `Customer Name` wins over `Customer`.
  /// Seen on the samples (plan §1): `Business Partner` (IT/ITR),
  /// `DELIVERED TO` (SIS), `CUSTOMER NAME` (AR), `Customer` (SI, DR),
  /// `ISSUED TO` (Reagents Issue Slip).
  static final RegExp _nameLabel = RegExp(
    r'^\s*(customer\s*name|customer|business\s*partner|delivered\s*to|'
    r'deliver\s*to|issued\s*to|sold\s*to|ship\s*to|consignee|client\s*name|client)'
    r'(?![A-Za-z])\s*:?\s*(.*)$',
    caseSensitive: false,
  );

  static final RegExp _addressLabel = RegExp(
    // "Addres:" too: OCR drops a letter (in-app capture of 2026-10-15).
    r'^\s*(addr(?:es{1,2})?\.?)(?![A-Za-z])\s*:?\s*(.*)$',
    caseSensitive: false,
  );

  /// Lines that end the customer block. Nothing at or below the first of
  /// these is read: Comments repeat the client with another contact person,
  /// and on a Goods Issue they are the only place the client appears.
  static final RegExp _blockEnd = RegExp(
    r'^\s*(comments?|remarks?)(?![A-Za-z])',
    caseSensitive: false,
  );

  /// Labels that are not a value: reaching one stops a name or an address.
  static final RegExp _otherLabel = RegExp(
    r'^\s*(tin|tel|fax|e-?mail|contact|address|business\s*style|details|'
    r'date|ref|posting|attention|attn|no\.?)(?![A-Za-z])',
    caseSensitive: false,
  );

  /// The issuer: us. Covers the misprint `DRYDALE` (Materials Issuance
  /// Slip), the two Makati address spellings and the warehouse stamp.
  static final RegExp _issuer = RegExp(
    r'MARSMAN|DRYS?DALE|MOLAVE|CHINO\s*ROCES|MDMPI',
    caseSensitive: false,
  );

  /// A code printed before the name (`NCR-414`, `DLR-190`). Not the client
  /// code: kept for logging only.
  /// OCR reads the dash as a dot or a space at times (`NCR.326`).
  static final RegExp _prefix = RegExp(r'^([A-Z]{2,4}[-.]?\s?\d{2,5})\s+(.+)$');

  /// Parts of one row further apart than this many line heights belong to
  /// different columns.
  static const double _maxGapInHeights = 6;

  static ScannedClientHeader extract(List<OcrLine> lines) {
    final sorted = BOcrOrientation.deskew(lines).where((l) => l.text.trim().isNotEmpty).toList()
      ..sort((a, b) {
        final byTop = a.box.top.compareTo(b.box.top);
        return byTop != 0 ? byTop : a.box.left.compareTo(b.box.left);
      });
    if (sorted.isEmpty) return ScannedClientHeader.empty;

    final end = sorted.indexWhere((l) => _blockEnd.hasMatch(l.text));
    final block = (end < 0 ? sorted : sorted.sublist(0, end))
        .where((l) => !_issuer.hasMatch(l.text))
        .toList();
    final page = _pageBounds(sorted);

    final nameLabel = _firstMatch(block, _nameLabel);
    if (nameLabel == null) {
      final candidates = _nameCandidates(block, page);
      return candidates.isEmpty
          ? ScannedClientHeader.empty
          : ScannedClientHeader(nameCandidates: candidates);
    }

    final used = <OcrLine>[nameLabel.line];
    final rawName = _valueOf(nameLabel, block, page, used, maxRows: 1);

    String? prefix;
    String? name = rawName;
    if (rawName != null) {
      final split = _prefix.firstMatch(rawName);
      if (split != null) {
        prefix = split.group(1);
        name = _clean(split.group(2)!);
      }
      if (name == null || _issuer.hasMatch(name)) name = null;
    }

    String? address;
    final below = block
        .where((l) => l.box.top > nameLabel.line.box.top - 1)
        .toList();
    final addressLabel = _firstMatch(below, _addressLabel);
    if (addressLabel != null) {
      used.add(addressLabel.line);
      address = _valueOf(addressLabel, block, page, used, maxRows: 2);
      if (address != null && _issuer.hasMatch(address)) address = null;
    }

    return ScannedClientHeader(
      label: nameLabel.labelText,
      prefix: prefix,
      name: name,
      address: address,
      rawLines: used,
      nameCandidates: name == null ? _nameCandidates(block, page) : const [],
    );
  }

  /// Most rows a fallback offers to the client matcher.
  static const int _maxCandidates = 8;

  /// The item table's column titles: the customer block sits above them.
  static final RegExp _tableTitle = RegExp(
    r'^\s*(item\s*code|description|qty|quantity|part\s*no)',
    caseSensitive: false,
  );

  /// The header rows that could be the customer name, for when no name was
  /// read under a label (a misread label, a curved photo). Taken from the
  /// left part of the page above the item table: rows that start with a
  /// code (`DLR-190  Galinato Clinic and Hospital`) first, then the others
  /// top to bottom. Labelled rows (TIN, Tel, Address, …) and rows with
  /// too few letters are skipped. The client matcher decides which, if any,
  /// is a client; the user still confirms.
  static List<String> _nameCandidates(List<OcrLine> block, Rect page) {
    final tableTop = block
        .where((l) => _tableTitle.hasMatch(l.text))
        .map((l) => l.box.top)
        .fold<double>(double.infinity, math.min);
    final area = block
        .where((l) =>
            l.box.top < tableTop && l.box.left < page.center.dx)
        .toList();
    final coded = <String>[];
    final others = <String>[];
    for (final row in OcrRows.group(area)) {
      final first = row.first.text;
      if (_isLabel(first) || _addressLabel.hasMatch(first)) continue;
      final text = _clean(row.map((l) => l.text).join(' '));
      if (text == null) continue;
      final split = _prefix.firstMatch(text);
      final value = split == null ? text : _clean(split.group(2)!);
      if (value == null) continue;
      if (RegExp(r'[A-Za-z]').allMatches(value).length < 5) continue;
      (split == null ? others : coded).add(value);
    }
    return [...coded, ...others].take(_maxCandidates).toList();
  }

  static _LabelHit? _firstMatch(List<OcrLine> lines, RegExp label) {
    for (final line in lines) {
      final m = label.firstMatch(line.text);
      if (m != null) {
        return _LabelHit(line, m.group(1)!.trim(), m.group(2)!.trim());
      }
    }
    return null;
  }

  /// The text a label names, up to [maxRows] rows, or null.
  static String? _valueOf(
    _LabelHit hit,
    List<OcrLine> block,
    Rect page,
    List<OcrLine> used, {
    required int maxRows,
  }) {
    final label = hit.line.box;
    final h = label.height;

    // "Customer: NCR-414 U.S. Department of Veterans Affairs" on one line.
    if (hit.rest.isNotEmpty) {
      final sameRow = _rowFrom(hit.line, block, h);
      used.addAll(sameRow);
      return _clean([hit.rest, ...sameRow.map((l) => l.text)].join(' '));
    }

    // The parts to the right on the label's row.
    final right = _rowFrom(hit.line, block, h);
    if (right.isNotEmpty) {
      used.addAll(right);
      return _clean(right.map((l) => l.text).join(' '));
    }

    // The row(s) below. The value starts near the label's column, and in
    // the left half of the page when the label is there. A part ending left
    // of where the anchor starts is margin, not value: the "NO" cut off from
    // a sheet underneath, beside "NCR-326", read as the label "No." and
    // stopped the name (gallery photo of SI 700014771, 2026-10-21).
    final labelInLeftHalf = label.center.dx < page.center.dx;
    final rows = <String>[];
    var anchor = hit.line;
    var previousBottom = label.bottom;
    for (var r = 0; r < maxRows; r++) {
      final reach = r == 0 ? 2.5 * h : 1.0 * h;
      bool inColumn(OcrLine l) =>
          !used.contains(l) &&
          l.box.center.dy > previousBottom &&
          l.box.left >= anchor.box.left - 3 * h &&
          l.box.right > anchor.box.left &&
          !(labelInLeftHalf && l.box.left >= page.center.dx);

      OcrLine? first;
      for (final l in block) {
        if (l.box.top > previousBottom + reach) break;
        if (inColumn(l)) {
          first = l;
          break;
        }
      }
      if (first == null) break;
      // The topmost part found may not be the leftmost of its row
      // ("DLR-190" printed a pixel lower than the name beside it).
      final start = first;
      first = block
          .where((l) => inColumn(l) && _sameRow(start.box, l.box))
          .reduce((a, b) => a.box.left <= b.box.left ? a : b);
      if (_isLabel(first.text)) break;
      final row = [first, ..._rowFrom(first, block, h)];
      used.addAll(row);
      rows.add(row.map((l) => l.text).join(' '));
      anchor = first;
      previousBottom = row.map((l) => l.box.bottom).reduce(math.max);
    }
    return rows.isEmpty ? null : _clean(rows.join(' '));
  }

  /// The parts to the right of [start] on its row, nearest first, until a
  /// gap wider than a column break or another label.
  static List<OcrLine> _rowFrom(
    OcrLine start,
    List<OcrLine> block,
    double h,
  ) {
    final candidates = block
        .where((l) => !identical(l, start) && l.box.left >= start.box.right - h)
        .toList()
      ..sort((a, b) => a.box.left.compareTo(b.box.left));

    // Each part is compared with the one before it, so a row that drifts
    // down across a tilted photo is still followed.
    final row = <OcrLine>[];
    var last = start.box;
    for (final l in candidates) {
      if (!_sameRow(last, l.box)) continue;
      if (l.box.left - last.right > _maxGapInHeights * h) break;
      if (_isLabel(l.text)) break;
      row.add(l);
      last = l.box;
    }
    return row;
  }

  /// Same row: middles within 0.6 of the smaller height (see [OcrRows]).
  /// Box overlap let a tall, tilted box bridge two printed rows.
  static bool _sameRow(Rect a, Rect b) => OcrRows.sameRow(a, b);

  static bool _isLabel(String text) =>
      _otherLabel.hasMatch(text) ||
      _nameLabel.hasMatch(text) ||
      text.trim().endsWith(':');

  static Rect _pageBounds(List<OcrLine> lines) => lines
      .map((l) => l.box)
      .reduce((a, b) => a.expandToInclude(b));

  /// Spaces collapsed and stray edge punctuation removed; null when empty.
  static String? _clean(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\s:;,.\-]+|[\s:;,\-]+$'), '');
    return cleaned.isEmpty ? null : cleaned;
  }
}

class _LabelHit {
  const _LabelHit(this.line, this.labelText, this.rest);

  final OcrLine line;

  /// The label as printed, without its colon.
  final String labelText;

  /// Text after the label on the same OCR line.
  final String rest;
}
