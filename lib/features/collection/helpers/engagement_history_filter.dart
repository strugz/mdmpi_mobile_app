import 'package:mdmpi_mobile_app/features/collection/helpers/collection_outcome.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

/// The three sections of the status filter sheet.
enum EngagementStatusGroup {
  payments('Payments'),
  office('Office activities'),
  visits('Visits without payment');

  const EngagementStatusGroup(this.label);
  final String label;
}

/// The statuses Engagement History filters by, in the order the filter
/// sheet shows them: payments, then office activities, then visits that
/// collected nothing (the four deferral reasons among them).
///
/// Every status a history entry can carry lands on exactly one of these;
/// anything unrecognised reads as Others. A reconciliation that an outcome
/// finished is also listed under Reconciliation.
enum EngagementStatus {
  collected('Collected', EngagementStatusGroup.payments,
      {CollectionStatusColors.statusCollected}),
  partial('Partial Payment', EngagementStatusGroup.payments,
      {CollectionStatusColors.statusPartial}),
  advance('Advance Payment', EngagementStatusGroup.payments,
      {CollectionStatusColors.statusAdvance}),
  advanceApplied('Advance Applied', EngagementStatusGroup.payments,
      {CollectionStatusColors.statusAdvanceApplied}),
  deposit('Deposit', EngagementStatusGroup.office,
      {CollectionStatusColors.statusDeposit}),
  cwt('CWT Pick-up', EngagementStatusGroup.office,
      {CollectionStatusColors.statusCWTPickup}),
  reconciliation('Reconciliation', EngagementStatusGroup.office,
      {CollectionStatusColors.statusReconciliation}),
  followUp('Follow Up', EngagementStatusGroup.visits,
      {CollectionStatusColors.statusFollowUp}),
  preCollection('Pre-Collection', EngagementStatusGroup.visits,
      {CollectionStatusColors.statusPreCollection}),
  unavailable('Customer Unavailable', EngagementStatusGroup.visits,
      {CollectionStatusColors.statusUnavailable}),
  refused('Refused to Pay', EngagementStatusGroup.visits,
      {CollectionStatusColors.statusRefused}),
  others('Others', EngagementStatusGroup.visits,
      {CollectionStatusColors.statusOthers});

  const EngagementStatus(this.label, this.group, this.statuses);

  /// What the chip says.
  final String label;

  /// The sheet section it sits in.
  final EngagementStatusGroup group;

  /// The stored statuses this filter matches.
  final Set<String> statuses;
}

/// Filtering and totals over the entry maps
/// `CollectionActivityController.activitiesByDate` builds ('history',
/// 'accountName', 'invoiceId', 'item', 'kind', 'reconciledOn').
class EngagementHistoryFilter {
  EngagementHistoryFilter._();

  static CollectionHistoryModel _history(Map<String, dynamic> e) =>
      e['history'] as CollectionHistoryModel;

  /// The statuses [e] is listed under: its own, plus Reconciliation when an
  /// outcome finished one. Never empty.
  static Set<EngagementStatus> statusesOf(Map<String, dynamic> e) {
    final status = _history(e).status.trim();
    final kind = e['kind'] as String? ?? '';

    final own = kind == 'ADVANCE'
        ? EngagementStatus.advance
        : EngagementStatus.values.firstWhere((s) => s.statuses.contains(status),
            orElse: () => EngagementStatus.others);

    return {
      own,
      if ((e['reconciledOn'] as String?) != null)
        EngagementStatus.reconciliation,
    };
  }

  /// Case-insensitive match on the account, the invoice number or its P.O.
  static bool matchesQuery(Map<String, dynamic> e, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final item = e['item'] as CollectionItemModel?;
    final fields = [
      e['accountName']?.toString() ?? '',
      e['invoiceId']?.toString() ?? '',
      item?.poNumber ?? '',
    ];
    return fields.any((f) => f.toLowerCase().contains(q));
  }

  /// [entries] narrowed to any of [statuses] (empty: every status) and to
  /// [query].
  static List<Map<String, dynamic>> apply(
    List<Map<String, dynamic>> entries, {
    Set<EngagementStatus> statuses = const {},
    String query = '',
  }) =>
      entries
          .where(
              (e) => statuses.isEmpty || statusesOf(e).any(statuses.contains))
          .where((e) => matchesQuery(e, query))
          .toList();

  /// How many of [entries] each status holds; every status is present, at
  /// zero when none.
  static Map<EngagementStatus, int> counts(List<Map<String, dynamic>> entries) {
    final counts = {for (final s in EngagementStatus.values) s: 0};
    for (final e in entries) {
      for (final s in statusesOf(e)) {
        counts[s] = counts[s]! + 1;
      }
    }
    return counts;
  }

  /// Money collected across [entries], by the one rule every total uses: an
  /// advance received, a deposit, a CWT pick-up and a reconciliation add
  /// nothing.
  static double collected(List<Map<String, dynamic>> entries) => entries
      .where((e) => CollectionOutcome.countsAsCollected(_history(e).status,
          kind: e['kind'] as String? ?? ''))
      .fold(0.0, (sum, e) => sum + _history(e).totalCollected);
}
