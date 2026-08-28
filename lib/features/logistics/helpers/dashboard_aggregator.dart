import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_bucket_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_date_filter.dart';

/// One request normalized for dashboard counting, independent of which of
/// the four model classes it originated from.
class DashboardEntry {
  const DashboardEntry({
    required this.module,
    required this.status,
    this.date,
  });

  final FormCategoryType module;

  /// Raw status string as stored on the request.
  final String status;

  /// Parsed request date, or null when the source string was unparseable.
  final DateTime? date;
}

/// Pure counting/filtering functions for the dashboard. No GetX, no Flutter —
/// everything here is directly unit-testable.
class DashboardAggregator {
  DashboardAggregator._();

  /// Tolerant String → DateTime parse: returns null for null, empty, or
  /// malformed input instead of throwing.
  static DateTime? tryParseDate(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }

  /// Entries matching [dateFilter] and, when given, [module].
  static List<DashboardEntry> applyFilter(
    List<DashboardEntry> entries,
    DashboardDateFilter dateFilter, {
    FormCategoryType? module,
  }) {
    return entries
        .where((e) =>
            (module == null || e.module == module) &&
            dateFilter.matches(e.date))
        .toList();
  }

  /// Request count per module. Every module appears in the result, including
  /// those with zero entries, so the dashboard always renders all six rows.
  static Map<FormCategoryType, int> countByModule(
      List<DashboardEntry> entries) {
    final counts = <FormCategoryType, int>{
      for (final module in FormCategoryType.values) module: 0,
    };
    for (final entry in entries) {
      counts[entry.module] = counts[entry.module]! + 1;
    }
    return counts;
  }

  /// Count per bucket label for the given bucket configuration. Statuses not
  /// covered by any bucket are ignored here (they still count toward totals
  /// via [applyFilter] length).
  static Map<String, int> countByBucket(
    List<DashboardEntry> entries,
    List<DashboardBucket> buckets,
  ) {
    final counts = <String, int>{for (final b in buckets) b.label: 0};
    for (final entry in entries) {
      for (final bucket in buckets) {
        if (bucket.contains(entry.status)) {
          counts[bucket.label] = counts[bucket.label]! + 1;
          break;
        }
      }
    }
    return counts;
  }

  /// Distinct years present in [entries] (dated entries only), newest first.
  static List<int> availableYears(List<DashboardEntry> entries) {
    final years = <int>{
      for (final entry in entries)
        if (entry.date != null) entry.date!.year,
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }
}
