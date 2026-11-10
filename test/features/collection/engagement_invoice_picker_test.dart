import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/widgets/engagement_invoice_picker.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The invoice checklist the Deposit and Reconciliation forms share. It has
/// to say when an account has nothing open, count what is picked, and report
/// every toggle back to the form.

CollectionItemModel _invoice(String id, {double amount = 1000}) =>
    CollectionItemModel(
      id: id,
      client: ClientModel(
        id: 'C1',
        code: 'NCR-400',
        name: 'Best Care Pharmacy',
        address: '',
        contact: '',
        emailAddress: '',
      ),
      toBeCollected: amount,
      postingDate: '2026-09-01',
      dueDate: '2026-09-30',
    );

Widget _host(Widget child) => MaterialApp(
      theme: BCollectionTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('an account with no open invoices says so instead of drawing '
      'an empty box', (tester) async {
    await tester.pumpWidget(_host(EngagementInvoicePicker(
      invoices: const [],
      selectedIds: const [],
      onToggle: (_, __) {},
    )));

    expect(find.text('No open invoices for this account on this phone.'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('Pick at least one'), findsOneWidget);
  });

  testWidgets('lists each invoice with its amount and reflects the selection',
      (tester) async {
    await tester.pumpWidget(_host(EngagementInvoicePicker(
      invoices: [_invoice('RC1', amount: 1200), _invoice('RC2', amount: 800)],
      selectedIds: const ['RC2'],
      onToggle: (_, __) {},
    )));

    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.text('SI RC1'), findsOneWidget);
    expect(find.text('SI RC2'), findsOneWidget);
    expect(find.textContaining('1,200'), findsOneWidget);
    expect(find.text('1 selected'), findsOneWidget);

    final rc2 = tester.widget<CheckboxListTile>(find.ancestor(
        of: find.text('SI RC2'), matching: find.byType(CheckboxListTile)));
    expect(rc2.value, isTrue);
    final rc1 = tester.widget<CheckboxListTile>(find.ancestor(
        of: find.text('SI RC1'), matching: find.byType(CheckboxListTile)));
    expect(rc1.value, isFalse);
  });

  testWidgets('the count follows the selection', (tester) async {
    await tester.pumpWidget(_host(EngagementInvoicePicker(
      invoices: [_invoice('RC1'), _invoice('RC2'), _invoice('RC3')],
      selectedIds: const ['RC1', 'RC3'],
      onToggle: (_, __) {},
    )));

    expect(find.text('2 selected'), findsOneWidget);
    expect(find.text('Pick at least one'), findsNothing);
  });

  testWidgets('tapping a row reports the invoice id and its new state',
      (tester) async {
    final calls = <(String, bool)>[];
    await tester.pumpWidget(_host(EngagementInvoicePicker(
      invoices: [_invoice('RC1'), _invoice('RC2')],
      selectedIds: const ['RC2'],
      onToggle: (id, selected) => calls.add((id, selected)),
    )));

    await tester.tap(find.text('SI RC1'));
    await tester.pump();
    await tester.tap(find.text('SI RC2'));
    await tester.pump();

    expect(calls, [('RC1', true), ('RC2', false)]);
  });

  testWidgets('the title names the SI and the subtitle the PO', (tester) async {
    await tester.pumpWidget(_host(EngagementInvoicePicker(
      invoices: [
        CollectionItemModel(
          id: 'SI-77',
          client: ClientModel(
              id: 'C1',
              code: 'NCR-400',
              name: 'Best Care Pharmacy',
              address: '',
              contact: '',
              emailAddress: ''),
          toBeCollected: 500,
          poNumber: 'PO-9',
          dueDate: '2026-09-30',
        ),
      ],
      selectedIds: const [],
      onToggle: (_, __) {},
    )));

    expect(find.text('SI SI-77'), findsOneWidget);
    expect(find.textContaining('PO PO-9'), findsOneWidget);
  });

  testWidgets('no Select all unless the form asks for it', (tester) async {
    await tester.pumpWidget(_host(EngagementInvoicePicker(
      invoices: [_invoice('RC1'), _invoice('RC2')],
      selectedIds: const [],
      onToggle: (_, __) {},
    )));

    expect(find.byKey(const ValueKey('invoice-picker-select-all')),
        findsNothing);
  });

  testWidgets('Select all picks every invoice; Clear when all are picked',
      (tester) async {
    final calls = <bool>[];
    await tester.pumpWidget(_host(EngagementInvoicePicker(
      invoices: [_invoice('RC1'), _invoice('RC2')],
      selectedIds: const ['RC1'],
      onToggle: (_, __) {},
      onToggleAll: calls.add,
    )));

    expect(find.text('Select all'), findsOneWidget);
    await tester.tap(find.text('Select all'));
    expect(calls, [true]);

    await tester.pumpWidget(_host(EngagementInvoicePicker(
      invoices: [_invoice('RC1'), _invoice('RC2')],
      selectedIds: const ['RC1', 'RC2'],
      onToggle: (_, __) {},
      onToggleAll: calls.add,
    )));
    await tester.tap(find.text('Clear'));
    expect(calls, [true, false]);
  });

  testWidgets('one invoice needs no Select all', (tester) async {
    await tester.pumpWidget(_host(EngagementInvoicePicker(
      invoices: [_invoice('RC1')],
      selectedIds: const [],
      onToggle: (_, __) {},
      onToggleAll: (_) {},
    )));

    expect(find.byKey(const ValueKey('invoice-picker-select-all')),
        findsNothing);
  });
}
