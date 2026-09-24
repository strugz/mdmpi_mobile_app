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
  /// Two carry an amount without being one: an Advanced Payment is float
  /// until applied to an invoice (the applied row is the collection), and a
  /// For Deposit is the collector banking money already counted when it was
  /// collected. Counting either added the same pesos twice. One rule, so
  /// Collected this Month, the calendar's visit totals and the history cards
  /// cannot disagree. [kind] is the archive's (INVOICE / ACCOUNT / OFFICE /
  /// ADVANCE) when the caller has it; the status alone decides otherwise.
  static bool countsAsCollected(String status, {String kind = ''}) {
    if (kind == 'ADVANCE') return false;
    final s = status.trim();
    return s != CollectionStatusColors.statusAdvance &&
        s != CollectionStatusColors.statusDeposit;
  }
}
