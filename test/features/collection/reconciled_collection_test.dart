import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation_fold.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// A reconciliation and the outcome that finished it are one event, told
/// once: the outcome's card reads "Reconciliation Collected" (or whatever
/// the outcome was) and its detail sheet names the reconciliation date. A
/// reconciliation nothing has finished yet stands on its own.

CollectionHistoryModel _entry(String date, String status,
        {double amount = 0}) =>
    CollectionHistoryModel(
      date: date,
      collectorName: 'Juan Dela Cruz',
      status: status,
      remarks: '',
      totalCollected: amount,
    );

CollectionItemModel _invoice(List<CollectionHistoryModel> history,
        {String id = 'RC1'}) =>
    CollectionItemModel(
      id: id,
      client: ClientModel(
        id: 'C1',
        code: 'NCR-400',
        name: 'Best Care Pharmacy',
        address: '',
        contact: '',
        emailAddress: '',
      ),
      toBeCollected: 0,
      totalCollected: 1200,
      status: 'Collected',
      history: history,
    );

Widget _host(Widget child) => MaterialApp(
      theme: BCollectionTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  const collected = '2026-09-22T09:30:00';
  const reconciled = '2026-09-20T10:15:00';

  group('the card', () {
    testWidgets('labels a collection that finished a reconciliation with both',
        (tester) async {
      await tester.pumpWidget(_host(ActivityHistoryCard(
        history: _entry(collected, 'Collected', amount: 1200),
        accountName: 'Best Care Pharmacy',
        invoiceId: 'RC1',
        reconciledOn: reconciled,
      )));

      expect(find.text('Reconciliation Collected'), findsOneWidget);
      expect(find.text('Collected'), findsNothing);
    });

    testWidgets('says Refused to Pay when that is how it ended',
        (tester) async {
      await tester.pumpWidget(_host(ActivityHistoryCard(
        history: _entry(collected, 'Refused to Pay'),
        reconciledOn: reconciled,
      )));

      expect(find.text('Reconciliation Refused to Pay'), findsOneWidget);
    });

    testWidgets('every outcome that can finish a reconciliation is labelled '
        'the same way', (tester) async {
      // Anything a collector can record on an invoice after reconciling it:
      // the outcomes of the update screen and the defer reasons alike.
      final outcomes = CollectionStatusColors.allStatuses
          .where((s) =>
              s != CollectionStatusColors.statusReconciliation &&
              s != CollectionStatusColors.statusDeposit &&
              s != CollectionStatusColors.statusCWTPickup)
          .toList();
      expect(outcomes, isNotEmpty);

      for (final outcome in outcomes) {
        await tester.pumpWidget(_host(ActivityHistoryCard(
          history: _entry(collected, outcome),
          reconciledOn: reconciled,
        )));
        expect(find.text('Reconciliation $outcome'), findsOneWidget,
            reason: outcome);
        expect(find.text(outcome), findsNothing, reason: outcome);
      }
    });

    testWidgets('finds the reconciliation in the invoice history itself',
        (tester) async {
      await tester.pumpWidget(_host(ActivityHistoryCard(
        history: _entry(collected, 'Collected', amount: 1200),
        item: _invoice([
          _entry(collected, 'Collected', amount: 1200),
          _entry(reconciled, 'Reconciliation'),
        ]),
      )));

      expect(find.text('Reconciliation Collected'), findsOneWidget);
    });

    testWidgets('a plain collection is labelled plainly', (tester) async {
      await tester.pumpWidget(_host(ActivityHistoryCard(
        history: _entry(collected, 'Collected', amount: 1200),
        item: _invoice([
          _entry(collected, 'Collected', amount: 1200),
          _entry('2026-09-10T08:00:00', 'Follow Up'),
        ]),
      )));

      expect(find.text('Collected'), findsOneWidget);
      expect(find.textContaining('Reconciliation'), findsNothing);
    });

    testWidgets('a reconciliation recorded after the outcome does not mark it',
        (tester) async {
      await tester.pumpWidget(_host(ActivityHistoryCard(
        history:
            _entry('2026-09-10T08:00:00', 'Partially Collected', amount: 300),
        item: _invoice([
          _entry(reconciled, 'Reconciliation'),
          _entry('2026-09-10T08:00:00', 'Partially Collected', amount: 300),
        ]),
      )));

      expect(find.text('Partially Collected'), findsOneWidget);
      expect(find.textContaining('Reconciliation '), findsNothing);
    });

    testWidgets('an open reconciliation is labelled as itself',
        (tester) async {
      await tester.pumpWidget(_host(ActivityHistoryCard(
        history: _entry(reconciled, 'Reconciliation'),
        reconciledOn: reconciled,
      )));

      expect(find.text('Reconciliation'), findsOneWidget);
    });

    testWidgets('an account-level outcome names the account and counts its '
        'invoices instead of printing N/A', (tester) async {
      await tester.pumpWidget(_host(ActivityHistoryCard(
        history: _entry(collected, 'Refused to Pay'),
        accountName: 'Best Care Pharmacy',
        reconciledOn: reconciled,
        invoiceCount: 2,
        accountFirst: true,
      )));

      expect(find.text('Best Care Pharmacy'), findsOneWidget);
      expect(find.text('Reconciliation Refused to Pay'), findsOneWidget);
      expect(find.text('2 invoices'), findsOneWidget);
      expect(find.textContaining('N/A'), findsNothing);
    });

    testWidgets('the detail sheet names the reconciliation date',
        (tester) async {
      await tester.pumpWidget(_host(ActivityHistoryCard(
        history: _entry(collected, 'Collected', amount: 1200),
        accountName: 'Best Care Pharmacy',
        invoiceId: 'RC1',
        reconciledOn: reconciled,
      )));

      await tester.tap(find.byType(Card));
      await tester.pumpAndSettle();

      expect(find.text('Reconciled on'), findsOneWidget);
      expect(find.textContaining('Sep 20'), findsWidgets);
      // The sheet's own status badge reads the combined label too.
      expect(find.text('Reconciliation Collected'), findsNWidgets(2));
    });
  });

  group('the list', () {
    // The list renders what the controller hands it; folding happens in the
    // controller's history getters. These cover the hand-off: a folded
    // history with its dates reads as one event per outcome.
    testWidgets('shows a finished reconciliation once, on its outcome',
        (tester) async {
      final invoice = _invoice([
        _entry(collected, 'Collected', amount: 1200),
        _entry(reconciled, 'Reconciliation'),
      ]);
      final folded = foldFinishedReconciliations(invoice.history);
      await tester.pumpWidget(_host(ActivityHistoryList(
        history: [for (final f in folded) f.history],
        items: {for (var i = 0; i < folded.length; i++) i: invoice},
        reconciledOn: {
          for (var i = 0; i < folded.length; i++) i: folded[i].reconciledOn
        },
      )));

      expect(find.byType(ActivityHistoryCard), findsOneWidget);
      expect(find.text('Reconciliation Collected'), findsOneWidget);
    });

    testWidgets('keeps an open reconciliation as its own entry',
        (tester) async {
      final invoice = _invoice([
        _entry(reconciled, 'Reconciliation'),
        _entry('2026-09-10T08:00:00', 'Follow Up'),
      ]);
      final folded = foldFinishedReconciliations(invoice.history);
      await tester.pumpWidget(_host(ActivityHistoryList(
        history: [for (final f in folded) f.history],
        items: {for (var i = 0; i < folded.length; i++) i: invoice},
        reconciledOn: {
          for (var i = 0; i < folded.length; i++) i: folded[i].reconciledOn
        },
      )));

      expect(find.byType(ActivityHistoryCard), findsNWidgets(2));
      expect(find.text('Reconciliation'), findsOneWidget);
      expect(find.text('Follow Up'), findsOneWidget);
    });

    testWidgets('renders every entry it is given, never folding on its own',
        (tester) async {
      final invoice = _invoice([
        _entry(collected, 'Collected', amount: 1200),
        _entry(reconciled, 'Reconciliation'),
      ]);
      await tester.pumpWidget(_host(ActivityHistoryList(
        history: invoice.history,
        items: {0: invoice, 1: invoice},
      )));

      expect(find.byType(ActivityHistoryCard), findsNWidgets(2));
    });
  });

  group('folding an invoice history', () {
    test('drops a finished reconciliation and dates its outcome', () {
      final folded = foldFinishedReconciliations([
        _entry(collected, 'Collected', amount: 1200),
        _entry(reconciled, 'Reconciliation'),
        _entry('2026-09-10T08:00:00', 'Follow Up'),
      ]);

      expect(folded.map((e) => e.history.status), ['Collected', 'Follow Up']);
      expect(folded.first.reconciledOn, reconciled);
      expect(folded.last.reconciledOn, isNull);
    });

    test('two reconciliations each fold into their own outcome', () {
      final folded = foldFinishedReconciliations([
        _entry('2026-09-01T09:00:00', 'Reconciliation'),
        _entry('2026-09-03T09:00:00', 'Partially Collected', amount: 100),
        _entry('2026-09-05T09:00:00', 'Reconciliation'),
        _entry('2026-09-07T09:00:00', 'Collected', amount: 900),
      ]);

      expect(folded.map((e) => e.history.status),
          ['Partially Collected', 'Collected']);
      expect(folded[0].reconciledOn, '2026-09-01T09:00:00');
      expect(folded[1].reconciledOn, '2026-09-05T09:00:00');
    });
  });
}
