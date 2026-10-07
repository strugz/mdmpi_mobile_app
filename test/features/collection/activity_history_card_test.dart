import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';

/// The engagement card as the calendar shows it: account first, time only.
Widget _host(ActivityHistoryCard card) => MaterialApp(
      theme: BCollectionTheme.light,
      home: Scaffold(body: ListView(children: [card])),
    );

const _refusal = CollectionHistoryModel(
  date: '2026-09-22T06:24:00',
  collectorName: 'RDR',
  status: 'Refused to Pay',
  remarks: 'No collection done: Refused to Pay',
);

void main() {
  testWidgets(
      'an account-level entry with no invoice list says "Whole '
      'account" once and never "N/A"', (tester) async {
    await tester.pumpWidget(_host(const ActivityHistoryCard(
      history: _refusal,
      accountName: 'Amrox Medical Systems',
      reconciledOn: '2026-09-22T06:23:00',
      accountFirst: true,
      timeOnly: true,
    )));

    expect(find.text('Amrox Medical Systems'), findsOneWidget);
    expect(find.text('Reconciliation Refused to Pay'), findsOneWidget);
    expect(find.text('Whole account'), findsOneWidget);
    expect(find.textContaining('N/A'), findsNothing);
    expect(find.textContaining('Invoice #'), findsNothing);
  });

  testWidgets('an account-level entry that lists its invoices counts them',
      (tester) async {
    await tester.pumpWidget(_host(const ActivityHistoryCard(
      history: _refusal,
      accountName: 'Amrox Medical Systems',
      invoiceCount: 3,
      accountFirst: true,
      timeOnly: true,
    )));

    expect(find.text('3 invoices'), findsOneWidget);
    expect(find.text('Whole account'), findsOneWidget);
    expect(find.textContaining('N/A'), findsNothing);
  });

  testWidgets('an empty account name is not a blank headline', (tester) async {
    await tester.pumpWidget(_host(const ActivityHistoryCard(
      history: _refusal,
      accountName: '',
      accountFirst: true,
      timeOnly: true,
    )));

    expect(find.text('Account Engagement'), findsOneWidget);
  });
}
