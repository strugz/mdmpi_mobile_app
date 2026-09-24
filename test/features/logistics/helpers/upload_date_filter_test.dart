import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/upload_date_filter.dart';

void main() {
  final now = DateTime(2026, 9, 24, 15, 30);
  bool m(UploadDateFilter f, String date, {UploadDateRange? range}) =>
      BUploadDateFilter.matches(f, date, now: now, range: range);

  test('parses the day from the formats the server sends', () {
    expect(BUploadDateFilter.parseDay('2026-09-24'), DateTime(2026, 9, 24));
    expect(BUploadDateFilter.parseDay('2026-09-24T00:00:00'),
        DateTime(2026, 9, 24));
    expect(BUploadDateFilter.parseDay('2026-09-24 08:00:00'),
        DateTime(2026, 9, 24));
    expect(BUploadDateFilter.parseDay(''), isNull);
    expect(BUploadDateFilter.parseDay('N/A'), isNull);
  });

  test('today, tomorrow and yesterday are calendar days', () {
    expect(m(UploadDateFilter.today, '2026-09-24'), isTrue);
    expect(m(UploadDateFilter.today, '2026-09-25'), isFalse);
    expect(m(UploadDateFilter.tomorrow, '2026-09-25'), isTrue);
    expect(m(UploadDateFilter.yesterday, '2026-09-23'), isTrue);
    expect(m(UploadDateFilter.yesterday, '2026-09-24'), isFalse);
  });

  test('last 7 days includes today and the six days before', () {
    expect(m(UploadDateFilter.last7Days, '2026-09-18'), isTrue);
    expect(m(UploadDateFilter.last7Days, '2026-09-24'), isTrue);
    expect(m(UploadDateFilter.last7Days, '2026-09-17'), isFalse);
    expect(m(UploadDateFilter.last7Days, '2026-09-25'), isFalse);
  });

  test('a range is inclusive and order-proof', () {
    final range = UploadDateRange(DateTime(2026, 9, 20), DateTime(2026, 9, 17));
    expect(range.start, DateTime(2026, 9, 17));
    expect(m(UploadDateFilter.range, '2026-09-17', range: range), isTrue);
    expect(m(UploadDateFilter.range, '2026-09-20', range: range), isTrue);
    expect(m(UploadDateFilter.range, '2026-09-21', range: range), isFalse);
  });

  test('an unreadable date only shows under All dates', () {
    expect(m(UploadDateFilter.all, ''), isTrue);
    expect(m(UploadDateFilter.today, ''), isFalse);
  });
}
