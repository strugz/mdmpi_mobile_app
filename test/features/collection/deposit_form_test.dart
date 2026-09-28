import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/deposit_form.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// For Deposit is the collector's activity only: bank, amount, check number
/// and optional remarks. No account, no invoices from the Collection Bucket.

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
    final activity = _Activity();
    Get.put<CollectionActivityController>(activity);
    // An open invoice in the bucket: the form must not offer it.
    activity.bucketItems.add(CollectionItemModel(
      id: 'INV-1',
      client: ClientModel(
          id: 'C-100',
          code: 'C-100',
          name: 'Antipolo Doctors Hospital',
          address: '',
          contact: '',
          emailAddress: ''),
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
          of: find.byWidgetPredicate((w) => w.runtimeType.toString() == 'BBankField'),
          matching: find.byType(EditableText))
      .first;

  testWidgets('asks only for bank, amount, check number and remarks',
      (tester) async {
    await pump(tester);

    expect(find.text('Account'), findsNothing);
    expect(find.text('INV-1'), findsNothing,
        reason: 'a deposit is not tied to bucket invoices');
    expect(find.byKey(const ValueKey('deposit-amount')), findsOneWidget);
    expect(find.byKey(const ValueKey('deposit-check-number')), findsOneWidget);
    expect(find.byKey(const ValueKey('deposit-remarks')), findsOneWidget);
    expect(bankField(), findsOneWidget);
  });

  testWidgets('bank, amount and check number are required; remarks are not',
      (tester) async {
    final activity = await pump(tester);

    await tester.tap(find.byKey(const ValueKey('deposit-save')));
    await tester.pumpAndSettle();

    expect(find.text('Bank is required'), findsOneWidget);
    expect(find.text('Amount is required'), findsOneWidget);
    expect(find.text('Check number is required'), findsOneWidget);
    expect(activity.saved, isEmpty);
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

  testWidgets('saves a deposit with no account and no invoices',
      (tester) async {
    final activity = await pump(tester);

    await tester.enterText(bankField(), 'BPI');
    await tester.enterText(
        find.byKey(const ValueKey('deposit-amount')), '2500000');
    await tester.enterText(
        find.byKey(const ValueKey('deposit-check-number')), ' 1254897 ');
    await tester.tap(find.byKey(const ValueKey('deposit-save')));
    await tester.pumpAndSettle();

    final d = activity.saved.single;
    expect(d.type, 'Deposit');
    expect(d.clientId, '');
    expect(d.accountName, '');
    expect(d.documentIds, isEmpty);
    expect(d.amount, 2500000);
    expect(d.bank, 'BPI');
    expect(d.check, '1254897');
    expect(d.remarks, '', reason: 'no invoice list written into the remarks');
    await drainSnackbar(tester);
  });
}
