import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/batch_activity_detail_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// One account can hold over a thousand invoices, and this screen records a
/// single payment across all of them. "Paid by check" used to be the last
/// child of the list, below every invoice row: on a batch of 1,095 that is a
/// switch about 140,000 pixels down the page. It describes the payment, not
/// any one invoice, so it belongs above the rows.

List<CollectionItemModel> _items(int count) {
  final client = ClientModel(
    id: 'c1',
    code: 'NLN-1',
    name: 'Rite-Tech Medical Inc.',
    address: '',
    contact: '',
    emailAddress: '',
  );
  return [
    for (var i = 0; i < count; i++)
      CollectionItemModel(
        id: '24000$i',
        client: client,
        toBeCollected: 1000 + i.toDouble(),
        dueDate: '2020-01-01',
      ),
  ];
}

Widget _host(List<CollectionItemModel> items) =>
    GetMaterialApp(home: BatchActivityDetailScreen(items: items));

void main() {
  tearDown(Get.reset);

  testWidgets('the payment controls are on screen before any invoice row',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(_items(1095)));
    await tester.pumpAndSettle();

    // Reachable without a single scroll.
    expect(find.text('Paid by check'), findsOneWidget);
    expect(find.text('Amount received'), findsOneWidget);

    // And above the allocation list, not after it.
    final method = tester.getTopLeft(find.text('Paid by check')).dy;
    final split = tester.getTopLeft(find.text('Split across invoices')).dy;
    expect(method, lessThan(split),
        reason: 'the payment method comes before the allocation');
  });

  testWidgets('a thousand invoices do not all get built', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(_items(1095)));
    await tester.pumpAndSettle();

    // Each row prints its invoice number, so counting them counts the rows
    // the list actually built.
    final built = find.textContaining('#24000', skipOffstage: true);
    expect(tester.widgetList(built).length, lessThan(30),
        reason: 'the list builds a screenful, not the whole batch');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the rows are still there, further down', (tester) async {
    await tester.pumpWidget(_host(_items(40)));
    await tester.pumpAndSettle();

    // The first row sits right under the header; the last is well past it.
    expect(find.text('#240000'), findsOneWidget);
    expect(find.text('#2400039'), findsNothing,
        reason: 'the far end of the batch is below the fold');

    await tester.scrollUntilVisible(find.text('#2400039'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('#2400039'), findsOneWidget);
  });

  testWidgets('distribute reaches rows that were never built', (tester) async {
    // The rows no longer hold the figures — the fields are built on demand,
    // so a row far down the batch has no TextEditingController when
    // Distribute runs. It must still be allocated.
    await tester.pumpWidget(_host(_items(40)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('batch-total')), '40000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Distribute'));
    await tester.pumpAndSettle();

    // Everything received is accounted for, including the rows off screen.
    expect(find.textContaining('left to allocate'), findsNothing);
    expect(find.text('Fully allocated'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('#2400039'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    // And the last row shows what it was given, the first time it is built.
    final field = tester.widget<TextField>(
        find.byKey(const ValueKey('batch-amount-2400039')));
    expect(field.controller!.text, isNotEmpty);
  });

  testWidgets('switching to check keeps its fields in reach', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(_items(1095)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // The three fields unfold where the switch is, near the top, so they do
    // not need hunting for either.
    expect(find.text('Check number'), findsOneWidget);
    expect(find.text('Check date'), findsOneWidget);
  });
}
