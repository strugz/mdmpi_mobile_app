import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_bucket_config.dart';

void main() {
  test('every module has a bucket configuration with New Request and Cancelled',
      () {
    for (final module in FormCategoryType.values) {
      final buckets = DashboardBucketConfig.bucketsFor(module);
      expect(buckets, isNotEmpty, reason: '$module has no buckets');
      expect(buckets.first.label, 'New Request');
      expect(buckets.last.label, 'Cancelled');
    }
  });

  test('no module maps one raw status to two buckets', () {
    for (final module in FormCategoryType.values) {
      final buckets = DashboardBucketConfig.bucketsFor(module);
      final seen = <String>{};
      for (final bucket in buckets) {
        for (final status in bucket.statuses) {
          final normalized = DashboardBucketConfig.normalizeStatus(status);
          expect(seen.add(normalized), isTrue,
              reason: '$module maps "$status" into more than one bucket');
        }
      }
    }
  });

  test('Air/Sea buckets cover all 12 raw statuses exactly once', () {
    const airSeaStatuses = [
      'New Request',
      'Getting Supplies Ready',
      'Item Packed',
      'Endorsed to Guard',
      'For Dispatch',
      'Dispatch',
      'Drop Off',
      'Received',
      'Provincial Pick Up',
      'Provincial In Transit',
      'Provincial Delivered',
      'Cancelled',
    ];
    final buckets = DashboardBucketConfig.bucketsFor(FormCategoryType.airSea);
    for (final status in airSeaStatuses) {
      final matching = buckets.where((b) => b.contains(status)).length;
      expect(matching, 1,
          reason: '"$status" matched $matching buckets, expected exactly 1');
    }
  });

  test('bucket matching is case-insensitive', () {
    final buckets = DashboardBucketConfig.bucketsFor(
        FormCategoryType.standardDelivery);
    final gettingReady =
        buckets.firstWhere((b) => b.label == 'Getting Supplies Ready');
    expect(gettingReady.contains('Getting supplies ready'), isTrue);
    expect(gettingReady.contains('GETTING SUPPLIES READY'), isTrue);
    expect(gettingReady.contains('  getting supplies ready  '), isTrue);
  });

  test('Pull Out / Return has a For Pull Out bucket; Stock Receive does not',
      () {
    final pullOutLabels = DashboardBucketConfig.bucketsFor(
            FormCategoryType.pullOutReturn)
        .map((b) => b.label)
        .toList();
    expect(pullOutLabels, [
      'New Request',
      'For Pull Out',
      'In Transit',
      'Taken Out',
      'Cancelled',
    ]);

    final stockReceiveLabels = DashboardBucketConfig.bucketsFor(
            FormCategoryType.stockReceive)
        .map((b) => b.label)
        .toList();
    expect(stockReceiveLabels, [
      'New Request',
      'In Transit',
      'Taken Out',
      'Cancelled',
    ]);
  });

  test('every module has an accent color and icon', () {
    for (final module in FormCategoryType.values) {
      expect(() => DashboardBucketConfig.moduleAccent(module), returnsNormally);
      expect(() => DashboardBucketConfig.moduleIcon(module), returnsNormally);
    }
  });
}
