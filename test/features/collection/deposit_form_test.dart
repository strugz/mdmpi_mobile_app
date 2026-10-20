import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/deposit_form.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// For Deposit is the collector's activity: bank, an optional check number,
/// the accounts it covers (each found by search, with its amount) and the
/// amount. The remarks are written from the accounts, "Account - Amount" one
/// per line, then an optional note. It settles no invoice and is recorded
/// against no account.

ClientModel _client(String code, String name) => ClientModel(
    id: code, code: code, name: name, address: '', contact: '', emailAddress: '');

final _registry = [
  _client('C-100', 'Antipolo Doctors Hospital'),
  _client('C-200', 'Ace Diagnostics Corp.'),
];

class _Activity extends CollectionActivityController {
  final saved = <({
    String type,
    String? clientId,
    String accountName,
    List<String> documentIds,
    double amount,
    String? bank,
    String? check,
    String remarks,
  })>[];

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<Result<List<ClientModel>>> searchClientRegistry(String term) async {
    final q = term.trim().toLowerCase();
    return Result.success([
      for (final c in _registry)
        if (q.isEmpty || c.name.toLowerCase().contains(q)) c,
    ]);
  }

  @override
  List<ClientModel> searchKnownAccounts(String term) => const [];

  @override
  Future<void> saveGlobalActivity({
    required String type,
    required String accountName,
    required String remarks,
    double totalCollected = 0,
    String? bankName,
    String? checkNumber,
    String? clientId,
    List<String> documentIds = const [],
  }) async =>
      saved.add((
        type: type,
        clientId: clientId,
        accountName: accountName,
        documentIds: documentIds,
        amount: totalCollected,
        bank: bankName,
        check: checkNumber,
        remarks: remarks,
      ));
}

void main() {
  tearDown(Get.reset);

  Future<_Activity> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final activity = _Activity();
    Get.put<CollectionActivityController>(activity);
    // An open invoice in the bucket: the form must not offer it.
    activity.bucketItems.add(CollectionItemModel(
      id: 'INV-1',
      client: _registry.first,
      toBeCollected: 5000,
    ));
    await tester.pumpWidget(GetMaterialApp(
        theme: BCollectionTheme.light, home: const DepositFormScreen()));
    await tester.pumpAndSettle();
    return activity;
  }

  Future<void> drainSnackbar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  Finder bankField() => find
      .descendant(
          of: find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == 'BBankField'),
          matching: find.byType(EditableText))
      .first;

  Future<void> addAccount(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(const ValueKey('deposit-add-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Future<void> lineAmount(WidgetTester tester, String code, String amount) =>
      tester.enterText(
          find.byKey(ValueKey('deposit-line-amount-$code')), amount);

  testWidgets('asks for bank, check number, accounts, amount and a note',
      (tester) async {
    await pump(tester);

    expect(find.text('INV-1'), findsNothing,
        reason: 'a deposit is not tied to bucket invoices');
    expect(bankField(), findsOneWidget);
    expect(find.byKey(const ValueKey('deposit-check-number')), findsOneWidget);
    expect(find.byKey(const ValueKey('deposit-add-account')), findsOneWidget);
    expect(find.byKey(const ValueKey('deposit-amount')), findsOneWidget);
    expect(find.byKey(const ValueKey('deposit-note')), findsOneWidget);
  });

  testWidgets('bank, amount and an account are required; check number is not',
      (tester) async {
    final activity = await pump(tester);

    await tester.tap(find.byKey(const ValueKey('deposit-save')));
    await tester.pumpAndSettle();

    expect(find.text('Bank is required'), findsOneWidget);
    expect(find.text('Amount is required'), findsOneWidget);
    expect(find.text('Add at least one account'), findsOneWidget);
    expect(find.text('Check number is required'), findsNothing);
    expect(activity.saved, isEmpty);
  });

  testWidgets('an account found by search adds a line, once', (tester) async {
    await pump(tester);
    await addAccount(tester, 'Antipolo Doctors Hospital');
    expect(find.byKey(const ValueKey('deposit-line-C-100')), findsOneWidget);

    await addAccount(tester, 'Antipolo Doctors Hospital');
    expect(find.byKey(const ValueKey('deposit-line-C-100')), findsOneWidget,
        reason: 'the same account is not listed twice');
    await drainSnackbar(tester);
  });

  testWidgets('every account needs its amount', (tester) async {
    final activity = await pump(tester);
    await tester.enterText(bankField(), 'BDO');
    await addAccount(tester, 'Antipolo Doctors Hospital');
    await tester.tap(find.byKey(const ValueKey('deposit-save')));
    await tester.pumpAndSettle();

    expect(find.text('Enter the amount for every account'), findsOneWidget);
    expect(activity.saved, isEmpty);
  });

  testWidgets('the amount follows the accounts until it is typed',
      (tester) async {
    await pump(tester);
    await addAccount(tester, 'Antipolo Doctors Hospital');
    await lineAmount(tester, 'C-100', '25000');
    await addAccount(tester, 'Ace Diagnostics Corp.');
    await lineAmount(tester, 'C-200', '5000');
    await tester.pumpAndSettle();

    final amount = find.byKey(const ValueKey('deposit-amount'));
    expect(
        tester
            .widget<EditableText>(
                find.descendant(of: amount, matching: find.byType(EditableText)))
            .controller
            .text,
        '30,000.00');

    // Typed by hand: it stays, and the form says what the accounts make.
    await tester.enterText(amount, '32000');
    await lineAmount(tester, 'C-200', '6000');
    await tester.pumpAndSettle();
    expect(
        BFormatter.parseAmount(tester
            .widget<EditableText>(
                find.descendant(of: amount, matching: find.byType(EditableText)))
            .controller
            .text),
        32000);
    expect(find.text('The accounts add up to ₱31,000.00'), findsOneWidget);
  });

  testWidgets('saves with remarks written Account - Amount, one per line',
      (tester) async {
    final activity = await pump(tester);

    await tester.enterText(bankField(), 'BPI');
    await tester.enterText(
        find.byKey(const ValueKey('deposit-check-number')), ' 1254897 ');
    await addAccount(tester, 'Antipolo Doctors Hospital');
    await lineAmount(tester, 'C-100', '25000');
    await addAccount(tester, 'Ace Diagnostics Corp.');
    await lineAmount(tester, 'C-200', '5000');
    await tester.enterText(
        find.byKey(const ValueKey('deposit-note')), ' Morning run ');
    await tester.pumpAndSettle();

    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey('deposit-remarks-preview')))
            .data,
        'Antipolo Doctors Hospital - 25,000.00\n'
        'Ace Diagnostics Corp. - 5,000.00\n'
        'Note: Morning run');

    await tester.tap(find.byKey(const ValueKey('deposit-save')));
    await tester.pumpAndSettle();

    final d = activity.saved.single;
    expect(d.type, 'Deposit');
    expect(d.clientId, '', reason: 'recorded against no account');
    expect(d.accountName, '');
    expect(d.documentIds, isEmpty);
    expect(d.amount, 30000);
    expect(d.bank, 'BPI');
    expect(d.check, '1254897');
    expect(
        d.remarks,
        'Antipolo Doctors Hospital - 25,000.00\n'
        'Ace Diagnostics Corp. - 5,000.00\n'
        'Note: Morning run');
    await drainSnackbar(tester);
  });

  testWidgets('a removed account leaves the lines and the total',
      (tester) async {
    final activity = await pump(tester);
    await tester.enterText(bankField(), 'BDO');
    await addAccount(tester, 'Antipolo Doctors Hospital');
    await lineAmount(tester, 'C-100', '25000');
    await addAccount(tester, 'Ace Diagnostics Corp.');
    await lineAmount(tester, 'C-200', '5000');
    await tester.tap(find.byKey(const ValueKey('deposit-line-remove-C-200')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deposit-save')));
    await tester.pumpAndSettle();

    final d = activity.saved.single;
    expect(d.remarks, 'Antipolo Doctors Hospital - 25,000.00');
    expect(d.amount, 25000);
    await drainSnackbar(tester);
  });

  testWidgets('the check number takes digits only, on the numeric keypad',
      (tester) async {
    await pump(tester);
    final field = find.byKey(const ValueKey('deposit-check-number'));

    final editable = tester.widget<EditableText>(
        find.descendant(of: field, matching: find.byType(EditableText)));
    expect(editable.keyboardType, TextInputType.number);

    await tester.enterText(field, 'CHK-8974564');
    await tester.pump();
    expect(editable.controller.text, '8974564');
  });
}
