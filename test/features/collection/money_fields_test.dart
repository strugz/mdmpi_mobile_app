import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/batch_activity_detail_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The screens that take a money amount, checked at the field rather than at
/// the parser: what the collector types has to arrive as the figure they saw.

CollectionItemModel _item(String id, double due) => CollectionItemModel(
      id: id,
      client: ClientModel(
        id: 'A',
        code: 'NLN-1',
        name: 'Accusure Medical Enterprises',
        address: '',
        contact: '',
        emailAddress: '',
      ),
      toBeCollected: due,
      dueDate: '2026-08-13',
      postingDate: '2026-08-13',
    );

String _textOf(WidgetTester tester, int index) => tester
    .widget<TextField>(find.byType(TextField).at(index))
    .controller!
    .text;

void main() {
  group('batch allocation', () {
    // Field order on the screen: bank, check #, check date, total, then one
    // amount/remark pair per invoice.
    const totalField = 3;
    const firstAmountField = 4;
    const secondAmountField = 6;

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(GetMaterialApp(
        home: BatchActivityDetailScreen(
          items: [_item('1', 600), _item('2', 400)],
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('a grouped total balances against grouped allocations',
        (tester) async {
      await pump(tester);

      // Typed with the separator, the way the field now renders it. Before,
      // every one of these read as zero: the total was zero so Save stayed
      // disabled, with nothing on screen explaining why.
      await tester.enterText(find.byType(TextField).at(totalField), '1000');
      await tester.enterText(
          find.byType(TextField).at(firstAmountField), '600');
      await tester.enterText(
          find.byType(TextField).at(secondAmountField), '400');
      await tester.pumpAndSettle();

      expect(_textOf(tester, totalField), '1,000');
      expect(find.text('Balanced! Ready to save.'), findsOneWidget);
    });

    testWidgets('centavos are kept, so the balance check can actually meet',
        (tester) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField).at(totalField), '1000.50');
      await tester.enterText(
          find.byType(TextField).at(firstAmountField), '600.25');
      await tester.enterText(
          find.byType(TextField).at(secondAmountField), '400.25');
      await tester.pumpAndSettle();

      expect(_textOf(tester, totalField), '1,000.50');
      expect(find.text('Balanced! Ready to save.'), findsOneWidget);
    });

    testWidgets('a short allocation still reports what is left', (tester) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField).at(totalField), '1000');
      await tester.enterText(
          find.byType(TextField).at(firstAmountField), '600');
      await tester.pumpAndSettle();

      expect(find.textContaining('400.00'), findsWidgets);
      expect(find.text('Balanced! Ready to save.'), findsNothing);
    });

    testWidgets('the save button is disabled until the split balances',
        (tester) async {
      await pump(tester);

      ElevatedButton saveButton() => tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Save Batch Engagement'),
          );

      await tester.enterText(find.byType(TextField).at(totalField), '1000');
      await tester.pumpAndSettle();
      expect(saveButton().onPressed, isNull);

      await tester.enterText(
          find.byType(TextField).at(firstAmountField), '1000');
      await tester.pumpAndSettle();
      expect(saveButton().onPressed, isNotNull);
    });
  });
}
