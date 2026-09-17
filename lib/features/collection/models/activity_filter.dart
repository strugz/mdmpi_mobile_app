import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

/// How late an invoice is, in the bands a collector plans a day by.
enum DueBand {
  any('Any'),
  dueSoon('Due in 7 days'),
  overdue('Overdue'),
  late30('Late 30+ days'),
  lateYear('Late 1 year+');

  const DueBand(this.label);
  final String label;

  bool matches(CollectionItemModel item) {
    final days = item.daysPastDue;
    return switch (this) {
      DueBand.any => true,
      // daysPastDue floors at zero for future dates, so "due soon" has to
      // look at the date itself.
      DueBand.dueSoon => _daysUntilDue(item) != null &&
          _daysUntilDue(item)! >= 0 &&
          _daysUntilDue(item)! <= 7,
      DueBand.overdue => days > 0,
      DueBand.late30 => days > 30,
      DueBand.lateYear => days > 365,
    };
  }

  static int? _daysUntilDue(CollectionItemModel item) {
    final iso = BFormatter.normalizeToIsoDatetime(item.dueDate);
    if (iso == null) return null;
    final due = DateTime.tryParse(iso);
    if (due == null) return null;
    final today = DateTime.now();
    return DateTime(due.year, due.month, due.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }
}

/// Amount due, in preset bands. A slider over a million-peso range moved
/// thousands of pesos per pixel; bands are what people mean anyway.
enum AmountBand {
  any('Any', 0, double.infinity),
  under10k('Under ₱10k', 0, 10000),
  from10kTo50k('₱10k to 50k', 10000, 50000),
  from50kTo200k('₱50k to 200k', 50000, 200000),
  over200k('Over ₱200k', 200000, double.infinity);

  const AmountBand(this.label, this.min, this.max);
  final String label;
  final double min;
  final double max;

  bool matches(double amount) => amount >= min && amount < max;
}

/// Order of the list.
///
/// [mostInvoices] and [fewestInvoices] are account-level: every invoice in an
/// account shares its count, so ordering by them only means something between
/// accounts. The controllers handle those two; [compare] falls back to the
/// default order for them.
enum ActivitySort {
  mostOverdue('Most overdue'),
  amountHigh('Amount high to low'),
  amountLow('Amount low to high'),
  mostInvoices('Most invoices'),
  fewestInvoices('Fewest invoices'),
  lastVisitOldest('Longest since visit'),
  name('Account name');

  const ActivitySort(this.label);
  final String label;

  /// True when the order is a property of the account, not of one invoice.
  bool get isAccountLevel =>
      this == ActivitySort.mostInvoices || this == ActivitySort.fewestInvoices;
}

/// The engagement list's filter and sort, as one value.
///
/// Every field here runs on data already on the invoice: the due date, the
/// last outcome recorded against it, the balance, and its history. Nothing
/// is fetched. The filter is immutable; the controller holds one in an Rx
/// and screens replace it with [copyWith].
class ActivityFilter {
  const ActivityFilter({
    this.due = DueBand.any,
    this.amount = AmountBand.any,
    this.area = '',
    this.sort = ActivitySort.mostOverdue,
  });

  static const none = ActivityFilter();

  final DueBand due;
  final AmountBand amount;

  /// Territory prefix, as [BCollectionArea] defines them. Empty is every area.
  final String area;

  final ActivitySort sort;

  /// Whether anything other than the sort is set. Sort alone is not a
  /// filter: it hides nothing.
  bool get isActive =>
      due != DueBand.any || amount != AmountBand.any || area.isNotEmpty;

  /// How many filter groups are set, for the badge on the filter button.
  int get activeCount =>
      (due != DueBand.any ? 1 : 0) +
      (amount != AmountBand.any ? 1 : 0) +
      (area.isNotEmpty ? 1 : 0);

  /// When [item] was last visited, or null if never.
  static DateTime? lastVisitOf(CollectionItemModel item) {
    DateTime? latest;
    for (final h in item.history) {
      final iso = BFormatter.normalizeToIsoDatetime(h.date);
      final dt = iso == null ? null : DateTime.tryParse(iso);
      if (dt != null && (latest == null || dt.isAfter(latest))) latest = dt;
    }
    return latest;
  }

  bool matches(CollectionItemModel item) {
    if (!due.matches(item)) return false;
    if (!amount.matches(item.toBeCollected)) return false;
    if (!BCollectionArea.matches(item.client.code, area)) return false;
    return true;
  }

  /// Order two invoices by [sort]. Ties break on id so the order is stable.
  int compare(CollectionItemModel a, CollectionItemModel b) {
    int result;
    switch (sort) {
      case ActivitySort.mostOverdue:
        result = b.daysPastDue.compareTo(a.daysPastDue);
      case ActivitySort.amountHigh:
        result = b.toBeCollected.compareTo(a.toBeCollected);
      case ActivitySort.amountLow:
        result = a.toBeCollected.compareTo(b.toBeCollected);
      // An account's invoice count says nothing about one of its invoices,
      // so inside an account these fall back to the default order.
      case ActivitySort.mostInvoices:
      case ActivitySort.fewestInvoices:
        result = b.daysPastDue.compareTo(a.daysPastDue);
      case ActivitySort.lastVisitOldest:
        // Never visited sorts first: it has waited the longest.
        final la = lastVisitOf(a);
        final lb = lastVisitOf(b);
        if (la == null && lb == null) {
          result = 0;
        } else if (la == null) {
          result = -1;
        } else if (lb == null) {
          result = 1;
        } else {
          result = la.compareTo(lb);
        }
      case ActivitySort.name:
        result = a.client.name.compareTo(b.client.name);
    }
    return result != 0 ? result : a.id.compareTo(b.id);
  }

  ActivityFilter copyWith({
    DueBand? due,
    AmountBand? amount,
    String? area,
    ActivitySort? sort,
  }) =>
      ActivityFilter(
        due: due ?? this.due,
        amount: amount ?? this.amount,
        area: area ?? this.area,
        sort: sort ?? this.sort,
      );

  @override
  bool operator ==(Object other) =>
      other is ActivityFilter &&
      other.due == due &&
      other.amount == amount &&
      other.area == area &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(due, amount, area, sort);
}
