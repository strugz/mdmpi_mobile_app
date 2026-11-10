import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_notification_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_notification_router.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/upload_reminder.dart';

/// The 17:00 "upload your collections" nudge: on while anything is queued,
/// daily, off once the queue is empty; a tap opens Upload Collections.

class _Phone implements INotificationService {
  _Phone({this.canSchedule = true});

  @override
  final bool canSchedule;

  ({
    int id,
    DateTime at,
    bool daily,
    String? payload,
    String channel
  })? scheduled;
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
    scheduled = (
      id: id,
      at: wallClock,
      daily: daily,
      payload: payload,
      channel: channelId
    );
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

void main() {
  test('the next 17:00 Manila: today before it, tomorrow after it', () {
    expect(BUploadReminder.nextAt(_manila('2026-10-14T09:00:00')),
        DateTime.utc(2026, 10, 14, 17));
    expect(BUploadReminder.nextAt(_manila('2026-10-14T17:00:01')),
        DateTime.utc(2026, 10, 15, 17));
    expect(BUploadReminder.nextAt(_manila('2026-10-31T23:30:00')),
        DateTime.utc(2026, 11, 1, 17));
  });

  test('work waiting: a daily reminder on its own channel', () async {
    final phone = _Phone();
    await BUploadReminder(
        notifications: () => phone,
        now: () => _manila('2026-10-14T09:00:00')).sync(3);
    final s = phone.scheduled!;
    expect(s.id, BUploadReminder.id);
    expect(s.at, DateTime.utc(2026, 10, 14, 17));
    expect(s.daily, isTrue);
    expect(s.payload, BUploadReminder.payload);
    expect(s.channel, BUploadReminder.channelId);
  });

  test('nothing waiting: the reminder is cancelled', () async {
    final phone = _Phone();
    await BUploadReminder(notifications: () => phone).sync(0);
    expect(phone.cancelled, [BUploadReminder.id]);
    expect(phone.scheduled, isNull);
  });

  test('a phone that cannot schedule is left alone', () async {
    final phone = _Phone(canSchedule: false);
    await BUploadReminder(notifications: () => phone).sync(3);
    expect(phone.scheduled, isNull);
    expect(phone.cancelled, isEmpty);
  });

  test('a tap opens Upload Collections; a follow up opens its case', () {
    expect(
        BCollectionNotificationRouter.destinationFor(BUploadReminder.payload),
        (route: BRoutes.collectionUploadOutbox, arguments: null));
    expect(BCollectionNotificationRouter.destinationFor('recon-case:RC-1'),
        (route: BRoutes.reconciliationCase, arguments: 'RC-1'));
    expect(BCollectionNotificationRouter.destinationFor('voucher-reread:C-1'),
        isNull);
  });
}
