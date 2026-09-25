import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_engagement_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/engagement_history_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/recent_activities_screen.dart';

/// Engagement History: one day at a time (today unless another is picked),
/// filtered by every status — Advance Payment included — and by search.

class _Activity extends CollectionActivityController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

final _today = DateTime.now();

String _at(int hour, {int daysAgo = 0}) =>
    DateTime(_today.year, _today.month, _today.day - daysAgo, hour)
        .toIso8601String();

CollectionEngagementRecord _row(
  String engagedAt, {
  String kind = 'INVOICE',
  required String itemId,
  required String clientName,
  String status = 'Collected',
  double amount = 1000,
}) =>
    CollectionEngagementRecord(
      localRef: CollectionEngagementRecord.buildLocalRef(
          kind: kind, subjectId: itemId, engagedAt: engagedAt),
      collectorCode: 'jay',
      collectorName: 'Jay Bryan Abaoag',
      kind: kind,
      itemId: itemId,
      clientId: clientName,
      clientName: clientName,
      engagedAt: engagedAt,
      engagedOn: BFormatter.localDayKey(engagedAt)!,
      status: status,
      amount: amount,
      createdAt: engagedAt,
    );

Map<String, dynamic> _entry(String status,
        {String kind = 'INVOICE',
        String account = 'Antipolo Doctors Hospital',
        String? invoiceId = 'SI-1',
        String? reconciledOn,
        double amount = 1000}) =>
    {
      'history': CollectionHistoryModel(
          date: _at(9),
          collectorName: 'Jay',
          status: status,
          remarks: '',
          totalCollected: amount),
      'accountName': account,
      'invoiceId': invoiceId,
      'kind': kind,
      'item': null,
      'reconciledOn': reconciledOn,
    };

final _searchField = find.descendant(
    of: find.byKey(const ValueKey('history-search-bar')),
    matching: find.byType(TextField));

/// Opens a From or To field's picker and types [day] into it: a grid cell
/// may sit in another month early in the month.
Future<void> _typeDate(WidgetTester tester, Key field, DateTime day) async {
  await tester.tap(find.byKey(field));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.edit_outlined));
  await tester.pumpAndSettle();
  await tester.enterText(
      find.byType(TextField).last, '${day.month}/${day.day}/${day.year}');
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

/// The date a From or To field shows (not its label).
String _fieldText(WidgetTester tester, String key) => tester
    .widgetList<Text>(find.descendant(
        of: find.byKey(ValueKey(key)), matching: find.byType(Text)))
    .map((t) => t.data ?? '')
    .firstWhere((d) => d != 'From' && d != 'To');

/// Taps the sheet's apply button, scrolling it into view first: the sheet is
/// taller than the test screen.
Future<void> _applySheet(WidgetTester tester) async {
  final apply = find.byKey(const ValueKey('filter-sheet-apply'));
  await tester.ensureVisible(apply);
  await tester.pumpAndSettle();
  await tester.tap(apply);
  await tester.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Filters'));
  await tester.pumpAndSettle();
}

void main() {
  group('EngagementHistoryFilter', () {
    test('every status lands on its own filter', () {
      Set<EngagementStatus> t(String s,
              {String kind = 'INVOICE', String? rec}) =>
          EngagementHistoryFilter.statusesOf(
              _entry(s, kind: kind, reconciledOn: rec));

      expect(t('Collected'), {EngagementStatus.collected});
      expect(t('Partially Collected'), {EngagementStatus.partial});
      expect(
          t('Advanced Payment', kind: 'ADVANCE'), {EngagementStatus.advance});
      expect(t('Advanced Payment Applied'), {EngagementStatus.advanceApplied});
      expect(t('Deposit', kind: 'OFFICE'), {EngagementStatus.deposit});
      expect(t('CWT Pick-up', kind: 'OFFICE'), {EngagementStatus.cwt});
      expect(t('Reconciliation'), {EngagementStatus.reconciliation});
      expect(t('Follow Up'), {EngagementStatus.followUp});
      expect(t('Pre-Collection'), {EngagementStatus.preCollection});
      expect(t('Customer Unavailable'), {EngagementStatus.unavailable});
      expect(t('Refused to Pay'), {EngagementStatus.refused});
      expect(t('Others'), {EngagementStatus.others});
      expect(t('Something new'), {EngagementStatus.others},
          reason: 'an unknown status is never lost');
      expect(t('Collected', rec: _at(8)),
          {EngagementStatus.collected, EngagementStatus.reconciliation},
          reason: 'a finished reconciliation is listed under both');
    });

    test('the chips name the statuses collectors use', () {
      expect(EngagementStatus.values.map((s) => s.label), [
        'Collected',
        'Partial Payment',
        'Advance Payment',
        'Advance Applied',
        'Deposit',
        'CWT Pick-up',
        'Reconciliation',
        'Follow Up',
        'Pre-Collection',
        'Customer Unavailable',
        'Refused to Pay',
        'Others',
      ]);
    });

    test('searches account, invoice and P.O., ignoring case', () {
      final e =
          _entry('Collected', account: 'Antipolo Doctors', invoiceId: 'SI-77');
      expect(EngagementHistoryFilter.matchesQuery(e, 'antipolo'), isTrue);
      expect(EngagementHistoryFilter.matchesQuery(e, 'si-7'), isTrue);
      expect(EngagementHistoryFilter.matchesQuery(e, 'bicol'), isFalse);
      expect(EngagementHistoryFilter.matchesQuery(e, '  '), isTrue);
    });

    test('counts every status, zero included, and totals only collections', () {
      final entries = [
        _entry('Collected', amount: 6305.23),
        _entry('Advanced Payment', kind: 'ADVANCE', amount: 750000),
        _entry('Advanced Payment Applied', amount: 350000),
        _entry('Deposit', kind: 'OFFICE', amount: 2500000),
      ];
      final counts = EngagementHistoryFilter.counts(entries);
      expect(counts.length, EngagementStatus.values.length);
      expect(counts[EngagementStatus.collected], 1);
      expect(counts[EngagementStatus.advance], 1);
      expect(counts[EngagementStatus.advanceApplied], 1);
      expect(counts[EngagementStatus.deposit], 1);
      expect(counts[EngagementStatus.cwt], 0);
      expect(EngagementHistoryFilter.collected(entries), 356305.23,
          reason: 'an advance received and a deposit add nothing');
    });
  });

  group('the Engagement History screen', () {
    tearDown(Get.reset);

    Future<_Activity> pump(
        WidgetTester tester, List<CollectionEngagementRecord> rows) async {
      final controller = _Activity();
      Get.put<CollectionActivityController>(controller);
      controller.ownEngagements.assignAll(rows);
      await tester.pumpWidget(MaterialApp(
        theme: BAppTheme.lightTheme,
        home: const RecentActivitiesScreen(),
      ));
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('opens on today, and only today, with no date bar',
        (tester) async {
      await pump(tester, [
        _row(_at(9), itemId: 'SI-TODAY', clientName: 'Antipolo'),
        _row(_at(9, daysAgo: 1), itemId: 'SI-YESTERDAY', clientName: 'Bicol'),
      ]);

      expect(find.byTooltip('Previous day'), findsNothing,
          reason: 'the day is set in the filter sheet');
      expect(find.text('Today · 1 engagement · ₱1,000.00 collected'),
          findsOneWidget);
      expect(find.text('Invoice #SI-TODAY'), findsOneWidget);
      expect(find.text('Invoice #SI-YESTERDAY'), findsNothing);
      expect(find.byKey(const ValueKey('filter-active-day')), findsNothing,
          reason: 'today is the default, not a filter');
    });

    testWidgets('Yesterday from the sheet, and its chip brings today back',
        (tester) async {
      await pump(tester, [
        _row(_at(9), itemId: 'SI-TODAY', clientName: 'Antipolo'),
        _row(_at(9, daysAgo: 1), itemId: 'SI-YESTERDAY', clientName: 'Bicol'),
      ]);

      await _openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('filter-range-yesterday')));
      await tester.pumpAndSettle();
      expect(find.text('Show 1 engagement'), findsOneWidget);
      await _applySheet(tester);

      expect(find.text('Invoice #SI-YESTERDAY'), findsOneWidget);
      expect(find.text('Invoice #SI-TODAY'), findsNothing);
      expect(find.byKey(const ValueKey('filter-active-day')), findsOneWidget);
      expect(find.textContaining('Yesterday · 1 engagement'), findsOneWidget);

      await tester.tap(find.descendant(
          of: find.byKey(const ValueKey('filter-active-day')),
          matching: find.byIcon(Iconsax.close_circle)));
      await tester.pumpAndSettle();
      expect(find.text('Invoice #SI-TODAY'), findsOneWidget);
      expect(find.byKey(const ValueKey('filter-active-day')), findsNothing);
    });

    testWidgets('From and To pick a range, with a heading for each day',
        (tester) async {
      final from = DateTime(_today.year, _today.month, _today.day - 3);
      final to = DateTime(_today.year, _today.month, _today.day - 2);
      await pump(tester, [
        _row(_at(9), itemId: 'SI-TODAY', clientName: 'Antipolo'),
        _row(_at(9, daysAgo: 2), itemId: 'SI-2DAYS', clientName: 'Bicol'),
        _row(_at(9, daysAgo: 3), itemId: 'SI-3DAYS', clientName: 'Cebu'),
        _row(_at(9, daysAgo: 4), itemId: 'SI-4DAYS', clientName: 'Davao'),
      ]);

      await _openSheet(tester);
      await _typeDate(tester, const ValueKey('filter-from'), from);
      await _typeDate(tester, const ValueKey('filter-to'), to);
      expect(_fieldText(tester, 'filter-from'),
          DateFormat('MMM d, yyyy').format(from));
      expect(_fieldText(tester, 'filter-to'),
          DateFormat('MMM d, yyyy').format(to));
      expect(find.text('Show 2 engagements'), findsOneWidget,
          reason: 'the counts follow the range in the draft');
      await _applySheet(tester);

      expect(find.text('Invoice #SI-2DAYS'), findsOneWidget);
      expect(find.text('Invoice #SI-3DAYS'), findsOneWidget);
      expect(find.text('Invoice #SI-TODAY'), findsNothing);
      expect(find.text('Invoice #SI-4DAYS'), findsNothing);
      expect(find.byKey(ValueKey('history-heading-$to')), findsOneWidget);
      expect(find.byKey(ValueKey('history-heading-$from')), findsOneWidget);
      expect(find.text(DateFormat('EEEE, MMM d').format(to)), findsOneWidget);
      expect(find.byKey(const ValueKey('filter-active-day')), findsOneWidget);
    });

    testWidgets('a From after To moves To with it, never an empty range',
        (tester) async {
      final weekAgo = DateTime(_today.year, _today.month, _today.day - 7);
      final twoDaysAgo = DateTime(_today.year, _today.month, _today.day - 2);
      await pump(tester, [
        _row(_at(9, daysAgo: 2), itemId: 'SI-2DAYS', clientName: 'Bicol'),
      ]);

      await _openSheet(tester);
      await _typeDate(tester, const ValueKey('filter-to'), weekAgo);
      expect(_fieldText(tester, 'filter-from'),
          DateFormat('MMM d, yyyy').format(weekAgo),
          reason: 'To before From pulls From back');

      await _typeDate(tester, const ValueKey('filter-from'), twoDaysAgo);
      expect(_fieldText(tester, 'filter-to'),
          DateFormat('MMM d, yyyy').format(twoDaysAgo),
          reason: 'From after To pushes To forward');
    });

    testWidgets('Last 7 days and This month fill both dates', (tester) async {
      await pump(tester, [
        _row(_at(9), itemId: 'SI-TODAY', clientName: 'Antipolo'),
        _row(_at(9, daysAgo: 6), itemId: 'SI-6DAYS', clientName: 'Bicol'),
        _row(_at(9, daysAgo: 7), itemId: 'SI-7DAYS', clientName: 'Cebu'),
      ]);

      await _openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('filter-range-last7')));
      await tester.pumpAndSettle();
      expect(
          _fieldText(tester, 'filter-from'),
          DateFormat('MMM d, yyyy')
              .format(DateTime(_today.year, _today.month, _today.day - 6)));
      expect(_fieldText(tester, 'filter-to'),
          DateFormat('MMM d, yyyy').format(_today));
      expect(find.text('Show 2 engagements'), findsOneWidget,
          reason: 'six days ago is in, seven is not');

      await tester.tap(find.byKey(const ValueKey('filter-range-month')));
      await tester.pumpAndSettle();
      expect(
          _fieldText(tester, 'filter-from'),
          DateFormat('MMM d, yyyy')
              .format(DateTime(_today.year, _today.month)));
    });

    testWidgets('a day with nothing says so and keeps the filter in reach',
        (tester) async {
      await pump(tester, [
        _row(_at(9, daysAgo: 2), itemId: 'SI-OLD', clientName: 'Bicol'),
      ]);

      expect(find.text('No engagements yet today'), findsOneWidget);
      expect(find.byTooltip('Filters'), findsOneWidget);
      expect(_searchField, findsOneWidget);
    });

    testWidgets('statuses live in a sheet, not a row on the page',
        (tester) async {
      await pump(tester, [
        _row(_at(9), itemId: 'SI-1', clientName: 'Antipolo'),
      ]);

      expect(find.byKey(const ValueKey('status-chip-cwt')), findsNothing,
          reason: 'no long chip row on the page');

      await _openSheet(tester);

      expect(find.text('Filter engagements'), findsOneWidget);
      for (final g in EngagementStatusGroup.values) {
        expect(find.text(g.label), findsOneWidget);
      }
      for (final s in EngagementStatus.values) {
        expect(find.byKey(ValueKey('status-chip-${s.name}')), findsOneWidget,
            reason: s.label);
      }
      expect(find.text('Collected · 1'), findsOneWidget);
      expect(find.text('CWT Pick-up · 0'), findsOneWidget);
    });

    testWidgets('the apply button counts, and blocks a pick that shows nothing',
        (tester) async {
      await pump(tester, [
        _row(_at(9), itemId: 'SI-1', clientName: 'Antipolo'),
        _row(_at(10),
            itemId: 'SI-2',
            clientName: 'Antipolo',
            status: 'Partially Collected'),
      ]);
      await _openSheet(tester);
      expect(find.text('Show 2 engagements'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('status-chip-cwt')));
      await tester.pumpAndSettle();
      expect(find.text('No engagements match'), findsOneWidget);
      expect(
          tester
              .widget<ElevatedButton>(
                  find.byKey(const ValueKey('filter-sheet-apply')))
              .onPressed,
          isNull);

      await tester.tap(find.byKey(const ValueKey('status-chip-partial')));
      await tester.pumpAndSettle();
      expect(find.text('Show 1 engagement'), findsOneWidget);
    });

    testWidgets('picks several statuses, shows them as chips, removes one',
        (tester) async {
      await pump(tester, [
        _row(_at(8), itemId: 'SI-1', clientName: 'Alexis Yu'),
        _row(_at(9),
            kind: 'ADVANCE',
            itemId: 'AP-1',
            clientName: 'Antipolo',
            status: 'Advanced Payment',
            amount: 750000),
        _row(_at(10),
            itemId: 'SI-2',
            clientName: 'Antipolo',
            status: 'Advanced Payment Applied',
            amount: 750000),
      ]);
      expect(find.text('Today · 3 engagements · ₱751,000.00 collected'),
          findsOneWidget);

      await _openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('status-chip-advance')));
      await tester
          .tap(find.byKey(const ValueKey('status-chip-advanceApplied')));
      await tester.pumpAndSettle();
      await _applySheet(tester);

      expect(find.text('Advance received'), findsOneWidget);
      expect(find.text('Invoice #SI-2'), findsOneWidget);
      expect(find.text('Invoice #SI-1'), findsNothing);
      expect(
          find.byKey(const ValueKey('status-active-advance')), findsOneWidget);
      expect(find.byKey(const ValueKey('status-active-advanceApplied')),
          findsOneWidget);

      // Remove Advance Payment from its chip: only the applied one is left.
      await tester.tap(find.descendant(
          of: find.byKey(const ValueKey('status-active-advance')),
          matching: find.byIcon(Iconsax.close_circle)));
      await tester.pumpAndSettle();
      expect(find.text('Advance received'), findsNothing);
      expect(find.text('Invoice #SI-2'), findsOneWidget);
    });

    testWidgets('a status filter holds when the day changes', (tester) async {
      await pump(tester, [
        _row(_at(9), itemId: 'SI-T1', clientName: 'Antipolo'),
        _row(_at(10),
            itemId: 'SI-T2',
            clientName: 'Antipolo',
            status: 'Partially Collected'),
        _row(_at(9, daysAgo: 1),
            itemId: 'SI-Y1',
            clientName: 'Bicol',
            status: 'Partially Collected'),
        _row(_at(10, daysAgo: 1), itemId: 'SI-Y2', clientName: 'Bicol'),
      ]);

      await _openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('status-chip-partial')));
      await tester.pumpAndSettle();
      await _applySheet(tester);
      expect(find.text('Invoice #SI-T2'), findsOneWidget);
      expect(find.text('Invoice #SI-T1'), findsNothing);

      // Change the day in the sheet: Partial Payment stays picked.
      await _openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('filter-range-yesterday')));
      await tester.pumpAndSettle();
      await _applySheet(tester);
      expect(find.text('Invoice #SI-Y1'), findsOneWidget);
      expect(find.text('Invoice #SI-Y2'), findsNothing);
    });

    testWidgets('search narrows, and Clear filters brings everything back',
        (tester) async {
      await pump(tester, [
        _row(_at(8), itemId: 'SI-1', clientName: 'Alexis Yu'),
        _row(_at(9), itemId: 'SI-2', clientName: 'Antipolo'),
      ]);

      await tester.enterText(_searchField, 'alexis');
      await tester.pumpAndSettle();
      expect(find.text('Invoice #SI-1'), findsOneWidget);
      expect(find.text('Invoice #SI-2'), findsNothing);

      await tester.enterText(_searchField, 'nobody');
      await tester.pumpAndSettle();
      expect(find.text('Nothing matches'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('Invoice #SI-1'), findsOneWidget);
      expect(find.text('Invoice #SI-2'), findsOneWidget);
      expect(tester.widget<TextField>(_searchField).controller!.text, isEmpty,
          reason: 'the field empties with the filter');
    });

    testWidgets('fits a narrow phone at a large font', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 780);
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pump(tester, [
        _row(_at(8),
            itemId: 'SI-1',
            clientName: 'Accusure Medical Enterprises Incorporated Hospital'),
        _row(_at(9),
            kind: 'ADVANCE',
            itemId: 'AP-1',
            clientName: 'Antipolo',
            status: 'Advanced Payment'),
      ]);
      expect(tester.takeException(), isNull);

      // The sheet too: twelve chips and three headings at 1.3×.
      await _openSheet(tester);
      expect(tester.takeException(), isNull);
      await tester
          .ensureVisible(find.byKey(const ValueKey('filter-sheet-apply')));
      expect(find.byKey(const ValueKey('filter-sheet-apply')).hitTestable(),
          findsOneWidget);
    });
  });
}
