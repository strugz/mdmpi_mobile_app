import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/activity_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_filter_sheet.dart';
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

  group('last visit outcome', () {
    test('reads the recorded outcome, then the last history status', () {
      expect(ActivityFilter.outcomeOf(_item(lastOutcome: 'Refused to Pay')),
          'Refused to Pay');
      expect(
          ActivityFilter.outcomeOf(_item(history: const [
            CollectionHistoryModel(
                date: '2026-09-01', collectorName: 'J', status: 'Follow Up'),
          ])),
          'Follow Up');
      expect(ActivityFilter.outcomeOf(_item()), ActivityFilter.noVisitYet);
    });

    test('an empty outcome set means everything', () {
      const f = ActivityFilter();
      expect(f.matches(_item(lastOutcome: 'Refused to Pay')), isTrue);
      expect(f.matches(_item()), isTrue);
      expect(f.isActive, isFalse);
    });

    test('toggling adds then removes', () {
      var f = const ActivityFilter().toggleOutcome('Follow Up');
      expect(f.outcomes, {'Follow Up'});
      expect(f.isActive, isTrue);
      f = f.toggleOutcome('Follow Up');
      expect(f.outcomes, isEmpty);
    });
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
      await tester
          .pumpWidget(host((_) {}, count: (f) => f.outcomes.isEmpty ? 5 : 0));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(CollectionStatusColors.statusRefused));
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
