import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/po_grouping.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/account_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/invoice_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/po_invoice_group_card.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// One customer P.O. is often billed as several invoices. The bucket counts
/// an account's P.O.s next to its invoices, and the account screen folds the
/// invoices under their P.O. These pin the fold, the count and the row.

ClientModel _client(String id) => ClientModel(
      id: id,
      code: 'NCR-$id',
      name: 'Client $id',
      address: '',
      contact: '',
      emailAddress: '',
    );

CollectionItemModel _inv(String id,
        {String po = '', double due = 100, String clientId = 'A'}) =>
    CollectionItemModel(
      id: id,
      client: _client(clientId),
      toBeCollected: due,
      poNumber: po,
      dueDate: '2020-01-01', // long overdue, so overdue counts are exercised
    );

void main() {
  group('PoGrouping.of', () {
    test('folds by P.O. case-insensitively, first appearance first', () {
      final g = PoGrouping.of([
        _inv('1', po: 'ADC-1'),
        _inv('2', po: 'PO-9'),
        _inv('3', po: 'adc-1 '),
        _inv('4'),
        _inv('5', po: 'PO-9'),
      ]);

      expect(g.groups.map((x) => x.poNumber), ['ADC-1', 'PO-9']);
      expect(g.groups[0].invoices.map((i) => i.id), ['1', '3']);
      expect(g.groups[1].invoices.map((i) => i.id), ['2', '5']);
      expect(g.ungrouped.map((i) => i.id), ['4']);
      expect(g.groups[0].key, 'ADC-1');
    });

    test('a group knows its total and how many are overdue', () {
      final g = PoGrouping.of([
        _inv('1', po: 'X', due: 100),
        _inv('2', po: 'X', due: 250.5),
      ]);
      expect(g.groups.single.totalDue, 350.5);
      expect(g.groups.single.overdueCount, 2);
    });

    test('with no P.O. anywhere there are no groups', () {
      final g = PoGrouping.of([_inv('1'), _inv('2')]);
      expect(g.hasGroups, isFalse);
      expect(g.ungrouped.length, 2);
    });
  });

  group('controller P.O. count', () {
    test('counts distinct P.O.s per account, bucket-only, open invoices only',
        () {
      final c = CollectionActivityController();
      c.startAggregateTracking();
      c.bucketItems.assignAll([
        _inv('1', po: 'ADC-1'),
        _inv('2', po: 'adc-1'), // same P.O., different case
        _inv('3', po: 'PO-9'),
        _inv('4'), // no P.O.
        _inv('5', po: 'SETTLED', due: 0), // settled: not counted
        _inv('6', po: 'B-1', clientId: 'B'),
      ]);

      expect(c.getAccountPoCount('A'), 2);
      expect(c.getAccountPoCount('B'), 1);
      expect(c.getAccountPoCount('nobody'), 0);
      Get.reset();
    });

    test('the Activity side counts P.O.s over engaged invoices', () {
      final c = CollectionActivityController();
      c.startAggregateTracking();
      c.activityItems.assignAll([
        _inv('1', po: 'ADC-1'),
        _inv('2', po: 'ADC-1'),
        _inv('3', po: 'PO-9'),
        _inv('4'),
        _inv('5', po: 'DONE', due: 0),
      ]);
      expect(c.getActivityAccountPoCount('A'), 2);
      expect(c.getActivityAccountInvoiceCount('A'), 4);
      Get.reset();
    });
  });

  group('AccountCard count line', () {
    Widget host(int poCount, int invoiceCount) => MaterialApp(
          home: Scaffold(
            body: AccountCard(
              client: _client('A'),
              invoiceCount: invoiceCount,
              poCount: poCount,
              totalAmount: 1000,
              onTap: () {},
            ),
          ),
        );

    testWidgets('leads with the P.O.s when there are any', (tester) async {
      await tester.pumpWidget(host(3, 7));
      expect(find.text('3 P.O.s · 7 invoices'), findsOneWidget);

      await tester.pumpWidget(host(1, 1));
      expect(find.text('1 P.O. · 1 invoice'), findsOneWidget);
    });

    testWidgets('reads as before when no invoice carries a P.O.',
        (tester) async {
      await tester.pumpWidget(host(0, 7));
      expect(find.text('7 invoices'), findsOneWidget);
      expect(find.textContaining('P.O.'), findsNothing);
    });
  });

  group('PoInvoiceGroupCard', () {
    testWidgets('closed shows the P.O., count and total; open shows the cards',
        (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final group = PoGrouping.of([
        _inv('INV-1', po: 'ADC-CHEM-2023-001-A', due: 100),
        _inv('INV-2', po: 'ADC-CHEM-2023-001-A', due: 200),
      ]).groups.single;

      var expanded = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: PoInvoiceGroupCard(
                group: group,
                expanded: expanded,
                onToggle: () => setState(() => expanded = !expanded),
              ),
            ),
          ),
        ),
      ));

      expect(find.text('PO ADC-CHEM-2023-001-A'), findsOneWidget);
      expect(find.text('2 invoices'), findsOneWidget);
      expect(find.text('2 overdue'), findsOneWidget);
      expect(find.byType(InvoiceCard), findsNothing);

      await tester.tap(find.text('PO ADC-CHEM-2023-001-A'));
      await tester.pumpAndSettle();
      expect(find.byType(InvoiceCard), findsNWidgets(2));
      expect(find.text('#INV-1'), findsOneWidget);

      await tester.tap(find.text('PO ADC-CHEM-2023-001-A'));
      await tester.pumpAndSettle();
      expect(find.byType(InvoiceCard), findsNothing);
    });

    testWidgets('a closed group still says how many of its invoices are ticked',
        (tester) async {
      final group = PoGrouping.of([
        _inv('INV-1', po: 'X-1'),
        _inv('INV-2', po: 'X-1'),
      ]).groups.single;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PoInvoiceGroupCard(
            group: group,
            expanded: false,
            onToggle: () {},
            selectedCount: 1,
          ),
        ),
      ));
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('the caller builds the cards under the header', (tester) async {
      final group = PoGrouping.of([_inv('INV-1', po: 'X-1')]).groups.single;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PoInvoiceGroupCard(
              group: group,
              expanded: true,
              onToggle: () {},
              itemBuilder: (item) => Text('custom ${item.id}'),
            ),
          ),
        ),
      ));
      expect(find.text('custom INV-1'), findsOneWidget);
      expect(find.byType(InvoiceCard), findsNothing);
    });
  });
}
