import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/ocr_read_text.dart';

OcrLine _l(String t, double x, double y, double w) =>
    OcrLine(t, Rect.fromLTWH(x, y, w, 20));

/// Laid out like the Goods Issue capture of 2026-11-26, in ML Kit's order:
/// the number comes long after its label.
final _page = [
  _l('GI No.', 1610, 466, 101),
  _l('Reference No.:', 1611, 610, 245),
  _l('760007227', 1738, 521, 174),
  _l('Posting Date:', 2109, 457, 226),
  _l('11/26/2026', 2138, 514, 191),
];

void main() {
  test('by rows: the label row, then the number row, left to right', () {
    final rows = OcrReadText.rows(_page);
    expect(rows.map((r) => r.text), [
      'GI No. | Posting Date:',
      '760007227 | 11/26/2026',
      'Reference No.:',
    ]);
    expect(rows.first.where, 'row 1');
  });

  test('raw lines keep ML Kit order and show the position', () {
    final lines = OcrReadText.lines(_page);
    expect(lines.map((l) => l.text).take(3),
        ['GI No.', 'Reference No.:', '760007227']);
    expect(lines.first.where, '#1  x 1610  y 466  w 101  h 20');
  });

  test('search ignores case and spaces; empty keeps all', () {
    final rows = OcrReadText.rows(_page);
    expect(OcrReadText.search(rows, 'gino').map((r) => r.where), ['row 1']);
    expect(OcrReadText.search(rows, '7600 07227'), hasLength(1));
    expect(OcrReadText.search(rows, ''), hasLength(3));
    expect(OcrReadText.search(rows, 'nothing here'), isEmpty);
  });

  test('copy text has one entry per line', () {
    expect(OcrReadText.asText(OcrReadText.rows(_page).take(1).toList()),
        'row 1: GI No. | Posting Date:');
  });
}
