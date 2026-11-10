import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_notification_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_clock.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_status_style.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_evaluation.dart';

/// One case as the scheduler reads it (the shape of `ReconCaseView.asRecord`).
typedef ReconReminderCase = ({ReconCaseBundle bundle, ReconEvaluation evaluation});

/// A morning reminder for one case's follow up.
class ReconReminder {
  const ReconReminder({
    required this.id,
    required this.caseId,
    required this.wallClock,
    required this.title,
    required this.body,
  });

  final int id;
  final String caseId;

  /// Manila wall-clock time to show it at.
  final DateTime wallClock;
  final String title;
  final String body;

  String get payload => ReconReminderScheduler.payloadFor(caseId);
}

/// Phone reminders for reconciliation follow ups
/// (docs/application/COLLECTION_RECON_FOLLOWUP_REMINDERS_PLAN.md, Phase 3).
///
/// Nothing is stored here: the reminders are a projection of the collector's
/// open cases. [sync] runs after every load of the cases, schedules one
/// notification at 08:00 Manila on each case's next-action due day, and
/// cancels the ones no longer wanted (logged, released, closed, moved, or
/// reminders turned off). The phone's own list of pending notifications is
/// the record of what was scheduled.
class ReconReminderScheduler {
  ReconReminderScheduler({
    required INotificationService? Function() notifications,
    required bool Function() enabled,
  })  : _notifications = notifications,
        _enabled = enabled;

  final INotificationService? Function() _notifications;
  final bool Function() _enabled;

  static const String payloadPrefix = 'recon-case:';
  static const String channelId = 'recon_followups';
  static const String channelName = 'Reconciliation follow ups';

  /// The hour (Manila) the reminder shows on the due day.
  static const int hour = 8;

  static String payloadFor(String caseId) => '$payloadPrefix$caseId';

  /// The case a reminder's payload points at; null for any other payload.
  static String? caseIdFrom(String? payload) {
    if (payload == null || !payload.startsWith(payloadPrefix)) return null;
    final id = payload.substring(payloadPrefix.length).trim();
    return id.isEmpty ? null : id;
  }

  /// A notification id for [caseId] that is the same on every run (String
  /// hashCode is not), kept in its own range (bit 30 set) so it never meets
  /// the small ids other notifications use.
  static int idFor(String caseId) {
    var h = 0x811c9dc5;
    for (final unit in caseId.codeUnits) {
      h = ((h ^ unit) * 0x01000193) & 0xffffffff;
    }
    return 0x40000000 | (h & 0x3fffffff);
  }

  /// The reminders [cases] call for at [now]: one per open case with a next
  /// action due today or later, at 08:00 Manila on the due day. One due
  /// today whose 08:00 has passed gets none (the collector has just set it,
  /// or the dashboard and calendar already show it).
  static List<ReconReminder> plan(
      Iterable<ReconReminderCase> cases, DateTime now) {
    final wallNow = BReconClock.fromInstant(now);
    return [
      for (final (:bundle, :evaluation) in cases)
        if (_wantsReminder(evaluation))
          if (_at(evaluation.nextActionDue!) case final at
              when at.isAfter(wallNow))
            ReconReminder(
              id: idFor(bundle.caseId),
              caseId: bundle.caseId,
              wallClock: at,
              title: 'Follow up today: ${bundle.reconCase.clientName}',
              body: '${BReconStyle.nextActionText(evaluation)} · '
                  '${evaluation.openInvoices.length} open · '
                  '${BFormatter.formatPesoCurrency(evaluation.amountUnderReconciliation)}',
            ),
    ];
  }

  static bool _wantsReminder(ReconEvaluation e) =>
      !e.isClosed &&
      e.nextActionDue != null &&
      e.dueState != ReconDueState.none &&
      e.dueState != ReconDueState.overdue;

  static DateTime _at(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day, hour);

  Future<void>? _running;
  List<ReconReminderCase>? _next;
  DateTime? _nextNow;

  /// Bring the phone's reminders in line with [mine] (the collector's open
  /// cases) at [now]. Calls that arrive while one runs are folded into a
  /// single follow-up run with the latest cases. Never throws.
  Future<void> sync(Iterable<ReconReminderCase> mine, DateTime now) {
    _next = mine.toList();
    _nextNow = now;
    return _running ??= _drain();
  }

  Future<void> _drain() async {
    try {
      while (_next != null) {
        final cases = _next!;
        final now = _nextNow!;
        _next = null;
        await _syncOnce(cases, now);
      }
    } finally {
      _running = null;
    }
  }

  Future<void> _syncOnce(List<ReconReminderCase> mine, DateTime now) async {
    final service = _notifications();
    if (service == null || !service.canSchedule) return;
    try {
      final wanted = _enabled() ? plan(mine, now) : const <ReconReminder>[];
      final keep = {for (final r in wanted) r.id};
      for (final p in await service.pending()) {
        if (caseIdFrom(p.payload) != null && !keep.contains(p.id)) {
          await service.cancel(p.id);
        }
      }
      // Scheduled again every time: same id replaces, so a moved date or a
      // changed amount is picked up without tracking what was there.
      for (final r in wanted) {
        await service.scheduleAt(
          id: r.id,
          title: r.title,
          body: r.body,
          wallClock: r.wallClock,
          channelId: channelId,
          channelName: channelName,
          payload: r.payload,
        );
      }
    } catch (e) {
      logDebug('ReconReminderScheduler: sync failed: $e');
    }
  }
}
