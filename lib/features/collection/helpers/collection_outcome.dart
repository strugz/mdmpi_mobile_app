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
}
