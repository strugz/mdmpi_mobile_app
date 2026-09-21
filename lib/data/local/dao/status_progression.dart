/// Shared lookup for the per-module status progression maps used by the DAOs.
///
/// Each module keeps its own ordinal map because the stage order differs, but
/// they all resolve a status string the same way: case-insensitively.
///
/// Case matters here because the same stage is spelled differently in
/// different places — `BTexts.statusGettingSuppliesReady` is
/// "Getting supplies ready" while the DAO maps were written
/// "Getting Supplies Ready". An exact-match lookup silently returned null for
/// that stage, which disabled the progression guard for it entirely: any
/// status could overwrite a row sitting in that stage, and that row could
/// overwrite anything.
class BStatusProgression {
  BStatusProgression._();

  /// Ordinal for [status] in [ranks], or null when the status is unknown.
  ///
  /// A null result means the guard cannot compare the two statuses and the
  /// caller must let the write through.
  static int? rank(Map<String, int> ranks, String? status) {
    if (status == null) return null;

    final needle = status.trim().toLowerCase();
    if (needle.isEmpty) return null;

    for (final entry in ranks.entries) {
      if (entry.key.toLowerCase() == needle) return entry.value;
    }

    return null;
  }

  /// Whether writing [next] over [current] would regress the status.
  ///
  /// Unknown statuses on either side return false: the guard only blocks a
  /// write it can positively prove is a regression. Cancelling is never a
  /// regression.
  static bool isRegression({
    required Map<String, int> ranks,
    required String? current,
    required String? next,
    String cancelledStatus = 'Cancelled',
  }) {
    if ((next ?? '').trim().toLowerCase() == cancelledStatus.toLowerCase()) {
      return false;
    }

    final currentRank = rank(ranks, current);
    final nextRank = rank(ranks, next);
    if (currentRank == null || nextRank == null) return false;

    return nextRank < currentRank;
  }
}
