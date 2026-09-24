import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_outcome.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/calendar/widgets/calendar_visit_card.dart';

/// A visit to Antipolo Doctors Hospital: a ₱750,000 advance received, then
/// ₱350,000 of it applied to an invoice. The calendar summed both and read
/// ₱1,100,000.00, and titled the advance "Invoice #AP-1790234393266". The
/// visit collected ₱350,000.00; the advance is float, and is not an invoice.

Map<String, dynamic> _entry({
  required String kind,
  required String status,
  required double amount,
  required String id,
  required String at,
}) =>
    {
      'history': CollectionHistoryModel(
        date: at,
        collectorName: 'Jay',
        status: status,
        totalCollected: amount,
      ),
      'accountName': 'Antipolo Doctors Hospital',
      'invoiceId': id,
      'kind': kind,
      'item': null,
      'reconciledOn': null,
      'invoiceCount': null,
    };

final _applied = _entry(
  kind: 'INVOICE',
  status: 'Advanced Payment Applied',
  amount: 350000,
  id: '4548879',
  at: '2026-09-24T08:08:00',
);
final _advance = _entry(
  kind: 'ADVANCE',
  status: 'Advanced Payment',
  amount: 750000,
  id: 'AP-1790234393266',
  at: '2026-09-24T07:19:00',
);

Widget _host(Widget child) => MaterialApp(
      theme: BCollectionTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('countsAsCollected', () {
    test('collections count', () {
      for (final s in [
        'Collected',
        'Partially Collected',
        'Advanced Payment Applied',
      ]) {
        expect(CollectionOutcome.countsAsCollected(s), isTrue, reason: s);
      }
    });

    test('float and deposits do not', () {
      expect(CollectionOutcome.countsAsCollected('Advanced Payment'), isFalse);
      expect(CollectionOutcome.countsAsCollected('Deposit'), isFalse);
      // Activities of the collector, not collections.
      expect(CollectionOutcome.countsAsCollected('CWT Pick-up'), isFalse);
      expect(CollectionOutcome.countsAsCollected('Reconciliation'), isFalse);
      expect(CollectionOutcome.countsAsCollected('Reconciliation Collected'),
          isTrue,
          reason: 'a collection that finished a reconciliation is money in');
      expect(CollectionOutcome.countsAsCollected('Collected', kind: 'ADVANCE'),
          isFalse,
          reason: 'an ADVANCE row is float whatever its status says');
    });
  });

  testWidgets('the visit total counts the collection, not the float',
      (tester) async {
    await tester.pumpWidget(_host(CalendarVisitCard(
      accountName: 'Antipolo Doctors Hospital',
      entries: [_applied, _advance],
      initiallyExpanded: true,
    )));
    await tester.pumpAndSettle();

    expect(find.text('₱1,100,000.00'), findsNothing);
    // The header total, and the applied row's own amount.
    expect(find.text('₱350,000.00'), findsNWidgets(2));
    // The advance keeps its row and amount, in ink rather than green.
    final advanceAmount = tester.widget<Text>(find.text('₱750,000.00'));
    expect(advanceAmount.style?.color, BCollectionColors.inkSecondary);
  });

  testWidgets('an advance row says what it is, not "Invoice #AP-…"',
      (tester) async {
    await tester.pumpWidget(_host(CalendarVisitCard(
      accountName: 'Antipolo Doctors Hospital',
      entries: [_applied, _advance],
      initiallyExpanded: true,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Advance received'), findsOneWidget);
    expect(find.textContaining('Invoice #AP-'), findsNothing);
    expect(find.text('Invoice #4548879'), findsOneWidget);
  });

  testWidgets('a lone advance card has no invoice or due line to fake',
      (tester) async {
    await tester.pumpWidget(_host(ActivityHistoryCard(
      history: _advance['history'] as CollectionHistoryModel,
      accountName: 'Antipolo Doctors Hospital',
      invoiceId: 'AP-1790234393266',
    )));
    await tester.pumpAndSettle();

    expect(find.text('Advance received'), findsOneWidget);
    expect(find.text('Float, awaiting an invoice'), findsOneWidget);
    expect(find.textContaining('N/A'), findsNothing);
    expect(find.textContaining('Invoice #AP-'), findsNothing);
  });
}
