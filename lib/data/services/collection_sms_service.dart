import 'package:flutter/material.dart';
import 'dart:async';

import 'package:another_telephony/telephony.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_permission_service.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_directory_repository.dart';
import 'package:mdmpi_mobile_app/data/services/messaging_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:url_launcher/url_launcher.dart';

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
  /// delay. Treated as Logistics does: a warning, not "Message Sent!".
  unconfirmed,

  /// SMS permission refused; the Messages app was opened pre-filled instead.
  handedOff,

  /// No Head with a number and no Collection contact: nobody to tell.
  noRecipients,

  /// Not Android, so there is no radio to send over (Windows).
  unavailable,

  /// The phone cannot send right now (no SIM, no service) or every send failed.
  failed,
}

/// How one recipient's send ended.
enum _RecipientResult { confirmed, unconfirmed, failed }

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
typedef MessagesAppLauncher = Future<bool> Function(
    List<String> to, String message);
typedef NetworkIssueChecker = Future<String?> Function();
typedef SmsOutcomeReporter = void Function(
    CollectionSmsOutcome outcome, int recipients, String? reason);
typedef ProgressOpener = void Function(RxString text);
typedef ProgressCloser = void Function();
typedef SentViewOpener = Future<void> Function();
typedef InitialsResolver = String Function();

/// The six Collection SMS triggers (spec of 2026-09-25):
///
/// 1. Acquiring Account   4. Clear Engagement
/// 2. Saving Engagement   5. Adding Deposit
/// 3. Defer Account       6. CWT Pick-Up
///
/// Every message goes to the collector's Head (Settings → My Head, at the
/// number the user directory holds) **and** to the Contact Directory contacts
/// tagged with department "Collection". Delivery follows the Logistics
/// notifications ([MessagingController]) step for step: check the SIM and
/// service, ask for permission (Messages app as the fallback), then send
/// behind the full-screen "sending" view with a per-recipient counter, each
/// send bounded by a timeout so the view always comes down, and the
/// "Message Sent!" view on success. Android-only: a clean no-op on Windows.
///
/// The message builders are static and pure; the notify methods never throw.
class CollectionSmsService extends GetxController {
  CollectionSmsService({
    HeadContactResolver? head,
    ContactNumbersResolver? contacts,
    SmsSender? send,
    SmsPermission? permission,
    MessagesAppLauncher? handOff,
    NetworkIssueChecker? networkIssue,
    bool Function()? smsAvailable,
    SmsOutcomeReporter? report,
    ProgressOpener? openProgress,
    ProgressCloser? closeProgress,
    SentViewOpener? showSent,
    InitialsResolver? initials,
    Duration betweenRecipients = const Duration(seconds: 1),
  })  : _head = head ?? _headFromDirectory,
        _contacts = contacts ?? _collectionContacts,
        _sendOne = send,
        _permission = permission,
        _handOff = handOff,
        _networkIssue = networkIssue,
        _smsAvailable = smsAvailable ?? (() => GetPlatform.isAndroid),
        _reportHook = report,
        _openProgress = openProgress ?? _openProgressView,
        _closeProgress = closeProgress ?? BFullScreenLoader.stopLoading,
        _showSent = showSent ?? BFullScreenLoader.openMessageSentDialog,
        _initials = initials ?? _collectorInitials,
        _betweenRecipients = betweenRecipients;

  static CollectionSmsService get instance => Get.find();

  /// Department tag used to select Collection SMS recipients in the Contact
  /// Directory (`contacts` table).
  static const String recipientDepartment = 'Collection';

  /// Bounds on the radio: the platform call itself, then the SENT report
  /// (the latter matches the Logistics notifications).
  static const Duration sendCallTimeout = Duration(seconds: 15);
  static const Duration sentConfirmationTimeout = Duration(seconds: 3);

  final HeadContactResolver _head;
  final ContactNumbersResolver _contacts;
  final SmsSender? _sendOne;
  final SmsPermission? _permission;
  final MessagesAppLauncher? _handOff;
  final NetworkIssueChecker? _networkIssue;
  final bool Function() _smsAvailable;
  final SmsOutcomeReporter? _reportHook;
  final ProgressOpener _openProgress;
  final ProgressCloser _closeProgress;
  final SentViewOpener _showSent;
  final InitialsResolver _initials;
  final Duration _betweenRecipients;

  /// "No one to text" is said once per app run, not on every save.
  static bool _noRecipientsShown = false;

  /// The text on the full-screen sending view.
  final RxString progressText = ''.obs;

  /// How many recipients the last lookup found; null before the first.
  /// Lets a screen know, without waiting, whether its save is about to be
  /// followed by the sending view (see [smsFollows]).
  int? _knownRecipients;

  @override
  void onInit() {
    super.onInit();
    // Warm the count so the first save already knows.
    // ignore: unawaited_futures
    recipients();
  }

  /// Whether this save is followed by an SMS: Android, someone to text, and
  /// (for Saving Engagement) a Collected or Partial outcome. While an SMS goes
  /// out, the sending view and "Message Sent!" are the only feedback, so a
  /// screen skips its own "Saved" snackbar when this is true.
  bool willSend({String? status}) {
    if (!_smsAvailable()) return false;
    if (status != null && collectionStatusWord(status) == null) return false;
    return (_knownRecipients ?? 1) > 0;
  }

  /// [willSend] on the registered service; false when there is none.
  static bool smsFollows({String? status}) {
    if (!Get.isRegistered<CollectionSmsService>()) return false;
    try {
      return Get.find<CollectionSmsService>().willSend(status: status);
    } catch (_) {
      return false;
    }
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

  /// "PO 230736" / "POs 2026-0323, 2026-0309"; '' when there are none.
  static String _labelled(String one, String many, Iterable<String> values) {
    final items = _items(values);
    if (items.isEmpty) return '';
    return '${items.length == 1 ? one : many} ${items.join(', ')}';
  }

  /// "PHP 37,759.82", not "₱37,759.82": the peso sign is outside the GSM-7
  /// SMS alphabet, and one such character turns the whole message into UCS-2,
  /// where a single SMS holds 70 characters instead of 160.
  static String _peso(double amount) =>
      'PHP ${BFormatter.formatPesoCurrency(amount, includeSymbol: false).trim()}';

  /// " Note: [text]." or '' when blank.
  static String _note(String label, String? value) {
    final t = _text(value, none: '');
    return t.isEmpty ? '' : ' $label: ${_end(t)}';
  }

  /// [value] closed with one period: "Accuteqs Diagnostics Corp." already
  /// ends a sentence, and another would read "Corp..".
  static String _end(String value) {
    final v = value.trim();
    return v.endsWith('.') ? v : '$v.';
  }

  // Each message leads with what happened, so the notification preview alone
  // tells the Head. The collector's initials are added by [send].

  /// 1. "Now handling [Client]. 5 POs, 6 invoices, PHP 95,198.18."
  /// Reconciliation lists every number: "Now handling [Client] for
  /// reconciliation. POs A, B. Invoices X, Y. PHP 118,139.87."
  /// Counts, not the numbers themselves: an account can carry dozens of
  /// invoices. [amount] is the balance taken on; left out when null.
  static String acquiringAccount({
    required String clientName,
    required Iterable<String> poNumbers,
    required Iterable<String> invoiceIds,
    double? amount,
    bool reconciliation = false,
  }) {
    if (reconciliation) {
      // Reconciliation names every PO and invoice: the Head checks them
      // one by one against the office's records.
      final parts = [
        _labelled('PO', 'POs', poNumbers),
        _labelled('Invoice', 'Invoices', invoiceIds),
        if (amount != null) _peso(amount),
      ].where((s) => s.isNotEmpty).map(_end);
      return [
        'Now handling ${clientName.trim()} for reconciliation.',
        ...parts,
      ].join(' ');
    }
    final details = [
      _count(_items(poNumbers).length, 'PO', 'POs'),
      _count(_items(invoiceIds).length, 'invoice', 'invoices'),
      if (amount != null) _peso(amount),
    ].where((s) => s.isNotEmpty).join(', ');
    return 'Now handling ${_end(clientName)}'
        '${details.isEmpty ? '' : ' ${_end(details)}'}';
  }

  /// 1, for one acquire of several accounts: ONE message, not one each.
  /// "Now handling 3 accounts: A (5 POs, 6 invoices, PHP 95,198.18); B (…).
  /// Total PHP 271,170.59." One account reads as [acquiringAccount].
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
    final lines = accounts.map((a) {
      final name = a.clientName.trim();
      if (a.reconciliation) {
        // Every PO and invoice, as for one account; ';' between the lists
        // because the numbers themselves are separated by ','.
        final parts = [
          _labelled('POs', 'POs', a.poNumbers),
          _labelled('invoices', 'invoices', a.invoiceIds),
          if (a.amount != null) _peso(a.amount!),
        ].where((s) => s.isNotEmpty).join('; ');
        return '$name (reconciliation${parts.isEmpty ? '' : ': $parts'})';
      }
      final details = [
        _count(_items(a.poNumbers).length, 'PO', 'POs'),
        _count(_items(a.invoiceIds).length, 'invoice', 'invoices'),
        if (a.amount != null) _peso(a.amount!),
      ].where((s) => s.isNotEmpty).join(', ');
      return details.isEmpty ? name : '$name ($details)';
    }).join('; ');
    final amounts = accounts.map((a) => a.amount).whereType<double>();
    final total = amounts.isEmpty
        ? ''
        : ' Total ${_peso(amounts.fold<double>(0, (sum, v) => sum + v))}.';
    return 'Now handling ${accounts.length} accounts: ${_end(lines)}$total';
  }

  /// "1 PO" / "5 POs"; '' for none.
  static String _count(int n, String one, String many) =>
      n == 0 ? '' : '$n ${n == 1 ? one : many}';

  /// The status word for an outcome, or null when that outcome sends
  /// nothing (Pre-Collection, Follow Up, …).
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

  /// 2. "Collected PHP [total] from [Client]. Invoice [Invoice] (PO [PO]).
  /// Check [Bank] [No.], dated [Date]." The check part only when paid by
  /// check (any of bank, number or date given).
  /// Partial: "Partial payment of PHP [total] from [Client]. …". Several
  /// invoices list each with its amount after the total.
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
    final lead = status == 'Partial'
        ? 'Partial payment of ${_peso(total)} from ${_end(clientName)}'
        : 'Collected ${_peso(total)} from ${_end(clientName)}';
    final invoicePart = switch (lines.length) {
      0 => '',
      1 => 'Invoice ${lines.single.id.trim()}',
      _ =>
        'Invoices ${lines.map((i) => '${i.id.trim()} ${_peso(i.amount)}').join(', ')}',
    };
    final pos = _labelled('PO', 'POs', poNumbers);
    final detail = [
      if (invoicePart.isNotEmpty) invoicePart,
      if (pos.isNotEmpty) '($pos)',
    ].join(' ');
    final message = detail.isEmpty ? lead : '$lead $detail.';
    final check = _checkDetails(bankName, checkNumber, checkDate);
    return check.isEmpty ? message : '$message $check';
  }

  /// "Check BDO 4588255, dated 09-28-2026."; '' when nothing is given.
  static String _checkDetails(
      String? bankName, String? checkNumber, String? checkDate) {
    final what = [_text(bankName, none: ''), _text(checkNumber, none: '')]
        .where((s) => s.isNotEmpty)
        .join(' ');
    final date = _text(checkDate, none: '');
    if (what.isEmpty && date.isEmpty) return '';
    if (date.isEmpty) return 'Check ${_end(what)}';
    return what.isEmpty
        ? 'Check dated ${_end(date)}'
        : 'Check $what, dated ${_end(date)}';
  }

  /// 3. "Postponed [Client]. Reason: [Remarks]."
  static String accountDeferred(
          {required String clientName, required String remarks}) =>
      'Postponed ${_end(clientName)}${_note('Reason', remarks)}';

  /// 4. "Done with [Client]."
  static String engagementCleared({required String clientName}) =>
      'Done with ${_end(clientName)}';

  /// 5. "Deposited PHP [Amount] at [Bank]. Check [No.]. Note: [Remarks]."
  /// The optional parts are left out when blank.
  static String depositAdded({
    required String bankName,
    required double amount,
    String? checkNumber,
    String? remarks,
  }) {
    final bank = _text(bankName, none: '');
    final check = _text(checkNumber, none: '');
    return _end(
            'Deposited ${_peso(amount)}${bank.isEmpty ? '' : ' at $bank'}') +
        (check.isEmpty ? '' : ' Check ${_end(check)}') +
        _note('Note', remarks);
  }

  /// 6. "Picked up CWT from [Client]. Note: [Remarks]."
  static String cwtPickup(
          {required String clientName, required String remarks}) =>
      'Picked up CWT from ${_end(clientName)}${_note('Note', remarks)}';

  /// 7. Reconciliation escalated (Reconciliation Tracker, to the Head only):
  /// "Reconciliation escalated: [Client]. 2 open invoices, PHP 276,995.00.
  /// Reason: [Remarks]."
  static String reconEscalated({
    required String clientName,
    required int openInvoices,
    required double openAmount,
    String remarks = '',
  }) =>
      'Reconciliation escalated: ${_end(clientName)} '
      '$openInvoices open ${openInvoices == 1 ? 'invoice' : 'invoices'}, '
      '${_end(_peso(openAmount))}${_note('Reason', remarks)}';

  /// "[message] - MAR": who sent it, since the Head hears from every
  /// collector. A plain hyphen, not a dash: a dash is outside GSM-7 too.
  static String signed(String message, String initials) {
    final i = initials.trim();
    return i.isEmpty ? message : '$message - $i';
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
    return send(acquiringAccounts(accounts));
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
        checkDate: checkDate));
  }

  Future<CollectionSmsOutcome> notifyAccountDeferred(
          {required String clientName, required String remarks}) =>
      send(accountDeferred(clientName: clientName, remarks: remarks));

  Future<CollectionSmsOutcome> notifyEngagementCleared(
          {required String clientName}) =>
      send(engagementCleared(clientName: clientName));

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
          remarks: remarks));

  Future<CollectionSmsOutcome> notifyCwtPickup(
          {required String clientName, required String remarks}) =>
      send(cwtPickup(clientName: clientName, remarks: remarks));

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
          headOnly: true);

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
    final result = [
      for (final n in numbers)
        if (n.trim().isNotEmpty && seen.add(_digits(n))) n.trim(),
    ];
    _knownRecipients = result.length;
    return result;
  }

  static String _digits(String number) => number.replaceAll(RegExp(r'\D'), '');

  /// The last queued send, and the "Message Sent!" view it left open.
  Future<void> _queue = Future<void>.value();
  Future<void>? _sentView;

  /// Send [message] to every recipient. Never throws; the outcome is
  /// reported on screen so a silent "nothing happened" is never the
  /// collector's only clue.
  ///
  /// One message at a time: acquiring three accounts fires three sends at
  /// once, and each opens and pops its own full-screen view. Overlapping,
  /// a pop can close another send's view (or the screen beneath it), so each
  /// send waits for the one before it, "Message Sent!" included.
  Future<CollectionSmsOutcome> send(String message, {bool headOnly = false}) {
    final result = _queue.then((_) => _sendNow(message, headOnly: headOnly));
    _queue = result
        .then((_) => _sentView ?? Future<void>.value())
        .catchError((Object _) {});
    return result;
  }

  Future<CollectionSmsOutcome> _sendNow(String message,
      {bool headOnly = false}) async {
    _sentView = null;
    message = signed(message, _safeInitials());
    var count = 0;
    String? reason;
    CollectionSmsOutcome outcome;
    try {
      final to = await recipients(headOnly: headOnly);
      count = to.length;
      if (to.isEmpty) {
        logDebug('CollectionSmsService: no recipients');
        outcome = CollectionSmsOutcome.noRecipients;
      } else if (!_smsAvailable()) {
        logDebug('CollectionSmsService: skipped (not Android)');
        outcome = CollectionSmsOutcome.unavailable;
      } else {
        final granted = await (_permission ?? _ensurePermission)();
        if (!granted) {
          // Refused: hand the pre-filled text to the Messages app, the same
          // fallback the Logistics notifications use.
          final opened = await (_handOff ?? _openMessagesApp)(to, message);
          outcome = opened
              ? CollectionSmsOutcome.handedOff
              : CollectionSmsOutcome.failed;
          if (!opened) reason = 'The Messages app could not be opened.';
        } else {
          reason = await (_networkIssue ?? _likelyNetworkIssue)();
          if (reason != null) {
            logDebug('CollectionSmsService: $reason');
            outcome = CollectionSmsOutcome.failed;
          } else {
            outcome = await _sendBehindProgressView(to, message);
            if (outcome == CollectionSmsOutcome.failed) {
              reason = 'The phone did not accept the message for sending.';
            } else if (outcome == CollectionSmsOutcome.unconfirmed) {
              reason = 'The phone did not confirm the SMS as sent within '
                  '${sentConfirmationTimeout.inSeconds} seconds. Check the SIM '
                  'load or balance and the signal, then try again.';
            }
          }
        }
      }
    } catch (e) {
      logDebug('CollectionSmsService.send error: $e');
      outcome = CollectionSmsOutcome.failed;
      reason = e.toString();
    }
    if (outcome == CollectionSmsOutcome.sent) {
      // The "Message Sent!" view, as after a Logistics notification. Not
      // awaited here: the caller's save is already done; the next queued
      // send waits for it (see [send]). It is the confirmation, so a "Saved"
      // snackbar that arrived meanwhile is taken down.
      if (_reportHook == null) _closeSnackbars();
      _sentView = _showSent().catchError((Object e) {
        logDebug('CollectionSmsService: sent view failed: $e');
      });
    }
    try {
      (_reportHook ?? _reportOnScreen)(outcome, count, reason);
    } catch (e) {
      logDebug('CollectionSmsService: report failed: $e');
    }
    return outcome;
  }

  /// One recipient at a time behind the full-screen view, like Logistics:
  /// "Sending message 1/2...". The view is taken down in a `finally`, and
  /// each send is bounded, so it cannot stay up whatever the radio does.
  Future<CollectionSmsOutcome> _sendBehindProgressView(
      List<String> to, String message) async {
    final total = to.length;
    progressText.value = 'Please wait message sending... (0/$total)';
    try {
      _openProgress(progressText);
    } catch (e) {
      logDebug('CollectionSmsService: progress view failed: $e');
    }
    var confirmed = 0;
    var unconfirmed = 0;
    try {
      for (var i = 0; i < total; i++) {
        progressText.value = 'Sending message ${i + 1}/$total...';
        switch (await _sendToRecipient(to[i], message)) {
          case _RecipientResult.confirmed:
            confirmed++;
          case _RecipientResult.unconfirmed:
            unconfirmed++;
          case _RecipientResult.failed:
            break;
        }
        if (i < total - 1 && _betweenRecipients > Duration.zero) {
          await Future.delayed(_betweenRecipients);
        }
      }
    } finally {
      try {
        _closeProgress();
      } catch (e) {
        logDebug('CollectionSmsService: closing progress view failed: $e');
      }
    }
    logDebug('CollectionSmsService: confirmed $confirmed, unconfirmed '
        '$unconfirmed of $total');
    if (confirmed == total) return CollectionSmsOutcome.sent;
    if (confirmed + unconfirmed == 0) return CollectionSmsOutcome.failed;
    return CollectionSmsOutcome.unconfirmed;
  }

  /// Confirmed when the radio reports SENT within the timeout (as Logistics
  /// requires before showing "Message Sent!"), unconfirmed when the phone
  /// accepted the send but no report came, failed when the send threw.
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
      await sent.future.timeout(sentConfirmationTimeout);
      return _RecipientResult.confirmed;
    } on TimeoutException {
      logDebug('CollectionSmsService: no SENT report for $to within '
          '${sentConfirmationTimeout.inSeconds}s');
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

  static void _openProgressView(RxString text) {
    // The save that triggered this has just shown its own "Saved" snackbar;
    // a snackbar draws above dialogs, so it would sit on the sending view
    // and then on "Message Sent!". One confirmation at a time.
    _closeSnackbars();
    BFullScreenLoader.openProgressLoadingDialog(text, BImages.docerAnimation);
  }

  static void _closeSnackbars() {
    try {
      if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    } catch (e) {
      logDebug('CollectionSmsService: closing snackbars failed: $e');
    }
  }

  /// What the collector sees when it went wrong: a warning saying why.
  /// Success shows the "Message Sent!" view (see [send]); the Messages-app
  /// hand-off shows nothing extra, the app opening is the feedback.
  void _reportOnScreen(
      CollectionSmsOutcome outcome, int recipients, String? reason) {
    switch (outcome) {
      case CollectionSmsOutcome.sent:
      case CollectionSmsOutcome.handedOff:
        break;
      case CollectionSmsOutcome.noRecipients:
        if (_noRecipientsShown) return;
        _noRecipientsShown = true;
        _notice(
          'SMS not sent: no one to text',
          'Set your Head in Settings > My Head (they need a phone number in '
              'the directory), or add a Contact Directory contact with '
              'department "Collection".',
        );
      case CollectionSmsOutcome.unconfirmed:
        _notice('SMS may not have been sent',
            reason ?? 'The phone did not confirm the SMS as sent.');
      case CollectionSmsOutcome.failed:
        _notice('SMS not sent',
            reason ?? 'The message could not be sent from this phone.');
      case CollectionSmsOutcome.unavailable:
        // Windows: there is no radio, and no save waits on one. Nothing to say.
        break;
    }
  }

  /// A small dialog for what went wrong. Not a snackbar: nothing about the
  /// sending flow is shown in one.
  static void _notice(String title, String message) {
    if (Get.testMode) return;
    try {
      Get.dialog<void>(
        AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Get.back<void>(), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      logDebug('CollectionSmsService: notice failed: $e');
    }
  }

  Future<bool> _openMessagesApp(List<String> to, String message) async {
    try {
      return await launchUrl(
        MessagingController.buildMessagingAppUri(to, message),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      logDebug('CollectionSmsService: Messages app hand-off failed: $e');
      return false;
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

  Future<bool> _ensurePermission() async {
    if (Get.isRegistered<IPermissionService>()) {
      final permission = await Get.find<IPermissionService>().requireForFeature(
        PermissionType.sms,
        featureName: 'Collection SMS notification',
      );
      if (!permission.granted) return false;
    }
    final granted = await _telephonyInstance.requestSmsPermissions;
    return granted ?? false;
  }
}
