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

  factory ReconSummary.of(Iterable<ReconEvaluation> cases) {
    var total = 0, open = 0, completed = 0, notCompleted = 0, escalated = 0;
    var under = 0.0, validated = 0.0;
    final aging = {for (final b in ReconAgingBucket.values) b: 0};
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
          final bucket = ReconAgingBucket.forDays(e.daysOpen);
          aging[bucket] = aging[bucket]! + 1;
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
    );
  }
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
