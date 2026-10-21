import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_sms_outbox_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/services/collection_sms_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_sms_outbox_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/sms/sms_outbox_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The SMS Outbox (update checklist item 29). Every Collection SMS is saved
/// to it and sent from it in the background, one by one, with nothing on the
/// collector's screen. One the phone could not send is tried again by
/// itself; one the phone accepted but never confirmed waits for Send now.
/// The Outbox keeps the day's messages: sent ones are cleared at midnight.

const _head = '0917 000 0001';
const _c1 = '0918 000 0002';
const _c2 = '0919 000 0003';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late CollectionSmsOutboxDao dao;
  late List<String> sentTo;
  late Set<String> failFor;
  late Set<String> silentFor;
  late bool granted;
  late DateTime clock;
  late List<String> contacts;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath,
        version: 1, onCreate: (db, _) async => ensureCollectionTables(db));
    dao = CollectionSmsOutboxDao(db);
    sentTo = [];
    failFor = {};
    silentFor = {};
    granted = true;
    clock = DateTime(2026, 10, 20, 9);
    contacts = [_c1, _c2];
  });

  tearDown(() async {
    await db.close();
    Get.reset();
  });

  /// [tick] moves the clock on a second at every read, as a real one does.
  CollectionSmsService build({bool outboxBroken = false, bool tick = true}) =>
      CollectionSmsService(
        report: (_, __, ___) {},
        networkIssue: () async => null,
        betweenRecipients: Duration.zero,
        confirmTimeout: const Duration(milliseconds: 50),
        head: () async => const HeadContact(
            key: 'MDD', name: 'Maria Dela Cruz', phone: _head),
        contacts: () async => contacts,
        permission: () async => granted,
        send: (to, message, onStatus) async {
          if (failFor.contains(to)) throw Exception('no signal');
          sentTo.add(to);
          if (!silentFor.contains(to)) onStatus(SendStatus.SENT);
        },
        smsAvailable: () => true,
        initials: () => 'MAR',
        outbox: () async =>
            outboxBroken ? throw StateError('no database') : dao,
        now: () =>
            tick ? clock = clock.add(const Duration(seconds: 1)) : clock,
        timers: false,
      );

  group('the table', () {
    test('a record round-trips, recipients included', () async {
      const r = SmsOutboxRecord(
        id: 'SMS-1',
        createdAt: '2026-10-20T09:00:00.000',
        kind: SmsKind.deposit,
        message: 'Deposited: PHP 1.00\n- MAR',
        recipients: [
          SmsOutboxRecipient(_head, SmsRecipientResult.sent),
          SmsOutboxRecipient(_c1, SmsRecipientResult.failed),
          SmsOutboxRecipient(_c2, SmsRecipientResult.unconfirmed),
        ],
        status: SmsOutboxStatus.unconfirmed,
        attempts: 1,
      );
      await dao.insert(r);
      final back = (await dao.getById('SMS-1'))!;
      expect(back.kind, SmsKind.deposit);
      expect(back.unconfirmedNumbers, [_c1, _c2],
          reason: 'Send now: everyone not confirmed');
      expect(back.retryableNumbers, [_c1],
          reason: 'by itself: only the one that never left the phone');
      expect(back.headline, 'Deposited: PHP 1.00');
      expect(back.needsAttention, isTrue);
    });

    test('a broken recipients column reads as none, not a crash', () {
      final r = SmsOutboxRecord.fromRow(
          {'id': 'X', 'message': 'm', 'recipients': '{not json'});
      expect(r.recipients, isEmpty);
    });
  });

  group('sending', () {
    test('every SMS is saved, then sent, each recipient with its result',
        () async {
      final sms = build();
      final outcome = await sms.notifyCwtPickup(
          clientName: 'Bacolod Adventist', remarks: '2307');
      expect(outcome, CollectionSmsOutcome.sent);

      final m = (await dao.getAll()).single;
      expect(m.kind, SmsKind.cwt);
      expect(m.message, 'Picked up CWT: Bacolod Adventist\nNote: 2307\n- MAR');
      expect(m.status, SmsOutboxStatus.sent);
      expect(m.recipients.map((r) => r.number), [_head, _c1, _c2]);
      expect(m.recipients.every((r) => r.confirmed), isTrue);
      expect(m.attempts, 1);
      expect(sms.needsAttention.value, 0);
    });

    test('a number that failed leaves it not sent yet', () async {
      failFor = {_c2};
      final sms = build();
      await sms.notifyEngagementCleared(clientName: 'Metro Globe');

      final m = (await dao.getAll()).single;
      expect(m.status, SmsOutboxStatus.unconfirmed,
          reason: 'some went out, one did not');
      expect(m.retryableNumbers, [_c2]);
      expect(sms.needsAttention.value, 1);
    });

    test('nobody went out: failed', () async {
      failFor = {_head, _c1, _c2};
      final sms = build();
      await sms.notifyEngagementCleared(clientName: 'Metro Globe');
      expect((await dao.getAll()).single.status, SmsOutboxStatus.failed);
    });

    test('nobody to text is kept, to be seen', () async {
      final sms = CollectionSmsService(
        head: () async => null,
        contacts: () async => [],
        smsAvailable: () => true,
        initials: () => 'MAR',
        outbox: () async => dao,
        now: () => clock,
        timers: false,
      );
      await sms.notifyEngagementCleared(clientName: 'X');
      final m = (await dao.getAll()).single;
      expect(m.status, SmsOutboxStatus.noRecipients);
      expect(m.unconfirmedNumbers, isEmpty, reason: 'nothing to send to');
    });

    test('permission off: it waits in the outbox, not in the Messages app',
        () async {
      granted = false;
      final sms = build();
      await sms.notifyEngagementCleared(clientName: 'X');
      final m = (await dao.getAll()).single;
      expect(m.status, SmsOutboxStatus.failed);
      expect(m.lastError, CollectionSmsService.permissionOffReason);
      expect(m.retryableNumbers, [_head, _c1, _c2]);
      expect(sentTo, isEmpty);
    });

    test('a broken outbox never stops the message', () async {
      final sms = build(outboxBroken: true);
      final outcome = await sms.notifyEngagementCleared(clientName: 'X');
      expect(outcome, CollectionSmsOutcome.sent);
      expect(sentTo, [_head, _c1, _c2]);
    });
  });

  group('the background dispatch', () {
    test('a failed message goes again by itself once its wait is over',
        () async {
      failFor = {_c2};
      final sms = build(tick: false);
      await sms.notifyEngagementCleared(clientName: 'Metro Globe');
      failFor = {};
      sentTo.clear();

      await sms.dispatchPending();
      expect(sentTo, isEmpty, reason: 'the first wait is a minute');

      clock = clock.add(CollectionSmsService.retryDelay(1));
      await sms.dispatchPending();
      expect(sentTo, [_c2], reason: 'only the number that never got it');
      final m = (await dao.getAll()).single;
      expect(m.status, SmsOutboxStatus.sent);
      expect(m.attempts, 2);
    });

    test('not confirmed is never sent again by itself', () async {
      silentFor = {_c1};
      final sms = build(tick: false);
      await sms.notifyEngagementCleared(clientName: 'X');
      sentTo.clear();

      clock = clock.add(const Duration(hours: 1));
      await sms.dispatchPending();
      expect(sentTo, isEmpty,
          reason: 'the phone accepted it: sending again might text twice');
      expect((await dao.getAll()).single.status, SmsOutboxStatus.unconfirmed);
    });

    test('after ten tries it waits for Send now', () async {
      failFor = {_head};
      contacts = [];
      final sms = build(tick: false);
      await sms.notifyEngagementCleared(clientName: 'X');
      for (var i = 1; i < CollectionSmsService.maxAutoAttempts + 3; i++) {
        clock = clock.add(const Duration(hours: 1));
        await sms.dispatchPending();
      }
      final m = (await dao.getAll()).single;
      expect(m.attempts, CollectionSmsService.maxAutoAttempts);
      expect(m.status, SmsOutboxStatus.failed);

      failFor = {};
      expect(await sms.resend(m.id), CollectionSmsOutcome.sent,
          reason: 'Send now still works');
    });

    test('a message left waiting when the app closed goes out at start',
        () async {
      await dao.insert(SmsOutboxRecord(
        id: 'LEFT',
        createdAt: clock.toIso8601String(),
        kind: SmsKind.deposit,
        message: 'Deposited: PHP 1.00\n- MAR',
        recipients: const [
          SmsOutboxRecipient(_head, SmsRecipientResult.pending),
        ],
      ));
      final sms = build();
      await sms.dispatchPending();
      expect(sentTo, [_head]);
      expect((await dao.getById('LEFT'))!.status, SmsOutboxStatus.sent);
    });

    test('messages go out oldest first, one after another', () async {
      await dao.insert(SmsOutboxRecord(
        id: 'B',
        createdAt: clock.add(const Duration(minutes: 5)).toIso8601String(),
        kind: 'x',
        message: 'B',
        recipients: const [
          SmsOutboxRecipient(_head, SmsRecipientResult.pending),
        ],
      ));
      await dao.insert(SmsOutboxRecord(
        id: 'A',
        createdAt: clock.toIso8601String(),
        kind: 'x',
        message: 'A',
        recipients: const [
          SmsOutboxRecipient(_head, SmsRecipientResult.pending),
        ],
      ));
      final order = <String>[];
      final sms = CollectionSmsService(
        report: (_, __, ___) {},
        networkIssue: () async => null,
        betweenRecipients: Duration.zero,
        head: () async => null,
        contacts: () async => [],
        permission: () async => true,
        send: (to, message, onStatus) async {
          order.add(message);
          onStatus(SendStatus.SENT);
        },
        smsAvailable: () => true,
        outbox: () async => dao,
        now: () => clock.add(const Duration(hours: 1)),
        timers: false,
      );
      await sms.dispatchPending();
      expect(order, ['A', 'B']);
    });
  });

  group('Send now', () {
    test('goes to the original numbers not confirmed, the same text',
        () async {
      silentFor = {_c2};
      final sms = build();
      await sms.notifyEngagementCleared(clientName: 'Metro Globe');
      final id = (await dao.getAll()).single.id;

      // The contact list has changed meanwhile.
      silentFor = {};
      contacts = ['0920 000 0009'];
      sentTo.clear();
      final outcome = await sms.resend(id);

      expect(outcome, CollectionSmsOutcome.sent);
      expect(sentTo, [_c2], reason: 'the original recipient, not the new list');
      final m = (await dao.getById(id))!;
      expect(m.status, SmsOutboxStatus.sent);
      expect(m.attempts, 2);
      expect(m.lastError, isNull);
    });

    test('nothing left to send: nothing sent', () async {
      final sms = build();
      await sms.notifyEngagementCleared(clientName: 'X');
      sentTo.clear();
      expect(await sms.resend((await dao.getAll()).single.id), isNull);
      expect(sentTo, isEmpty);
    });

    test('a sent SMS can be resent: the same text, to everyone again',
        () async {
      final sms = build();
      await sms.notifyEngagementCleared(clientName: 'Metro Globe');
      final id = (await dao.getAll()).single.id;
      sentTo.clear();

      expect(await sms.resendToEveryone(id), CollectionSmsOutcome.sent);
      expect(sentTo, [_head, _c1, _c2]);
      final m = (await dao.getById(id))!;
      expect(m.status, SmsOutboxStatus.sent, reason: 'still under Sent today');
      expect(m.attempts, 2);
    });

    test('a resend that fails for a number is retried by itself', () async {
      final sms = build(tick: false);
      await sms.notifyEngagementCleared(clientName: 'Metro Globe');
      final id = (await dao.getAll()).single.id;

      failFor = {_c1};
      await sms.resendToEveryone(id);
      final m = (await dao.getById(id))!;
      expect(m.needsAttention, isTrue, reason: 'back under Not sent yet');
      expect(m.retryableNumbers, [_c1]);

      failFor = {};
      sentTo.clear();
      clock = clock.add(CollectionSmsService.retryDelay(m.attempts));
      await sms.dispatchPending();
      expect(sentTo, [_c1]);
    });

    test('Send all now sends each, one after another', () async {
      failFor = {_c1};
      final sms = build();
      await sms.notifyEngagementCleared(clientName: 'A');
      await sms.notifyEngagementCleared(clientName: 'B');
      failFor = {};
      sentTo.clear();
      final ids = (await dao.getAll()).map((m) => m.id).toList();

      expect(await sms.resendAll(ids), 2);
      expect(sentTo, [_c1, _c1]);
    });
  });

  test("at midnight yesterday's sent messages go; today's and unsent stay",
      () async {
    Future<void> put(String id, String createdAt, String status) =>
        dao.insert(SmsOutboxRecord(
            id: id,
            createdAt: createdAt,
            kind: 'x',
            message: 'm',
            status: status,
            recipients: [
              SmsOutboxRecipient(
                  _head,
                  status == SmsOutboxStatus.sent
                      ? SmsRecipientResult.sent
                      : SmsRecipientResult.failed),
            ]));
    await put('YESTERDAY-SENT', '2026-10-19T23:59:00.000', SmsOutboxStatus.sent);
    await put('YESTERDAY-FAILED', '2026-10-19T18:00:00.000',
        SmsOutboxStatus.failed);
    await put('TODAY-SENT', '2026-10-20T00:01:00.000', SmsOutboxStatus.sent);

    final sms = build(tick: false);
    await sms.refreshOutbox(purge: true);

    expect((await dao.getAll()).map((m) => m.id).toSet(),
        {'YESTERDAY-FAILED', 'TODAY-SENT'});
    expect(sms.needsAttention.value, 1);
  });

  group('the screen', () {
    SmsOutboxRecord msg(String id, String status, List<String> results,
            {String text = 'Done: Metro Globe\n- MAR', int attempts = 1}) =>
        SmsOutboxRecord(
          id: id,
          createdAt: '2026-10-20T09:00:00.000',
          kind: SmsKind.cleared,
          message: text,
          status: status,
          recipients: [
            for (final (i, r) in results.indexed)
              SmsOutboxRecipient(['0917', '0918', '0919'][i], r),
          ],
          attempts: attempts,
          lastError: status == SmsOutboxStatus.sent ? null : 'no signal',
        );

    Future<_FakeSms> open(
        WidgetTester tester, List<SmsOutboxRecord> messages) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final sms = _FakeSms(messages);
      Get.put<CollectionSmsService>(sms);
      Get.put(CollectionSmsOutboxController(sms: sms));
      await tester.pumpWidget(GetMaterialApp(
          theme: BCollectionTheme.light,
          home: const CollectionSmsOutboxScreen()));
      await tester.pumpAndSettle();
      return sms;
    }

    testWidgets('empty: says so', (tester) async {
      await open(tester, []);
      expect(find.text('No Collection SMS yet.'), findsOneWidget);
    });

    testWidgets('not sent yet comes first; sent today below', (tester) async {
      await open(tester, [
        msg('A', SmsOutboxStatus.unconfirmed, [
          SmsRecipientResult.sent,
          SmsRecipientResult.sent,
          SmsRecipientResult.failed,
        ]),
        msg('B', SmsOutboxStatus.sent, [SmsRecipientResult.sent],
            text: 'Picked up CWT: Bacolod\n- MAR'),
      ]);

      expect(find.text('Not sent yet (1)'), findsOneWidget);
      expect(find.text('Sent today (1)'), findsOneWidget);
      expect(find.text('Done: Metro Globe'), findsOneWidget);
      expect(find.text('0919'), findsOneWidget);
      expect(find.text('Retrying · try 2'), findsOneWidget,
          reason: 'the app is still trying it by itself');
      expect(find.text('Send now to 1'), findsOneWidget);
      expect(find.byKey(const ValueKey('sms-outbox-resend-B')), findsNothing,
          reason: 'a sent message has nothing to send');
    });

    testWidgets('after ten tries it reads Failed', (tester) async {
      await open(tester, [
        msg('A', SmsOutboxStatus.failed, [SmsRecipientResult.failed],
            attempts: CollectionSmsService.maxAutoAttempts),
      ]);
      expect(find.text('Failed'), findsWidgets);
    });

    testWidgets('Send now sends it and it moves to Sent today',
        (tester) async {
      final sms = await open(tester, [
        msg('A', SmsOutboxStatus.failed, [SmsRecipientResult.failed]),
      ]);
      await tester.tap(find.byKey(const ValueKey('sms-outbox-resend-A')));
      await tester.pumpAndSettle();

      expect(sms.resent, ['A']);
      expect(find.text('Not sent yet (0)'), findsOneWidget);
      expect(find.text('Every SMS went out.'), findsOneWidget);
    });

    testWidgets('Discard asks first, then removes it', (tester) async {
      final sms = await open(tester, [
        msg('A', SmsOutboxStatus.failed, [SmsRecipientResult.failed]),
      ]);
      await tester.tap(find.byKey(const ValueKey('sms-outbox-discard-A')));
      await tester.pumpAndSettle();
      expect(find.text('Discard this SMS?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sms-outbox-discard-confirm')));
      await tester.pumpAndSettle();

      expect(sms.discarded, ['A']);
      expect(find.text('No Collection SMS yet.'), findsOneWidget);
    });

    testWidgets('a sent SMS has Resend, which asks first', (tester) async {
      final sms = await open(tester, [
        msg('B', SmsOutboxStatus.sent,
            [SmsRecipientResult.sent, SmsRecipientResult.sent]),
      ]);
      expect(find.byKey(const ValueKey('sms-outbox-resend-sent-B')),
          findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sms-outbox-resend-sent-B')));
      await tester.pumpAndSettle();
      expect(find.text('Resend this SMS?'), findsOneWidget);
      expect(find.textContaining('all 2 recipients'), findsOneWidget);

      await tester
          .tap(find.byKey(const ValueKey('sms-outbox-resend-sent-confirm')));
      await tester.pumpAndSettle();
      expect(sms.resentToEveryone, ['B']);
    });

    testWidgets('cancel sends nothing', (tester) async {
      final sms = await open(tester, [
        msg('B', SmsOutboxStatus.sent, [SmsRecipientResult.sent]),
      ]);
      await tester.tap(find.byKey(const ValueKey('sms-outbox-resend-sent-B')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(sms.resentToEveryone, isEmpty);
    });

    testWidgets('not sent yet has Send now, not Resend', (tester) async {
      await open(tester, [
        msg('A', SmsOutboxStatus.failed, [SmsRecipientResult.failed]),
      ]);
      expect(find.byKey(const ValueKey('sms-outbox-resend-sent-A')),
          findsNothing);
      expect(find.byKey(const ValueKey('sms-outbox-resend-A')), findsOneWidget);
    });

    testWidgets('Send all now appears for more than one', (tester) async {
      final sms = await open(tester, [
        msg('A', SmsOutboxStatus.failed, [SmsRecipientResult.failed]),
        msg('B', SmsOutboxStatus.failed, [SmsRecipientResult.failed]),
      ]);
      await tester.tap(find.byKey(const ValueKey('sms-outbox-resend-all')));
      await tester.pumpAndSettle();
      expect(sms.resent.toSet(), {'A', 'B'});
    });
  });
}

/// The service as the screen sees it, with the outbox in memory.
class _FakeSms extends CollectionSmsService {
  _FakeSms(this._messages) : super(smsAvailable: () => true, timers: false);

  final List<SmsOutboxRecord> _messages;
  final resent = <String>[];
  final resentToEveryone = <String>[];
  final discarded = <String>[];

  @override
  Future<CollectionSmsOutcome?> resendToEveryone(String id) async {
    resentToEveryone.add(id);
    return CollectionSmsOutcome.sent;
  }

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<List<SmsOutboxRecord>> outboxMessages() async => List.of(_messages);

  @override
  Future<CollectionSmsOutcome?> resend(String id) async {
    resent.add(id);
    final i = _messages.indexWhere((m) => m.id == id);
    _messages[i] = _messages[i].copyWith(
      status: SmsOutboxStatus.sent,
      recipients: [
        for (final r in _messages[i].recipients)
          SmsOutboxRecipient(r.number, SmsRecipientResult.sent),
      ],
    );
    return CollectionSmsOutcome.sent;
  }

  @override
  Future<void> discard(String id) async {
    discarded.add(id);
    _messages.removeWhere((m) => m.id == id);
  }
}
