import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/invoice_card.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// InvoiceCard replaced two near-identical tiles. The design point it has to
/// hold onto is that urgency is graded: previously every overdue invoice
/// painted its whole card red, and since nearly all of them are overdue the
/// list went uniformly red and the signal meant nothing.

String _date(int daysFromNow) => DateFormat('yyyy-MM-dd')
    .format(DateTime.now().add(Duration(days: daysFromNow)));

CollectionItemModel _item({
  String id = '700013390',
  String clientName = 'Accusure Medical Enterprises',
  double toBeCollected = 1000,
  double totalCollected = 0,
  String? dueDate,
  int dueInDays = 10,
  String status = '',
}) =>
    CollectionItemModel(
      id: id,
      client: ClientModel(
        id: 'A',
        code: 'NLN-1',
        name: clientName,
        address: '',
        contact: '',
        emailAddress: '',
      ),
      toBeCollected: toBeCollected,
      totalCollected: totalCollected,
      dueDate: dueDate ?? _date(dueInDays),
      postingDate: _date(-60),
      status: status,
    );

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        // Unbounded height, as every real list here is.
        body: SingleChildScrollView(child: Column(children: [child])),
      ),
    );

void main() {
  group('urgency grading', () {
    test('settled when nothing is left to collect', () {
      final c = InvoiceCard(item: _item(toBeCollected: 0, totalCollected: 500));
      expect(c.urgency, InvoiceUrgency.settled);
    });

    test('upcoming when the due date has not passed', () {
      final c = InvoiceCard(item: _item(dueInDays: 10));
      expect(c.urgency, InvoiceUrgency.upcoming);
    });

    test('due when overdue but inside the late threshold', () {
      final c = InvoiceCard(item: _item(dueInDays: -10));
      expect(c.urgency, InvoiceUrgency.due);
    });

    test('late past the threshold', () {
      final c = InvoiceCard(item: _item(dueInDays: -33));
      expect(c.urgency, InvoiceUrgency.late);
    });

    test('settled wins over an overdue date', () {
      final c = InvoiceCard(
        item: _item(toBeCollected: 0, totalCollected: 500, dueInDays: -90),
      );
      expect(c.urgency, InvoiceUrgency.settled);
    });
  });

  group('rendering', () {
    testWidgets('lays out inside a scroll view', (tester) async {
      await tester.pumpWidget(_host(InvoiceCard(item: _item())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('leads with the amount, with the number set to be read',
        (tester) async {
      await tester
          .pumpWidget(_host(InvoiceCard(item: _item(toBeCollected: 37759.82))));
      await tester.pumpAndSettle();

      expect(find.text('#700013390'), findsOneWidget);
      final amount = tester.widget<Text>(find.textContaining('37,759.82'));
      final number = tester.widget<Text>(find.text('#700013390'));
      expect(amount.style!.fontSize!, greaterThan(number.style!.fontSize!),
          reason: 'the amount is what the collector is here for');
      expect(amount.style!.color, BColors.primary);

      // The number is how the document is referred to and what a deposit is
      // matched back to. It was once a grey label — the quietest thing on the
      // card — and stopped being findable.
      expect(number.style!.fontWeight, FontWeight.w700);
      expect(number.style!.color, isNot(BColors.darkGrey),
          reason: 'an identifier people look up is not set in secondary grey');
    });

    testWidgets('hides the account name by default and shows it on request',
        (tester) async {
      // Inside one account's screen the name is already the page title.
      await tester.pumpWidget(_host(InvoiceCard(item: _item())));
      await tester.pumpAndSettle();
      expect(find.text('Accusure Medical Enterprises'), findsNothing);

      // Mixed lists need it.
      await tester
          .pumpWidget(_host(InvoiceCard(item: _item(), showAccountName: true)));
      await tester.pumpAndSettle();
      expect(find.text('Accusure Medical Enterprises'), findsOneWidget);
    });

    testWidgets('shows one due line and no posting-date row', (tester) async {
      await tester.pumpWidget(_host(InvoiceCard(item: _item(dueInDays: -33))));
      await tester.pumpAndSettle();

      expect(find.textContaining('Due '), findsOneWidget);
      expect(find.text('33 days overdue'), findsOneWidget);
      // The posting date moved to the details sheet; it used to truncate here.
      expect(find.textContaining('Invoice Date'), findsNothing);
    });

    testWidgets('a settled invoice reads as collected', (tester) async {
      await tester.pumpWidget(_host(
        InvoiceCard(item: _item(toBeCollected: 0, totalCollected: 2500)),
      ));
      await tester.pumpAndSettle();

      final amount = tester.widget<Text>(find.textContaining('2,500'));
      expect(amount.style!.color, BColors.success);
      expect(find.textContaining('overdue'), findsNothing);
    });

    testWidgets('an invoice with no due date says so', (tester) async {
      await tester.pumpWidget(_host(InvoiceCard(item: _item(dueDate: 'N/A'))));
      await tester.pumpAndSettle();

      expect(find.text('No due date'), findsOneWidget);
    });

    testWidgets('tap and long press are reported', (tester) async {
      var taps = 0, holds = 0;
      await tester.pumpWidget(_host(InvoiceCard(
        item: _item(),
        onTap: () => taps++,
        onLongPress: () => holds++,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InvoiceCard));
      await tester.pumpAndSettle();
      expect(taps, 1);

      await tester.longPress(find.byType(InvoiceCard));
      await tester.pumpAndSettle();
      expect(holds, 1);
    });

    testWidgets('selection mode swaps the info button for a mark',
        (tester) async {
      await tester.pumpWidget(_host(InvoiceCard(
        item: _item(),
        onInfoTap: () {},
        isSelectionMode: true,
        isSelected: true,
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(IconButton), findsNothing);
    });
  });
}
