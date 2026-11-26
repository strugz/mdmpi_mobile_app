import 'package:mdmpi_mobile_app/base/utils/b_ocr_orientation.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/ocr_rows.dart';

/// One entry of the OCR viewer (Developer Tools): its text and where it is.
typedef OcrReadEntry = ({String text, String where});

/// What a scan read, for the developer OCR viewer: the page by rows (the
/// order the one-scan readers see) or the raw lines in ML Kit's order, and
/// a search over them.
class OcrReadText {
  OcrReadText._();

  /// The page straightened and grouped into rows, top to bottom, each row
  /// left to right; parts of a row joined with " | ".
  static List<OcrReadEntry> rows(List<OcrLine> lines) {
    final grouped = OcrRows.group(BOcrOrientation.deskew(lines));
    return [
      for (var i = 0; i < grouped.length; i++)
        (
          text: grouped[i].map((l) => l.text.trim()).join(' | '),
          where: 'row ${i + 1}',
        ),
    ];
  }

  /// The lines as ML Kit returned them, with their position and size.
  static List<OcrReadEntry> lines(List<OcrLine> lines) => [
        for (var i = 0; i < lines.length; i++)
          (
            text: lines[i].text,
            where: '#${i + 1}  x ${lines[i].box.left.round()}  '
                'y ${lines[i].box.top.round()}  '
                'w ${lines[i].box.width.round()}  '
                'h ${lines[i].box.height.round()}',
          ),
      ];

  /// The entries containing [query], ignoring case and spaces ("gino"
  /// finds "GI No."). An empty query keeps all.
  static List<OcrReadEntry> search(List<OcrReadEntry> entries, String query) {
    final q = _key(query);
    if (q.isEmpty) return entries;
    return [
      for (final e in entries)
        if (_key(e.text).contains(q)) e,
    ];
  }

  /// [entries] as plain text, one per line, for the clipboard.
  static String asText(List<OcrReadEntry> entries) =>
      entries.map((e) => '${e.where}: ${e.text}').join('\n');

  static String _key(String s) => s.replaceAll(RegExp(r'\s+'), '').toLowerCase();
}
