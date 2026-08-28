import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_aggregator.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_bucket_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_date_filter.dart';

DashboardEntry entry(FormCategoryType module, String status, {DateTime? date}) =>
    DashboardEntry(module: module, status: status, date: date);

void main() {
  group('tryParseDate', () {
    test('parses ISO strings', () {
      expect(DashboardAggregator.tryParseDate('2026-08-28'),
          DateTime(2026, 8, 28));
      expect(DashboardAggregator.tryParseDate('2026-08-28T10:30:00'),
          DateTime(2026, 8, 28, 10, 30));
    });

    test('returns null for null, empty, and garbage', () {
      expect(DashboardAggregator.tryParseDate(null), isNull);
      expect(DashboardAggregator.tryParseDate(''), isNull);
      expect(DashboardAggregator.tryParseDate('   '), isNull);
      expect(DashboardAggregator.tryParseDate('not-a-date'), isNull);
    });

    test('trims surrounding whitespace', () {
      expect(DashboardAggregator.tryParseDate(' 2026-01-05 '),
          DateTime(2026, 1, 5));
    });
  });

  group('applyFilter', () {
    final entries = [
      entry(FormCategoryType.standardDelivery, 'Delivered',
          date: DateTime(2026, 8, 10)),
      entry(FormCategoryType.standardDelivery, 'New Request',
          date: DateTime(2025, 2, 1)),
      entry(FormCategoryType.pullOutReturn, 'In Transit',
          date: DateTime(2026, 8, 20)),
      entry(FormCategoryType.pickUp, 'Received'), // undated
    ];

    test('all time + all modules keeps everything', () {
      final result = DashboardAggregator.applyFilter(
          entries, const DashboardDateFilter.allTime());
      expect(result.length, 4);
    });

    test('module filter narrows to that module', () {
      final result = DashboardAggregator.applyFilter(
        entries,
        const DashboardDateFilter.allTime(),
        module: FormCategoryType.standardDelivery,
      );
      expect(result.length, 2);
      expect(result.every((e) => e.module == FormCategoryType.standardDelivery),
          isTrue);
    });

    test('year filter excludes other years and undated entries', () {
      final result = DashboardAggregator.applyFilter(
          entries, const DashboardDateFilter(year: 2026));
      expect(result.length, 2);
    });

    test('year + month + module combine', () {
      final result = DashboardAggregator.applyFilter(
        entries,
        const DashboardDateFilter(year: 2026, month: 8),
        module: FormCategoryType.pullOutReturn,
      );
      expect(result.length, 1);
      expect(result.single.status, 'In Transit');
    });
  });

  group('countByModule', () {
    test('counts per module and includes zero modules', () {
      final counts = DashboardAggregator.countByModule([
        entry(FormCategoryType.standardDelivery, 'Delivered'),
        entry(FormCategoryType.standardDelivery, 'New Request'),
        entry(FormCategoryType.airSea, 'Dispatch'),
      ]);
      expect(counts[FormCategoryType.standardDelivery], 2);
      expect(counts[FormCategoryType.airSea], 1);
      expect(counts[FormCategoryType.pickUp], 0);
      expect(counts.length, FormCategoryType.values.length);
    });
  });

  group('countByBucket', () {
    test('buckets Standard Delivery statuses including the casing trap', () {
      final buckets = DashboardBucketConfig.bucketsFor(
          FormCategoryType.standardDelivery);
      final counts = DashboardAggregator.countByBucket([
        // As emitted for SD/Hotline (lowercase "supplies ready")
        entry(FormCategoryType.standardDelivery, 'Getting supplies ready'),
        // Title Case variant must land in the same bucket
        entry(FormCategoryType.standardDelivery, 'Getting Supplies Ready'),
        entry(FormCategoryType.standardDelivery, 'Delivered'),
      ], buckets);
      expect(counts['Getting Supplies Ready'], 2);
      expect(counts['Delivered'], 1);
      expect(counts['New Request'], 0);
    });

    test('unknown status is ignored by buckets', () {
      final buckets =
          DashboardBucketConfig.bucketsFor(FormCategoryType.pullOutReturn);
      final counts = DashboardAggregator.countByBucket([
        entry(FormCategoryType.pullOutReturn, 'Some Future Status'),
        entry(FormCategoryType.pullOutReturn, 'Taken Out'),
      ], buckets);
      expect(counts['Taken Out'], 1);
      expect(counts.values.fold<int>(0, (a, b) => a + b), 1);
    });

    test('Air/Sea stages roll up into composite buckets', () {
      final buckets =
          DashboardBucketConfig.bucketsFor(FormCategoryType.airSea);
      final counts = DashboardAggregator.countByBucket([
        entry(FormCategoryType.airSea, 'Endorsed to Guard'),
        entry(FormCategoryType.airSea, 'For Dispatch'),
        entry(FormCategoryType.airSea, 'Dispatch'),
        entry(FormCategoryType.airSea, 'Provincial In Transit'),
        entry(FormCategoryType.airSea, 'Provincial Delivered'),
        entry(FormCategoryType.airSea, 'Received'),
      ], buckets);
      expect(counts['Preparing'], 2);
      expect(counts['In Transit'], 2);
      expect(counts['Completed'], 2);
    });
  });

  group('availableYears', () {
    test('returns distinct years newest first, skipping undated', () {
      final years = DashboardAggregator.availableYears([
        entry(FormCategoryType.pickUp, 'Received', date: DateTime(2024, 5, 1)),
        entry(FormCategoryType.pickUp, 'Received', date: DateTime(2026, 1, 1)),
        entry(FormCategoryType.pickUp, 'Received', date: DateTime(2026, 7, 9)),
        entry(FormCategoryType.pickUp, 'Received'),
      ]);
      expect(years, [2026, 2024]);
    });

    test('empty input yields empty list', () {
      expect(DashboardAggregator.availableYears([]), isEmpty);
    });
  });
}
