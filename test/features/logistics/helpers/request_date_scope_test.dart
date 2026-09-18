import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/request_date_scope.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';

void main() {
  group('RequestDateScope.fromFilter', () {
    const expected = <RequestFilter, RequestDateScope>{
      RequestFilter.today: RequestDateScope.today,
      RequestFilter.yesterday: RequestDateScope.yesterday,
      RequestFilter.tomorrow: RequestDateScope.tomorrow,
      // The backend reads FiveDaysAgo/ThirtyDaysAgo as one exact day, while
      // the app means "within the last N days". Mapping them to the matching
      // backend member would silently drop 4 (or 29) days of rows, so they
      // must stay on `all` and be narrowed client-side.
      RequestFilter.fiveDaysAgo: RequestDateScope.all,
      RequestFilter.thirtyDaysAgo: RequestDateScope.all,
      RequestFilter.all: RequestDateScope.all,
    };

    test('covers every RequestFilter value', () {
      expect(expected.keys, containsAll(RequestFilter.values));
    });

    for (final entry in expected.entries) {
      test('${entry.key.name} -> ${entry.value.name}', () {
        expect(RequestDateScope.fromFilter(entry.key), entry.value);
      });
    }
  });

  group('RequestDateScope.covers', () {
    test('all covers every scope', () {
      for (final scope in RequestDateScope.values) {
        expect(RequestDateScope.all.covers(scope), isTrue,
            reason: 'all should cover ${scope.name}');
      }
    });

    test('a scope covers itself', () {
      for (final scope in RequestDateScope.values) {
        expect(scope.covers(scope), isTrue);
      }
    });

    test('a narrow scope does not cover a wider or sibling one', () {
      expect(RequestDateScope.today.covers(RequestDateScope.all), isFalse);
      expect(RequestDateScope.today.covers(RequestDateScope.yesterday), isFalse);
      expect(RequestDateScope.yesterday.covers(RequestDateScope.today), isFalse);
      expect(RequestDateScope.tomorrow.covers(RequestDateScope.all), isFalse);
    });
  });

  group('RequestDateScope.queryParameters', () {
    test('emits the backend enum member name', () {
      expect(RequestDateScope.today.queryParameters,
          const {'dateFilter': 'Today'});
      expect(RequestDateScope.yesterday.queryParameters,
          const {'dateFilter': 'Yesterday'});
      expect(RequestDateScope.tomorrow.queryParameters,
          const {'dateFilter': 'Tomorrow'});
      expect(
          RequestDateScope.all.queryParameters, const {'dateFilter': 'All'});
    });
  });

  group('shouldRefetch', () {
    test('never refetches before anything has loaded', () {
      for (final filter in RequestFilter.values) {
        expect(shouldRefetch(null, filter), isFalse);
      }
    });

    test('widening from today needs a fetch', () {
      expect(shouldRefetch(RequestDateScope.today, RequestFilter.all), isTrue);
      expect(shouldRefetch(RequestDateScope.today, RequestFilter.fiveDaysAgo),
          isTrue);
      expect(shouldRefetch(RequestDateScope.today, RequestFilter.thirtyDaysAgo),
          isTrue);
      expect(shouldRefetch(RequestDateScope.today, RequestFilter.yesterday),
          isTrue);
    });

    test('staying on the same filter needs no fetch', () {
      expect(shouldRefetch(RequestDateScope.today, RequestFilter.today),
          isFalse);
      expect(
          shouldRefetch(RequestDateScope.yesterday, RequestFilter.yesterday),
          isFalse);
    });

    test('narrowing from all needs no fetch', () {
      for (final filter in RequestFilter.values) {
        expect(shouldRefetch(RequestDateScope.all, filter), isFalse,
            reason: 'all already covers ${filter.name}');
      }
    });
  });
}
