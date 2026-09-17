import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
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

/// Order of the engagement list.
enum ActivitySort {
  mostOverdue('Most overdue'),
  amountHigh('Highest amount'),
  lastVisitOldest('Longest since visit'),
  name('Account name');

  const ActivitySort(this.label);
  final String label;
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
    this.outcomes = const {},
    this.amount = AmountBand.any,
    this.area = '',
    this.sort = ActivitySort.mostOverdue,
  });

  static const none = ActivityFilter();

  final DueBand due;

  /// Outcomes of the last visit to include. Empty means all. Contains
  /// [noVisitYet] to include invoices nobody has visited.
  final Set<String> outcomes;
  final AmountBand amount;

  /// Territory prefix, as [BCollectionArea] defines them. Empty is every area.
  final String area;

  final ActivitySort sort;

  /// Sentinel outcome for an invoice with no history at all.
  static const noVisitYet = 'No visit yet';

  /// The outcomes offered as chips, in the order they appear.
  static const outcomeOptions = [
    CollectionStatusColors.statusFollowUp,
    CollectionStatusColors.statusUnavailable,
    CollectionStatusColors.statusRefused,
    CollectionStatusColors.statusPreCollection,
    CollectionStatusColors.statusPartial,
    noVisitYet,
  ];

  /// Whether anything other than the default sort is set. Sort alone is not a
  /// filter: it hides nothing.
  bool get isActive =>
      due != DueBand.any ||
      outcomes.isNotEmpty ||
      amount != AmountBand.any ||
      area.isNotEmpty;

  /// How many filter groups are set, for the badge on the filter button.
  int get activeCount =>
      (due != DueBand.any ? 1 : 0) +
      (outcomes.isNotEmpty ? 1 : 0) +
      (amount != AmountBand.any ? 1 : 0) +
      (area.isNotEmpty ? 1 : 0);

  /// The last outcome recorded on [item], or [noVisitYet].
  static String outcomeOf(CollectionItemModel item) {
    final last = item.lastOutcome?.trim() ?? '';
    if (last.isNotEmpty) return last;
    if (item.history.isEmpty) return noVisitYet;
    final status = item.history.last.status.trim();
    return status.isEmpty ? noVisitYet : status;
  }

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
    if (outcomes.isNotEmpty && !outcomes.contains(outcomeOf(item))) {
      return false;
    }
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
    Set<String>? outcomes,
    AmountBand? amount,
    String? area,
    ActivitySort? sort,
  }) =>
      ActivityFilter(
        due: due ?? this.due,
        outcomes: outcomes ?? this.outcomes,
        amount: amount ?? this.amount,
        area: area ?? this.area,
        sort: sort ?? this.sort,
      );

  /// The same filter with [outcome] added or removed.
  ActivityFilter toggleOutcome(String outcome) {
    final next = Set<String>.from(outcomes);
    if (!next.remove(outcome)) next.add(outcome);
    return copyWith(outcomes: next);
  }

  @override
  bool operator ==(Object other) =>
      other is ActivityFilter &&
      other.due == due &&
      other.amount == amount &&
      other.area == area &&
      other.sort == sort &&
      other.outcomes.length == outcomes.length &&
      other.outcomes.containsAll(outcomes);

  @override
  int get hashCode => Object.hash(due, amount, area, sort, outcomes.length);
}
