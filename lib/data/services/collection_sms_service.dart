import 'package:flutter/widgets.dart';
import 'dart:async';

import 'package:another_telephony/telephony.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_sms_outbox_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/deposit_remarks.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_directory_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// The Head the collector chose (Settings → My Head) and how to reach them.
class HeadContact {
  const HeadContact(
      {required this.key, required this.name, required this.phone});

  final String key;
  final String name;

  /// '' when the directory has no number for them.
  final String phone;

  bool get hasPhone => phone.trim().isNotEmpty;
}

/// What happened to a Collection SMS.
enum CollectionSmsOutcome {
  /// The radio reported SENT for every recipient.
  sent,

  /// The phone accepted the send, but the radio did not report SENT for at
  /// least one recipient in time. Usually no SIM load / credit, or a carrier
  /// delay. Not tried again by itself: it waits for a hand Resend.
  unconfirmed,

  /// No Head with a number and no Collection contact: nobody to tell.
  noRecipients,

  /// Not Android, so there is no radio to send over (Windows).
  unavailable,

  /// The phone could not send it (no SIM, no service, no permission) or every
  /// send failed. Tried again by itself.
  failed,
}

/// How one recipient's send ended.
enum _RecipientResult { confirmed, unconfirmed, failed }

/// How one attempt went: the outcome, why when it went wrong, how many
/// were to receive it, and each number's [SmsRecipientResult].
class _Delivery {
  const _Delivery(this.outcome, this.reason, this.recipients, this.results);

  final CollectionSmsOutcome outcome;
  final String? reason;
  final int recipients;
  final Map<String, String> results;
}

/// The trigger each Collection SMS came from, as the SMS Outbox names it.
abstract final class SmsKind {
  static const acquiring = 'Acquiring Account';
  static const engagement = 'Saving Engagement';
  static const deferred = 'Defer Account';
  static const cleared = 'Clear Engagement';
  static const deposit = 'Adding Deposit';
  static const cwt = 'CWT Pick-Up';
  static const routing = 'Routing of Documents';
  static const escalated = 'Reconciliation Escalated';
}

/// One invoice in an Engagement Saved message.
class SmsInvoiceLine {
  const SmsInvoiceLine({required this.id, required this.amount});

  final String id;
  final double amount;
}

/// One account in an Acquiring Account message.
class SmsAccountLine {
  const SmsAccountLine({
    required this.clientName,
    required this.poNumbers,
    required this.invoiceIds,
    this.amount,
    this.reconciliation = false,
  });

  final String clientName;
  final Iterable<String> poNumbers;
  final Iterable<String> invoiceIds;

  /// The balance taken on; left out of the message when null.
  final double? amount;

  /// Taken on for reconciliation (its invoices were marked Reconciliation),
  /// not for collection. The message says so.
  final bool reconciliation;
}

typedef HeadContactResolver = Future<HeadContact?> Function();
typedef ContactNumbersResolver = Future<List<String>> Function();
typedef SmsSender = Future<void> Function(
    String to, String message, void Function(SendStatus status) onStatus);
typedef SmsPermission = Future<bool> Function();
typedef NetworkIssueChecker = Future<String?> Function();
typedef SmsOutcomeReporter = void Function(
    CollectionSmsOutcome outcome, int recipients, String? reason);
typedef InitialsResolver = String Function();

/// The eight Collection SMS triggers: Acquiring Account, Saving Engagement,
/// Defer Account, Clear Engagement, Adding Deposit, CWT Pick-Up, Routing of
/// Documents and Reconciliation Escalated (the last to the Head only).
///
/// Every message goes to the collector's Head (Settings → My Head, at the
/// number the user directory holds) **and** to the Contact Directory contacts
/// tagged with department "Collection".
///
/// Sending is in the background. A message is saved to the SMS Outbox and
/// sent from there, one message and one recipient at a time, with no view,
/// dialog or wait on the collector's screen: their work goes straight on. A
/// message the phone could not send (no signal, no SIM, no permission) is
/// tried again by itself; one the phone accepted but never confirmed waits
/// for a hand Resend, since sending it again might text the Head twice. The
/// Outbox keeps the day's messages; sent ones are cleared at midnight.
/// Android-only: a clean no-op on Windows.
///
/// The message builders are static and pure; the notify methods never throw.
class CollectionSmsService extends GetxController with WidgetsBindingObserver {
  CollectionSmsService({
    HeadContactResolver? head,
    ContactNumbersResolver? contacts,
    SmsSender? send,
    SmsPermission? permission,
    NetworkIssueChecker? networkIssue,
    bool Function()? smsAvailable,
    SmsOutcomeReporter? report,
    InitialsResolver? initials,
    Future<CollectionSmsOutboxDao?> Function()? outbox,
    DateTime Function()? now,
    Duration betweenRecipients = const Duration(seconds: 1),
    Duration confirmTimeout = defaultConfirmTimeout,
    bool timers = true,
  })  : _head = head ?? _headFromDirectory,
        _contacts = contacts ?? _collectionContacts,
        _sendOne = send,
        _permission = permission,
        _networkIssue = networkIssue,
        _smsAvailable = smsAvailable ?? (() => GetPlatform.isAndroid),
        _reportHook = report,
        _initials = initials ?? _collectorInitials,
        _outbox = outbox,
        _now = now ?? DateTime.now,
        _betweenRecipients = betweenRecipients,
        _confirmTimeout = confirmTimeout,
        _timersOn = timers;

  static CollectionSmsService get instance => Get.find();

  /// Department tag used to select Collection SMS recipients in the Contact
  /// Directory (`contacts` table).
  static const String recipientDepartment = 'Collection';

  /// Bounds on the radio: the platform call itself, then the SENT report.
  /// Nobody waits on the report any more, so it is given 30 seconds (it was
  /// 3 while the sending view held the screen); a slow carrier then reads
  /// as sent rather than as "not confirmed".
  static const Duration sendCallTimeout = Duration(seconds: 15);
  static const Duration defaultConfirmTimeout = Duration(seconds: 30);

  final HeadContactResolver _head;
  final ContactNumbersResolver _contacts;
  final SmsSender? _sendOne;
  final SmsPermission? _permission;
  final NetworkIssueChecker? _networkIssue;
  final bool Function() _smsAvailable;
  final SmsOutcomeReporter? _reportHook;
  final InitialsResolver _initials;
  final Future<CollectionSmsOutboxDao?> Function()? _outbox;
  final DateTime Function() _now;
  final Duration _betweenRecipients;
  final Duration _confirmTimeout;
  final bool _timersOn;

  @override
  void onInit() {
    super.onInit();
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (e) {
      logDebug('CollectionSmsService: lifecycle unavailable: $e');
    }
    // Clear yesterday's sent messages, then send whatever is still waiting
    // (the app may have closed with messages in the outbox).
    // ignore: unawaited_futures
    refreshOutbox(purge: true).then((_) => dispatchPending());
    _scheduleMidnight();
  }

  @override
  void onClose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _retryTimer?.cancel();
    _midnightTimer?.cancel();
    super.onClose();
  }

  /// Back in front: a new day may have started, the signal may be back, and
  /// SMS permission may have been turned on in the phone's settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _permissionAsked = false;
    // ignore: unawaited_futures
    refreshOutbox(purge: true).then((_) => dispatchPending());
  }

  Telephony? _telephony;
  Telephony get _telephonyInstance => _telephony ??= Telephony.instance;

  // ------------------------------------------------------------------
  // Templates
  // ------------------------------------------------------------------

  static List<String> _items(Iterable<String> values) {
    final seen = <String>{};
    return [
      for (final v in values.map((v) => v.trim()))
        if (v.isNotEmpty && seen.add(v)) v,
    ];
  }

  /// "PO: 230736" / "POs: 2026-0323, 2026-0309"; '' when there are none.
  static String _labelled(String one, String many, Iterable<String> values) {
    final items = _items(values);
    if (items.isEmpty) return '';
    return '${items.length == 1 ? one : many}: ${items.join(', ')}';
  }

  /// "PHP 37,759.82", not "₱37,759.82": the peso sign is outside the GSM-7
  /// SMS alphabet, and one such character turns the whole message into UCS-2,
  /// where a single SMS holds 70 characters instead of 160.
  static String _peso(double amount) =>
      'PHP ${BFormatter.formatPesoCurrency(amount, includeSymbol: false).trim()}';

  /// "Note: [text]" or '' when blank.
  static String _note(String label, String? value) {
    final t = _text(value, none: '');
    return t.isEmpty ? '' : '$label: $t';
  }

  /// One fact per line, blank parts left out.
  ///
  /// The messages used to be one run of sentences, and with invoice numbers,
  /// amounts, POs, check numbers and dates side by side the Head could not
  /// tell which number was which. Now each number sits on its own line
  /// behind a label. A line break is in the GSM-7 alphabet, so it costs one
  /// character, like the ". " it replaces.
  static String _lines(Iterable<String> lines) =>
      lines.map((l) => l.trim()).where((l) => l.isNotEmpty).join('\n');

  /// [name] tidied for the end of a line: a stray closing period goes, but
  /// "Corp." or "Inc." keeps its own.
  static String _name(String name) {
    final n = _text(name, none: '');
    if (_abbrev.hasMatch(n)) return n;
    return n.replaceFirst(RegExp(r'\.+$'), '');
  }

  static final RegExp _abbrev =
      RegExp(r'\b(Corp|Inc|Co|Ltd|Bros|Jr|Sr)\.$', caseSensitive: false);

  // Each message leads with what happened and to whom, on the first line,
  // so the notification preview alone tells the Head. The details follow,
  // one labelled line each. The collector's initials are added by [send].

  /// 1. Acquiring Account:
  ///
  ///     Now handling: Abbott Laboratories
  ///     1 PO, 1 invoice
  ///     Balance: PHP 112,000.00
  ///
  /// Counts, not the numbers themselves: an account can carry dozens of
  /// invoices. Reconciliation lists every number, because the Head checks
  /// them one by one against the office's records:
  ///
  ///     Now handling for reconciliation: Amka Trading
  ///     POs: 1, 2
  ///     Invoices: a, b
  ///     Balance: PHP 118,139.87
  ///
  /// [amount] is the balance taken on; left out when null.
  static String acquiringAccount({
    required String clientName,
    required Iterable<String> poNumbers,
    required Iterable<String> invoiceIds,
    double? amount,
    bool reconciliation = false,
  }) {
    final name = _name(clientName);
    if (reconciliation) {
      return _lines([
        'Now handling for reconciliation: $name',
        _labelled('PO', 'POs', poNumbers),
        _labelled('Invoice', 'Invoices', invoiceIds),
        if (amount != null) 'Balance: ${_peso(amount)}',
      ]);
    }
    return _lines([
      'Now handling: $name',
      _counts(poNumbers, invoiceIds),
      if (amount != null) 'Balance: ${_peso(amount)}',
    ]);
  }

  /// "5 POs, 6 invoices"; '' when there are neither.
  static String _counts(Iterable<String> pos, Iterable<String> invoices) => [
        _count(_items(pos).length, 'PO', 'POs'),
        _count(_items(invoices).length, 'invoice', 'invoices'),
      ].where((s) => s.isNotEmpty).join(', ');

  /// 1, for one acquire of several accounts: ONE message, not one each,
  /// numbered so each account's figures stay with its name:
  ///
  ///     Now handling 3 accounts
  ///     1. Alexis Yu Best Care Pharmacy
  ///     5 POs, 6 invoices, PHP 95,198.18
  ///     2. ...
  ///     Total: PHP 271,170.59
  ///
  /// One account reads as [acquiringAccount].
  static String acquiringAccounts(List<SmsAccountLine> accounts) {
    if (accounts.length == 1) {
      final a = accounts.single;
      return acquiringAccount(
          clientName: a.clientName,
          poNumbers: a.poNumbers,
          invoiceIds: a.invoiceIds,
          amount: a.amount,
          reconciliation: a.reconciliation);
    }
    final lines = <String>['Now handling ${accounts.length} accounts'];
    for (final (i, a) in accounts.indexed) {
      final name = _name(a.clientName);
      if (a.reconciliation) {
        // Every PO and invoice, as for one account.
        lines.addAll([
          '${i + 1}. $name (reconciliation)',
          _labelled('PO', 'POs', a.poNumbers),
          _labelled('Invoice', 'Invoices', a.invoiceIds),
          if (a.amount != null) 'Balance: ${_peso(a.amount!)}',
        ]);
      } else {
        lines.addAll([
          '${i + 1}. $name',
          [
            _counts(a.poNumbers, a.invoiceIds),
            if (a.amount != null) _peso(a.amount!),
          ].where((s) => s.isNotEmpty).join(', '),
        ]);
      }
    }
    final amounts = accounts.map((a) => a.amount).whereType<double>();
    if (amounts.isNotEmpty) {
      lines.add(
          'Total: ${_peso(amounts.fold<double>(0, (sum, v) => sum + v))}');
    }
    return _lines(lines);
  }

  /// "1 PO" / "5 POs"; '' for none.
  static String _count(int n, String one, String many) =>
      n == 0 ? '' : '$n ${n == 1 ? one : many}';

  /// The status word for an outcome, or null when that outcome sends
  /// nothing (Pre-Collection, Follow Up, ...).
  static String? collectionStatusWord(String status) {
    final s = status.trim().toLowerCase();
    if (s == CollectionStatusColors.statusCollected.toLowerCase()) {
      return 'Collected';
    }
    if (s == CollectionStatusColors.statusPartial.toLowerCase() ||
        s == 'partial payment' ||
        s == 'partial') {
      return 'Partial';
    }
    return null;
  }

  /// 2. Saving Engagement:
  ///
  ///     Collected: Accusure Medical Enterprises
  ///     Amount: PHP 24,281.25
  ///     Invoice: 700013391
  ///     PO: 2026-0309
  ///     Check: BDO 4588255
  ///     Check Date: 09-28-2026
  ///
  /// Partial reads "Partial payment: ...". Several invoices list each with
  /// its amount, one per line, under "Invoices:". The check lines only when
  /// paid by check: the bank and number, and the date on its own line.
  static String engagementSaved({
    required String clientName,
    required Iterable<String> poNumbers,
    required List<SmsInvoiceLine> invoices,
    required String status,
    String? bankName,
    String? checkNumber,
    String? checkDate,
  }) {
    final lines = invoices.where((i) => i.id.trim().isNotEmpty).toList();
    final total = lines.fold<double>(0, (sum, i) => sum + i.amount);
    return _lines([
      '${status == 'Partial' ? 'Partial payment' : 'Collected'}: '
          '${_name(clientName)}',
      'Amount: ${_peso(total)}',
      if (lines.length == 1) 'Invoice: ${lines.single.id.trim()}',
      if (lines.length > 1) ...[
        'Invoices:',
        for (final i in lines) '${i.id.trim()} - ${_peso(i.amount)}',
      ],
      _labelled('PO', 'POs', poNumbers),
      ..._checkDetails(bankName, checkNumber, checkDate),
    ]);
  }

  /// "Check: BDO 4588255" and "Check Date: 09-28-2026", each only when
  /// given; none for cash. The date has its own line and label: run on
  /// after the check number as ", dated …" it read as more of the number.
  static List<String> _checkDetails(
      String? bankName, String? checkNumber, String? checkDate) {
    final what = [_text(bankName, none: ''), _text(checkNumber, none: '')]
        .where((s) => s.isNotEmpty)
        .join(' ');
    final date = _text(checkDate, none: '');
    return [
      if (what.isNotEmpty) 'Check: $what',
      if (date.isNotEmpty) 'Check Date: $date',
    ];
  }

  /// 3. "Postponed: [Client]" / "Reason: [Remarks]".
  static String accountDeferred(
          {required String clientName, required String remarks}) =>
      _lines(['Postponed: ${_name(clientName)}', _note('Reason', remarks)]);

  /// 4. "Done: [Client]".
  static String engagementCleared({required String clientName}) =>
      'Done: ${_name(clientName)}';

  /// 5. Adding Deposit; the optional lines left out when blank:
  ///
  ///     Deposited: PHP 30,000.00
  ///     Deposited At Bank: BDO
  ///     Check: 1254897
  ///     Antipolo Doctors Hospital - PHP 25,000.00
  ///     Ace Diagnostics Corp. - PHP 5,000.00
  ///     Note: Morning run
  ///
  /// The remarks are the deposit's accounts, "Account - Amount" one per line
  /// ([BDepositRemarks]), and its note: each keeps its own line. Remarks
  /// written before that format read as one "Note:" line, as they did.
  static String depositAdded({
    required String bankName,
    required double amount,
    String? checkNumber,
    String? remarks,
  }) =>
      _lines([
        'Deposited: ${_peso(amount)}',
        _note('Deposited At Bank', bankName),
        _note('Check', checkNumber),
        ..._depositRemarks(remarks),
      ]);

  static List<String> _depositRemarks(String? remarks) {
    final lines = (remarks ?? '')
        .split('\n')
        .map((l) => _text(l, none: ''))
        .where((l) => l.isNotEmpty)
        .toList();
    final structured = lines.any((l) =>
        BDepositRemarks.parseLine(l) != null || l.startsWith('Note:'));
    if (!structured) {
      final note = _note('Note', lines.join(' '));
      return note.isEmpty ? const [] : [note];
    }
    return [
      for (final l in lines)
        switch (BDepositRemarks.parseLine(l)) {
          final p? => '${p.account} - PHP ${p.amount}',
          null => l,
        },
    ];
  }

  /// 6. "Picked up CWT: [Client]" / "Note: [Remarks]".
  static String cwtPickup(
          {required String clientName, required String remarks}) =>
      _lines(['Picked up CWT: ${_name(clientName)}', _note('Note', remarks)]);

  /// 8. "Routed documents: [Client]" / "Note: [Remarks]".
  static String documentsRouted(
          {required String clientName, required String remarks}) =>
      _lines(['Routed documents: ${_name(clientName)}', _note('Note', remarks)]);

  /// 7. Reconciliation escalated (Reconciliation Tracker, to the Head only):
  ///
  ///     Reconciliation escalated: [Client]
  ///     Open: 2 invoices, PHP 276,995.00
  ///     Reason: [Remarks]
  static String reconEscalated({
    required String clientName,
    required int openInvoices,
    required double openAmount,
    String remarks = '',
  }) =>
      _lines([
        'Reconciliation escalated: ${_name(clientName)}',
        'Open: $openInvoices ${openInvoices == 1 ? 'invoice' : 'invoices'}, '
            '${_peso(openAmount)}',
        _note('Reason', remarks),
      ]);

  /// The message with "- MAR" on its own last line: who sent it, since the
  /// Head hears from every collector. A plain hyphen, not a dash: a dash is
  /// outside GSM-7 too.
  static String signed(String message, String initials) {
    final i = initials.trim();
    return i.isEmpty ? message : '$message\n- $i';
  }

  static String _text(String? value, {String none = 'none'}) {
    final t = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    return t.isEmpty ? none : t;
  }

  // ------------------------------------------------------------------
  // Triggers
  // ------------------------------------------------------------------

  /// Every account of one acquire in a single message.
  Future<CollectionSmsOutcome?> notifyAcquiringAccounts(
      List<SmsAccountLine> accounts) {
    if (accounts.isEmpty) return Future.value(null);
    return send(acquiringAccounts(accounts), kind: SmsKind.acquiring);
  }

  /// Sends only for a Collected or Partial outcome; other outcomes resolve
  /// to null without sending.
  Future<CollectionSmsOutcome?> notifyEngagementSaved({
    required String clientName,
    required Iterable<String> poNumbers,
    required List<SmsInvoiceLine> invoices,
    required String status,
    String? bankName,
    String? checkNumber,
    String? checkDate,
  }) {
    final word = collectionStatusWord(status);
    if (word == null) return Future.value(null);
    return send(engagementSaved(
        clientName: clientName,
        poNumbers: poNumbers,
        invoices: invoices,
        status: word,
        bankName: bankName,
        checkNumber: checkNumber,
        checkDate: checkDate),
        kind: SmsKind.engagement);
  }

  Future<CollectionSmsOutcome> notifyAccountDeferred(
          {required String clientName, required String remarks}) =>
      send(accountDeferred(clientName: clientName, remarks: remarks),
          kind: SmsKind.deferred);

  Future<CollectionSmsOutcome> notifyEngagementCleared(
          {required String clientName}) =>
      send(engagementCleared(clientName: clientName),
          kind: SmsKind.cleared);

  Future<CollectionSmsOutcome> notifyDepositAdded({
    required String bankName,
    required double amount,
    String? checkNumber,
    String? remarks,
  }) =>
      send(depositAdded(
          bankName: bankName,
          amount: amount,
          checkNumber: checkNumber,
          remarks: remarks),
          kind: SmsKind.deposit);

  Future<CollectionSmsOutcome> notifyCwtPickup(
          {required String clientName, required String remarks}) =>
      send(cwtPickup(clientName: clientName, remarks: remarks),
          kind: SmsKind.cwt);

  Future<CollectionSmsOutcome> notifyDocumentsRouted(
          {required String clientName, required String remarks}) =>
      send(documentsRouted(clientName: clientName, remarks: remarks),
          kind: SmsKind.routing);

  /// A case escalated to the Head: the Head alone is told, not the
  /// Collection contacts; an escalation is theirs to take on.
  Future<CollectionSmsOutcome> notifyReconEscalated({
    required String clientName,
    required int openInvoices,
    required double openAmount,
    String remarks = '',
  }) =>
      send(
          reconEscalated(
              clientName: clientName,
              openInvoices: openInvoices,
              openAmount: openAmount,
              remarks: remarks),
          headOnly: true,
          kind: SmsKind.escalated);

  /// Whether a Head with a number is set, for the one-time Settings hint.
  Future<bool> hasHead() async {
    try {
      final head = await _head();
      return head != null && head.hasPhone;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------------
  // Delivery
  // ------------------------------------------------------------------

  /// The Head first, then the Collection contacts, without duplicates.
  /// [headOnly]: the Head alone (a reconciliation escalation).
  Future<List<String>> recipients({bool headOnly = false}) async {
    final numbers = <String>[];
    try {
      final head = await _head();
      if (head != null && head.hasPhone) numbers.add(head.phone.trim());
    } catch (e) {
      logDebug('CollectionSmsService: head lookup failed: $e');
    }
    if (headOnly) return numbers;
    try {
      numbers.addAll(await _contacts());
    } catch (e) {
      logDebug('CollectionSmsService: contacts lookup failed: $e');
    }
    final seen = <String>{};
    return [
      for (final n in numbers)
        if (n.trim().isNotEmpty && seen.add(_digits(n))) n.trim(),
    ];
  }

  static String _digits(String number) => number.replaceAll(RegExp(r'\D'), '');

  /// Every send runs after the one before it: one message at a time, one
  /// recipient at a time.
  Future<void> _queue = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() job) {
    final result = _queue.then((_) => job());
    _queue = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  /// Completes once every send queued so far is done. Never fails.
  Future<void> get settled => _queue;

  /// Save [message] to the SMS Outbox and send it in the background. [kind]
  /// names the trigger in the Outbox. Never throws, and nothing shows on
  /// screen: the collector's screen does not wait for it (callers do not
  /// await it). Resolves to how the first attempt went; a message the phone
  /// could not send is tried again by itself (see [dispatchPending]).
  Future<CollectionSmsOutcome> send(String message,
      {bool headOnly = false, String kind = ''}) async {
    final text = signed(message, _safeInitials());
    if (!_smsAvailable()) {
      _report(const _Delivery(CollectionSmsOutcome.unavailable, null, 0, {}));
      return CollectionSmsOutcome.unavailable;
    }
    final to = await recipients(headOnly: headOnly);
    final record = await _recordNew(
        kind: kind, message: text, headOnly: headOnly, to: to);
    if (to.isEmpty) {
      _report(const _Delivery(CollectionSmsOutcome.noRecipients,
          'No Head with a number and no Collection contact.', 0, {}));
      return CollectionSmsOutcome.noRecipients;
    }
    if (record == null) {
      // No outbox (its table cannot be written): send once, quietly, as
      // before. The outbox must never stop a message from going out.
      return _serial(() async {
        final delivery = await _deliver(to, text);
        _report(delivery);
        return delivery.outcome;
      });
    }
    return await _serial<CollectionSmsOutcome?>(() => _attempt(record.id)) ??
        CollectionSmsOutcome.failed;
  }

  /// Send outbox message [id] again now, to every original recipient that
  /// has not confirmed it, "not confirmed" ones included (Settings → SMS
  /// Outbox). Null when there is nothing to send.
  Future<CollectionSmsOutcome?> resend(String id) =>
      _serial(() => _attempt(id, byHand: true));

  /// Send a message that already went out again, the same text to every
  /// one of its original recipients (Settings → SMS Outbox → Sent today →
  /// Resend), e.g. when the Head says it never arrived. Queued like any
  /// other; a number that fails this time is retried by itself.
  Future<CollectionSmsOutcome?> resendToEveryone(String id) =>
      _serial(() => _attempt(id, everyone: true));

  /// Resends each of [ids], one after another. Returns how many went out in
  /// full.
  Future<int> resendAll(Iterable<String> ids) async {
    var sent = 0;
    for (final id in ids.toList()) {
      if (await resend(id) == CollectionSmsOutcome.sent) sent++;
    }
    return sent;
  }

  /// Removes outbox message [id] (the collector decided not to send it).
  Future<void> discard(String id) async {
    final dao = await _outboxDao();
    if (dao == null) return;
    await _safely(() => dao.delete(id));
    await refreshOutbox();
  }

  /// Every outbox message, newest first; empty when there is no outbox.
  Future<List<SmsOutboxRecord>> outboxMessages() async {
    final dao = await _outboxDao();
    if (dao == null) return const [];
    return await _safely(dao.getAll) ?? const [];
  }

  /// One attempt at outbox message [id]: its numbers that never got it (or,
  /// [byHand], every number not confirmed; [everyone], all of them). Null
  /// when there is none to try.
  Future<CollectionSmsOutcome?> _attempt(String id,
      {bool byHand = false, bool everyone = false}) async {
    final dao = await _outboxDao();
    if (dao == null) return null;
    final record = await _safely(() => dao.getById(id));
    if (record == null) return null;
    final targets = everyone
        ? [for (final r in record.recipients) r.number]
        : byHand
            ? record.unconfirmedNumbers
            : record.retryableNumbers;
    if (targets.isEmpty) return null;
    final delivery = await _deliver(targets, record.message);
    await _recordResult(record, targets, delivery);
    _report(delivery);
    _scheduleRetry();
    return delivery.outcome;
  }

  // ------------------------------------------------------------------
  // Background dispatch
  // ------------------------------------------------------------------

  /// A message is tried by itself at most this many times; after that it
  /// waits for a hand Resend.
  static const int maxAutoAttempts = 10;

  /// How long to wait before trying again, after each failed attempt; the
  /// last applies to every attempt after it.
  static const List<Duration> retryDelays = [
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
  ];

  static Duration retryDelay(int attempts) =>
      retryDelays[(attempts - 1).clamp(0, retryDelays.length - 1)];

  bool _dispatching = false;
  bool _dispatchAgain = false;
  Timer? _retryTimer;
  Timer? _midnightTimer;

  /// Sends, one after another, every outbox message due: never tried, or
  /// failed and past its wait. Run at start-up, when the app comes back to
  /// the front, and when a retry falls due. Never throws.
  Future<void> dispatchPending() async {
    if (_dispatching) {
      _dispatchAgain = true;
      return;
    }
    _dispatching = true;
    try {
      do {
        _dispatchAgain = false;
        for (final m in await _dueMessages()) {
          await _serial(() => _attempt(m.id));
        }
      } while (_dispatchAgain);
    } catch (e) {
      logDebug('CollectionSmsService.dispatchPending error: $e');
    } finally {
      _dispatching = false;
      _scheduleRetry();
    }
  }

  /// Messages with a number still to reach, oldest first; with [due], only
  /// those whose wait is over.
  Future<List<SmsOutboxRecord>> _retryable({bool due = true}) async {
    final all = await outboxMessages();
    final now = _now();
    return [
      for (final m in all.reversed)
        if (m.status != SmsOutboxStatus.noRecipients &&
            m.retryableNumbers.isNotEmpty &&
            m.attempts < maxAutoAttempts &&
            (!due || !_nextTry(m).isAfter(now)))
          m,
    ];
  }

  Future<List<SmsOutboxRecord>> _dueMessages() => _retryable();

  DateTime _nextTry(SmsOutboxRecord m) {
    final last = DateTime.tryParse(m.lastAttemptAt ?? '');
    if (m.attempts == 0 || last == null) return DateTime(0);
    return last.add(retryDelay(m.attempts));
  }

  /// One timer, for the next message whose wait ends.
  void _scheduleRetry() {
    if (!_timersOn) return;
    // ignore: unawaited_futures
    _retryable(due: false).then((waiting) {
      _retryTimer?.cancel();
      if (waiting.isEmpty) return;
      final next = waiting.map(_nextTry).reduce((a, b) => a.isBefore(b) ? a : b);
      var wait = next.difference(_now());
      if (wait.isNegative) wait = Duration.zero;
      _retryTimer = Timer(wait, () {
        // ignore: unawaited_futures
        dispatchPending();
      });
    }).catchError((Object e) {
      logDebug('CollectionSmsService: retry not scheduled: $e');
    });
  }

  /// At 00:00 the day's sent messages are cleared, so the Outbox starts
  /// each day fresh.
  void _scheduleMidnight() {
    if (!_timersOn) return;
    _midnightTimer?.cancel();
    final now = _now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(midnight.difference(now), () {
      // ignore: unawaited_futures
      refreshOutbox(purge: true);
      _scheduleMidnight();
    });
  }

  // ------------------------------------------------------------------
  // Sending
  // ------------------------------------------------------------------

  /// Asked at most once per app run, and again when the app comes back to
  /// the front: a refusal leaves the messages in the outbox instead of
  /// asking again and again in the background.
  bool _permissionAsked = false;
  bool _permissionGranted = false;

  Future<bool> _hasPermission() async {
    if (_permissionGranted) return true;
    if (_permissionAsked) return false;
    _permissionAsked = true;
    try {
      _permissionGranted = await (_permission ?? _ensurePermission)();
    } catch (e) {
      logDebug('CollectionSmsService: permission check failed: $e');
      _permissionGranted = false;
    }
    return _permissionGranted;
  }

  static const String permissionOffReason =
      'SMS permission is off for this app. Allow it in the phone settings; '
      'the message waits here and goes out by itself.';

  /// One attempt at [to], quietly: the outcome, why when it went wrong, and
  /// each number's [SmsRecipientResult].
  Future<_Delivery> _deliver(List<String> to, String message) async {
    String? reason;
    var results = <String, String>{};
    CollectionSmsOutcome outcome;
    try {
      if (to.isEmpty) {
        outcome = CollectionSmsOutcome.noRecipients;
      } else if (!_smsAvailable()) {
        outcome = CollectionSmsOutcome.unavailable;
      } else if (!await _hasPermission()) {
        outcome = CollectionSmsOutcome.failed;
        reason = permissionOffReason;
      } else {
        reason = await (_networkIssue ?? _likelyNetworkIssue)();
        if (reason != null) {
          logDebug('CollectionSmsService: $reason');
          outcome = CollectionSmsOutcome.failed;
        } else {
          final sent = await _sendEach(to, message);
          outcome = sent.outcome;
          results = sent.results;
          if (outcome == CollectionSmsOutcome.failed) {
            reason = 'The phone did not accept the message for sending.';
          } else if (outcome == CollectionSmsOutcome.unconfirmed) {
            reason = 'The phone did not confirm the SMS as sent within '
                '${_confirmTimeout.inSeconds} seconds. Check the SIM load or '
                'balance and the signal, then resend.';
          }
        }
      }
    } catch (e) {
      logDebug('CollectionSmsService.send error: $e');
      outcome = CollectionSmsOutcome.failed;
      reason = e.toString();
    }
    return _Delivery(outcome, reason, to.length, results);
  }

  /// One recipient at a time, each send bounded by a timeout.
  Future<({CollectionSmsOutcome outcome, Map<String, String> results})>
      _sendEach(List<String> to, String message) async {
    final results = <String, String>{};
    var confirmed = 0;
    var unconfirmed = 0;
    for (var i = 0; i < to.length; i++) {
      switch (await _sendToRecipient(to[i], message)) {
        case _RecipientResult.confirmed:
          confirmed++;
          results[to[i]] = SmsRecipientResult.sent;
        case _RecipientResult.unconfirmed:
          unconfirmed++;
          results[to[i]] = SmsRecipientResult.unconfirmed;
        case _RecipientResult.failed:
          results[to[i]] = SmsRecipientResult.failed;
      }
      if (i < to.length - 1 && _betweenRecipients > Duration.zero) {
        await Future.delayed(_betweenRecipients);
      }
    }
    logDebug('CollectionSmsService: confirmed $confirmed, unconfirmed '
        '$unconfirmed of ${to.length}');
    final outcome = confirmed == to.length
        ? CollectionSmsOutcome.sent
        : confirmed + unconfirmed == 0
            ? CollectionSmsOutcome.failed
            : CollectionSmsOutcome.unconfirmed;
    return (outcome: outcome, results: results);
  }

  /// Confirmed when the radio reports SENT within the timeout, unconfirmed
  /// when the phone accepted the send but no report came, failed when the
  /// send threw.
  Future<_RecipientResult> _sendToRecipient(String to, String message) async {
    final sent = Completer<void>();
    void onStatus(SendStatus status) {
      if (status == SendStatus.SENT && !sent.isCompleted) sent.complete();
    }

    try {
      await (_sendOne ?? _sendSms)(to, message, onStatus)
          .timeout(sendCallTimeout);
    } catch (e) {
      logDebug('CollectionSmsService: send to $to failed: $e');
      return _RecipientResult.failed;
    }
    try {
      await sent.future.timeout(_confirmTimeout);
      return _RecipientResult.confirmed;
    } on TimeoutException {
      logDebug('CollectionSmsService: no SENT report for $to within '
          '${_confirmTimeout.inSeconds}s');
      return _RecipientResult.unconfirmed;
    }
  }

  /// Always multipart: Android's divideMessage decides how many parts the
  /// text needs, and a one-part message goes out as a plain SMS. A
  /// `length > 160` test cannot decide it, because the limit depends on the
  /// alphabet (70 for UCS-2); a text over one part sent as a single SMS is
  /// refused by the phone (`getSubmitPdu() returned null`) and never leaves it,
  /// while the plugin still reports SENT.
  Future<void> _sendSms(
          String to, String message, void Function(SendStatus) onStatus) =>
      _telephonyInstance.sendSms(
        to: to,
        message: message,
        isMultipart: true,
        statusListener: onStatus,
      );

  /// Nothing is shown: the outcome goes to the hook (tests) or the log, and
  /// the SMS Outbox carries it for the collector.
  void _report(_Delivery delivery) {
    try {
      final hook = _reportHook;
      if (hook != null) {
        hook(delivery.outcome, delivery.recipients, delivery.reason);
      } else if (delivery.outcome != CollectionSmsOutcome.sent) {
        logDebug('CollectionSmsService: ${delivery.outcome.name}'
            '${delivery.reason == null ? '' : ': ${delivery.reason}'}');
      }
    } catch (e) {
      logDebug('CollectionSmsService: report failed: $e');
    }
  }

  // ------------------------------------------------------------------
  // SMS Outbox
  // ------------------------------------------------------------------

  /// Bumped whenever the outbox changes, so a screen can reload with `ever`.
  final RxInt outboxVersion = 0.obs;

  /// Messages not sent yet (waiting, failed, not confirmed, nobody to text):
  /// the Settings badge.
  final RxInt needsAttention = 0.obs;

  /// Saved before sending, so a message survives the app closing mid-send.
  Future<SmsOutboxRecord?> _recordNew({
    required String kind,
    required String message,
    required bool headOnly,
    required List<String> to,
  }) async {
    final dao = await _outboxDao();
    if (dao == null) return null;
    final now = _now();
    final record = SmsOutboxRecord(
      id: 'SMS-${now.microsecondsSinceEpoch}',
      createdAt: now.toIso8601String(),
      kind: kind,
      message: message,
      headOnly: headOnly,
      status:
          to.isEmpty ? SmsOutboxStatus.noRecipients : SmsOutboxStatus.pending,
      recipients: [
        for (final n in to) SmsOutboxRecipient(n, SmsRecipientResult.pending),
      ],
    );
    try {
      await dao.insert(record);
    } catch (e) {
      logDebug('CollectionSmsService: outbox write failed: $e');
      return null;
    }
    await refreshOutbox();
    return record;
  }

  /// [record] after one attempt at [attempted]: each attempted number takes
  /// its new result (a number the attempt never reached, failed), the
  /// others keep theirs.
  Future<void> _recordResult(
      SmsOutboxRecord record, List<String> attempted, _Delivery delivery) async {
    final dao = await _outboxDao();
    if (dao == null) return;
    final tried = attempted.toSet();
    final recipients = [
      for (final r in record.recipients)
        tried.contains(r.number)
            ? SmsOutboxRecipient(r.number,
                delivery.results[r.number] ?? SmsRecipientResult.failed)
            : r,
    ];
    final updated = record.copyWith(
      status: _statusOf(delivery.outcome, recipients),
      recipients: recipients,
      attempts: record.attempts + 1,
      lastError: delivery.reason,
      clearError: delivery.reason == null,
      lastAttemptAt: _now().toIso8601String(),
    );
    await _safely(() => dao.update(updated));
    await refreshOutbox();
  }

  static String _statusOf(
      CollectionSmsOutcome outcome, List<SmsOutboxRecipient> recipients) {
    if (outcome == CollectionSmsOutcome.noRecipients || recipients.isEmpty) {
      return SmsOutboxStatus.noRecipients;
    }
    if (recipients.every((r) => r.confirmed)) return SmsOutboxStatus.sent;
    final anyAccepted = recipients.any((r) =>
        r.result == SmsRecipientResult.sent ||
        r.result == SmsRecipientResult.unconfirmed);
    return anyAccepted ? SmsOutboxStatus.unconfirmed : SmsOutboxStatus.failed;
  }

  /// With [purge], clears the messages sent before today (the Outbox shows
  /// the day's messages; ones not sent stay until they go out or are
  /// discarded). Recounts what is not sent yet. Never throws.
  Future<void> refreshOutbox({bool purge = false}) async {
    final dao = await _outboxDao();
    if (dao == null) return;
    if (purge) {
      final now = _now();
      await _safely(() => dao.purgeDeliveredBefore(
          DateTime(now.year, now.month, now.day).toIso8601String()));
    }
    needsAttention.value = await _safely(dao.countNeedingAttention) ?? 0;
    outboxVersion.value++;
  }

  Future<CollectionSmsOutboxDao?> _outboxDao() async {
    try {
      return await (_outbox ?? _defaultOutbox)();
    } catch (e) {
      logDebug('CollectionSmsService: outbox unavailable: $e');
      return null;
    }
  }

  static Future<CollectionSmsOutboxDao?> _defaultOutbox() =>
      DatabaseHelper.instance.collectionSmsOutboxDao;

  /// Runs an outbox read or write; null (logged) when it fails, so the
  /// outbox can never stop a message from going out.
  static Future<T?> _safely<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      logDebug('CollectionSmsService: outbox write failed: $e');
      return null;
    }
  }

  /// The same pre-flight as Logistics: SMS-capable, SIM ready, service up.
  Future<String?> _likelyNetworkIssue() async {
    final capable = await _quiet(() => _telephonyInstance.isSmsCapable);
    if (capable == false) {
      return 'This device is not capable of sending SMS messages.';
    }
    final sim = await _quiet(() => _telephonyInstance.simState);
    if (sim != null &&
        sim != SimState.READY &&
        sim != SimState.LOADED &&
        sim != SimState.PRESENT) {
      return 'The SIM is not ready for SMS messaging (${sim.name}).';
    }
    final service = await _quiet(() => _telephonyInstance.serviceState);
    if (service == ServiceState.OUT_OF_SERVICE ||
        service == ServiceState.POWER_OFF) {
      return 'The mobile network is unavailable for SMS (${service!.name}).';
    }
    return null;
  }

  static Future<T?> _quiet<T>(Future<T?> Function() getter) async {
    try {
      return await getter().timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  String _safeInitials() {
    try {
      return _initials();
    } catch (e) {
      logDebug('CollectionSmsService: initials lookup failed: $e');
      return '';
    }
  }

  /// The signed-in collector's initials (e.g. MAR); '' without a user.
  static String _collectorInitials() {
    if (!Get.isRegistered<UserController>()) return '';
    return Get.find<UserController>().user.value.initial;
  }

  /// Settings → My Head, then the directory for the number. Null when no
  /// Head is chosen or the app runs without a signed-in user.
  static Future<HeadContact?> _headFromDirectory() async {
    if (!Get.isRegistered<UserController>()) return null;
    final user = Get.find<UserController>().user.value;
    final key = user.headKey.trim();
    if (key.isEmpty) return null;
    final person = Get.isRegistered<UserDirectoryRepository>()
        ? await Get.find<UserDirectoryRepository>().find(key)
        : null;
    return HeadContact(
      key: key,
      name:
          person?.name ?? (user.headName.trim().isEmpty ? key : user.headName),
      phone: person?.phone ?? '',
    );
  }

  static Future<List<String>> _collectionContacts() async {
    final dao = await DatabaseHelper.instance.contactDao;
    return dao.getPhoneNumbersByDepartment(recipientDepartment);
  }

  /// Android's own SMS permission prompt, and only that: no app dialog in
  /// front of it, since sending is in the background. Already granted, it
  /// asks nothing.
  Future<bool> _ensurePermission() async {
    final granted = await _telephonyInstance.requestSmsPermissions;
    return granted ?? false;
  }
}
