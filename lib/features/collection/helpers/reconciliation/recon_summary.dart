import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_evaluation.dart';

/// How long an open case has been open, in calendar days.
enum ReconAgingBucket {
  upTo7('0–7 days', 0, 7),
  upTo15('8–15 days', 8, 15),
  upTo30('16–30 days', 16, 30),
  over30('31+ days', 31, null);

  const ReconAgingBucket(this.label, this.minDays, this.maxDays);

  final String label;
  final int minDays;

  /// Null for the open-ended last bucket.
  final int? maxDays;

  static ReconAgingBucket forDays(int days) {
    for (final b in values) {
      if (days >= b.minDays && (b.maxDays == null || days <= b.maxDays!)) {
        return b;
      }
    }
    return upTo7; // a negative age (a clock ahead of the server) is new
  }
}

/// The Summary report over a set of cases.
class ReconSummary {
  const ReconSummary({
    required this.totalCases,
    required this.open,
    required this.completed,
    required this.notCompleted,
    required this.escalated,
    required this.amountUnderReconciliation,
    required this.amountValidatedPaid,
    required this.aging,
    required this.agingAmount,
    required this.openByStatus,
    required this.flagged,
    required this.needsAttention,
  });

  final int totalCases;
  final int open;
  final int completed;
  final int notCompleted;
  final int escalated;

  /// Still owed on the open cases' unsettled invoices.
  final double amountUnderReconciliation;

  /// Validated paid on any case, waiting for Accounting to post it.
  final double amountValidatedPaid;

  /// Open cases per aging bucket, every bucket present.
  final Map<ReconAgingBucket, int> aging;

  /// Still owed on the open cases in each aging bucket, every bucket present.
  final Map<ReconAgingBucket, double> agingAmount;

  /// Open cases by where they stand (the three open statuses, every one
  /// present): whose turn it is across the set.
  final Map<ReconCaseStatus, int> openByStatus;

  /// Open cases carrying each flag, every flag present. A case with two
  /// flags counts under both.
  final Map<ReconFlag, int> flagged;

  /// Open cases carrying at least one flag.
  final int needsAttention;

  /// The open statuses, in the order the reports show them.
  static const openStatuses = [
    ReconCaseStatus.waitingForCollector,
    ReconCaseStatus.waitingForAccount,
    ReconCaseStatus.underValidation,
  ];

  factory ReconSummary.of(Iterable<ReconEvaluation> cases) {
    var total = 0, open = 0, completed = 0, notCompleted = 0, escalated = 0;
    var under = 0.0, validated = 0.0, attention = 0;
    final aging = {for (final b in ReconAgingBucket.values) b: 0};
    final agingAmount = {for (final b in ReconAgingBucket.values) b: 0.0};
    final byStatus = {for (final s in openStatuses) s: 0};
    final flagged = {for (final f in ReconFlag.values) f: 0};
    for (final e in cases) {
      total++;
      validated += e.amountValidatedPaid;
      switch (e.status) {
        case ReconCaseStatus.completed:
          completed++;
        case ReconCaseStatus.notCompleted:
          notCompleted++;
        case ReconCaseStatus.escalated:
          escalated++;
        case ReconCaseStatus.waitingForCollector:
        case ReconCaseStatus.waitingForAccount:
        case ReconCaseStatus.underValidation:
          open++;
          under += e.amountUnderReconciliation;
          byStatus[e.status] = byStatus[e.status]! + 1;
          final bucket = ReconAgingBucket.forDays(e.daysOpen);
          aging[bucket] = aging[bucket]! + 1;
          agingAmount[bucket] =
              agingAmount[bucket]! + e.amountUnderReconciliation;
          if (e.flags.isNotEmpty) attention++;
          for (final f in e.flags) {
            flagged[f] = flagged[f]! + 1;
          }
      }
    }
    return ReconSummary(
      totalCases: total,
      open: open,
      completed: completed,
      notCompleted: notCompleted,
      escalated: escalated,
      amountUnderReconciliation: under,
      amountValidatedPaid: validated,
      aging: aging,
      agingAmount: agingAmount,
      openByStatus: byStatus,
      flagged: flagged,
      needsAttention: attention,
    );
  }
}

/// One collector's share of a set of cases (the team report).
class ReconCollectorSummary {
  const ReconCollectorSummary({
    required this.collectorCode,
    required this.collectorName,
    required this.open,
    required this.needsAttention,
    required this.closed,
    required this.amountUnderReconciliation,
  });

  /// Empty when the case has no holder (released, not yet acquired).
  final String collectorCode;
  final String collectorName;
  final int open;

  /// Open cases with at least one flag.
  final int needsAttention;
  final int closed;
  final double amountUnderReconciliation;

  String get label => collectorName.trim().isNotEmpty
      ? collectorName.trim()
      : collectorCode.trim().isNotEmpty
          ? collectorCode.trim()
          : 'No holder';
}

/// Who holds what: one row per collector (and one for cases with no holder),
/// the most open cases first, then the most owed.
List<ReconCollectorSummary> reconByCollector(
    Iterable<({ReconCaseBundle bundle, ReconEvaluation evaluation})> cases) {
  final open = <String, int>{};
  final attention = <String, int>{};
  final closed = <String, int>{};
  final under = <String, double>{};
  final names = <String, String>{};
  for (final (:bundle, :evaluation) in cases) {
    final code = bundle.reconCase.collectorCode.trim().toUpperCase();
    final name = bundle.reconCase.collectorName.trim();
    if (name.isNotEmpty || !names.containsKey(code)) names[code] = name;
    if (evaluation.isClosed) {
      closed[code] = (closed[code] ?? 0) + 1;
      continue;
    }
    open[code] = (open[code] ?? 0) + 1;
    under[code] = (under[code] ?? 0) + evaluation.amountUnderReconciliation;
    if (evaluation.flags.isNotEmpty) {
      attention[code] = (attention[code] ?? 0) + 1;
    }
  }
  return [
    for (final code in names.keys)
      ReconCollectorSummary(
        collectorCode: code,
        collectorName: names[code] ?? '',
        open: open[code] ?? 0,
        needsAttention: attention[code] ?? 0,
        closed: closed[code] ?? 0,
        amountUnderReconciliation: under[code] ?? 0,
      ),
  ]..sort((a, b) {
      final byOpen = b.open.compareTo(a.open);
      if (byOpen != 0) return byOpen;
      final byAmount =
          b.amountUnderReconciliation.compareTo(a.amountUnderReconciliation);
      if (byAmount != 0) return byAmount;
      return a.label.compareTo(b.label);
    });
}

/// The collector dashboard's order: open cases first, the one untouched
/// longest at the top, so the case most likely forgotten is seen first; then
/// the closed ones, the latest first (history).
int compareForReconDashboard(ReconEvaluation a, ReconEvaluation b) {
  if (a.isClosed != b.isClosed) return a.isClosed ? 1 : -1;
  return a.isClosed
      ? a.daysSinceLastActivity.compareTo(b.daysSinceLastActivity)
      : b.daysSinceLastActivity.compareTo(a.daysSinceLastActivity);
}
