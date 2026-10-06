import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';

/// Result of matching Reconciliation rows to the outcomes that finished them
/// across the engagement archive. See
/// `CollectionActivityController.reconciliationMerge`.
class ReconciliationMerge {
  const ReconciliationMerge(
      {required this.finished, required this.reconciledOn});

  /// localRefs of Reconciliation rows an outcome has finished.
  final Set<String> finished;

  /// outcome localRef -> engagedAt of the reconciliation it finished.
  final Map<String, String> reconciledOn;
}

/// One entry of an invoice's history after finished reconciliations have
/// been folded into the outcomes that finished them.
class FoldedHistoryEntry {
  const FoldedHistoryEntry(this.history, this.reconciledOn);
  final CollectionHistoryModel history;
  final String? reconciledOn;
}

/// The same rule as `CollectionActivityController.reconciliationMerge`, for
/// a single invoice's history: a Reconciliation entry followed by an outcome
/// is dropped and the outcome carries its date; a reconciliation nothing
/// has finished stays. Order of the input is preserved.
///
/// Pure. Callers fold once when they assemble history for display (the
/// controller's history getters do); widgets render the folded result and
/// never fold themselves.
List<FoldedHistoryEntry> foldFinishedReconciliations(
    List<CollectionHistoryModel> history) {
  final dated = <(DateTime, int)>[];
  for (var i = 0; i < history.length; i++) {
    final at = BFormatter.parseLocal(history[i].date);
    if (at != null) dated.add((at, i));
  }
  dated.sort((a, b) => a.$1.compareTo(b.$1));

  final drop = <int>{};
  final reconciledOn = <int, String>{};
  int? open;
  for (final (_, i) in dated) {
    if (history[i].status == 'Reconciliation') {
      open = i;
      continue;
    }
    if (open != null) {
      drop.add(open);
      reconciledOn[i] = history[open].date;
      open = null;
    }
  }

  return [
    for (var i = 0; i < history.length; i++)
      if (!drop.contains(i)) FoldedHistoryEntry(history[i], reconciledOn[i]),
  ];
}
