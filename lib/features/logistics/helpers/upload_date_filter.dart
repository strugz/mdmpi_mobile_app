/// Delivery-date filter for Settings > Upload Data.
///
/// Pure (no Flutter imports) so the controller can hold it and tests can pin
/// "today". Dates are compared as calendar days on the phone's clock, which is
/// how the delivery lists read `DeliveryDate` ("2026-09-24").
enum UploadDateFilter { all, today, tomorrow, yesterday, last7Days, range }

extension UploadDateFilterX on UploadDateFilter {
  String get label => switch (this) {
        UploadDateFilter.all => 'All dates',
        UploadDateFilter.today => 'Today',
        UploadDateFilter.tomorrow => 'Tomorrow',
        UploadDateFilter.yesterday => 'Yesterday',
        UploadDateFilter.last7Days => 'Last 7 days',
        UploadDateFilter.range => 'Pick range',
      };
}

/// An inclusive span of calendar days.
class UploadDateRange {
  UploadDateRange(DateTime start, DateTime end)
      : start = _day(start.isAfter(end) ? end : start),
        end = _day(start.isAfter(end) ? start : end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime day) {
    final d = _day(day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  @override
  bool operator ==(Object other) =>
      other is UploadDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

class BUploadDateFilter {
  BUploadDateFilter._();

  /// The calendar day in a `DeliveryDate` string, or null when it is not a
  /// date. Only the first ten characters are read, so "2026-09-24T00:00:00"
  /// and "2026-09-24 08:00" both work.
  static DateTime? parseDay(String raw) {
    final s = raw.trim();
    if (s.length < 10) return null;
    final parsed = DateTime.tryParse(s.substring(0, 10));
    return parsed == null ? null : _day(parsed);
  }

  /// Whether a request delivered on [deliveryDate] passes [filter]. A request
  /// without a readable date only shows under "All dates".
  static bool matches(
    UploadDateFilter filter,
    String deliveryDate, {
    required DateTime now,
    UploadDateRange? range,
  }) {
    if (filter == UploadDateFilter.all) return true;
    final day = parseDay(deliveryDate);
    if (day == null) return false;
    final today = _day(now);
    return switch (filter) {
      UploadDateFilter.all => true,
      UploadDateFilter.today => day == today,
      UploadDateFilter.tomorrow => day == today.add(const Duration(days: 1)),
      UploadDateFilter.yesterday =>
        day == today.subtract(const Duration(days: 1)),
      UploadDateFilter.last7Days =>
        UploadDateRange(today.subtract(const Duration(days: 6)), today)
            .contains(day),
      UploadDateFilter.range => range?.contains(day) ?? true,
    };
  }
}
