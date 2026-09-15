import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// An Obx subscribes to the observables its builder actually reads. Caching the
/// per-account aggregates briefly broke that: a warm cache returned its maps
/// without touching bucketItems/activityItems, so an Obx reading only an
/// aggregate registered no dependency at all. On the Collection home screen
/// that threw "improper use of a GetX has been detected" and painted all four
/// summary tiles as red error boxes.
///
/// These tests read aggregates inside a real Obx, which unit tests on the
/// controller alone cannot catch.

CollectionItemModel _item(
  String id, {
  double toBeCollected = 0,
  double totalCollected = 0,
}) =>
    CollectionItemModel(
      id: id,
      client: ClientModel(
        id: 'A',
        code: 'NLN-1',
        name: 'Acme',
        address: '',
        contact: '',
        emailAddress: '',
      ),
      toBeCollected: toBeCollected,
      totalCollected: totalCollected,
    );

CollectionActivityController _bareController() {
  // onInit needs the repository and sync manager from DI; nothing here uses them.
  final c = CollectionActivityController();
  c.startAggregateTracking();
  return c;
}

Widget _obxText(String Function() read) =>
    MaterialApp(home: Scaffold(body: Obx(() => Text(read()))));

/// Several Obx widgets reading aggregates as siblings, like the four summary
/// tiles on the Collection home screen.
Widget _obxTexts(List<String Function()> reads) => MaterialApp(
      home: Scaffold(
        body: Column(
          children: [for (final r in reads) Obx(() => Text(r()))],
        ),
      ),
    );

void main() {
  testWidgets('sibling Obx tiles reading aggregates all render',
      (tester) async {
    // The home screen shape, and the shape that actually broke: the first
    // read leaves the cache warm, so every later Obx saw a cached value and
    // touched no observable at all.
    final c = _bareController();

    await tester.pumpWidget(_obxTexts([
      () => '${c.completedItems.length}',
      () => '${c.overdueItems.length}',
      () => '${c.getAccountTotalDue('A')}',
      () => '${c.getAccountInvoiceCount('A')}',
    ]));

    expect(tester.takeException(), isNull);
    expect(find.byType(Text), findsNWidgets(4));
  });

  testWidgets('an Obx reading a warm cached aggregate does not throw',
      (tester) async {
    final c = _bareController();
    // Something else already populated the cache this frame, exactly as the
    // totals card at the top of the dashboard does.
    c.allItems;

    await tester.pumpWidget(_obxText(() => '${c.completedItems.length}'));

    expect(tester.takeException(), isNull);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('an Obx reading a warm account total does not throw',
      (tester) async {
    final c = _bareController();
    c.allItems;

    await tester.pumpWidget(_obxText(() => '${c.getAccountTotalDue('A')}'));

    expect(tester.takeException(), isNull);
  });

  testWidgets('completedItems rebuilds its Obx when items arrive',
      (tester) async {
    final c = _bareController();
    c.allItems; // warm, as another widget on the screen would leave it
    await tester.pumpWidget(_obxText(() => '${c.completedItems.length}'));
    expect(find.text('0'), findsOneWidget);

    // A settled invoice arrives: toBeCollected 0 makes it "completed".
    c.bucketItems.add(_item('INV-1', toBeCollected: 0, totalCollected: 500));
    await tester.pump();

    expect(find.text('1'), findsOneWidget, reason: 'Obx must have subscribed');
  });

  testWidgets('account totals rebuild their Obx when items change',
      (tester) async {
    final c = _bareController();
    c.allItems; // warm, as another widget on the screen would leave it
    await tester.pumpWidget(_obxText(() => '${c.getAccountTotalDue('A')}'));
    expect(find.text('0.0'), findsOneWidget);

    c.bucketItems.add(_item('INV-1', toBeCollected: 250));
    await tester.pump();
    expect(find.text('250.0'), findsOneWidget);

    // Recording a collection replaces the model in place.
    c.bucketItems[0] = _item('INV-1', toBeCollected: 100, totalCollected: 150);
    await tester.pump();
    expect(find.text('100.0'), findsOneWidget);

    c.bucketItems.removeAt(0);
    await tester.pump();
    expect(find.text('0.0'), findsOneWidget);
  });

  testWidgets('invoice count rebuilds its Obx as the bucket changes',
      (tester) async {
    final c = _bareController();
    c.allItems; // warm, as another widget on the screen would leave it
    await tester.pumpWidget(_obxText(() => '${c.getAccountInvoiceCount('A')}'));
    expect(find.text('0'), findsOneWidget);

    c.bucketItems.add(_item('INV-1', toBeCollected: 250));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    // Settling it drops it from the count without changing the list length.
    c.bucketItems[0] = _item('INV-1', toBeCollected: 0, totalCollected: 250);
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
  });
}
