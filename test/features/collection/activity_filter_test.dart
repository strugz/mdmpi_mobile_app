import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/activity_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_filter_sheet.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_fill_chip.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_filter_bar.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The engagement filter runs on data already on the invoice: due date, last
/// outcome, balance, history. These cases pin each band and the sort, then
/// drive the sheet the way a collector would.

String _daysAgo(int days) {
  final d = DateTime.now().subtract(Duration(days: days));
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

CollectionItemModel _item({
  String id = '1',
  String name = 'Acme',
  String code = 'NLN-1',
  double due = 10000,
  int overdueDays = 0,
  String? lastOutcome,
  String poNumber = '',
  List<CollectionHistoryModel> history = const [],
}) =>
    CollectionItemModel(
      id: id,
      client: ClientModel(
        id: 'c$id',
        code: code,
        name: name,
        address: '',
        contact: '',
        emailAddress: '',
      ),
      toBeCollected: due,
      dueDate: _daysAgo(overdueDays),
      lastOutcome: lastOutcome,
      poNumber: poNumber,
      history: history,
    );

void main() {
  group('due bands', () {
    test('overdue, late 30+, late 1 year+ nest by days past due', () {
      final fresh = _item(overdueDays: 0);
      final week = _item(overdueDays: 7);
      final quarter = _item(overdueDays: 90);
      final years = _item(overdueDays: 800);

      expect(DueBand.overdue.matches(fresh), isFalse);
      expect(DueBand.overdue.matches(week), isTrue);
      expect(DueBand.late30.matches(week), isFalse);
      expect(DueBand.late30.matches(quarter), isTrue);
      expect(DueBand.lateYear.matches(quarter), isFalse);
      expect(DueBand.lateYear.matches(years), isTrue);
    });

    test('due in 7 days is the week ahead, not the past', () {
      expect(DueBand.dueSoon.matches(_item(overdueDays: -3)), isTrue);
      expect(DueBand.dueSoon.matches(_item(overdueDays: 0)), isTrue);
      expect(DueBand.dueSoon.matches(_item(overdueDays: -10)), isFalse);
      expect(DueBand.dueSoon.matches(_item(overdueDays: 2)), isFalse);
    });
  });

  test('amount bands are half-open so a value lands in exactly one', () {
    final bands = AmountBand.values.where((b) => b != AmountBand.any);
    for (final amount in [0.0, 9999.99, 10000.0, 50000.0, 200000.0, 1e7]) {
      expect(bands.where((b) => b.matches(amount)).length, 1,
          reason: '$amount');
    }
  });

  test('sort by longest since visit puts never-visited first', () {
    final never = _item(id: 'a');
    final old = _item(id: 'b', history: const [
      CollectionHistoryModel(date: '2025-01-01', collectorName: 'J'),
    ]);
    final recent = _item(id: 'c', history: const [
      CollectionHistoryModel(date: '2026-09-01', collectorName: 'J'),
    ]);
    const f = ActivityFilter(sort: ActivitySort.lastVisitOldest);
    final sorted = [recent, old, never]..sort(f.compare);
    expect(sorted.map((i) => i.id), ['a', 'b', 'c']);
  });

  test('sort alone is not an active filter', () {
    expect(const ActivityFilter(sort: ActivitySort.name).isActive, isFalse);
    expect(const ActivityFilter(due: DueBand.overdue).activeCount, 1);
  });

  group('P.O. number lookup', () {
    test('matches any part of the P.O., ignoring case', () {
      const f = ActivityFilter(poNumber: 'chem-2023');
      expect(f.matches(_item(poNumber: 'ADC-CHEM-2023-001-A')), isTrue);
      expect(f.matches(_item(poNumber: 'ADC-HEMA-2023-052')), isFalse);
      expect(f.matches(_item()), isFalse, reason: 'no P.O. cannot match');
    });

    test('whitespace alone is not a lookup', () {
      const blank = ActivityFilter(poNumber: '   ');
      expect(blank.hasPoNumber, isFalse);
      expect(blank.isActive, isFalse);
      expect(blank.matches(_item()), isTrue);
    });

    test('counts as one filter group and equality sees it', () {
      const f = ActivityFilter(poNumber: '2026-0262');
      expect(f.isActive, isTrue);
      expect(f.activeCount, 1);
      expect(f, isNot(equals(ActivityFilter.none)));
      expect(f.copyWith(poNumber: ''), ActivityFilter.none);
    });

    test('Has P.O. / No P.O. split the bucket by presence', () {
      final withPo = _item(id: 'a', poNumber: '23-122');
      final without = _item(id: 'b');

      const has = ActivityFilter(poPresence: PoPresence.has);
      expect(has.matches(withPo), isTrue);
      expect(has.matches(without), isFalse);

      const none = ActivityFilter(poPresence: PoPresence.none);
      expect(none.matches(withPo), isFalse);
      expect(none.matches(without), isTrue);
      expect(none.isActive, isTrue);
      expect(none.activeCount, 1);
    });

    test('presence and typed text are one group in the badge count', () {
      const both =
          ActivityFilter(poPresence: PoPresence.has, poNumber: 'ADC');
      expect(both.activeCount, 1);
    });
  });

  group('sheet', () {
    Widget host(void Function(ActivityFilter?) onResult,
        {required int Function(ActivityFilter) count}) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async => onResult(await ActivityFilterSheet.show(
                    context,
                    initial: ActivityFilter.none,
                    count: count)),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('the apply button carries the live count', (tester) async {
      ActivityFilter? result;
      await tester.pumpWidget(host((r) => result = r,
          count: (f) => f.due == DueBand.overdue ? 3 : 12));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Show 12 accounts'), findsOneWidget);

      await tester.tap(find.text('Overdue'));
      await tester.pumpAndSettle();
      expect(find.text('Show 3 accounts'), findsOneWidget);

      // The sheet is taller than the test viewport; the apply button is the
      // last thing in it.
      await tester.ensureVisible(find.text('Show 3 accounts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show 3 accounts'));
      await tester.pumpAndSettle();
      expect(result?.due, DueBand.overdue);
    });

    testWidgets('a filter that matches nothing cannot be applied',
        (tester) async {
      await tester.pumpWidget(
          host((_) {}, count: (f) => f.amount == AmountBand.any ? 5 : 0));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Over ₱200k'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('No accounts match'));
      await tester.pumpAndSettle();
      final button = tester.widget<ElevatedButton>(find.ancestor(
          of: find.text('No accounts match'),
          matching: find.byType(ElevatedButton)));
      expect(button.onPressed, isNull);
    });

    testWidgets('reset clears the draft', (tester) async {
      await tester.pumpWidget(host((_) {}, count: (_) => 4));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Reset'), findsNothing, reason: 'nothing set yet');

      await tester.tap(find.text('Over ₱200k'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(find.text('Reset'), findsNothing);
    });
  });

  group('area', () {
    test('matches on the client code prefix, case-insensitively', () {
      const f = ActivityFilter(area: 'NLN');
      expect(f.matches(_item(code: 'NLN-115')), isTrue);
      expect(f.matches(_item(code: 'nln-9')), isTrue);
      expect(f.matches(_item(code: 'NCR-205')), isFalse);
      expect(f.isActive, isTrue);
    });

    test('an unnamed prefix falls into Others', () {
      const f = ActivityFilter(area: 'OTHERS');
      expect(f.matches(_item(code: 'VET-1')), isTrue);
      expect(f.matches(_item(code: 'NLN-1')), isFalse);
    });

    test('empty area matches every code', () {
      expect(const ActivityFilter().matches(_item(code: 'VET-1')), isTrue);
    });
  });

  group('quick filter bar', () {
    // The bar scrolls horizontally; a phone-width test viewport builds only
    // the first few chips, so the cases that reach a later chip widen the view.
    Widget host(ActivityFilter initial, void Function(ActivityFilter) sink,
        {List<String> areas = const []}) {
      return MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => QuickFilterBar(
              filter: initial,
              areas: areas,
              onChanged: (f) => setState(() {
                initial = f;
                sink(f);
              }),
            ),
          ),
        ),
      );
    }

    testWidgets('one tap sets a filter and a second tap clears it',
        (tester) async {
      ActivityFilter? last;
      await tester.pumpWidget(host(ActivityFilter.none, (f) => last = f));

      await tester.tap(find.text('Overdue'));
      await tester.pumpAndSettle();
      expect(last?.due, DueBand.overdue);

      await tester.tap(find.text('Overdue'));
      await tester.pumpAndSettle();
      expect(last?.due, DueBand.any);
    });

    testWidgets('All clears every dimension, including ones with no preset',
        (tester) async {
      ActivityFilter? last;
      await tester.pumpWidget(host(
        const ActivityFilter(
            due: DueBand.late30, amount: AmountBand.over200k, area: 'NLN'),
        (f) => last = f,
      ));

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(last?.isActive, isFalse);
      expect(last?.amount, AmountBand.any);
      expect(last?.area, isEmpty);
    });

    testWidgets('a dimension with no preset shows as a removable chip',
        (tester) async {
      tester.view.physicalSize = const Size(3000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      ActivityFilter? last;
      await tester.pumpWidget(host(
        const ActivityFilter(amount: AmountBand.over200k),
        (f) => last = f,
      ));

      expect(find.text('Over ₱200k'), findsOneWidget);
      await tester.tap(find.text('Over ₱200k'));
      await tester.pumpAndSettle();

      expect(last?.amount, AmountBand.any);
    });

    // Nothing in the bucket has been engaged, so every account would answer
    // the last-visit question the same way; the bucket hides it.
    // The bar carries how-late and territory only.
    testWidgets('carries no outcome presets', (tester) async {
      tester.view.physicalSize = const Size(3000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QuickFilterBar(filter: ActivityFilter.none, onChanged: (_) {}),
        ),
      ));

      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text(CollectionStatusColors.statusFollowUp), findsNothing);
      expect(find.text(CollectionStatusColors.statusUnavailable), findsNothing);
    });

    // One chip per order, carrying both directions: descending, then
    // ascending, then off. Orders hide nothing, so All stays lit throughout.
    testWidgets('the amount chip cycles high, low, off', (tester) async {
      tester.view.physicalSize = const Size(3000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      ActivityFilter? last;
      await tester.pumpWidget(host(ActivityFilter.none, (f) => last = f));

      expect(find.text(ActivitySort.amountLow.label), findsNothing,
          reason: 'off, the chip offers the first direction only');

      await tester.tap(find.text(ActivitySort.amountHigh.label));
      await tester.pumpAndSettle();
      expect(last?.sort, ActivitySort.amountHigh);
      expect(last?.isActive, isFalse, reason: 'an order hides nothing');

      await tester.tap(find.text(ActivitySort.amountHigh.label));
      await tester.pumpAndSettle();
      expect(last?.sort, ActivitySort.amountLow);
      expect(find.text(ActivitySort.amountHigh.label), findsNothing);

      await tester.tap(find.text(ActivitySort.amountLow.label));
      await tester.pumpAndSettle();
      expect(last?.sort, ActivitySort.mostOverdue);
    });

    // The icon set draws its own up and down arrows in different styles, so
    // the ascending one read as a stray triangle. One glyph, turned over.
    testWidgets('the amount arrow is one glyph, mirrored for ascending',
        (tester) async {
      tester.view.physicalSize = const Size(3000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      double turnsOn(String label) => tester
          .widget<BQuickFillChip>(find.ancestor(
            of: find.text(label),
            matching: find.byType(BQuickFillChip),
          ))
          .iconTurns;

      IconData? iconOn(String label) => tester
          .widget<BQuickFillChip>(find.ancestor(
            of: find.text(label),
            matching: find.byType(BQuickFillChip),
          ))
          .icon;

      await tester.pumpWidget(host(
        const ActivityFilter(sort: ActivitySort.amountHigh),
        (_) {},
      ));
      final descending = iconOn(ActivitySort.amountHigh.label);
      expect(turnsOn(ActivitySort.amountHigh.label), 0);

      await tester.tap(find.text(ActivitySort.amountHigh.label));
      await tester.pumpAndSettle();

      expect(iconOn(ActivitySort.amountLow.label), descending,
          reason: 'same glyph, not a second arrow from the icon set');
      expect(turnsOn(ActivitySort.amountLow.label), 0.5);
    });

    testWidgets('the invoice chip cycles most, fewest, off', (tester) async {
      tester.view.physicalSize = const Size(3000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      ActivityFilter? last;
      await tester.pumpWidget(host(ActivityFilter.none, (f) => last = f));

      await tester.tap(find.text(ActivitySort.mostInvoices.label));
      await tester.pumpAndSettle();
      expect(last?.sort, ActivitySort.mostInvoices);

      await tester.tap(find.text(ActivitySort.mostInvoices.label));
      await tester.pumpAndSettle();
      expect(last?.sort, ActivitySort.fewestInvoices);

      await tester.tap(find.text(ActivitySort.fewestInvoices.label));
      await tester.pumpAndSettle();
      expect(last?.sort, ActivitySort.mostOverdue);
    });

    // Each chip owns one order, so starting the other resets the first.
    testWidgets('starting one order replaces the other', (tester) async {
      tester.view.physicalSize = const Size(3000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      ActivityFilter? last;
      await tester.pumpWidget(host(
        const ActivityFilter(sort: ActivitySort.amountLow),
        (f) => last = f,
      ));

      await tester.tap(find.text(ActivitySort.mostInvoices.label));
      await tester.pumpAndSettle();
      expect(last?.sort, ActivitySort.mostInvoices);
      expect(find.text(ActivitySort.amountHigh.label), findsOneWidget,
          reason: 'the amount chip falls back to its first direction');
    });

    testWidgets('the bucket returns to its own catalogue order',
        (tester) async {
      tester.view.physicalSize = const Size(3000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      ActivityFilter? last;
      var filter = const ActivityFilter(sort: ActivitySort.amountLow);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => QuickFilterBar(
              filter: filter,
              defaultSort: ActivitySort.name,
              onChanged: (f) => setState(() {
                filter = f;
                last = f;
              }),
            ),
          ),
        ),
      ));

      // Off the end of the cycle the bucket lands on its own order, not the
      // engagement list's.
      await tester.tap(find.text(ActivitySort.amountLow.label));
      await tester.pumpAndSettle();
      expect(last?.sort, ActivitySort.name);
    });

    testWidgets('a sort chosen only in the sheet shows here as removable',
        (tester) async {
      tester.view.physicalSize = const Size(3000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      ActivityFilter? last;
      await tester.pumpWidget(host(
        const ActivityFilter(sort: ActivitySort.lastVisitOldest),
        (f) => last = f,
      ));

      expect(find.text(ActivitySort.lastVisitOldest.label), findsOneWidget);
      await tester.tap(find.text(ActivitySort.lastVisitOldest.label));
      await tester.pumpAndSettle();
      expect(last?.sort, ActivitySort.mostOverdue);
    });

    testWidgets('areas present in the data are offered', (tester) async {
      tester.view.physicalSize = const Size(3000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      ActivityFilter? last;
      await tester.pumpWidget(host(ActivityFilter.none, (f) => last = f,
          areas: const ['NLN', 'NCR']));

      expect(find.text('North Luzon'), findsOneWidget);
      expect(find.text('Visayas'), findsNothing);

      await tester.tap(find.text('NCR'));
      await tester.pumpAndSettle();
      expect(last?.area, 'NCR');
    });
  });

  group('amount sort', () {
    test('high to low and low to high are mirror orders', () {
      final small = _item(id: '1', due: 5000);
      final big = _item(id: '2', due: 900000);

      final high = [small, big]
        ..sort(const ActivityFilter(sort: ActivitySort.amountHigh).compare);
      expect(high.first.id, '2');

      final low = [big, small]
        ..sort(const ActivityFilter(sort: ActivitySort.amountLow).compare);
      expect(low.first.id, '1');
    });
  });

  group('invoice count sort', () {
    test('is account-level, so it does not order invoices', () {
      expect(ActivitySort.mostInvoices.isAccountLevel, isTrue);
      expect(ActivitySort.fewestInvoices.isAccountLevel, isTrue);
      expect(ActivitySort.amountHigh.isAccountLevel, isFalse);
      expect(ActivitySort.mostOverdue.isAccountLevel, isFalse);
    });

    test('inside one account it falls back to the default order', () {
      final fresh = _item(id: '1', overdueDays: 2);
      final ancient = _item(id: '2', overdueDays: 900);
      final sorted = [fresh, ancient]
        ..sort(const ActivityFilter(sort: ActivitySort.mostInvoices).compare);
      expect(sorted.first.id, '2', reason: 'most overdue first');
    });
  });

  // The bucket is a catalogue, so it keeps alphabetical order until the
  // collector asks for another; the engagement list leads with most overdue.
  test('the bucket default sorts by name and filters nothing', () {
    const spec = ActivityFilter(sort: ActivitySort.name);
    expect(spec.isActive, isFalse);
    expect(spec.sort, ActivitySort.name);

    final a = _item(id: '1', name: 'Zeta', overdueDays: 900);
    final b = _item(id: '2', name: 'Alpha', overdueDays: 1);
    final sorted = [a, b]..sort(spec.compare);
    expect(sorted.first.client.name, 'Alpha');
  });

  group('sheet P.O. field', () {
    Widget host(void Function(ActivityFilter?) onResult,
        {required int Function(ActivityFilter) count}) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async => onResult(await ActivityFilterSheet.show(
                    context,
                    initial: ActivityFilter.none,
                    count: count)),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('typing a P.O. drives the live count and is applied',
        (tester) async {
      ActivityFilter? result;
      await tester.pumpWidget(host((r) => result = r,
          count: (f) => f.hasPoNumber ? 2 : 12));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final field = find.widgetWithText(TextField, 'Any part of the P.O. number');
      await tester.ensureVisible(field);
      await tester.enterText(field, '2026-0262');
      await tester.pumpAndSettle();

      expect(find.text('Show 2 accounts'), findsOneWidget);

      await tester.ensureVisible(find.text('Show 2 accounts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show 2 accounts'));
      await tester.pumpAndSettle();

      expect(result?.poNumber, '2026-0262');
      expect(result?.activeCount, 1);
    });

    testWidgets('No P.O. clears the typed number and disables the field',
        (tester) async {
      ActivityFilter? result;
      await tester.pumpWidget(host((r) => result = r, count: (_) => 4));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final field = find.widgetWithText(TextField, 'Any part of the P.O. number');
      await tester.ensureVisible(field);
      await tester.enterText(field, 'ADC');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('No P.O.'));
      await tester.tap(find.text('No P.O.'));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(tester.widget<TextField>(field).enabled, isFalse);

      await tester.ensureVisible(find.text('Show 4 accounts'));
      await tester.tap(find.text('Show 4 accounts'));
      await tester.pumpAndSettle();
      expect(result?.poPresence, PoPresence.none);
      expect(result?.poNumber, isEmpty);
    });

    testWidgets('typing while No P.O. is on flips it back to Any',
        (tester) async {
      ActivityFilter? result;
      await tester.pumpWidget(host((r) => result = r, count: (_) => 4));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('No P.O.'));
      await tester.tap(find.text('No P.O.'));
      await tester.pumpAndSettle();
      // Back to Any so the field is usable again, then type.
      await tester.tap(find.widgetWithText(BQuickFillChip, 'Any').at(2));
      await tester.pumpAndSettle();

      final field = find.widgetWithText(TextField, 'Any part of the P.O. number');
      await tester.ensureVisible(field);
      await tester.enterText(field, '23-122');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Show 4 accounts'));
      await tester.tap(find.text('Show 4 accounts'));
      await tester.pumpAndSettle();
      expect(result?.poPresence, PoPresence.any);
      expect(result?.poNumber, '23-122');
    });

    testWidgets('Reset empties the field, not just the draft', (tester) async {
      await tester.pumpWidget(host((_) {}, count: (_) => 5));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final field = find.widgetWithText(TextField, 'Any part of the P.O. number');
      await tester.ensureVisible(field);
      await tester.enterText(field, 'ADC');
      await tester.pumpAndSettle();
      expect(find.text('Reset'), findsOneWidget);

      // Focusing the field scrolled the header away; Reset lives up there.
      await tester.ensureVisible(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(find.text('Reset'), findsNothing);
    });
  });

  testWidgets('No P.O. shows as a removable chip', (tester) async {
    var filter = const ActivityFilter(poPresence: PoPresence.none);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => ActiveFilterChips(
            filter: filter,
            onChanged: (f) => setState(() => filter = f),
          ),
        ),
      ),
    ));

    expect(find.text('No P.O.'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove No P.O.'));
    await tester.pumpAndSettle();
    expect(filter.isActive, isFalse);
  });

  testWidgets('a typed P.O. hides the redundant Has P.O. chip', (tester) async {
    const filter =
        ActivityFilter(poPresence: PoPresence.has, poNumber: '23-122');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ActiveFilterChips(filter: filter, onChanged: (_) {})),
    ));
    expect(find.text('PO 23-122'), findsOneWidget);
    expect(find.text('Has P.O.'), findsNothing);
  });

  testWidgets('an applied P.O. shows as a removable chip', (tester) async {
    var filter = const ActivityFilter(poNumber: '23-122');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => ActiveFilterChips(
            filter: filter,
            onChanged: (f) => setState(() => filter = f),
          ),
        ),
      ),
    ));

    expect(find.text('PO 23-122'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove PO 23-122'));
    await tester.pumpAndSettle();

    expect(filter.hasPoNumber, isFalse);
    expect(find.text('PO 23-122'), findsNothing);
  });

  testWidgets('active chips remove one filter at a time', (tester) async {
    var filter =
        const ActivityFilter(due: DueBand.late30, amount: AmountBand.over200k);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => ActiveFilterChips(
            filter: filter,
            onChanged: (f) => setState(() => filter = f),
          ),
        ),
      ),
    ));

    expect(find.text('Late 30+ days'), findsOneWidget);
    expect(find.text('Over ₱200k'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove Late 30+ days'));
    await tester.pumpAndSettle();

    expect(filter.due, DueBand.any);
    expect(filter.amount, AmountBand.over200k);
    expect(find.text('Late 30+ days'), findsNothing);
  });
}
