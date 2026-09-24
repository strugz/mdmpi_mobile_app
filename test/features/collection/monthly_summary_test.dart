import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/total_collected_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/total_collected_month/monthly_summary_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_engagement_dao.dart';

/// The month's ledger. What these protect: the headline total is the month's
/// total and not the search result's; the month cannot be stepped into the
/// future; and the collector's name only appears when it tells you something.

class _Activity extends CollectionActivityController {
  @override
  void onInit() {}
}

class _Totals extends TotalCollectedController {
  @override
  void onInit() {}

  @override
  Future<void> reloadTarget() async {}
}

final _now = DateTime.now();
final _fmt = DateFormat('yyyy-MM-dd HH:mm');

String _onDay(int day, [int hour = 10]) =>
    _fmt.format(DateTime(_now.year, _now.month, day, hour));

ClientModel _client(String id, String name) => ClientModel(
    id: id, code: 'c', name: name, address: '', contact: '', emailAddress: '');

/// One Actual Collection entry as the office would post it. [when] is an
/// [_onDay] string or a [DateTime].
MonthlyEntry _posted(Object when, double amount, String account) =>
    MonthlyEntry(
      date: when is DateTime ? when : _fmt.parse(when as String),
      amount: amount,
      accountName: account,
      invoiceNumber: '',
      collectorName: 'Office',
    );

/// Two For Deposit activities this month, as Field Engagement logs them.
List<Map<String, dynamic>> _deposits() => [
      {
        'type': 'Deposit',
        'accountName': 'Alexis Yu Best Care Pharmacy',
        'history': _paid(_onDay(15), 20000),
      },
      {
        'type': 'Deposit',
        'accountName': 'Bicol Medical Center',
        'history': _paid(_onDay(16), 12000),
      },
    ];

CollectionHistoryModel _paid(String date, double amount,
        {String collector = 'Jay'}) =>
    CollectionHistoryModel(
      date: date,
      collectorName: collector,
      status: 'Collected',
      totalCollected: amount,
    );

/// The archive row behind a collection. The ledger reads these rather than the
/// invoices' own history: an invoice that settles stops coming back from the
/// server, and the month used to lose its collections along with it.
CollectionEngagementRecord _engagement(
  String date,
  double amount, {
  required String itemId,
  required String clientName,
  String collector = 'Jay',
}) =>
    CollectionEngagementRecord(
      localRef: CollectionEngagementRecord.buildLocalRef(
          kind: 'INVOICE', subjectId: itemId, engagedAt: date),
      collectorCode: 'jay',
      collectorName: collector,
      kind: 'INVOICE',
      itemId: itemId,
      clientId: itemId,
      clientName: clientName,
      engagedAt: date,
      engagedOn: date.split(' ').first,
      status: 'Collected',
      amount: amount,
      createdAt: date,
    );

/// A For Deposit as the archive stores it: an OFFICE row with the amount.
CollectionEngagementRecord _depositEngagement(String date, double amount) =>
    CollectionEngagementRecord(
      localRef: CollectionEngagementRecord.buildLocalRef(
          kind: 'OFFICE', subjectId: 'A', engagedAt: date),
      collectorCode: 'jay',
      collectorName: 'Jay',
      kind: 'OFFICE',
      itemId: '',
      clientId: 'A',
      clientName: 'Alexis Yu Best Care Pharmacy',
      engagedAt: date,
      engagedOn: date.split(' ').first,
      status: 'Deposit',
      amount: amount,
      createdAt: date,
    );

/// An Advanced Payment as the archive stores it on receipt: an ADVANCE row.
CollectionEngagementRecord _advanceEngagement(String date, double amount) =>
    CollectionEngagementRecord(
      localRef: CollectionEngagementRecord.buildLocalRef(
          kind: 'ADVANCE', subjectId: 'AP-1', engagedAt: date),
      collectorCode: 'jay',
      collectorName: 'Jay',
      kind: 'ADVANCE',
      itemId: 'AP-1',
      clientId: 'A',
      clientName: 'Alexis Yu Best Care Pharmacy',
      engagedAt: date,
      engagedOn: date.split(' ').first,
      status: 'Advanced Payment',
      amount: amount,
      createdAt: date,
    );

/// An advance applied to an invoice: the INVOICE row assignAdvance archives,
/// on the date the collector chose.
CollectionEngagementRecord _appliedAdvance(String date, double amount,
        {required String itemId}) =>
    CollectionEngagementRecord(
      localRef: CollectionEngagementRecord.buildLocalRef(
          kind: 'INVOICE', subjectId: itemId, engagedAt: date),
      collectorCode: 'jay',
      collectorName: 'Jay',
      kind: 'INVOICE',
      itemId: itemId,
      clientId: 'A',
      clientName: 'Alexis Yu Best Care Pharmacy',
      engagedAt: date,
      engagedOn: date.split(' ').first,
      status: 'Advanced Payment Applied',
      amount: amount,
      createdAt: date,
    );

/// Three collections on two days, two accounts, one collector.
({_Activity activity, _Totals totals}) _seed({bool twoCollectors = false}) {
  final activity = _Activity();
  Get.put<CollectionActivityController>(activity);
  activity.startAggregateTracking();

  final alexis = _client('A', 'Alexis Yu Best Care Pharmacy');
  final bicol = _client('B', 'Bicol Medical Center');
  activity.activityItems.assignAll([
    CollectionItemModel(
      id: '97339',
      client: alexis,
      toBeCollected: 0,
      history: [_paid(_onDay(17), 32261.31)],
    ),
    CollectionItemModel(
      id: '97340',
      client: alexis,
      toBeCollected: 100,
      history: [_paid(_onDay(17, 14), 5000)],
    ),
    CollectionItemModel(
      id: '96776',
      client: bicol,
      toBeCollected: 0,
      history: [
        _paid(_onDay(12), 9716, collector: twoCollectors ? 'Maria' : 'Jay')
      ],
    ),
  ]);

  activity.ownEngagements.assignAll([
    _engagement(_onDay(17), 32261.31,
        itemId: '97339', clientName: 'Alexis Yu Best Care Pharmacy'),
    _engagement(_onDay(17, 14), 5000,
        itemId: '97340', clientName: 'Alexis Yu Best Care Pharmacy'),
    _engagement(_onDay(12), 9716,
        itemId: '96776',
        clientName: 'Bicol Medical Center',
        collector: twoCollectors ? 'Maria' : 'Jay'),
  ]);

  final totals = _Totals();
  Get.put<TotalCollectedController>(totals);
  return (activity: activity, totals: totals);
}

void main() {
  tearDown(Get.reset);

  group('the total', () {
    test('is the month, not the search result', () {
      final s = _seed();
      expect(s.totals.monthlyTotal, closeTo(46977.31, 0.001));

      s.totals.searchQuery.value = 'bicol';
      // The list narrows. The figure labelled "Total" must not.
      expect(s.totals.monthlyEntries.length, 1);
      expect(s.totals.monthlyTotal, closeTo(46977.31, 0.001));

      s.totals.searchQuery.value = 'nothing like this';
      expect(s.totals.monthlyEntries, isEmpty);
      expect(s.totals.monthlyTotal, closeTo(46977.31, 0.001));
    });

    // Revisions item 9: For Deposit records what the collector did. It is not
    // money the office has counted, and Actual Collection used to be exactly
    // the sum of deposits.
    test('for Actual Collection ignores deposits', () {
      final s = _seed();
      s.activity.globalActivities.addAll(_deposits());

      expect(s.totals.actualCollectionTotal, 0);
      expect(s.totals.postedEntries, isEmpty);
    });

    // A For Deposit is archived as an OFFICE engagement carrying its amount,
    // and the month's total used to add it — counting the same pesos twice,
    // once when collected and again when taken to the bank.
    test('for Collected this Month ignores deposits too', () {
      final s = _seed();
      s.activity.ownEngagements.addAll([
        _depositEngagement(_onDay(15), 20000),
        _depositEngagement(_onDay(16), 12000),
      ]);

      expect(s.totals.monthlyTotal, closeTo(46977.31, 0.001),
          reason: 'a deposit is an activity, not a collection');
      expect(s.totals.monthEntries.map((e) => e.invoiceNumber),
          isNot(contains('Deposit')));
      expect(s.activity.ownEngagements.where((e) => e.status == 'Deposit'),
          hasLength(2),
          reason: 'the deposits are still in the archive for the calendar');
    });

    // An Advanced Payment is float. It counts toward no month until the
    // collector applies it to an invoice, and then in the month of the date
    // they chose. It used to count when received and again when applied.
    test('for Collected this Month leaves an unapplied advance out', () {
      final s = _seed();
      s.activity.ownEngagements.add(_advanceEngagement(_onDay(10), 50000));

      expect(s.totals.monthlyTotal, closeTo(46977.31, 0.001));
      expect(s.totals.monthEntries.map((e) => e.invoiceNumber),
          isNot(contains('AP-1')));
    });

    test('for Collected this Month counts an applied advance in its month', () {
      final s = _seed();
      final lastMonth = DateTime(_now.year, _now.month - 1, 20);
      s.activity.ownEngagements.addAll([
        // Received this month, still float.
        _advanceEngagement(_onDay(10), 50000),
        // Applied to an invoice, dated this month by the collector.
        _appliedAdvance(_onDay(11), 8000, itemId: 'INV-AP-1'),
        // Applied and dated last month: that month's, not this one's.
        _appliedAdvance(_fmt.format(lastMonth), 3000, itemId: 'INV-AP-2'),
      ]);

      expect(s.totals.monthlyTotal, closeTo(46977.31 + 8000, 0.001));

      s.totals.previousMonth();
      expect(s.totals.monthEntries.map((e) => e.invoiceNumber),
          contains('INV-AP-2'));
      expect(s.totals.monthEntries.map((e) => e.invoiceNumber),
          isNot(contains('AP-1')));
    });

    test('an applied advance is stamped on the chosen day, at the time applied',
        () {
      final stamp = CollectionActivityController.collectionStamp(
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 24, 14, 5, 9),
      );
      expect(stamp, startsWith('2026-08-31T14:05:09'));
      expect(BFormatter.localDayKey(stamp), '2026-08-31',
          reason: 'it must file under the chosen day, in the chosen month');
    });

    test('for Actual Collection is what the office posted, not the search', () {
      final s = _seed();
      s.totals.postedActual.addAll([
        _posted(_onDay(15), 20000, 'Alexis Yu Best Care Pharmacy'),
        _posted(_onDay(16), 12000, 'Bicol Medical Center'),
        // Another month: posted, but not this one's.
        _posted(DateTime(2020, 1, 15), 99999, 'Bicol Medical Center'),
      ]);

      expect(s.totals.actualCollectionTotal, 32000);
      expect(s.totals.postedEntries.length, 2);

      s.totals.searchQuery.value = 'bicol';
      expect(s.totals.actualEntries.length, 1);
      expect(s.totals.actualCollectionTotal, 32000,
          reason: 'the total never follows the search, and still must not');
    });
  });

  group('stepping through months', () {
    test('cannot go past the current month', () {
      final s = _seed();
      expect(
          s.totals.selectedMonth.value, TotalCollectedController.thisMonth());
      expect(s.totals.canGoForward, isFalse);

      s.totals.nextMonth();
      expect(s.totals.selectedMonth.value, TotalCollectedController.thisMonth(),
          reason:
              'nothing has been collected in a month that has not happened');
    });

    test('goes back one month at a time, and forward again', () {
      final s = _seed();
      final head = TotalCollectedController.thisMonth();

      s.totals.previousMonth();
      expect(
          s.totals.selectedMonth.value, DateTime(head.year, head.month - 1, 1));
      expect(s.totals.canGoForward, isTrue);

      s.totals.nextMonth();
      expect(s.totals.selectedMonth.value, head);
    });

    test('offers twelve months, newest first, and stops at the oldest', () {
      final s = _seed();
      final months = s.totals.selectableMonths;
      expect(months.length, 12);
      expect(months.first, TotalCollectedController.thisMonth());

      for (var i = 0; i < 11; i++) {
        s.totals.previousMonth();
      }
      expect(s.totals.selectedMonth.value, months.last);
      expect(s.totals.canGoBack, isFalse);
      s.totals.previousMonth();
      expect(s.totals.selectedMonth.value, months.last);
    });
  });

  group('collectors', () {
    test('counts distinct names regardless of case or spacing', () {
      final s = _seed();
      final entries = [
        MonthlyEntry(
            date: _now,
            amount: 1,
            accountName: 'a',
            invoiceNumber: '1',
            collectorName: 'Jay'),
        MonthlyEntry(
            date: _now,
            amount: 1,
            accountName: 'a',
            invoiceNumber: '2',
            collectorName: ' jay '),
        MonthlyEntry(
            date: _now,
            amount: 1,
            accountName: 'a',
            invoiceNumber: '3',
            collectorName: 'Maria'),
      ];
      expect(s.totals.distinctCollectors(entries), 2);
    });
  });

  group('the screen', () {
    Future<void> pump(WidgetTester tester, {String type = 'Collection'}) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(GetMaterialApp(
        theme: BAppTheme.lightTheme,
        home: MonthlySummaryScreen(type: type),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('leads with the month and what it came to', (tester) async {
      _seed();
      await pump(tester);

      expect(find.text(DateFormat('MMMM yyyy').format(_now)), findsOneWidget);
      expect(find.text('₱46,977.31'), findsOneWidget);
      expect(find.text('3 collections · 2 accounts'), findsOneWidget);
    });

    testWidgets('the headline holds still while the search narrows the list',
        (tester) async {
      _seed();
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'bicol');
      await tester.pumpAndSettle();

      expect(find.text('₱46,977.31'), findsOneWidget,
          reason: 'the month total');
      expect(find.text('1 of 3 match "bicol"'), findsOneWidget);
      expect(find.text('Alexis Yu Best Care Pharmacy'), findsNothing);
      expect(find.text('Bicol Medical Center'), findsOneWidget);
    });

    testWidgets(
        'groups entries under their day, with a subtotal where it helps',
        (tester) async {
      _seed();
      await pump(tester);

      final d17 =
          DateFormat('EEE, MMM d').format(DateTime(_now.year, _now.month, 17));
      final d12 =
          DateFormat('EEE, MMM d').format(DateTime(_now.year, _now.month, 12));
      expect(find.text(d17), findsOneWidget);
      expect(find.text(d12), findsOneWidget);
      // Two entries on the 17th earn a subtotal; the lone entry on the 12th
      // would only repeat its own amount.
      expect(find.text('₱37,261.31'), findsOneWidget);
    });

    testWidgets(
        'does not print one collector\'s name on every line of their own ledger',
        (tester) async {
      _seed();
      await pump(tester);

      expect(find.textContaining('Jay'), findsNothing);
    });

    testWidgets('prints collectors once there is more than one',
        (tester) async {
      _seed(twoCollectors: true);
      await pump(tester);

      expect(find.textContaining('Maria'), findsOneWidget);
      expect(find.textContaining('Jay'), findsNWidgets(2));
    });

    testWidgets('the forward arrow is disabled at the current month',
        (tester) async {
      _seed();
      await pump(tester);

      // The tooltip is built inside the IconButton, so walk up to the button.
      IconButton button(String tooltip) =>
          tester.widget<IconButton>(find.ancestor(
              of: find.byTooltip(tooltip), matching: find.byType(IconButton)));
      final next = button('Next month');
      final back = button('Previous month');
      expect(next.onPressed, isNull);
      expect(back.onPressed, isNotNull);
    });

    testWidgets('an empty month says so and offers the arrows', (tester) async {
      final s = _seed();
      await pump(tester);

      s.totals.previousMonth();
      await tester.pumpAndSettle();

      final prev = DateTime(_now.year, _now.month - 1, 1);
      expect(
          find.text('Nothing collected in ${DateFormat('MMMM').format(prev)}'),
          findsOneWidget);
      expect(find.byType(TextField), findsNothing,
          reason: 'nothing to search in an empty month');
    });

    testWidgets('Actual Collection shows progress against the target',
        (tester) async {
      final s = _seed();
      s.totals.postedActual
          .add(_posted(_onDay(16), 32000, 'Bicol Medical Center'));
      s.totals.targetAmount.value = 50000;
      await pump(tester, type: 'Actual');

      expect(find.text('₱32,000.00'), findsWidgets);
      expect(find.text('64% of ₱50,000.00 target'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('Actual Collection with no target offers to set one',
        (tester) async {
      _seed();
      await pump(tester, type: 'Actual');

      expect(find.text('Set a target'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('a month of deposits alone posts nothing, and says why',
        (tester) async {
      final s = _seed();
      s.activity.globalActivities.addAll(_deposits());
      s.totals.targetAmount.value = 50000;
      await pump(tester, type: 'Actual');

      final month = DateFormat('MMMM').format(s.totals.selectedMonth.value);
      expect(
          find.text('No Actual Collection posted for $month'), findsOneWidget);
      expect(find.textContaining('stay in your engagement history'),
          findsOneWidget);
      expect(find.text('0% of ₱50,000.00 target'), findsOneWidget);
      expect(find.text('Deposited'), findsNothing);
    });
  });
}
