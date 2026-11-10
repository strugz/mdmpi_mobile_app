import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_notification_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_notification_router.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/upload_reminder.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/unfinished/unfinished_requests_reminder.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/unfinished/unfinished_request.dart';

/// The 08:00 "unfinished requests" notification: daily while anything is
/// unfinished, with the counts; cancelled at zero or when switched off; a
/// tap opens the list.

class _Phone implements INotificationService {
  _Phone({this.canSchedule = true, this.throwOnSchedule = false});

  @override
  final bool canSchedule;
  final bool throwOnSchedule;

  final scheduled = <({
    int id,
    String title,
    String body,
    DateTime at,
    bool daily,
    String? payload,
    String channel,
  })>[];
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
    if (throwOnSchedule) throw StateError('no plugin');
    scheduled.add((
      id: id,
      title: title,
      body: body,
      at: wallClock,
      daily: daily,
      payload: payload,
      channel: channelId,
    ));
    return true;
  }

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Future<List<PendingNotification>> pending() async => const [];

  @override
  Future<void> init(
      {void Function(String? payload)? onSelectNotification}) async {}

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
  Future<void> cancelAll() async {}
}

DateTime _manila(String wall) => DateTime.parse('$wall+08:00');

UnfinishedSummary _summary(int standard, int pullOut) => UnfinishedSummary([
      for (var i = 0; i < standard; i++)
        UnfinishedRequest(
            type: FormCategoryType.standardDelivery,
            id: 'sd$i',
            client: '',
            status: 'For Delivery',
            createdAt: ''),
      for (var i = 0; i < pullOut; i++)
        UnfinishedRequest(
            type: FormCategoryType.pullOutReturn,
            id: 'po$i',
            client: '',
            status: 'For Pull Out',
            createdAt: ''),
    ]);

void main() {
  BUnfinishedRequestsReminder reminder(_Phone phone,
          {bool on = true, String now = '2026-10-21T07:00:00'}) =>
      BUnfinishedRequestsReminder(
        notifications: () => phone,
        enabled: () => on,
        now: () => _manila(now),
      );

  group('nextAt', () {
    test('08:00 Manila today before 8, tomorrow from 8 on', () {
      expect(BUnfinishedRequestsReminder.nextAt(_manila('2026-10-21T07:59:00')),
          DateTime.utc(2026, 10, 21, 8));
      expect(BUnfinishedRequestsReminder.nextAt(_manila('2026-10-21T08:00:00')),
          DateTime.utc(2026, 10, 22, 8));
      expect(BUnfinishedRequestsReminder.nextAt(_manila('2026-10-21T23:30:00')),
          DateTime.utc(2026, 10, 22, 8));
    });
  });

  group('sync', () {
    test('schedules a daily 08:00 notification with the counts', () async {
      final phone = _Phone();
      await reminder(phone).sync(_summary(3, 2));
      final s = phone.scheduled.single;
      expect(s.id, BUnfinishedRequestsReminder.id);
      expect(s.at, DateTime.utc(2026, 10, 21, 8));
      expect(s.daily, isTrue);
      expect(s.payload, BUnfinishedRequestsReminder.payload);
      expect(s.channel, BUnfinishedRequestsReminder.channelId);
      expect(s.title, '5 unfinished requests');
      expect(s.body, 'Standard Delivery 3 · Pull Out 2. Tap to see them.');
    });

    test('cancels when nothing is unfinished', () async {
      final phone = _Phone();
      await reminder(phone).sync(UnfinishedSummary.empty);
      expect(phone.scheduled, isEmpty);
      expect(phone.cancelled, [BUnfinishedRequestsReminder.id]);
    });

    test('cancels when switched off', () async {
      final phone = _Phone();
      await reminder(phone, on: false).sync(_summary(1, 0));
      expect(phone.scheduled, isEmpty);
      expect(phone.cancelled, [BUnfinishedRequestsReminder.id]);
    });

    test('does nothing where it cannot schedule (Windows)', () async {
      final phone = _Phone(canSchedule: false);
      await reminder(phone).sync(_summary(1, 0));
      expect(phone.scheduled, isEmpty);
      expect(phone.cancelled, isEmpty);
    });

    test('never throws', () async {
      await reminder(_Phone(throwOnSchedule: true)).sync(_summary(1, 0));
      await BUnfinishedRequestsReminder(
              notifications: () => null, enabled: () => true)
          .sync(_summary(1, 0));
    });

    test('calls made while one runs fold into one more, with the latest',
        () async {
      final phone = _Phone();
      final r = reminder(phone);
      await Future.wait([
        r.sync(_summary(1, 0)),
        r.sync(_summary(2, 0)),
        r.sync(_summary(3, 0)),
      ]);
      expect(phone.scheduled.length, 2);
      expect(phone.scheduled.last.title, '3 unfinished requests');
    });

    test('its id and payload stay apart from the Collection reminders', () {
      expect(BUnfinishedRequestsReminder.id, isNot(BUploadReminder.id));
      expect(BUnfinishedRequestsReminder.id & (1 << 30), 0);
      expect(BUnfinishedRequestsReminder.payload,
          isNot(BUploadReminder.payload));
    });
  });

  group('showNow', () {
    test('shows with the counts when something is unfinished', () async {
      expect(await reminder(_Phone()).showNow(_summary(1, 1)), isTrue);
    });

    test('not with nothing unfinished, switched off, or on Windows',
        () async {
      expect(await reminder(_Phone()).showNow(UnfinishedSummary.empty),
          isFalse);
      expect(await reminder(_Phone(), on: false).showNow(_summary(1, 0)),
          isFalse);
      expect(
          await reminder(_Phone(canSchedule: false)).showNow(_summary(1, 0)),
          isFalse);
    });

    test('its own id, so it never replaces the 08:00 one', () {
      expect(BUnfinishedRequestsReminder.nowId,
          isNot(BUnfinishedRequestsReminder.id));
    });
  });

  test('a tap opens the Unfinished requests list', () {
    final to = BCollectionNotificationRouter.destinationFor(
        BUnfinishedRequestsReminder.payload);
    expect(to?.route, BRoutes.unfinishedRequests);
    expect(to?.arguments, isNull);
  });
}
