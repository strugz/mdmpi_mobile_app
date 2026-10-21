import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:mdmpi_mobile_app/base/utils/b_ocr_orientation.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';

/// Rows of a scanned page, shared by the one-scan readers (plan §4.3–§4.5).
///
/// Lines are compared by their middles, not by how their boxes overlap. A
/// line OCR read at its own small tilt gets a box up to twice its text
/// height (`96,624.00` and the customer name in the in-app capture of
/// 2026-10-15); with overlap such a box bridged two printed rows, which
/// swallowed the first item into the table header and the client name into
/// the TIN line.
class OcrRows {
  OcrRows._();

  /// Two lines share a row when their middles are within 0.6 of the
  /// smaller one's height.
  static bool sameRow(Rect a, Rect b) =>
      (a.center.dy - b.center.dy).abs() <=
      0.6 * math.min(a.height, b.height);

  /// [lines] (already straightened) grouped into rows, top to bottom, each
  /// row left to right. A line joins the current row when its middle is
  /// within 0.6 of a typical text height of the row's middle.
  static List<List<OcrLine>> group(List<OcrLine> lines) {
    final visible = lines.where((l) => l.text.trim().isNotEmpty).toList();
    if (visible.isEmpty) return [];
    final heights = visible.map((l) => l.box.height).toList()..sort();
    final reach = 0.6 * heights[heights.length ~/ 2];
    visible.sort((a, b) => a.box.center.dy.compareTo(b.box.center.dy));

    final rows = <List<OcrLine>>[];
    var rowMiddle = 0.0;
    for (final line in visible) {
      final middle = line.box.center.dy;
      if (rows.isNotEmpty && (middle - rowMiddle).abs() <= reach) {
        rows.last.add(line);
        rowMiddle += (middle - rowMiddle) / rows.last.length;
      } else {
        rows.add([line]);
        rowMiddle = middle;
      }
    }
    for (final row in rows) {
      row.sort((a, b) => a.box.left.compareTo(b.box.left));
    }
    return rows;
  }

  /// The page's text in reading order: straightened, one row per line, left
  /// to right. ML Kit returns text block by block, which can put a label
  /// ("Delivery Receipt:") far from its value ("DR 690014771").
  static String readingText(List<OcrLine> lines) => group(
          BOcrOrientation.deskew(lines))
      .map((row) => row.map((l) => l.text.trim()).join(' '))
      .join('\n');
}
