import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_notification_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_reminder_scheduler.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';

import 'recon_test_data.dart';

/// Phone reminders for follow ups
/// (docs/application/COLLECTION_RECON_FOLLOWUP_REMINDERS_PLAN.md, Phase 3):
/// 08:00 Manila on the due day, kept in line with the cases on every sync,
/// and never touching other notifications.

typedef T = ReconActivityType;

class _Scheduled {
  _Scheduled(this.id, this.title, this.body, this.wallClock, this.payload);
  final int id;
  final String title;
  final String body;
  final DateTime wallClock;
  final String? payload;
}

class _FakeNotifications implements INotificationService {
  _FakeNotifications({this.canSchedule = true});

  @override
  final bool canSchedule;

  final scheduled = <int, _Scheduled>{};
  final cancelled = <int>[];

  @override
  Future<bool> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime wallClock,
    required String channelId,
    required String channelName,
    String timeZone = 'Asia/Manila',
    String? payload,
    bool daily = false,
  }) async {
    expect(channelId, ReconReminderScheduler.channelId);
    expect(timeZone, 'Asia/Manila');
    scheduled[id] = _Scheduled(id, title, body, wallClock, payload);
    return true;
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
  }

  @override
  Future<List<PendingNotification>> pending() async => [
        for (final s in scheduled.values) (id: s.id, payload: s.payload),
      ];

  @override
  Future<void> init({void Function(String? payload)? onSelectNotification}) async {}

  @override
  Future<void> showSimple(
      {required int id,
      required String title,
      required String body,
      String? payload}) async {}

  @override
  Future<void> showNow(
      {required int id,
      required String title,
      required String body,
      required String channelId,
      required String channelName,
      String? payload}) async {}

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<void> cancelAll() async => scheduled.clear();
}

ReconReminderCase _case(String id, List<ReconActivity> steps,
    {String now = '2026-09-18T07:00:00', String client = 'Accusure'}) {
  final bundle = ReconCaseBundle(
    reconCase: ReconCase(
        caseId: id,
        clientCode: 'C-$id',
        clientName: client,
        collectorCode: 'JCA',
        dateOpened: '2026-09-01T09:00:00'),
    invoices: threeInvoices,
    activities: steps,
  );
  return (bundle: bundle, evaluation: evaluate(steps, now: now));
}

void main() {
  const now = '2026-09-18T07:00:00';
  final soaDue20 = step(T.soaSent, '2026-09-10T09:00:00',
      due: '2026-09-20', action: 'Visit to follow up on SOA');

  group('plan', () {
    test('08:00 Manila on the due day, with what to do and what is owed', () {
      final r = ReconReminderScheduler.plan(
              [_case('RC-1', [soaDue20], client: "5'R's Medical Supply")],
              phInstant(now))
          .single;
      expect(r.wallClock, DateTime.utc(2026, 9, 20, 8));
      expect(r.title, "Follow up today: 5'R's Medical Supply");
      expect(r.body, 'Visit to follow up on SOA · 3 open · ₱60,000.00');
      expect(r.payload, 'recon-case:RC-1');
      expect(r.id, ReconReminderScheduler.idFor('RC-1'));
    });

    test('due today: before 08:00 yes, after 08:00 no', () {
      final dueToday = step(T.soaSent, '2026-09-10T09:00:00', due: '2026-09-18');
      expect(
          ReconReminderScheduler.plan(
              [_case('RC-1', [dueToday])], phInstant('2026-09-18T07:59:00')),
          hasLength(1));
      expect(
          ReconReminderScheduler.plan(
              [_case('RC-1', [dueToday])], phInstant('2026-09-18T08:01:00')),
          isEmpty);
    });

    test('none for overdue, no date, or a closed case', () {
      final overdue = step(T.soaSent, '2026-09-10T09:00:00', due: '2026-09-15');
      final noDate = step(T.soaSent, '2026-09-10T09:00:00');
      final closed = [
        soaDue20,
        step(T.caseNotCompleted, '2026-09-12T09:00:00'),
      ];
      expect(
          ReconReminderScheduler.plan([
            _case('RC-1', [overdue]),
            _case('RC-2', [noDate]),
            _case('RC-3', closed),
          ], phInstant(now)),
          isEmpty);
    });

    test('the id is the same on every run, and out of the small range', () {
      final id = ReconReminderScheduler.idFor('RC-JCABAOAG-1791882979712550');
      expect(id, ReconReminderScheduler.idFor('RC-JCABAOAG-1791882979712550'));
      expect(id, isNot(ReconReminderScheduler.idFor('RC-JCABAOAG-1')));
      expect(id, greaterThanOrEqualTo(0x40000000));
      expect(id, lessThan(0x80000000));
    });

    test('a tap payload names its case; other payloads do not', () {
      expect(ReconReminderScheduler.caseIdFrom('recon-case:RC-1'), 'RC-1');
      expect(ReconReminderScheduler.caseIdFrom('voucher-reread:C-1'), isNull);
      expect(ReconReminderScheduler.caseIdFrom(null), isNull);
      expect(ReconReminderScheduler.caseIdFrom('recon-case:'), isNull);
    });
  });

  group('sync', () {
    late _FakeNotifications phone;
    late bool enabled;
    late ReconReminderScheduler scheduler;

    setUp(() {
      phone = _FakeNotifications();
      enabled = true;
      scheduler = ReconReminderScheduler(
          notifications: () => phone, enabled: () => enabled);
    });

    test('schedules what is due and leaves other notifications alone',
        () async {
      phone.scheduled[7] = _Scheduled(
          7, 'Voucher', '', DateTime.utc(2026, 9, 19), 'voucher-reread:C-1');
      await scheduler.sync([_case('RC-1', [soaDue20])], phInstant(now));
      expect(phone.scheduled.keys,
          containsAll([7, ReconReminderScheduler.idFor('RC-1')]));
      expect(phone.cancelled, isEmpty);
    });

    test('logging the follow up cancels its reminder', () async {
      await scheduler.sync([_case('RC-1', [soaDue20])], phInstant(now));
      final followedUp = _case('RC-1', [
        soaDue20,
        step(T.followUp, '2026-09-18T06:00:00'),
      ]);
      await scheduler.sync([followedUp], phInstant(now));
      expect(phone.scheduled, isEmpty);
      expect(phone.cancelled, [ReconReminderScheduler.idFor('RC-1')]);
    });

    test('a case that is no longer mine loses its reminder', () async {
      await scheduler.sync([_case('RC-1', [soaDue20])], phInstant(now));
      await scheduler.sync(const [], phInstant(now));
      expect(phone.scheduled, isEmpty);
    });

    test('a moved date is scheduled again under the same id', () async {
      await scheduler.sync([_case('RC-1', [soaDue20])], phInstant(now));
      final moved = _case('RC-1', [
        soaDue20,
        step(T.followUp, '2026-09-18T06:00:00', due: '2026-09-25'),
      ]);
      await scheduler.sync([moved], phInstant(now));
      expect(phone.scheduled.values.single.wallClock,
          DateTime.utc(2026, 9, 25, 8));
    });

    test('turned off: every follow-up reminder is cancelled', () async {
      await scheduler.sync([_case('RC-1', [soaDue20])], phInstant(now));
      enabled = false;
      await scheduler.sync([_case('RC-1', [soaDue20])], phInstant(now));
      expect(phone.scheduled, isEmpty);
    });

    test('a phone that cannot schedule is left untouched', () async {
      phone = _FakeNotifications(canSchedule: false);
      await scheduler.sync([_case('RC-1', [soaDue20])], phInstant(now));
      expect(phone.scheduled, isEmpty);
    });

    test('calls during a run fold into one more run with the latest cases',
        () async {
      final first =
          scheduler.sync([_case('RC-1', [soaDue20])], phInstant(now));
      final second = scheduler.sync(
          [_case('RC-2', [soaDue20], client: 'Other')], phInstant(now));
      expect(identical(first, second), isTrue);
      await second;
      expect(phone.scheduled.keys, [ReconReminderScheduler.idFor('RC-2')]);
    });
  });
}
