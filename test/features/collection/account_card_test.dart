import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/account_card.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The account card answers one question — how much is still out on this
/// account — so these pin the things that used to get in the way of it: a
/// literal "N/A" where an address should be, and a zero painted green as
/// though nothing collected were an achievement.

ClientModel _client({String name = 'Abbott Laboratories', String address = ''}) =>
    ClientModel(
      id: 'A',
      code: 'NLN-1',
      name: name,
      address: address,
      contact: '',
      emailAddress: '',
    );

Widget _host(AccountCard card) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: card)));

AccountCard _card({
  String address = '',
  int invoiceCount = 1,
  double totalAmount = 112000,
  double totalCollected = 0,
  int overdueCount = 0,
  VoidCallback? onClaimTap,
  bool isSelectionMode = false,
}) =>
    AccountCard(
      client: _client(address: address),
      invoiceCount: invoiceCount,
      totalAmount: totalAmount,
      totalCollected: totalCollected,
      overdueCount: overdueCount,
      onClaimTap: onClaimTap,
      isSelectionMode: isSelectionMode,
      onTap: () {},
      onInfoTap: () {},
    );

Color _colourOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  group('the address row', () {
    testWidgets('is not shown for a placeholder address', (tester) async {
      for (final placeholder in ['N/A', 'n/a', '  ', '-', 'None']) {
        await tester.pumpWidget(_host(_card(address: placeholder)));
        await tester.pumpAndSettle();

        expect(find.text(placeholder), findsNothing,
            reason: '"$placeholder" is not an address worth a row');
      }
    });

    testWidgets('is shown for a real one', (tester) async {
      await tester.pumpWidget(_host(_card(address: 'Tagbilaran City, Bohol')));
      await tester.pumpAndSettle();

      expect(find.text('Tagbilaran City, Bohol'), findsOneWidget);
    });
  });

  group('the outstanding balance', () {
    testWidgets('is the number the card leads with', (tester) async {
      await tester.pumpWidget(_host(_card(totalAmount: 112000)));
      await tester.pumpAndSettle();

      expect(find.text('₱112,000.00'), findsOneWidget);
      expect(find.text('outstanding'), findsOneWidget);
      expect(_colourOf(tester, '₱112,000.00'), BColors.primary);
    });

    testWidgets('nothing collected shows no green and no progress bar',
        (tester) async {
      await tester.pumpWidget(_host(_card(totalCollected: 0)));
      await tester.pumpAndSettle();

      // A green ₱0.00 used to sit here, which reads as "done" on an account
      // where nothing has been done.
      expect(find.text('₱0.00'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('a part-collected account shows how far along it is',
        (tester) async {
      await tester.pumpWidget(
          _host(_card(totalAmount: 36320.50, totalCollected: 61000)));
      await tester.pumpAndSettle();

      expect(find.text('₱36,320.50'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
          find.textContaining('₱61,000.00 collected so far'), findsOneWidget);
    });

    testWidgets('a settled account leads with what was collected, in green',
        (tester) async {
      await tester
          .pumpWidget(_host(_card(totalAmount: 0, totalCollected: 45000)));
      await tester.pumpAndSettle();

      expect(find.text('₱45,000.00'), findsOneWidget);
      expect(find.text('collected'), findsOneWidget);
      expect(_colourOf(tester, '₱45,000.00'), BColors.success);
      // The headline already says it; the caption underneath would be the
      // same sentence twice.
      expect(find.textContaining('collected so far'), findsNothing);
    });
  });

  group('urgency and actions', () {
    testWidgets('overdue invoices are called out', (tester) async {
      await tester.pumpWidget(_host(_card(invoiceCount: 6, overdueCount: 5)));
      await tester.pumpAndSettle();

      expect(find.text('6 invoices'), findsOneWidget);
      expect(find.text('5 overdue'), findsOneWidget);
    });

    testWidgets('nothing overdue means no badge', (tester) async {
      await tester.pumpWidget(_host(_card(overdueCount: 0)));
      await tester.pumpAndSettle();

      expect(find.textContaining('overdue'), findsNothing);
    });

    testWidgets('one invoice is singular', (tester) async {
      await tester.pumpWidget(_host(_card(invoiceCount: 1)));
      await tester.pumpAndSettle();

      expect(find.text('1 invoice'), findsOneWidget);
    });

    testWidgets('Acquire is offered only where the screen asked for it',
        (tester) async {
      await tester.pumpWidget(_host(_card()));
      await tester.pumpAndSettle();
      expect(find.text('Acquire Account'), findsNothing);

      await tester.pumpWidget(_host(_card(onClaimTap: () {})));
      await tester.pumpAndSettle();
      expect(find.text('Acquire Account'), findsOneWidget);

      // Selecting accounts in bulk is a different job from acquiring one.
      await tester
          .pumpWidget(_host(_card(onClaimTap: () {}, isSelectionMode: true)));
      await tester.pumpAndSettle();
      expect(find.text('Acquire Account'), findsNothing);
    });
  });

  group('the day summary', () {
    CollectionItemModel invoice(String id, double due, double collected,
            {String dueDate = '2999-01-01'}) =>
        CollectionItemModel(
          id: id,
          client: _client(),
          toBeCollected: due,
          totalCollected: collected,
          dueDate: dueDate,
        );

    test('adds up the accounts on screen', () {
      final c = CollectionActivityController();
      c.startAggregateTracking();
      c.masterAccountList.assignAll([_client()]);
      c.activityItems.assignAll([
        invoice('1', 100, 50),
        invoice('2', 200, 0),
      ]);

      final summary = c.activitySummary;
      expect(summary.accounts, 1);
      expect(summary.invoices, 2);
      expect(summary.due, 300);
      expect(summary.collected, 50);
    });

    test('counts only the invoices that are actually past due', () {
      final c = CollectionActivityController();
      c.startAggregateTracking();
      c.masterAccountList.assignAll([_client()]);
      c.activityItems.assignAll([
        invoice('1', 100, 0, dueDate: '2020-01-01'),
        invoice('2', 200, 0, dueDate: '2999-01-01'),
      ]);

      expect(c.getActivityAccountOverdueCount('A'), 1);
      expect(c.activitySummary.overdue, 1);
    });
  });
}
