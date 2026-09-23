import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/po/account_po_invoices_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/account_card.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The P.O. breakdown lives on its own page: the account card's count line
/// opens it, and the page lists each P.O. with the invoices under it.

ClientModel _client() => ClientModel(
    id: 'A', code: 'NCR-1', name: 'Accuteqs', address: '', contact: '', emailAddress: '');

CollectionItemModel _inv(String id, {String po = '', double due = 100}) =>
    CollectionItemModel(
        id: id, client: _client(), toBeCollected: due, poNumber: po, dueDate: '2026-12-31');

final _invoices = [
  _inv('240002769', po: 'ADC-CHEM-2023-001-A', due: 10780),
  _inv('240003966', po: 'ADC-CHEM-2023-001-A', due: 7425),
  _inv('135862', po: 'ADC-CLMC-2022-001', due: 51814.59),
  _inv('999'),
];

// An RxList, as the controller's lists are: the page reads it inside an Obx.
Widget _page() {
  final rx = RxList<CollectionItemModel>(_invoices);
  return GetMaterialApp(
    home: AccountPoInvoicesScreen(client: _client(), invoices: () => rx.toList()),
  );
}

void main() {
  testWidgets('lists every P.O. with its invoices, and a No P.O. section',
      (tester) async {
    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();

    expect(find.text('2 P.O.s · 4 invoices'), findsOneWidget);
    expect(find.text('PO ADC-CHEM-2023-001-A'), findsOneWidget);
    expect(find.text('PO ADC-CLMC-2022-001'), findsOneWidget);
    expect(find.text('No P.O.'), findsOneWidget);
    expect(find.text('#240002769'), findsOneWidget);
    expect(find.text('#999'), findsOneWidget);
  });

  testWidgets('tapping a P.O. folds it', (tester) async {
    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();

    await tester.tap(find.text('PO ADC-CHEM-2023-001-A'));
    await tester.pumpAndSettle();
    expect(find.text('#240002769'), findsNothing);
    expect(find.text('#135862'), findsOneWidget);
  });

  testWidgets('search narrows to a P.O. or an invoice number', (tester) async {
    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'clmc');
    await tester.pumpAndSettle();
    expect(find.text('PO ADC-CLMC-2022-001'), findsOneWidget);
    expect(find.text('PO ADC-CHEM-2023-001-A'), findsNothing);

    await tester.enterText(find.byType(TextField), '3966');
    await tester.pumpAndSettle();
    expect(find.text('#240003966'), findsOneWidget);
    expect(find.text('#240002769'), findsNothing);
  });

  testWidgets('the card count line opens the page and does not tick the account',
      (tester) async {
    var ticked = 0;
    var opened = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AccountCard(
          client: _client(),
          invoiceCount: 7,
          poCount: 5,
          totalAmount: 1000,
          onTap: () => ticked++,
          onPoInvoicesTap: () => opened++,
        ),
      ),
    ));

    await tester.tap(find.text('5 P.O.s · 7 invoices'));
    expect(opened, 1);
    expect(ticked, 0);
  });
}
