import 'package:mdmpi_mobile_app/features/collection/models/activity_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

/// What has already been recorded against an invoice.
///
/// Inside an account this is the question the engagement list cannot answer:
/// which of these have I not touched yet, and which are part paid and waiting
/// on the rest.
enum InvoiceProgress {
  any('Any'),
  untouched('Nothing recorded'),
  partPaid('Part paid');

  const InvoiceProgress(this.label);
  final String label;

  bool matches(CollectionItemModel item) => switch (this) {
        InvoiceProgress.any => true,
        InvoiceProgress.untouched =>
          item.history.isEmpty && item.totalCollected <= 0,
        InvoiceProgress.partPaid => item.totalCollected > 0,
      };
}

/// Order of one account's invoice list.
///
/// Every order here is a property of the invoice itself. The engagement list's
/// sorts are not: "Most invoices" and "Account name" have nothing to order by
/// once the account is already chosen.
///
/// There is deliberately no "Invoice number". The ids run in issue order, so
/// it would be [mostOverdue] under another name; looking one up is the search
/// field's job, not a sort's; and comparing ids as text only holds while they
/// all happen to be the same length. It survives as the tie-break below,
/// which is all it was ever good for.
enum InvoiceSort {
  mostOverdue('Most overdue'),
  leastOverdue('Least overdue'),
  amountHigh('Amount high to low'),
  amountLow('Amount low to high');

  const InvoiceSort(this.label);
  final String label;
}

/// The filter and sort for the invoices of a single account.
///
/// Separate from [ActivityFilter] on purpose. That one picks *accounts* off
/// the engagement list — it asks about the area and counts invoices per
/// account — and reusing it here meant the filter button on an account's
/// invoices opened a sheet titled "Filter engagements" offering an area that
/// every invoice in the account already shares, and promising to "Show 23
/// accounts" on a screen that shows one.
///
/// This one asks only what can be asked of an invoice: how late it is, how
/// much it is for, what has been recorded against it, and in what order.
/// [DueBand] and [AmountBand] are shared, so the two sheets read the same.
class InvoiceFilter {
  const InvoiceFilter({
    this.due = DueBand.any,
    this.amount = AmountBand.any,
    this.progress = InvoiceProgress.any,
    this.sort = InvoiceSort.mostOverdue,
  });

  static const none = InvoiceFilter();

  final DueBand due;
  final AmountBand amount;
  final InvoiceProgress progress;
  final InvoiceSort sort;

  /// Whether anything other than the sort is set. Sort alone is not a filter:
  /// it hides nothing.
  bool get isActive =>
      due != DueBand.any ||
      amount != AmountBand.any ||
      progress != InvoiceProgress.any;

  bool matches(CollectionItemModel item) {
    if (!due.matches(item)) return false;
    if (!amount.matches(item.toBeCollected)) return false;
    if (!progress.matches(item)) return false;
    return true;
  }

  /// Order two invoices by [sort]. Ties break on id so the order is stable.
  int compare(CollectionItemModel a, CollectionItemModel b) {
    final result = switch (sort) {
      InvoiceSort.mostOverdue => b.daysPastDue.compareTo(a.daysPastDue),
      InvoiceSort.leastOverdue => a.daysPastDue.compareTo(b.daysPastDue),
      InvoiceSort.amountHigh => b.toBeCollected.compareTo(a.toBeCollected),
      InvoiceSort.amountLow => a.toBeCollected.compareTo(b.toBeCollected),
    };
    return result != 0 ? result : a.id.compareTo(b.id);
  }

  InvoiceFilter copyWith({
    DueBand? due,
    AmountBand? amount,
    InvoiceProgress? progress,
    InvoiceSort? sort,
  }) =>
      InvoiceFilter(
        due: due ?? this.due,
        amount: amount ?? this.amount,
        progress: progress ?? this.progress,
        sort: sort ?? this.sort,
      );

  @override
  bool operator ==(Object other) =>
      other is InvoiceFilter &&
      other.due == due &&
      other.amount == amount &&
      other.progress == progress &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(due, amount, progress, sort);
}
