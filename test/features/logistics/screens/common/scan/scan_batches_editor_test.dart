import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/scan/scan_batches_editor.dart';

void main() {
  late ScanBatchesDraft draft;

  Future<void> pump(WidgetTester tester, List<InventoryBatchModel> batches) async {
    // A 360 px phone, the narrowest the app supports.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    draft = ScanBatchesDraft(batches);
    addTearDown(draft.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Form(child: ScanBatchesEditor(draft: draft)),
        ),
      ),
    ));
  }

  final read = InventoryBatchModel(
      batchSerial: 'LOT-A1', batchQuantity: 3, expiryDate: '07/23/2027');

  testWidgets('shows the batch as read and keeps an edit', (tester) async {
    await pump(tester, [read]);

    expect(find.text('LOT-A1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('07/23/2027'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'no overflow at 360 px');

    await tester.enterText(find.byKey(const Key('scanBatchSerial-0')), 'LOT-A2');
    await tester.enterText(find.byKey(const Key('scanBatchQty-0')), '1,000');
    final b = draft.batches.single;
    expect(b.batchSerial, 'LOT-A2');
    expect(b.batchQuantity, 1000);
    expect(b.expiryDate, '07/23/2027');
  });

  testWidgets('Add batch adds a row; a row left empty is dropped',
      (tester) async {
    await pump(tester, []);
    expect(find.text('No batch read.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('scanBatchAdd')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scanBatchSerial-0')), findsOneWidget);
    expect(draft.batches, isEmpty);

    await tester.enterText(find.byKey(const Key('scanBatchSerial-0')), 'LOT-B');
    expect(draft.batches.single.batchSerial, 'LOT-B');
    expect(draft.batches.single.batchQuantity, 0);
  });

  testWidgets('remove drops that batch only', (tester) async {
    await pump(tester, [
      read,
      InventoryBatchModel(batchSerial: 'LOT-C', batchQuantity: 2, expiryDate: ''),
    ]);

    await tester.tap(find.byKey(const Key('scanBatchRemove-0')));
    await tester.pumpAndSettle();

    expect(draft.batches.map((b) => b.batchSerial), ['LOT-C']);
    expect(find.text('LOT-A1'), findsNothing);
  });

  testWidgets('a quantity that is not a number fails validation',
      (tester) async {
    await pump(tester, [read]);
    await tester.enterText(find.byKey(const Key('scanBatchQty-0')), 'abc');
    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isFalse);
    await tester.pump();
    expect(find.text('Not a number'), findsOneWidget);
  });
}
