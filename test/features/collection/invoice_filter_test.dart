import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/models/activity_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/invoice_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/invoice_filter_sheet.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_fill_chip.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The account's invoice list gets its own filter. The engagement sheet used
/// to open here, which asked about the area — a property every invoice in an
/// account already shares — and offered to "Show 23 accounts" on a screen
/// that shows one account's invoices.

String _daysAgo(int days) {
  final d = DateTime.now().subtract(Duration(days: days));
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

CollectionItemModel _item({
  String id = '1',
  double due = 10000,
  double collected = 0,
  int overdueDays = 0,
  List<CollectionHistoryModel> history = const [],
}) =>
    CollectionItemModel(
      id: id,
      client: ClientModel(
        id: 'c1',
        code: 'NLN-1',
        name: 'Acme',
        address: '',
        contact: '',
        emailAddress: '',
      ),
      toBeCollected: due,
      totalCollected: collected,
      dueDate: _daysAgo(overdueDays),
      history: history,
    );

void main() {
  group('what has been recorded', () {
    final visit = CollectionHistoryModel(
      date: _daysAgo(2),
      status: 'Follow-up',
      remarks: 'Promised next week',
      collectorName: 'JB',
    );

    test('untouched means no history and nothing collected', () {
      expect(InvoiceProgress.untouched.matches(_item()), isTrue);
      expect(
        InvoiceProgress.untouched.matches(_item(history: [visit])),
        isFalse,
      );
      expect(InvoiceProgress.untouched.matches(_item(collected: 500)), isFalse);
    });

    test('part paid means money has landed on it', () {
      expect(InvoiceProgress.partPaid.matches(_item()), isFalse);
      expect(InvoiceProgress.partPaid.matches(_item(collected: 500)), isTrue);
      // Visited but unpaid is neither untouched nor part paid.
      expect(
        InvoiceProgress.partPaid.matches(_item(history: [visit])),
        isFalse,
      );
    });

    test('any keeps everything', () {
      expect(InvoiceProgress.any.matches(_item()), isTrue);
      expect(InvoiceProgress.any.matches(_item(collected: 500)), isTrue);
    });
  });

  group('the filter as a whole', () {
    test('sort alone is not an active filter', () {
      expect(InvoiceFilter.none.isActive, isFalse);
      expect(
        const InvoiceFilter(sort: InvoiceSort.amountHigh).isActive,
        isFalse,
      );
      expect(const InvoiceFilter(due: DueBand.late30).isActive, isTrue);
      expect(
        const InvoiceFilter(progress: InvoiceProgress.partPaid).isActive,
        isTrue,
      );
    });

    test('every band has to agree before an invoice is kept', () {
      const filter = InvoiceFilter(
        due: DueBand.late30,
        amount: AmountBand.from10kTo50k,
      );

      expect(filter.matches(_item(overdueDays: 90, due: 20000)), isTrue);
      expect(filter.matches(_item(overdueDays: 5, due: 20000)), isFalse);
      expect(filter.matches(_item(overdueDays: 90, due: 900)), isFalse);
    });

    test('orders run on the invoice, and ties break on id', () {
      final old = _item(id: '1', overdueDays: 900, due: 1000);
      final recent = _item(id: '2', overdueDays: 10, due: 90000);

      int by(InvoiceSort s) =>
          InvoiceFilter(sort: s).compare(old, recent).sign;

      expect(by(InvoiceSort.mostOverdue), -1);
      expect(by(InvoiceSort.leastOverdue), 1);
      expect(by(InvoiceSort.amountHigh), 1);
      expect(by(InvoiceSort.amountLow), -1);

      // Same amount, so the id decides rather than the order shuffling.
      final a = _item(id: '1', due: 500, overdueDays: 3);
      final b = _item(id: '2', due: 500, overdueDays: 3);
      expect(
        const InvoiceFilter(sort: InvoiceSort.amountHigh).compare(a, b),
        lessThan(0),
      );
    });
  });

  group('the sheet', () {
    Future<InvoiceFilter?> open(
      WidgetTester tester, {
      required int Function(InvoiceFilter) count,
    }) async {
      InvoiceFilter? chosen;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                chosen = await InvoiceFilterSheet.show(
                  context,
                  initial: InvoiceFilter.none,
                  count: count,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return chosen;
    }

    testWidgets('counts invoices, not accounts', (tester) async {
      await open(tester, count: (_) => 12);
      expect(find.text('Show 12 invoices'), findsOneWidget);
      expect(find.text('Filter invoices'), findsOneWidget);
      // The engagement sheet's account-level questions have no place here.
      expect(find.text('Area'), findsNothing);
      expect(find.text('Most invoices'), findsNothing);
      // Nor does an order that is "Most overdue" under another name, on a
      // screen whose search field already finds an invoice by number.
      expect(find.text('Invoice number'), findsNothing);
    });

    testWidgets('a filter that shows nothing cannot be applied',
        (tester) async {
      await open(tester, count: (_) => 0);
      final apply = find.widgetWithText(ElevatedButton, 'No invoices match');
      expect(apply, findsOneWidget);
      expect(tester.widget<ElevatedButton>(apply).onPressed, isNull);
    });

    testWidgets('a chosen band comes back on apply', (tester) async {
      InvoiceFilter? chosen;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                chosen = await InvoiceFilterSheet.show(
                  context,
                  initial: InvoiceFilter.none,
                  count: (_) => 3,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final chip = find.widgetWithText(
          BQuickFillChip, InvoiceProgress.partPaid.label);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show 3 invoices'));
      await tester.pumpAndSettle();

      expect(chosen?.progress, InvoiceProgress.partPaid);
    });
  });

  group('the chips under the search bar', () {
    testWidgets('nothing set draws nothing', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ActiveInvoiceFilterChips(
            filter: InvoiceFilter.none,
            onChanged: (_) {},
          ),
        ),
      ));
      expect(find.byType(InputChip), findsNothing);
    });

    testWidgets('removing a chip clears that band alone', (tester) async {
      InvoiceFilter? updated;
      const filter = InvoiceFilter(
        due: DueBand.late30,
        progress: InvoiceProgress.partPaid,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ActiveInvoiceFilterChips(
            filter: filter,
            onChanged: (f) => updated = f,
          ),
        ),
      ));

      expect(find.byType(InputChip), findsNWidgets(2));
      await tester.tap(find.byTooltip('Remove ${DueBand.late30.label}'));
      await tester.pumpAndSettle();

      expect(updated?.due, DueBand.any);
      expect(updated?.progress, InvoiceProgress.partPaid);
    });
  });
}
