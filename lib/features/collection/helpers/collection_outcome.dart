import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_engagement_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';

/// What an amount says about the outcome of a collection.
///
/// Shared so the single-invoice form and the batch screen never disagree
/// about what paying in full means. Both let the collector override it, and
/// both stop deriving once they do.
class CollectionOutcome {
  CollectionOutcome._();

  /// The outcome implied by collecting [amount] against a [balance].
  ///
  /// Null means the amount has no opinion: nothing collected says nothing
  /// about whether this was a follow-up, a refusal or an unanswered door.
  static String? forAmount(double amount, double balance) {
    if (amount <= 0) return null;
    if (amount >= balance) return CollectionStatusColors.statusCollected;
    return CollectionStatusColors.statusPartial;
  }

  /// Whether an engagement's amount is money collected from an account.
  ///
  /// Four activities are not collections, whatever amount they carry: an
  /// Advanced Payment is float until applied to an invoice (the applied row
  /// is the collection); a For Deposit banks money already counted when it
  /// was collected; a CWT Pick-up collects a tax certificate; a
  /// Reconciliation reviews a disputed balance. They are the collector's
  /// activities, shown in the history and the calendar, and add nothing to a
  /// money total. One rule, so Collected this Month, the calendar's visit
  /// totals and the history cards cannot disagree. [kind] is the archive's
  /// (INVOICE / ACCOUNT / OFFICE / ADVANCE) when the caller has it; the status
  /// alone decides otherwise.
  static bool countsAsCollected(String status, {String kind = ''}) {
    if (kind == 'ADVANCE') return false;
    return !_activitiesOnly.contains(status.trim());
  }

  /// Whether an archive record is the collection that settled its invoice.
  ///
  /// The archive's own flag when the row carries it (set on the collection
  /// that brought the balance to zero, including an Advanced Payment applied
  /// in full); for rows written before the flag existed, an invoice
  /// engagement whose outcome is Collected. A partial collection, a visit
  /// that collected nothing, and an advance that only reduced the balance
  /// are not settlements.
  static bool settlesInvoice(CollectionEngagementRecord e) =>
      e.kind == 'INVOICE' &&
      e.itemId.isNotEmpty &&
      (e.settled || e.status.trim() == CollectionStatusColors.statusCollected);

  static const Set<String> _activitiesOnly = {
    CollectionStatusColors.statusAdvance,
    CollectionStatusColors.statusDeposit,
    CollectionStatusColors.statusCWTPickup,
    CollectionStatusColors.statusReconciliation,
  };
}
