import 'dart:convert';

import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_pending_dao.dart';

/// What discarding queued changes must also remove from this phone, so the
/// work does not go on showing on other screens after it was thrown away.
///
/// Read from the queue itself, so it matches exactly and never reaches work
/// already uploaded (that has no queued change left):
/// - every Collection write archives its engagement at the same stamp it
///   queues as `EngagementDate`, so those stamps find the calendar and report
///   rows;
/// - RECON_OPEN_CASE is queued under its case id, RECON_ACTIVITY under its
///   step id.
///
/// Invoices, claims, advances, office activities and account history are not
/// listed: the bucket download that follows replaces them with the server's.
class PendingDiscardPlan {
  const PendingDiscardPlan({
    this.engagedAts = const {},
    this.caseIds = const {},
    this.activityIds = const {},
  });

  /// `EngagementDate` stamps of the discarded Collection changes.
  final Set<String> engagedAts;

  /// Cases opened on this phone and never uploaded.
  final Set<String> caseIds;

  /// Reconciliation steps logged on this phone and never uploaded.
  final Set<String> activityIds;

  bool get isEmpty =>
      engagedAts.isEmpty && caseIds.isEmpty && activityIds.isEmpty;

  static const openCase = 'RECON_OPEN_CASE';
  static const reconStep = 'RECON_ACTIVITY';

  factory PendingDiscardPlan.from(Iterable<PendingChange> changes) {
    final engagedAts = <String>{};
    final caseIds = <String>{};
    final activityIds = <String>{};
    for (final c in changes) {
      final id = (c.itemId ?? '').trim();
      switch (c.operation) {
        case openCase:
          if (id.isNotEmpty) caseIds.add(id);
        case reconStep:
          if (id.isNotEmpty) activityIds.add(id);
        default:
          final stamp = _engagementDate(c.payload);
          if (stamp != null) engagedAts.add(stamp);
      }
    }
    return PendingDiscardPlan(
        engagedAts: engagedAts, caseIds: caseIds, activityIds: activityIds);
  }

  static String? _engagementDate(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      final stamp = decoded['EngagementDate']?.toString().trim() ?? '';
      return stamp.isEmpty ? null : stamp;
    } catch (_) {
      return null;
    }
  }
}
