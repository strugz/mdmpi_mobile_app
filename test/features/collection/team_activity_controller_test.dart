import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/models/directory_user.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_roles.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/team_engagement.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/team_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

/// The Head's Team Activity tab (Collection TODO items 21–22): the feed
/// model, the controller's month and collector handling, and the role gate.

Map<String, dynamic> _row({
  String kind = 'Engagement',
  int id = 1,
  String collector = 'EMP1',
  String? collectorName = 'Juan',
  String? client = 'NCR-300',
  String? clientName = 'Metro Globe',
  String? doc = 'S1',
  String type = 'Field',
  String? status = 'Collected',
  num amount = 900,
  String? date = '2026-09-15',
  String? remarks,
  String? bank,
  String? ref,
}) =>
    {
      'Kind': kind,
      'Id': id,
      'CollectorCode': collector,
      'CollectorName': collectorName,
      'ClientCode': client,
      'ClientName': clientName,
      'DocumentId': doc,
      'ActivityType': type,
      'Status': status,
      'Amount': amount,
      'Date': date,
      'Remarks': remarks,
      'BankName': bank,
      'ReferenceNo': ref,
    };

TeamActivityFeed _feed(List<Map<String, dynamic>> rows,
        {List<Map<String, dynamic>>? collectors}) =>
    TeamActivityFeed.fromJson({
      'From': '2026-09-01',
      'To': '2026-09-30',
      'Collectors': collectors ??
          [
            {'Code': 'EMP1', 'Name': 'Juan'},
            {'Code': 'EMP2', 'Name': 'Maria'},
          ],
      'Engagements': rows,
    });

void main() {
  tearDown(Get.reset);

  group('TeamActivityFeed.fromJson', () {
    test('reads the PascalCase contract, tolerating nulls', () {
      final feed = _feed([
        _row(),
        _row(
            kind: 'Deposit',
            id: 7,
            client: null,
            clientName: null,
            doc: null,
            type: 'Deposit',
            status: null,
            amount: 2500,
            bank: 'BPI',
            ref: '1254897',
            date: '2026-09-18'),
      ]);

      expect(feed.from, '2026-09-01');
      expect(feed.collectors, [
        const TeamCollector(code: 'EMP1', name: 'Juan'),
        const TeamCollector(code: 'EMP2', name: 'Maria'),
      ]);
      final e = feed.engagements.first;
      expect(e.kind, 'Engagement');
      expect(e.collectorLabel, 'Juan');
      expect(e.statusLabel, 'Collected');
      expect(e.amount, 900);
      expect(e.key, 'Engagement:1');

      final d = feed.engagements.last;
      expect(d.isDeposit, isTrue);
      expect(d.clientCode, '');
      expect(d.statusLabel, 'Deposit');
      expect(d.bankName, 'BPI');
      expect(d.referenceNo, '1254897');
    });

    test('a collector with no name shows by code; a code-less row is dropped',
        () {
      final feed = _feed(const [], collectors: [
        {'Code': 'EMP3', 'Name': ''},
        {'Code': '', 'Name': 'Ghost'},
      ]);
      expect(feed.collectors, [const TeamCollector(code: 'EMP3', name: 'EMP3')]);
    });
  });

  group('TeamActivityController', () {
    late List<({DateTime from, DateTime to, String? collector})> calls;
    late Result<TeamActivityFeed> Function(String? collector) answer;
    late DateTime now;

    late Result<List<DirectoryUser>> members;

    TeamActivityController build({Completer<void>? gate}) =>
        TeamActivityController(
          now: () => now,
          members: () async => members,
          load: ({required from, required to, collector}) async {
            calls.add((from: from, to: to, collector: collector));
            if (gate != null) await gate.future;
            return answer(collector);
          },
        );

    setUp(() {
      calls = [];
      // Juan and Maria are Firestore Collection users; the picker is them.
      members = Result.success(const [
        DirectoryUser(key: 'JRR', name: 'Juan', department: 'Collection',
            username: 'EMP1', inFirestore: true),
        DirectoryUser(key: 'MSA', name: 'Maria', department: 'Collection',
            username: 'EMP2', inFirestore: true),
      ]);
      now = DateTime(2026, 9, 25, 14, 30);
      answer = (_) => Result.success(_feed([
            _row(),
            _row(id: 2, collector: 'EMP2', collectorName: 'Maria',
                status: 'Partial Payment', amount: 100, date: '2026-09-15'),
            _row(id: 3, type: 'Deferred', doc: null, status: 'Follow-up',
                amount: 0, date: '2026-09-16'),
            _row(kind: 'Deposit', id: 9, type: 'Deposit', status: null,
                amount: 2500, date: '2026-09-15', client: null,
                clientName: null, doc: null, bank: 'BPI'),
            _row(id: 4, date: null),
          ]));
    });

    test('loads the month on screen for everyone, today selected', () async {
      final c = build();
      await c.load();

      expect(calls.single.from, DateTime(2026, 9, 1));
      expect(calls.single.to, DateTime(2026, 9, 30));
      expect(calls.single.collector, isNull);
      expect(c.selectedDay.value, DateTime(2026, 9, 25));
      expect(c.isTodaySelected, isTrue);
      expect(c.loadedAt.value, now);
      expect(c.selectionLabel, 'All collectors');
      expect(c.collectors.map((x) => x.name), ['Juan', 'Maria']);
      expect(c.error.value, isNull);
    });

    test('the picker is Firestore Users with Department Collection, only',
        () async {
      members = Result.success(const [
        DirectoryUser(
            key: 'JCA',
            name: 'Jay Abaoag',
            department: 'COLLECTION',
            username: 'EMP1',
            inFirestore: true,
            inCntmst: true),
        DirectoryUser(
            key: 'PSR',
            name: 'Pedro Silang',
            department: 'Collection',
            username: 'psilang',
            inFirestore: true),
        DirectoryUser(
            key: 'CNT',
            name: 'Cntmst Only',
            department: 'COLLECTION',
            inCntmst: true),
        DirectoryUser(
            key: 'LOG',
            name: 'Logistics Guy',
            department: 'Logistics',
            username: 'log',
            inFirestore: true),
      ]);
      final c = build();
      await c.load();

      expect(c.collectors, [
        const TeamCollector(code: 'EMP1', name: 'Jay Abaoag'),
        const TeamCollector(code: 'psilang', name: 'Pedro Silang'),
      ], reason: 'Maria (EMP2) uploaded but has no Collection Firestore user; '
          'the CNTMST-only row and Logistics are out');
      await c.selectCollector('psilang');
      expect(c.selectionLabel, 'Pedro Silang');
    });

    test('a directory failure leaves the picker empty, not wrong', () async {
      members = Result.failure('offline');
      final c = build();
      await c.load();
      expect(c.collectors, isEmpty);
      expect(c.engagements.length, 5, reason: 'the feed still loads');
    });

    test('groups by day; an undated row is not on any day', () async {
      final c = build();
      await c.load();

      expect(c.byDay.keys, [DateTime(2026, 9, 15), DateTime(2026, 9, 16)]);
      expect(c.on(DateTime(2026, 9, 15, 23, 59)).length, 3);
      expect(c.on(DateTime(2026, 9, 16)).single.isDeferred, isTrue);
      expect(c.on(DateTime(2026, 9, 17)), isEmpty);
    });

    test('day entries carry who did it, and deposits are not summed',
        () async {
      final c = build();
      await c.load();

      final entries = c.dayEntries(DateTime(2026, 9, 15));
      final histories =
          entries.map((e) => e['history'] as CollectionHistoryModel).toList();
      expect(histories.map((h) => h.collectorName), ['Juan', 'Maria', 'Juan']);
      expect(histories[0].status, 'Collected');
      expect(histories[0].remarks, 'No remarks');
      expect(entries[0]['accountName'], 'Metro Globe');
      expect(entries[0]['invoiceId'], 'S1');

      final deposit = entries[2];
      expect((deposit['history'] as CollectionHistoryModel).status, 'Deposit');
      expect(deposit['accountName'], 'Bank deposit · BPI');
      expect(deposit['invoiceId'], isNull);

      expect(c.collectedOn(DateTime(2026, 9, 15)), 1000);
    });

    test('picking a collector reloads for that code; picking again is a no-op',
        () async {
      final c = build();
      await c.load();
      await c.selectCollector('EMP2');
      await c.selectCollector('EMP2');

      expect(calls.length, 2);
      expect(calls.last.collector, 'EMP2');
      expect(c.selectionLabel, 'Maria');

      await c.selectCollector('');
      expect(calls.last.collector, isNull);
      expect(c.selectionLabel, 'All collectors');
    });

    test('stepping the month reloads it and keeps a day inside it', () async {
      final c = build();
      await c.load();
      await c.stepMonth(-1);

      expect(calls.last.from, DateTime(2026, 8, 1));
      expect(calls.last.to, DateTime(2026, 8, 31));
      expect(c.selectedDay.value, DateTime(2026, 8, 1));

      await c.stepMonth(1);
      expect(c.selectedDay.value, DateTime(2026, 9, 25),
          reason: 'back in the current month, today is selected again');
    });

    test('selecting a day in another month shows that month', () async {
      final c = build();
      await c.load();
      await c.selectDay(DateTime(2026, 10, 3));

      expect(c.focusedMonth.value, DateTime(2026, 10, 1));
      expect(c.selectedDay.value, DateTime(2026, 10, 3));
      expect(calls.last.from, DateTime(2026, 10, 1));
    });

    test('a failed load keeps what was on screen and reports the message',
        () async {
      final c = build();
      await c.load();
      answer = (_) => Result.failure('Could not reach the server.');
      await c.stepMonth(1);

      expect(c.error.value, 'Could not reach the server.');
      expect(c.engagements.length, 5, reason: 'the previous feed stays');
      expect(c.collectors.length, 2);
      expect(c.isLoading.value, isFalse);
    });

    test('a slow answer for an earlier month is dropped', () async {
      final gate = Completer<void>();
      final c = build(gate: gate);
      final first = c.load(); // September, waits on the gate
      answer = (_) => Result.success(_feed([_row(id: 50, date: '2026-10-02')]));
      final second = c.stepMonth(1); // October, also waits on the gate
      gate.complete();
      await Future.wait([first, second]);

      // Both loads answered with the October feed after the gate opened, but
      // the September call was superseded, so only one answer was applied.
      expect(c.engagements.map((e) => e.id), [50]);
      expect(c.focusedMonth.value, DateTime(2026, 10, 1));
    });
  });

  group('BCollectionRoles.isHead', () {
    UserModel user(String dept, String role) => UserModel(
        id: 'u',
        firstName: 'A',
        lastName: 'B',
        username: 'ab',
        email: 'e',
        phoneNumber: '',
        profilePicture: '',
        department: dept,
        role: role);

    test('needs the Collection department and the CollectionHead role', () {
      expect(BTexts.roleCollectionHead, 'CollectionHead');
      expect(BCollectionRoles.isHead(user('Collection', 'CollectionHead')),
          isTrue);
      expect(
          BCollectionRoles.isHead(
              user(' collection ', 'Viewer, collectionhead ')),
          isTrue,
          reason: 'case and spacing as typed on the web');
      expect(BCollectionRoles.isHead(user('Collection', 'CollectionPoster')),
          isFalse);
      expect(BCollectionRoles.isHead(user('Logistics', 'CollectionHead')),
          isFalse);
      expect(BCollectionRoles.isHead(user('Collection', '')), isFalse);
    });
  });
}
