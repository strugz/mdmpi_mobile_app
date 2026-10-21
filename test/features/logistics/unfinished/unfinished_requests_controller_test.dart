import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_notification_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/unfinished_requests_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/unfinished/unfinished_requests_reminder.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/unfinished/unfinished_request.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/unfinished/unfinished_requests_screen.dart';

/// The controller behind the Unfinished requests list and the 08:00
/// reminder, and the list screen itself.

class _Phone implements INotificationService {
  final titles = <String>[];
  final cancelled = <int>[];

  @override
  bool get canSchedule => true;

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
    titles.add(title);
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

  final shownNow = <String>[];

  @override
  Future<void> showNow(
      {required int id,
      required String title,
      required String body,
      required String channelId,
      required String channelName,
      String? payload}) async {
    shownNow.add(title);
  }

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<void> cancelAll() async {}
}

UnfinishedRequest _req(FormCategoryType type, String id, String status,
        {String client = 'ABC Trading'}) =>
    UnfinishedRequest(
        type: type,
        id: id,
        client: client,
        status: status,
        createdAt: '2026-10-0${id.length}T09:00:00');

class _Harness {
  _Harness({
    this.department = 'Logistics',
    List<UnfinishedRequest>? requests,
  }) : requests = requests ??
            [
              _req(FormCategoryType.standardDelivery, '101', 'For Delivery'),
              _req(FormCategoryType.standardDelivery, '102', 'Delivered'),
              _req(FormCategoryType.pullOutReturn, '201', 'For Pull Out'),
            ];

  String department;
  String role = 'Admin';
  String initial = 'JDC';
  String now = '2026-10-21T09:00:00';
  List<UnfinishedRequest> requests;
  final store = <String, dynamic>{};
  final phone = _Phone();
  int permissionAsks = 0;

  late final reminder = BUnfinishedRequestsReminder(
    notifications: () => phone,
    enabled: () => UnfinishedRequestsController.readReminderOn(store.call),
  );

  UnfinishedRequestsController build() => UnfinishedRequestsController(
        loader: () async => requests,
        currentUser: () =>
            (role: role, initial: initial, department: department),
        reminder: () => reminder,
        askPermission: () async => permissionAsks++,
        read: (k) => store[k],
        write: (k, v) async => store[k] = v,
        now: () => DateTime.parse('$now+08:00'),
      )..onInit();
}

extension on Map<String, dynamic> {
  dynamic call(String key) => this[key];
}

void main() {
  group('UnfinishedRequestsController', () {
    test('lists the unfinished ones and schedules the reminder', () async {
      final h = _Harness();
      final c = h.build();
      await c.reload();
      expect(c.summary.value.requests.map((r) => r.id), ['101', '201']);
      expect(h.phone.titles, ['2 unfinished requests']);
      expect(h.permissionAsks, 1);
    });

    test('asks for the permission only once', () async {
      final h = _Harness();
      final c = h.build();
      await c.reload();
      await c.reload();
      expect(h.permissionAsks, 1);
      expect(h.store[UnfinishedRequestsController.permissionAskedKey], isTrue);
    });

    test('nothing unfinished: cancels and never asks', () async {
      final h = _Harness(requests: [
        _req(FormCategoryType.pickUp, '301', 'Received'),
      ]);
      final c = h.build();
      await c.reload();
      expect(c.summary.value.total, 0);
      expect(h.phone.titles, isEmpty);
      expect(h.phone.cancelled, [BUnfinishedRequestsReminder.id]);
      expect(h.permissionAsks, 0);
    });

    test('the switch is on by default, saved, and cancels at once', () async {
      final h = _Harness();
      final c = h.build();
      expect(c.reminderOn.value, isTrue);
      await c.reload();
      await c.setReminderOn(false);
      expect(h.store[UnfinishedRequestsController.reminderKey], isFalse);
      expect(h.phone.cancelled, [BUnfinishedRequestsReminder.id]);
      expect(h.build().reminderOn.value, isFalse);
    });

    group('first open or login of the day', () {
      test('shows at once, then not again the same day', () async {
        final h = _Harness();
        final c = h.build();
        await c.reload();
        await c.reload();
        expect(h.phone.shownNow, ['2 unfinished requests']);
        expect(
            h.store['${UnfinishedRequestsController.shownOnKeyPrefix}JDC'],
            '2026-10-21');
        // Logging in again the same day: a new controller, same storage.
        await h.build().reload();
        expect(h.phone.shownNow.length, 1);
      });

      test('shows again the next Manila day', () async {
        final h = _Harness()..now = '2026-10-21T23:59:00';
        await h.build().reload();
        h.now = '2026-10-22T00:01:00';
        await h.build().reload();
        expect(h.phone.shownNow.length, 2);
      });

      test('a different user on the same phone gets their own', () async {
        final h = _Harness();
        await h.build().reload();
        h.initial = 'MRS';
        await h.build().reload();
        expect(h.phone.shownNow.length, 2);
      });

      test('nothing unfinished: not shown, and not marked', () async {
        final h = _Harness(requests: const []);
        final c = h.build();
        await c.reload();
        expect(h.phone.shownNow, isEmpty);
        // Later the same day something is unfinished: it shows then.
        h.requests = [
          _req(FormCategoryType.pickUp, '301', 'New Request'),
        ];
        await c.reload();
        expect(h.phone.shownNow, ['1 unfinished request']);
      });

      test('the switch off stops it too', () async {
        final h = _Harness();
        final c = h.build();
        await c.setReminderOn(false);
        await c.reload();
        expect(h.phone.shownNow, isEmpty);
      });
    });

    test('a Collection user gets nothing', () async {
      final h = _Harness(department: 'Collection');
      final c = h.build();
      await c.reload();
      expect(c.summary.value.total, 0);
      expect(h.phone.cancelled, [BUnfinishedRequestsReminder.id]);
    });

    test('a failing loader never throws and stops loading', () async {
      final h = _Harness();
      final c = UnfinishedRequestsController(
        loader: () async => throw StateError('db closed'),
        currentUser: () => (role: 'Admin', initial: 'JDC', department: ''),
        read: (k) => h.store[k],
        write: (k, v) async => h.store[k] = v,
      )..onInit();
      await c.reload();
      expect(c.summary.value.total, 0);
      expect(c.isLoading.value, isFalse);
    });

    test('overlapping reloads fold into one more run', () async {
      final h = _Harness();
      var loads = 0;
      final c = UnfinishedRequestsController(
        loader: () async {
          loads++;
          return h.requests;
        },
        currentUser: () => (role: 'Admin', initial: 'JDC', department: ''),
        read: (k) => h.store[k],
        write: (k, v) async => h.store[k] = v,
      )..onInit();
      await Future.wait([c.reload(), c.reload(), c.reload()]);
      expect(loads, 2);
    });
  });

  group('UnfinishedRequestsScreen', () {
    tearDown(Get.reset);

    testWidgets('groups by type and opens the tapped request',
        (tester) async {
      final h = _Harness();
      Get.put(h.build());
      UnfinishedRequest? opened;

      await tester.pumpWidget(GetMaterialApp(
        home: UnfinishedRequestsScreen(onOpen: (_, r) => opened = r),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Standard Delivery (1)'), findsOneWidget);
      expect(find.text('Pull Out (1)'), findsOneWidget);
      expect(find.text('#101 · ABC Trading'), findsOneWidget);
      expect(find.textContaining('Delivered'), findsNothing);

      await tester.tap(find.text('#201 · ABC Trading'));
      expect(opened?.id, '201');
    });

    testWidgets('says so when everything is finished', (tester) async {
      final h = _Harness(requests: const []);
      Get.put(h.build());

      await tester.pumpWidget(
          const GetMaterialApp(home: UnfinishedRequestsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('All your requests are finished'), findsOneWidget);
    });
  });
}
