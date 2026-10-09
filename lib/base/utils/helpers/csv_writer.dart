import 'dart:convert';
import 'dart:typed_data';

import 'package:mdmpi_mobile_app/data/models/report_table.dart';

/// Writes a [ReportTable] as CSV that Excel opens cleanly: RFC 4180 quoting,
/// CRLF line ends, and a UTF-8 byte-order mark so names and the peso sign
/// survive. A text cell that Excel would run as a formula (it starts with
/// = + - @, a tab or a carriage return) gets a leading apostrophe; numbers
/// are never touched, so a negative amount stays a number.
class BCsv {
  BCsv._();

  static const String bom = '﻿';

  static String encode(ReportTable table, {bool withBom = true}) {
    final out = StringBuffer();
    if (withBom) out.write(bom);
    out.write(table.headers.map(cell).join(','));
    out.write('\r\n');
    for (final row in [...table.rows, if (table.totals != null) table.totals!]) {
      out.write(row.map(_cellOf).join(','));
      out.write('\r\n');
    }
    return out.toString();
  }

  static Uint8List bytes(ReportTable table) =>
      Uint8List.fromList(utf8.encode(encode(table)));

  static String _cellOf(ReportCell c) =>
      c.kind == ReportCellKind.text ? cell(c.csv) : c.csv;

  /// One text cell, guarded and quoted as needed.
  static String cell(String raw) {
    var s = raw;
    if (s.isNotEmpty && '=+-@\t\r'.contains(s[0])) s = "'$s";
    final needsQuotes = s.contains(RegExp(r'[",\r\n]'));
    return needsQuotes ? '"${s.replaceAll('"', '""')}"' : s;
  }
}

/// File names for exported reports: `mdmpi_activity_JCA_2026-09.csv`.
class BReportFileName {
  BReportFileName._();

  static String build(String report, {String? collector, String? period}) {
    final parts = [
      'mdmpi',
      report,
      if (collector != null && collector.trim().isNotEmpty) collector,
      if (period != null && period.trim().isNotEmpty) period,
    ];
    final name = parts
        .map((p) => p.trim().replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_'))
        .join('_');
    return '$name.csv';
  }
}
