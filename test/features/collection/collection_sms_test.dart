import 'package:another_telephony/telephony.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/services/collection_sms_service.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

/// The six Collection SMS triggers (spec of 2026-09-25): templates, who gets
/// them, and what happens when the radio or the permission is missing.

class _Activity extends CollectionActivityController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  tearDown(Get.reset);

  group('templates', () {
    test('7. Reconciliation escalated', () {
      expect(
        CollectionSmsService.reconEscalated(
            clientName: 'Allied Care Experts (ACE) Medical Center - Bohol, Inc.',
            openInvoices: 1,
            openAmount: 276995,
            remarks: 'No proof after three follow-ups'),
        'Reconciliation escalated: Allied Care Experts (ACE) Medical Center - '
        'Bohol, Inc. 1 open invoice, PHP 276,995.00. Reason: No proof after '
        'three follow-ups.',
      );
      expect(
        CollectionSmsService.reconEscalated(
            clientName: 'Metro Globe', openInvoices: 2, openAmount: 100),
        'Reconciliation escalated: Metro Globe. 2 open invoices, PHP 100.00.',
      );
      expect(
          RegExp(r'^[\x20-\x7E]*$').hasMatch(CollectionSmsService.reconEscalated(
              clientName: 'X', openInvoices: 1, openAmount: 1)),
          isTrue,
          reason: 'plain SMS text');
    });

    test('1. Acquiring Account', () {
      expect(
        CollectionSmsService.acquiringAccount(
            clientName: 'Abbott Laboratories',
            poNumbers: ['230736'],
            invoiceIds: ['270000031'],
            amount: 112000),
        'Now handling Abbott Laboratories. 1 PO, 1 invoice, PHP 112,000.00.',
      );
      expect(
        CollectionSmsService.acquiringAccount(
            clientName: 'Metro Globe',
            poNumbers: ['PO-88', '', 'PO-89', 'PO-88'],
            invoiceIds: ['700011347', '700011348'],
            amount: 6251.5),
        'Now handling Metro Globe. 2 POs, 2 invoices, PHP 6,251.50.',
      );
      expect(
        CollectionSmsService.acquiringAccount(
            clientName: 'Metro Globe', poNumbers: [], invoiceIds: ['S1']),
        'Now handling Metro Globe. 1 invoice.',
      );
    });

    test(
        '2. Saving Engagement: the amount leads, the PO only when there is one',
        () {
      expect(
        CollectionSmsService.engagementSaved(
            clientName: 'Accusure Medical Enterprises',
            poNumbers: ['2026-0309'],
            invoices: const [SmsInvoiceLine(id: '700013391', amount: 24281.25)],
            status: 'Collected'),
        'Collected PHP 24,281.25 from Accusure Medical Enterprises. '
        'Invoice 700013391 (PO 2026-0309).',
      );
      expect(
        CollectionSmsService.engagementSaved(
            clientName: 'Metro Globe',
            poNumbers: ['PO-88'],
            invoices: const [
              SmsInvoiceLine(id: '700011347', amount: 6001),
              SmsInvoiceLine(id: '700011348', amount: 250.5),
            ],
            status: 'Partial'),
        'Partial payment of PHP 6,251.50 from Metro Globe. Invoices '
        '700011347 PHP 6,001.00, 700011348 PHP 250.50 (PO PO-88).',
      );
      expect(
        CollectionSmsService.engagementSaved(
            clientName: 'Metro Globe',
            poNumbers: [''],
            invoices: const [SmsInvoiceLine(id: 'S1', amount: 900)],
            status: 'Collected'),
        'Collected PHP 900.00 from Metro Globe. Invoice S1.',
      );
    });

    test('1. an account taken on for reconciliation says so', () {
      expect(
        CollectionSmsService.acquiringAccounts(const [
          SmsAccountLine(
              clientName: 'Amka Trading',
              poNumbers: ['1', '2', '3', '4', '5'],
              invoiceIds: ['a', 'b', 'c', 'd', 'e'],
              amount: 118139.87,
              reconciliation: true),
        ]),
        'Now handling Amka Trading for reconciliation. POs 1, 2, 3, 4, 5. '
        'Invoices a, b, c, d, e. PHP 118,139.87.',
      );
      expect(
        CollectionSmsService.acquiringAccounts(const [
          SmsAccountLine(
              clientName: 'Amka Trading',
              poNumbers: ['1'],
              invoiceIds: ['a'],
              amount: 100,
              reconciliation: true),
          SmsAccountLine(
              clientName: 'Metro Globe',
              poNumbers: ['2'],
              invoiceIds: ['b'],
              amount: 50),
        ]),
        'Now handling 2 accounts: Amka Trading (reconciliation: POs 1; '
        'invoices a; PHP 100.00); Metro Globe (1 PO, 1 invoice, PHP 50.00). '
        'Total PHP 150.00.',
      );
    });

    test('1. several accounts acquired together make one message', () {
      expect(
        CollectionSmsService.acquiringAccounts(const [
          SmsAccountLine(
              clientName: 'Alexis Yu Best Care Pharmacy',
              poNumbers: ['9/21/18', '12/20/17', '14625', '11/20/17', '24684'],
              invoiceIds: ['1', '2', '3', '4', '5', '6'],
              amount: 95198.18),
          SmsAccountLine(
              clientName: 'Ace Diagnostics Corp.',
              poNumbers: ['QTS24-03B-B'],
              invoiceIds: ['270000090'],
              amount: 20000),
          SmsAccountLine(
              clientName: 'Accuteqs Diagnostics Corp.',
              poNumbers: ['A', 'B', 'C', 'D'],
              invoiceIds: ['1', '2', '3', '4', '5', '6'],
              amount: 155972.41),
        ]),
        'Now handling 3 accounts: Alexis Yu Best Care Pharmacy (5 POs, '
        '6 invoices, PHP 95,198.18); Ace Diagnostics Corp. (1 PO, 1 invoice, '
        'PHP 20,000.00); Accuteqs Diagnostics Corp. (4 POs, 6 invoices, '
        'PHP 155,972.41). Total PHP 271,170.59.',
      );
      expect(
        CollectionSmsService.acquiringAccounts(const [
          SmsAccountLine(
              clientName: 'Metro Globe',
              poNumbers: ['PO-88'],
              invoiceIds: ['S1'],
              amount: 900),
        ]),
        'Now handling Metro Globe. 1 PO, 1 invoice, PHP 900.00.',
        reason: 'one account reads as before',
      );
    });

    test('2. Saving Engagement paid by check carries the check details', () {
      String saved({String? bank, String? no, String? date}) =>
          CollectionSmsService.engagementSaved(
              clientName: 'Accusure Medical Enterprises',
              poNumbers: ['2026-0328'],
              invoices: const [
                SmsInvoiceLine(id: '700013392', amount: 121208.04)
              ],
              status: 'Collected',
              bankName: bank,
              checkNumber: no,
              checkDate: date);
      const base = 'Collected PHP 121,208.04 from Accusure Medical '
          'Enterprises. Invoice 700013392 (PO 2026-0328).';
      expect(saved(bank: 'BDO', no: '4588255', date: '09-28-2026'),
          '$base Check BDO 4588255, dated 09-28-2026.');
      expect(saved(bank: 'BDO', no: '4588255'), '$base Check BDO 4588255.');
      expect(saved(date: '09-28-2026'), '$base Check dated 09-28-2026.');
      expect(saved(bank: ' ', no: '', date: null), base,
          reason: 'cash: no check part at all');
    });

    test('every template stays in plain SMS text (no peso sign)', () {
      // One character outside GSM-7 (the peso sign was one) makes the whole
      // message UCS-2, 70 characters per SMS: the phone refused the Saving
      // Engagement text outright on 2026-09-28.
      final messages = [
        CollectionSmsService.acquiringAccount(
            clientName: 'Accusure Medical Enterprises',
            poNumbers: ['2026-0323'],
            invoiceIds: ['700013390']),
        CollectionSmsService.engagementSaved(
            clientName: 'Accusure Medical Enterprises',
            poNumbers: ['2026-0323'],
            invoices: const [SmsInvoiceLine(id: '700013390', amount: 37759.82)],
            status: 'Collected'),
        CollectionSmsService.accountDeferred(clientName: 'X', remarks: 'r'),
        CollectionSmsService.engagementCleared(clientName: 'X'),
        CollectionSmsService.depositAdded(bankName: 'BDO', amount: 526664),
        CollectionSmsService.cwtPickup(clientName: 'X', remarks: 'r'),
        CollectionSmsService.signed('m', 'MAR'),
      ];
      for (final m in messages) {
        expect(RegExp(r'^[\x20-\x7E]*$').hasMatch(m), isTrue, reason: m);
      }
    });

    test('2. only Collected and Partial outcomes send', () {
      expect(
          CollectionSmsService.collectionStatusWord('Collected'), 'Collected');
      expect(CollectionSmsService.collectionStatusWord('Partially Collected'),
          'Partial');
      expect(CollectionSmsService.collectionStatusWord('partial payment'),
          'Partial');
      expect(
          CollectionSmsService.collectionStatusWord('Pre-Collection'), isNull);
      expect(CollectionSmsService.collectionStatusWord('Follow Up'), isNull);
      expect(CollectionSmsService.collectionStatusWord(''), isNull);
    });

    test('3. Defer Account', () {
      expect(
        CollectionSmsService.accountDeferred(
            clientName: 'Metro Globe', remarks: 'Follow Up - Signatory  out'),
        'Postponed Metro Globe. Reason: Follow Up - Signatory out.',
      );
      expect(
        CollectionSmsService.accountDeferred(clientName: 'X', remarks: '  '),
        'Postponed X.',
      );
    });

    test('4. Clear Engagement', () {
      expect(
        CollectionSmsService.engagementCleared(clientName: 'Metro Globe'),
        'Done with Metro Globe.',
      );
    });

    test('5. Adding Deposit, optional parts left out when blank', () {
      expect(
        CollectionSmsService.depositAdded(
            bankName: 'BDO',
            amount: 526664,
            checkNumber: '1254897',
            remarks: 'Morning run'),
        'Deposited PHP 526,664.00 at BDO. Check 1254897. Note: Morning run.',
      );
      expect(
        CollectionSmsService.depositAdded(bankName: 'BPI', amount: 2500),
        'Deposited PHP 2,500.00 at BPI.',
      );
      expect(
        CollectionSmsService.depositAdded(
            bankName: '', amount: 1, checkNumber: ' ', remarks: ''),
        'Deposited PHP 1.00.',
      );
    });

    test('6. CWT Pick-Up', () {
      expect(
        CollectionSmsService.cwtPickup(
            clientName: 'Bacolod Adventist', remarks: '2307 picked up'),
        'Picked up CWT from Bacolod Adventist. Note: 2307 picked up.',
      );
      expect(CollectionSmsService.cwtPickup(clientName: 'X', remarks: ''),
          'Picked up CWT from X.');
    });

    test('a name or remark that ends with a period is not doubled', () {
      expect(
          CollectionSmsService.engagementCleared(
              clientName: 'Accuteqs Diagnostics Corp.'),
          'Done with Accuteqs Diagnostics Corp.');
      expect(
          CollectionSmsService.acquiringAccount(
              clientName: 'Accuteqs Diagnostics Corp.',
              poNumbers: [],
              invoiceIds: ['S1']),
          'Now handling Accuteqs Diagnostics Corp. 1 invoice.');
      expect(
          CollectionSmsService.cwtPickup(
              clientName: 'Accuteqs Diagnostics Corp.', remarks: 'Signed.'),
          'Picked up CWT from Accuteqs Diagnostics Corp. Note: Signed.');
      expect(
          CollectionSmsService.depositAdded(
              bankName: 'BDO', amount: 1, remarks: 'Done.'),
          'Deposited PHP 1.00 at BDO. Note: Done.');
    });

    test("the collector's initials close every message", () {
      expect(CollectionSmsService.signed('Released X.', 'MAR'),
          'Released X. - MAR');
      expect(CollectionSmsService.signed('Released X.', ' '), 'Released X.');
    });
  });

  group('delivery', () {
    late List<(String, String)> sent;
    late List<(List<String>, String)> handedOff;
    late bool granted;
    late bool android;
    late String? networkIssue;
    late HeadContact? head;
    late List<String> contacts;
    late Set<String> failFor;
    late Set<String> silentFor;
    late List<(CollectionSmsOutcome, int, String?)> reported;
    late List<String> progress;
    late int progressClosed;
    late int sentViews;
    late String initials;

    CollectionSmsService build() => CollectionSmsService(
          report: (o, n, r) => reported.add((o, n, r)),
          openProgress: (text) => progress.add(text.value),
          closeProgress: () => progressClosed++,
          showSent: () async => sentViews++,
          networkIssue: () async => networkIssue,
          betweenRecipients: Duration.zero,
          head: () async => head,
          contacts: () async => contacts,
          permission: () async => granted,
          send: (to, message, onStatus) async {
            if (failFor.contains(to)) throw Exception('no signal');
            sent.add((to, message));
            // The radio reports SENT unless this number is "silent".
            if (!silentFor.contains(to)) onStatus(SendStatus.SENT);
          },
          handOff: (to, message) async {
            handedOff.add((to, message));
            return true;
          },
          smsAvailable: () => android,
          initials: () => initials,
        );

    setUp(() {
      sent = [];
      handedOff = [];
      reported = [];
      progress = [];
      progressClosed = 0;
      sentViews = 0;
      initials = 'MAR';
      granted = true;
      android = true;
      networkIssue = null;
      failFor = {};
      silentFor = {};
      head = const HeadContact(
          key: 'MDD', name: 'Maria Dela Cruz', phone: '0917 000 0001');
      contacts = ['0918 000 0002', '0917-000-0001', '0919 000 0003'];
    });

    test('an escalation goes to the Head alone, not the Collection contacts',
        () async {
      final r = await build().notifyReconEscalated(
          clientName: 'Metro Globe', openInvoices: 1, openAmount: 100);
      expect(r, CollectionSmsOutcome.sent);
      expect(sent.map((s) => s.$1), ['0917 000 0001']);
      expect(sent.single.$2, endsWith(' - MAR'));

      head = null;
      sent = [];
      expect(
          await build().notifyReconEscalated(
              clientName: 'Metro Globe', openInvoices: 1, openAmount: 100),
          CollectionSmsOutcome.noRecipients,
          reason: 'no Head set: nobody to tell, the contacts are not a stand-in');
      expect(sent, isEmpty);
    });

    test('the Head first, then the Collection contacts, no duplicates',
        () async {
      expect(await build().recipients(),
          ['0917 000 0001', '0918 000 0002', '0919 000 0003']);
    });

    test(
        'a message reaches everyone behind the sending view, then Message Sent',
        () async {
      final r =
          await build().notifyEngagementCleared(clientName: 'Metro Globe');
      expect(r, CollectionSmsOutcome.sent);
      expect(sent.map((s) => s.$1),
          ['0917 000 0001', '0918 000 0002', '0919 000 0003']);
      expect(sent.first.$2, 'Done with Metro Globe. - MAR');
      expect(progress, ['Please wait message sending... (0/3)'],
          reason: 'the full-screen view opens once, before the first send');
      expect(progressClosed, 1, reason: 'and always comes down');
      expect(reported.single.$1, CollectionSmsOutcome.sent);
      expect(reported.single.$2, 3);
      expect(sentViews, 1);
    });

    test('no Head: the contacts still get it; nobody at all: noRecipients',
        () async {
      head = null;
      expect(await build().notifyCwtPickup(clientName: 'X', remarks: 'r'),
          CollectionSmsOutcome.sent);
      expect(sent.length, 3,
          reason: 'the three contacts, one of them the '
              "Head's own number listed as a contact");
      expect(await build().hasHead(), isFalse);

      contacts = [];
      progress = [];
      expect(await build().notifyCwtPickup(clientName: 'X', remarks: 'r'),
          CollectionSmsOutcome.noRecipients);
      expect(reported.last.$1, CollectionSmsOutcome.noRecipients,
          reason: 'the collector is told why nothing went out');
      expect(progress, isEmpty, reason: 'nothing was sending');
    });

    test('a Head without a number counts as no Head', () async {
      head = const HeadContact(key: 'MDD', name: 'M', phone: ' ');
      expect(await build().hasHead(), isFalse);
      expect(await build().recipients(),
          ['0918 000 0002', '0917-000-0001', '0919 000 0003']);
    });

    test('not Android: unavailable, nothing sent', () async {
      android = false;
      expect(await build().notifyDepositAdded(bankName: 'BDO', amount: 1),
          CollectionSmsOutcome.unavailable);
      expect(sent, isEmpty);
      expect(progress, isEmpty);
    });

    test('permission refused: the Messages app opens with everyone', () async {
      granted = false;
      expect(await build().notifyAccountDeferred(clientName: 'X', remarks: 'r'),
          CollectionSmsOutcome.handedOff);
      expect(sent, isEmpty);
      expect(handedOff.single.$1,
          ['0917 000 0001', '0918 000 0002', '0919 000 0003']);
      expect(handedOff.single.$2, 'Postponed X. Reason: r. - MAR',
          reason: 'the Messages app gets the signed text too');
      expect(progress, isEmpty, reason: 'no radio send, no sending view');
    });

    test('no SIM or service: failed with the reason, before any send',
        () async {
      networkIssue = 'The SIM is not ready for SMS messaging (ABSENT).';
      expect(await build().notifyCwtPickup(clientName: 'X', remarks: 'r'),
          CollectionSmsOutcome.failed);
      expect(sent, isEmpty);
      expect(progress, isEmpty);
      expect(reported.single.$3, contains('SIM is not ready'));
    });

    test(
        'one recipient failing does not stop the others; all failing is failed',
        () async {
      failFor = {'0918 000 0002'};
      expect(
          await build().notifyAcquiringAccounts(const [
            SmsAccountLine(clientName: 'X', poNumbers: [], invoiceIds: ['S1'])
          ]),
          CollectionSmsOutcome.unconfirmed,
          reason: 'two of three went out: a warning, not Message Sent');
      expect(sent.length, 2);
      expect(progressClosed, 1);

      sent = [];
      failFor = {'0917 000 0001', '0918 000 0002', '0919 000 0003'};
      expect(
          await build().notifyAcquiringAccounts(const [
            SmsAccountLine(clientName: 'X', poNumbers: [], invoiceIds: ['S1'])
          ]),
          CollectionSmsOutcome.failed);
      expect(progressClosed, 2, reason: 'the view comes down on failure too');
      expect(sentViews, 0, reason: 'neither run was fully confirmed');
    });

    test(
        'a missing SENT report is a warning, not Message Sent, and cannot '
        'hold the view', () async {
      silentFor = {'0917 000 0001'};
      contacts = [];
      final started = DateTime.now();
      expect(await build().notifyCwtPickup(clientName: 'X', remarks: 'r'),
          CollectionSmsOutcome.unconfirmed);
      expect(
          DateTime.now().difference(started),
          lessThan(CollectionSmsService.sentConfirmationTimeout +
              const Duration(seconds: 2)));
      expect(progressClosed, 1);
      expect(sentViews, 0,
          reason: 'Logistics shows Message Sent only when '
              'every recipient is confirmed');
      expect(reported.single.$3, contains('SIM load'));
    });

    test('sends overlapping in time go out one after another', () async {
      contacts = [];
      final events = <String>[];
      final svc = CollectionSmsService(
        report: (_, __, ___) {},
        openProgress: (_) => events.add('open'),
        closeProgress: () => events.add('close'),
        showSent: () async {
          events.add('sent view');
          await Future<void>.delayed(const Duration(milliseconds: 20));
          events.add('sent view closed');
        },
        networkIssue: () async => null,
        betweenRecipients: Duration.zero,
        head: () async => head,
        contacts: () async => contacts,
        permission: () async => true,
        send: (to, message, onStatus) async {
          events.add(message);
          onStatus(SendStatus.SENT);
        },
        smsAvailable: () => true,
        initials: () => '',
      );
      final outcomes = await Future.wait([
        svc.notifyEngagementCleared(clientName: 'A'),
        svc.notifyEngagementCleared(clientName: 'B'),
      ]);
      expect(outcomes, everyElement(CollectionSmsOutcome.sent));
      // The outcome does not wait for the last "Message Sent!" to close.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
          events,
          [
            'open',
            'Done with A.',
            'close',
            'sent view',
            'sent view closed',
            'open',
            'Done with B.',
            'close',
            'sent view',
            'sent view closed',
          ],
          reason:
              'B opens nothing until A, its Message Sent included, is done');
    });

    test('one confirmed and one silent is unconfirmed', () async {
      silentFor = {'0918 000 0002'};
      contacts = ['0918 000 0002'];
      expect(await build().notifyCwtPickup(clientName: 'X', remarks: 'r'),
          CollectionSmsOutcome.unconfirmed);
      expect(sent.length, 2);
      expect(sentViews, 0);
    });

    test('willSend: a screen knows ahead whether the sending view follows',
        () async {
      final svc = build();
      await svc.recipients();
      expect(svc.willSend(), isTrue);
      expect(svc.willSend(status: 'Collected'), isTrue);
      expect(svc.willSend(status: 'Partially Collected'), isTrue);
      expect(svc.willSend(status: 'Pre-Collection'), isFalse,
          reason: 'no SMS for that outcome, so the screen keeps its snackbar');

      head = null;
      contacts = [];
      await svc.recipients();
      expect(svc.willSend(), isFalse, reason: 'nobody to text');

      android = false;
      expect(build().willSend(), isFalse);
    });

    test('an outcome that is not Collected or Partial sends nothing', () async {
      final r = await build().notifyEngagementSaved(
          clientName: 'X',
          poNumbers: [],
          invoices: const [SmsInvoiceLine(id: 'S1', amount: 0)],
          status: 'Pre-Collection');
      expect(r, isNull);
      expect(sent, isEmpty);
    });
  });

  group('controller', () {
    test('Clear Engagement passes the outcome through and survives no service',
        () async {
      final c = _Activity();
      Get.put<CollectionActivityController>(c);
      expect(await c.notifyEngagementCleared(clientName: 'X'), isNull);

      final sent = <String>[];
      Get.put(CollectionSmsService(
        report: (_, __, ___) {},
        openProgress: (_) {},
        closeProgress: () {},
        showSent: () async {},
        networkIssue: () async => null,
        head: () async =>
            const HeadContact(key: 'MDD', name: 'M', phone: '0917'),
        contacts: () async => [],
        permission: () async => true,
        send: (_, message, onStatus) async {
          sent.add(message);
          onStatus(SendStatus.SENT);
        },
        smsAvailable: () => true,
      ));
      expect(await c.notifyEngagementCleared(clientName: 'Metro Globe'),
          CollectionSmsOutcome.sent);
      expect(sent.single, 'Done with Metro Globe.',
          reason: 'no signed-in user in the test, so no initials');
    });
  });
}
