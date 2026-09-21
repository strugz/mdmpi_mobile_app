import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/batch_activity_detail_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_fill_chip.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The batch screen splits one payment across several invoices. Its job is
/// the split, so that is what these cover: the money must arrive as the
/// figure the collector saw, and the arithmetic must never be left to them.

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

Finder _total() => find.byKey(const ValueKey('batch-total'));
Finder _amount(String id) => find.byKey(ValueKey('batch-amount-$id'));

String _textOf(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).controller!.text;

Finder _chip(String startsWith) => find.byWidgetPredicate(
      (w) => w is BQuickFillChip && w.label.startsWith(startsWith),
    );

/// Chips sit below the fold on a phone-sized viewport, so scroll to one
/// before tapping: a tap on an off-screen widget lands on nothing.
///
/// Every row carries the same "Full" chip, so take the first match rather
/// than requiring the label to be unique on screen.
Future<void> _tapChip(WidgetTester tester, String startsWith) async {
  final finder = _chip(startsWith).first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

ElevatedButton _saveButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Record 2 invoices'),
    );

void main() {
  Future<void> pump(WidgetTester tester,
      {List<CollectionItemModel>? items}) async {
    // The invoice rows live in a lazy list, so a row below the fold is not
    // in the tree at all and cannot be typed into. A tall surface puts the
    // whole screen in view; this is about reaching the fields, not about
    // how the screen looks on a phone.
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(GetMaterialApp(
      home: BatchActivityDetailScreen(
        items: items ?? [_item('1', 600), _item('2', 400)],
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('splitting the payment', () {
    testWidgets('one tap pours the amount over the invoices in order',
        (tester) async {
      await pump(tester);

      await tester.enterText(_total(), '1000');
      await tester.pumpAndSettle();
      await _tapChip(tester, 'Distribute');

      expect(_textOf(tester, _amount('1')), '600.00');
      expect(_textOf(tester, _amount('2')), '400.00');
      expect(find.text('Fully allocated'), findsOneWidget);
    });

    testWidgets('a short payment settles what it can and stops',
        (tester) async {
      await pump(tester);

      await tester.enterText(_total(), '750');
      await tester.pumpAndSettle();
      await _tapChip(tester, 'Distribute');

      // The first invoice is settled in full and the remainder lands on the
      // second, which is how a payment is actually applied.
      expect(_textOf(tester, _amount('1')), '600.00');
      expect(_textOf(tester, _amount('2')), '150.00');
      expect(find.text('Fully allocated'), findsOneWidget);
    });

    testWidgets('an overpayment leaves nothing stranded on the last invoice',
        (tester) async {
      await pump(tester);

      await tester.enterText(_total(), '1200');
      await tester.pumpAndSettle();
      await _tapChip(tester, 'Distribute');

      // Each invoice takes its balance and no more, so the excess shows up
      // as unallocated rather than silently inflating a row.
      expect(_textOf(tester, _amount('1')), '600.00');
      expect(_textOf(tester, _amount('2')), '400.00');
      expect(find.textContaining('left to allocate'), findsOneWidget);
    });

    testWidgets('settling everything is a single chip', (tester) async {
      await pump(tester);

      await _tapChip(tester, 'Settles all');

      expect(_textOf(tester, _total()), '1,000.00');
      expect(_textOf(tester, _amount('1')), '600.00');
      expect(find.text('Fully allocated'), findsOneWidget);
    });

    testWidgets('centavos survive the split', (tester) async {
      await pump(tester, items: [_item('1', 600.25), _item('2', 400.25)]);

      await tester.enterText(_total(), '1000.50');
      await tester.pumpAndSettle();
      await _tapChip(tester, 'Distribute');

      expect(_textOf(tester, _amount('1')), '600.25');
      expect(_textOf(tester, _amount('2')), '400.25');
      expect(find.text('Fully allocated'), findsOneWidget);
    });

    testWidgets('clearing empties every row', (tester) async {
      await pump(tester);

      await tester.enterText(_total(), '1000');
      await tester.pumpAndSettle();
      await _tapChip(tester, 'Distribute');
      await _tapChip(tester, 'Clear');

      expect(_textOf(tester, _amount('1')), '');
      expect(_textOf(tester, _amount('2')), '');
    });
  });

  group('the leftover centavos', () {
    testWidgets('a row can take the remainder without typing a decimal',
        (tester) async {
      await pump(tester, items: [_item('1', 32261.31), _item('2', 9716.00)]);

      // The exact situation from the field: the split is short by centavos,
      // and typing them means finding a decimal point on a numeric keypad.
      await tester.enterText(_total(), '35000');
      await tester.enterText(_amount('1'), '32261.31');
      await tester.enterText(_amount('2'), '2738');
      await tester.pumpAndSettle();

      expect(find.textContaining('0.69 left to allocate'), findsOneWidget);

      await _tapChip(tester, 'Add the remaining');

      expect(_textOf(tester, _amount('2')), '2,738.69');
      expect(find.text('Fully allocated'), findsOneWidget);
    });

    testWidgets('the chip is not offered once the split balances',
        (tester) async {
      await pump(tester);

      await tester.enterText(_total(), '1000');
      await tester.pumpAndSettle();
      await _tapChip(tester, 'Distribute');

      expect(_chip('Add the remaining'), findsNothing);
    });

    testWidgets('no row offers to take more than its invoice owes',
        (tester) async {
      await pump(tester, items: [_item('1', 600), _item('2', 400)]);

      // 900 still unallocated, against invoices of 600 and 400: no single row
      // can absorb it, so nothing offers to. Distribute is the way out.
      await tester.enterText(_total(), '1000');
      await tester.enterText(_amount('1'), '100');
      await tester.pumpAndSettle();

      expect(_chip('Add the remaining'), findsNothing);
    });

    testWidgets('a row offers to take a remainder that fits', (tester) async {
      await pump(tester, items: [_item('1', 600), _item('2', 400)]);

      // 100 unallocated. Row 1 has 100 of headroom left, row 2 is already at
      // its full balance, so only row 1 offers.
      await tester.enterText(_total(), '1000');
      await tester.enterText(_amount('1'), '500');
      await tester.enterText(_amount('2'), '400');
      await tester.pumpAndSettle();

      expect(_chip('Add the remaining'), findsOneWidget);

      await _tapChip(tester, 'Add the remaining');

      expect(_textOf(tester, _amount('1')), '600.00');
      expect(find.text('Fully allocated'), findsOneWidget);
    });
  });

  group('what is left to allocate', () {
    testWidgets('save is blocked until the split balances, and says why',
        (tester) async {
      await pump(tester);

      expect(find.text('Enter the amount received'), findsOneWidget);
      expect(_saveButton(tester).onPressed, isNull);

      await tester.enterText(_total(), '1000');
      await tester.pumpAndSettle();
      expect(find.textContaining('left to allocate'), findsOneWidget);
      expect(_saveButton(tester).onPressed, isNull);

      await _tapChip(tester, 'Distribute');
      expect(_saveButton(tester).onPressed, isNotNull);
    });

    testWidgets('allocating more than was received is called out',
        (tester) async {
      await pump(tester);

      await tester.enterText(_total(), '500');
      await tester.enterText(_amount('1'), '600');
      await tester.pumpAndSettle();

      expect(find.textContaining('over'), findsWidgets);
      expect(_saveButton(tester).onPressed, isNull);
    });

    testWidgets('a grouped total balances against grouped allocations',
        (tester) async {
      await pump(tester);

      // Before, every one of these read as zero: the total was zero, so Save
      // stayed disabled with nothing on screen explaining why.
      await tester.enterText(_total(), '1000');
      await tester.enterText(_amount('1'), '600');
      await tester.enterText(_amount('2'), '400');
      await tester.pumpAndSettle();

      expect(_textOf(tester, _total()), '1,000');
      expect(find.text('Fully allocated'), findsOneWidget);
    });
  });

  group('per-invoice outcome', () {
    testWidgets('a row starts with no outcome rather than pre-collected',
        (tester) async {
      await pump(tester);

      // Every row used to open marked Collected, so a row left at zero was
      // recorded as paid in full against a real invoice.
      expect(find.text('Set outcome'), findsNWidgets(2));
      expect(find.text(CollectionStatusColors.statusCollected), findsNothing);
    });

    testWidgets('a balanced split with an untouched row cannot be saved',
        (tester) async {
      await pump(tester);

      // The whole payment lands on the first invoice: the numbers agree, but
      // nobody has said what happened to the second.
      await tester.enterText(_total(), '600');
      await tester.enterText(_amount('1'), '600');
      await tester.pumpAndSettle();

      expect(find.text('Set the outcome on 1 invoice'), findsOneWidget);
      expect(_saveButton(tester).onPressed, isNull);
    });

    testWidgets('clearing an amount takes its outcome with it', (tester) async {
      await pump(tester);

      await tester.enterText(_amount('1'), '600');
      await tester.pumpAndSettle();
      expect(find.text(CollectionStatusColors.statusCollected), findsOneWidget);

      await tester.enterText(_amount('1'), '');
      await tester.pumpAndSettle();
      expect(find.text(CollectionStatusColors.statusCollected), findsNothing);
    });

    testWidgets('a row settled in full is marked Collected', (tester) async {
      await pump(tester);

      await tester.enterText(_amount('1'), '600');
      await tester.pumpAndSettle();

      expect(find.text(CollectionStatusColors.statusCollected), findsWidgets);
    });

    testWidgets('a part payment marks that row Partially Collected',
        (tester) async {
      await pump(tester);

      await tester.enterText(_amount('1'), '100');
      await tester.pumpAndSettle();

      expect(find.text(CollectionStatusColors.statusPartial), findsOneWidget);
    });

    testWidgets('a row reports what it will leave behind', (tester) async {
      await pump(tester);

      await tester.enterText(_amount('1'), '100');
      await tester.pumpAndSettle();

      expect(find.textContaining('will remain'), findsOneWidget);
    });

    testWidgets('one row settling in full does not move the others',
        (tester) async {
      await pump(tester);

      await _tapChip(tester, 'Full');
      await tester.pumpAndSettle();

      expect(_textOf(tester, _amount('1')), '600.00');
      expect(_textOf(tester, _amount('2')), '');
    });
  });

  group('check details', () {
    testWidgets('the three check fields are off by default', (tester) async {
      await pump(tester);

      expect(find.text('Bank'), findsNothing);
      expect(find.text('Check number'), findsNothing);
      expect(find.text('Check date'), findsNothing);
    });

    testWidgets('switching "Paid by check" on reveals them', (tester) async {
      await pump(tester);

      final toggle = find.byType(SwitchListTile);
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(find.text('Bank'), findsOneWidget);
      expect(find.text('Check number'), findsOneWidget);
      expect(find.text('Check date'), findsOneWidget);
    });
  });
}
