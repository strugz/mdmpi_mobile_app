import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/activity_detail_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_fill_chip.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// This form is filled in the field, one-handed, many times a day, so the
/// thing worth protecting is how little has to be typed: the check fields are
/// hidden unless asked for, the balance is one tap, and the outcome follows
/// the amount.

CollectionItemModel _item({
  double toBeCollected = 37759.82,
  List<CollectionHistoryModel> history = const [],
}) =>
    CollectionItemModel(
      id: '700013390',
      client: ClientModel(
        id: 'A',
        code: 'NLN-1',
        name: 'Accusure Medical Enterprises',
        address: '',
        contact: '',
        emailAddress: '',
      ),
      toBeCollected: toBeCollected,
      dueDate: '2026-08-13',
      postingDate: '2026-08-13',
      history: history,
    );

Widget _host(CollectionItemModel item) =>
    GetMaterialApp(home: ActivityDetailScreen(item: item));

Finder _chip(String startsWith) => find.byWidgetPredicate(
      (w) => w is BQuickFillChip && w.label.startsWith(startsWith),
    );

String _amountText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).first).controller!.text;

Future<void> _tapCheckToggle(WidgetTester tester) async {
  final toggle = find.byType(SwitchListTile);
  await tester.ensureVisible(toggle);
  await tester.pumpAndSettle();
  await tester.tap(toggle);
  await tester.pumpAndSettle();
}

/// Chips can sit below the fold on a phone-sized viewport, so scroll to the
/// chip before tapping it; a tap on an off-screen widget lands on nothing.
Future<void> _tapChip(WidgetTester tester, String startsWith) async {
  final finder = _chip(startsWith);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('typing reduction', () {
    testWidgets('the three check fields are off by default', (tester) async {
      await tester.pumpWidget(_host(_item()));
      await tester.pumpAndSettle();

      expect(find.text('Paid by check'), findsOneWidget);
      expect(find.text('Bank'), findsNothing);
      expect(find.text('Check number'), findsNothing);
      expect(find.text('Check date'), findsNothing);
    });

    testWidgets('switching "Paid by check" on reveals them', (tester) async {
      await tester.pumpWidget(_host(_item()));
      await tester.pumpAndSettle();

      await _tapCheckToggle(tester);

      expect(find.text('Bank'), findsOneWidget);
      expect(find.text('Check number'), findsOneWidget);
      expect(find.text('Check date'), findsOneWidget);
    });

    testWidgets('an invoice last paid by check opens with the switch on',
        (tester) async {
      await tester.pumpWidget(_host(_item(history: const [
        CollectionHistoryModel(
          date: '2026-09-01',
          collectorName: 'Juan',
          status: 'Partially Collected',
          totalCollected: 100,
          bankName: 'BPI',
          checkNumber: '12345',
        ),
      ])));
      await tester.pumpAndSettle();

      expect(find.text('Bank'), findsOneWidget);
      expect(find.text('BPI'), findsOneWidget, reason: 'carried over');
    });

    testWidgets('the full balance is one tap', (tester) async {
      await tester.pumpWidget(_host(_item(toBeCollected: 37759.82)));
      await tester.pumpAndSettle();

      expect(_amountText(tester), '');
      await _tapChip(tester, 'Full');

      // Grouped, matching what typing the same figure into the field produces.
      expect(_amountText(tester), '37,759.82');
      expect(find.text('Settles this invoice in full'), findsOneWidget);
    });

    testWidgets('a part payment reports what will remain', (tester) async {
      await tester.pumpWidget(_host(_item(toBeCollected: 1000)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '400');
      await tester.pumpAndSettle();

      expect(find.textContaining('600'), findsOneWidget);
    });

    testWidgets('overpaying is flagged rather than blocked', (tester) async {
      await tester.pumpWidget(_host(_item(toBeCollected: 1000)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '1500');
      await tester.pumpAndSettle();

      expect(find.textContaining('more than the balance'), findsOneWidget);
    });

    testWidgets('letters and symbols cannot be typed into the amount',
        (tester) async {
      await tester.pumpWidget(_host(_item()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, r'₱1,2a3.4b5');
      await tester.pumpAndSettle();

      expect(_amountText(tester), '123.45');
    });

    testWidgets('a second decimal point is rejected', (tester) async {
      await tester.pumpWidget(_host(_item()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '12.34');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '12.34.5');
      await tester.pumpAndSettle();

      expect(_amountText(tester), '12.34');
    });
  });

  group('outcome follows the amount', () {
    testWidgets('paying in full selects Collected', (tester) async {
      await tester.pumpWidget(_host(_item(toBeCollected: 1000)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.pumpAndSettle();

      final chip = tester.widget<BQuickFillChip>(
          _chip(CollectionStatusColors.statusCollected));
      expect(chip.selected, isTrue);
    });

    testWidgets('paying part selects Partially Collected', (tester) async {
      await tester.pumpWidget(_host(_item(toBeCollected: 1000)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '250');
      await tester.pumpAndSettle();

      final partial = tester
          .widget<BQuickFillChip>(_chip(CollectionStatusColors.statusPartial));
      expect(partial.selected, isTrue);
    });

    testWidgets('a hand-picked outcome is not overridden by later typing',
        (tester) async {
      await tester.pumpWidget(_host(_item(toBeCollected: 1000)));
      await tester.pumpAndSettle();

      await _tapChip(tester, CollectionStatusColors.statusPreCollection);

      // Typing an amount must not yank the outcome away from their choice.
      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.pumpAndSettle();

      final chosen = tester.widget<BQuickFillChip>(
          _chip(CollectionStatusColors.statusPreCollection));
      expect(chosen.selected, isTrue);
    });

    testWidgets('Others asks for a remark', (tester) async {
      await tester.pumpWidget(_host(_item()));
      await tester.pumpAndSettle();

      expect(find.text('What happened?'), findsNothing);
      await _tapChip(tester, CollectionStatusColors.statusOthers);
      expect(find.text('What happened?'), findsOneWidget);
    });
  });

  group('recentBankNames', () {
    CollectionItemModel withBanks(String id, List<String?> banks) =>
        CollectionItemModel(
          id: id,
          client: ClientModel(
              id: 'A',
              code: 'NLN-1',
              name: 'A',
              address: '',
              contact: '',
              emailAddress: ''),
          toBeCollected: 100,
          history: [
            for (final b in banks)
              CollectionHistoryModel(
                date: '2026-09-01',
                collectorName: 'Juan',
                status: 'Collected',
                totalCollected: 10,
                bankName: b,
              ),
          ],
        );

    test('ranks by how often each bank was used and ignores blanks', () {
      final c = CollectionActivityController();
      c.startAggregateTracking();
      c.bucketItems.assignAll([
        withBanks('1', ['BPI', 'BDO', null, '']),
        withBanks('2', ['BDO', 'BDO', 'Metrobank']),
      ]);

      expect(c.recentBankNames(), ['BDO', 'BPI', 'Metrobank']);
    });

    test('treats the same bank in different case as one', () {
      final c = CollectionActivityController();
      c.startAggregateTracking();
      c.bucketItems.assignAll([
        withBanks('1', ['BPI', 'bpi', 'Bpi']),
      ]);

      expect(c.recentBankNames().length, 1);
    });

    test('caps the number of chips offered', () {
      final c = CollectionActivityController();
      c.startAggregateTracking();
      c.bucketItems.assignAll([
        withBanks('1', ['A', 'B', 'C', 'D', 'E', 'F']),
      ]);

      expect(c.recentBankNames(limit: 4).length, 4);
    });
  });
}
