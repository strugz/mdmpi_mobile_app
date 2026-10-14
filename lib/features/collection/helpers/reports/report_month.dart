import 'package:intl/intl.dart';

/// Months as the reports key them: `yyyy-MM`.
class BReportMonth {
  BReportMonth._();

  static final DateFormat _label = DateFormat('MMMM yyyy');

  /// `2026-09` for any day of September 2026.
  static String key(DateTime month) =>
      '${month.year.toString().padLeft(4, '0')}-'
      '${month.month.toString().padLeft(2, '0')}';

  /// "September 2026".
  static String label(DateTime month) => _label.format(month);

  /// The first day of [day]'s month.
  static DateTime first(DateTime day) => DateTime(day.year, day.month);

  /// The last day of [month].
  static DateTime last(DateTime month) =>
      DateTime(month.year, month.month + 1, 0);

  /// Whether [time] (a wall-clock time, any zone flag) falls in [yearMonth].
  static bool contains(String yearMonth, DateTime? time) =>
      time != null && key(time) == yearMonth;
}
