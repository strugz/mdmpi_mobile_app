import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';

/// What a [ReportCell] holds, which decides how it reads on screen and in
/// the CSV.
enum ReportCellKind { text, integer, money, date }

/// One value of a report. The screen and the CSV read the same cell, so the
/// two cannot disagree.
class ReportCell {
  const ReportCell.text(String? value)
      : value = value ?? '',
        kind = ReportCellKind.text;
  const ReportCell.integer(int this.value) : kind = ReportCellKind.integer;
  const ReportCell.money(double this.value) : kind = ReportCellKind.money;

  /// [value] is a wall-clock time; null reads blank.
  const ReportCell.date(DateTime? this.value) : kind = ReportCellKind.date;

  /// 'Y' / 'N'.
  const ReportCell.yesNo(bool yes)
      : value = yes ? 'Y' : 'N',
        kind = ReportCellKind.text;

  static const blank = ReportCell.text('');

  final Object? value;
  final ReportCellKind kind;

  static final DateFormat _csvDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _shownDate = DateFormat('MMM d, yyyy');

  /// For a spreadsheet: money as a plain number (no symbol, no thousands
  /// separator), dates as yyyy-MM-dd.
  String get csv => switch (kind) {
        ReportCellKind.money => (value as double).toStringAsFixed(2),
        ReportCellKind.date =>
          value == null ? '' : _csvDate.format(value as DateTime),
        _ => '$value',
      };

  /// For the screen: pesos with the symbol, dates spelled out.
  String get display => switch (kind) {
        ReportCellKind.money =>
          BFormatter.formatPesoCurrency(value as double),
        ReportCellKind.date =>
          value == null ? '' : _shownDate.format(value as DateTime),
        _ => '$value',
      };
}

/// A report as rows of cells: what the screen lists and the CSV holds.
class ReportTable {
  const ReportTable({
    required this.title,
    required this.headers,
    required this.rows,
    this.totals,
    this.summary = const {},
  });

  /// "Activity report · 2026-09".
  final String title;
  final List<String> headers;
  final List<List<ReportCell>> rows;

  /// A last row as wide as [headers]; null for none.
  final List<ReportCell>? totals;

  /// Label → shown value, for the chips above the list.
  final Map<String, String> summary;

  bool get isEmpty => rows.isEmpty;
}
