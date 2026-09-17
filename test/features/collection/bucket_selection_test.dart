import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/collection_bucket_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/bucket_toolbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/account_card.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The Bucket is a catalogue you pick from, so what these protect is the one
/// way of picking: the whole card ticks the account, a labelled "Details"
/// control is the way into its page, and a bar totals what is ticked.

class _Stub extends CollectionActivityController {
  @override
  void onInit() {}
}

ClientModel _client(String id, String name) => ClientModel(
    id: id,
    code: 'NLN-1',
    name: name,
    address: '',
    contact: '',
    emailAddress: '');

CollectionItemModel _invoice(String id, ClientModel c, double due,
        {String dueDate = '2999-01-01'}) =>
    CollectionItemModel(
        id: id, client: c, toBeCollected: due, dueDate: dueDate);

_Stub _seeded() {
  final c = Get.put<CollectionActivityController>(_Stub()) as _Stub;
  c.startAggregateTracking();
  final abbott = _client('1', 'Abbott Laboratories');
  final ace = _client('2', 'Ace Diagnostics Corp.');
  final zuellig = _client('3', 'Zuellig Pharma');
  // Deliberately not alphabetical: this is the order the server sends.
  c.masterAccountList.assignAll([zuellig, abbott, ace]);
  c.bucketItems.assignAll([
    _invoice('a', abbott, 112000, dueDate: '2020-01-01'),
    _invoice('b', ace, 20000),
    _invoice('c', zuellig, 500),
  ]);
  return c;
}

void main() {
  group('the card', () {
    Widget host(AccountCard card) =>
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: card)));

    testWidgets('a selectable row ticks from its circle, not from its body',
        (tester) async {
      var selected = 0;
      var opened = 0;
      await tester.pumpWidget(host(AccountCard(
        client: _client('1', 'Abbott Laboratories'),
        invoiceCount: 1,
        totalAmount: 112000,
        onSelectTap: () => selected++,
        onTap: () => opened++,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Select Abbott Laboratories'));
      await tester.pumpAndSettle();
      expect((selected, opened), (1, 0), reason: 'the circle selects');

      await tester.tap(find.text('Abbott Laboratories'));
      await tester.pumpAndSettle();
      expect((selected, opened), (1, 1), reason: 'the row opens');
    });

    testWidgets('no details button where the row already opens the account',
        (tester) async {
      await tester.pumpWidget(host(AccountCard(
        client: _client('1', 'Abbott Laboratories'),
        invoiceCount: 1,
        totalAmount: 112000,
        onSelectTap: () {},
        onTap: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Account details'), findsNothing);
    });

    testWidgets('the Acquire label is readable under the real theme',
        (tester) async {
      // The app theme pads OutlinedButtons 16pt top and bottom. Inside a 40pt
      // button that left an 8pt window, and the label rendered as four dots.
      await tester.pumpWidget(MaterialApp(
        theme: BAppTheme.lightTheme,
        home: Scaffold(
          body: AccountCard(
            client: _client('1', 'Abbott Laboratories'),
            invoiceCount: 1,
            totalAmount: 112000,
            onTap: () {},
            onClaimTap: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final label = find.text('Acquire Account');
      final button =
          find.ancestor(of: label, matching: find.byType(OutlinedButton));
      final labelBox = tester.getRect(label);
      final buttonBox = tester.getRect(button);
      expect(buttonBox.contains(labelBox.topLeft), isTrue);
      expect(buttonBox.contains(labelBox.bottomRight), isTrue,
          reason:
              'the label must sit wholly inside the button, not be clipped');
    });
  });

  group('the controller', () {
    tearDown(Get.reset);

    test('lists the catalogue alphabetically whatever order it arrived in', () {
      final c = _seeded();
      expect(c.bucketAccounts.map((a) => a.name).toList(),
          ['Abbott Laboratories', 'Ace Diagnostics Corp.', 'Zuellig Pharma']);
    });

    test('sums what is on screen', () {
      final c = _seeded();
      final summary = c.bucketSummary;
      expect(summary.accounts, 3);
      expect(summary.due, 132500);
    });

    test('sums exactly what is ticked', () {
      final c = _seeded();
      c.toggleAccountSelection('1');
      c.toggleAccountSelection('3');
      final summary = c.selectionSummary;
      expect(summary.accounts, 2);
      expect(summary.due, 112500);
    });

    test('select all takes only what the filters leave visible', () {
      final c = _seeded();
      c.bucketSearchQuery.value = 'a';
      c.selectAllVisibleAccounts();
      // "Abbott", "Ace" and "Zuellig Pharma" all contain an "a".
      expect(c.selectedAccountIds, {'1', '2', '3'});

      c.exitSelectionMode();
      c.bucketSearchQuery.value = 'abbott';
      c.selectAllVisibleAccounts();
      expect(c.selectedAccountIds, {'1'});
      expect(c.isSelectionMode.value, isTrue);
    });

    test('counts overdue invoices per bucket account', () {
      final c = _seeded();
      expect(c.getBucketAccountOverdueCount('1'), 1);
      expect(c.getBucketAccountOverdueCount('2'), 0);
    });
  });

  group('the toolbar figure', () {
    test('is a sense of scale, not a ledger entry', () {
      expect(BucketToolbar.compactPeso(12432110), '₱12.4M');
      expect(BucketToolbar.compactPeso(740261.18), '₱740k');
      expect(BucketToolbar.compactPeso(9999), '₱9,999.00');
      expect(BucketToolbar.compactPeso(0), '₱0.00');
    });
  });

  group('the screen', () {
    tearDown(Get.reset);

    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(GetMaterialApp(
        theme: BAppTheme.lightTheme,
        home: const CollectionBucketScreen(),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('tapping the card body ticks the account, not opens it',
        (tester) async {
      _seeded();
      await pump(tester);

      // Anywhere on the card — the name is as good a place as any.
      await tester.tap(find.text('Abbott Laboratories'));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget,
          reason: 'the card is the target for the thing this screen is for');
      expect(find.byType(CollectionBucketScreen), findsOneWidget,
          reason: 'still on the Bucket - nothing was navigated to');
    });

    testWidgets('every card carries a labelled way into the account',
        (tester) async {
      _seeded();
      await pump(tester);

      expect(find.text('Details'), findsNWidgets(3));
      expect(find.bySemanticsLabel('Open Abbott Laboratories'), findsOneWidget);
    });

    testWidgets('the filters stay put while rows are ticked', (tester) async {
      _seeded();
      await pump(tester);
      expect(find.text('Search by account name…'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Select Abbott Laboratories'));
      await tester.pumpAndSettle();

      // They used to collapse on the first tick, the search bar vanishing
      // under the collector's finger on the way to the second account.
      expect(find.text('Search by account name…'), findsOneWidget);
      expect(find.text('All areas'), findsOneWidget);
    });

    testWidgets('ticking a row brings up the bar with the running total',
        (tester) async {
      _seeded();
      await pump(tester);
      expect(find.textContaining('Acquire'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Select Abbott Laboratories'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('₱112,000.00'), findsWidgets);
      expect(find.text('Acquire account'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Select Ace Diagnostics Corp.'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
      expect(find.text('₱132,000.00'), findsOneWidget,
          reason: 'the basket total');
      expect(find.text('Acquire 2 accounts'), findsOneWidget);
    });

    testWidgets('select all, then clear, from the app bar', (tester) async {
      _seeded();
      await pump(tester);
      await tester.tap(find.bySemanticsLabel('Select Abbott Laboratories'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();
      expect(find.text('3 selected'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear selection'));
      await tester.pumpAndSettle();
      expect(find.text('Collection Bucket'), findsOneWidget);
      expect(find.textContaining('Acquire'), findsNothing);
    });

    testWidgets('the toolbar says how much is in view', (tester) async {
      _seeded();
      await pump(tester);
      expect(find.text('3 accounts · ₱133k'), findsOneWidget);
    });
  });
}
