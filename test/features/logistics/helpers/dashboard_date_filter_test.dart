import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_date_filter.dart';

void main() {
  group('DashboardDateFilter.allTime', () {
    const filter = DashboardDateFilter.allTime();

    test('matches any date', () {
      expect(filter.matches(DateTime(2026, 8, 28)), isTrue);
      expect(filter.matches(DateTime(1999, 1, 1)), isTrue);
    });

    test('matches null dates', () {
      expect(filter.matches(null), isTrue);
    });

    test('reports isAllTime', () {
      expect(filter.isAllTime, isTrue);
    });
  });

  group('DashboardDateFilter year only', () {
    const filter = DashboardDateFilter(year: 2026);

    test('matches any month within the year', () {
      expect(filter.matches(DateTime(2026, 1, 1)), isTrue);
      expect(filter.matches(DateTime(2026, 12, 31, 23, 59, 59)), isTrue);
    });

    test('rejects other years', () {
      expect(filter.matches(DateTime(2025, 12, 31)), isFalse);
      expect(filter.matches(DateTime(2027, 1, 1)), isFalse);
    });

    test('rejects null dates', () {
      expect(filter.matches(null), isFalse);
    });
  });

  group('DashboardDateFilter year + month', () {
    const filter = DashboardDateFilter(year: 2026, month: 8);

    test('matches month boundaries', () {
      expect(filter.matches(DateTime(2026, 8, 1)), isTrue);
      expect(filter.matches(DateTime(2026, 8, 31, 23, 59, 59)), isTrue);
    });

    test('rejects adjacent months', () {
      expect(filter.matches(DateTime(2026, 7, 31)), isFalse);
      expect(filter.matches(DateTime(2026, 9, 1)), isFalse);
    });

    test('rejects same month in another year', () {
      expect(filter.matches(DateTime(2025, 8, 15)), isFalse);
    });

    test('rejects null dates', () {
      expect(filter.matches(null), isFalse);
    });
  });

  test('equality is by value', () {
    expect(const DashboardDateFilter(year: 2026, month: 8),
        const DashboardDateFilter(year: 2026, month: 8));
    expect(const DashboardDateFilter(year: 2026),
        isNot(const DashboardDateFilter(year: 2026, month: 8)));
    expect(const DashboardDateFilter.allTime(), const DashboardDateFilter());
  });
}
