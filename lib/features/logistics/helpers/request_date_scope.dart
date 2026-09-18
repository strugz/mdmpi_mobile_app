import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';

/// Wire-level date scope sent to `/api4` as `?dateFilter=<wireValue>`.
///
/// Deliberately narrower than [RequestFilter]: the backend only understands
/// these four values in a way that matches what the app means by them.
enum RequestDateScope {
  today('Today'),
  yesterday('Yesterday'),
  tomorrow('Tomorrow'),
  all('All');

  const RequestDateScope(this.wireValue);

  /// Value sent as `?dateFilter=`; must match the backend `RequestDateFilter`
  /// enum member names.
  final String wireValue;

  /// Wire scope needed to satisfy [filter].
  ///
  /// `fiveDaysAgo` / `thirtyDaysAgo` deliberately map to [all]: the backend
  /// reads those enum members as one *exact* day, while the app means "within
  /// the last N days". Sending them would silently drop 4 (or 29) days of
  /// rows. Do not "fix" this — the client-side `applyFilter()` pass still
  /// narrows the response down to the real N-day range.
  static RequestDateScope fromFilter(RequestFilter filter) {
    switch (filter) {
      case RequestFilter.today:
        return today;
      case RequestFilter.yesterday:
        return yesterday;
      case RequestFilter.tomorrow:
        return tomorrow;
      case RequestFilter.fiveDaysAgo:
      case RequestFilter.thirtyDaysAgo:
      case RequestFilter.all:
        return all;
    }
  }

  /// True when data already loaded at `this` scope is a superset of [needed].
  bool covers(RequestDateScope needed) => this == all || this == needed;

  /// Query parameters to merge into the request URI.
  Map<String, String> get queryParameters => {'dateFilter': wireValue};
}

/// Whether switching to [next] needs a wider fetch than what is already loaded.
///
/// Returns false when nothing has loaded yet ([loaded] is null): the initial
/// load is driven by the controller's own fetch, not by a filter change.
bool shouldRefetch(RequestDateScope? loaded, RequestFilter next) =>
    loaded != null && !loaded.covers(RequestDateScope.fromFilter(next));
