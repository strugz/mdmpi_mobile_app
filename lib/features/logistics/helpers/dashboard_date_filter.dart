/// Date filter for the activity dashboard.
///
/// Three granularities:
/// - All time: `year == null` (month is ignored)
/// - Whole year: `year != null, month == null`
/// - Specific month: both set
///
/// Pure value object — no GetX or Flutter dependencies so it is directly
/// unit-testable.
class DashboardDateFilter {
  const DashboardDateFilter({this.year, this.month});

  const DashboardDateFilter.allTime()
      : year = null,
        month = null;

  /// Selected year, or null for all time.
  final int? year;

  /// Selected month (1-12) within [year], or null for the whole year.
  /// Only meaningful when [year] is set.
  final int? month;

  bool get isAllTime => year == null;

  /// Whether [date] falls inside this filter window.
  ///
  /// Entries without a parseable date (`null`) are included under all time
  /// but excluded once a year/month is selected — an undated request cannot
  /// be proven to belong to the window.
  bool matches(DateTime? date) {
    if (year == null) return true;
    if (date == null) return false;
    if (date.year != year) return false;
    if (month != null && date.month != month) return false;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardDateFilter &&
      other.year == year &&
      other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => 'DashboardDateFilter(year: $year, month: $month)';
}
