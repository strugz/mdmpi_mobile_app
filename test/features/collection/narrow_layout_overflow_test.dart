import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/po_grouping.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_info_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/engagement_summary.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/invoice_details_modal.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/calendar/widgets/calendar_visit_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/collection_summary_grid.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/collection_totals_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/account_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/invoice_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/po_invoice_group_card.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// Every Collection card and row, on a narrow phone, with the data that
/// makes a line longest: a seven-figure amount, a long account name, the
/// longest outcome, every badge on. At the default and an enlarged system
/// font. Any RenderFlex overflow fails, and names the widget.
///
/// The P.O. header once overflowed by 25px on a 360pt phone because a Row
/// held fixed badges beside a total; this sweeps the rest for the same.
///
/// The test font draws every glyph a full em wide — about twice a real one —
/// so 1.0 here is already a stringent stand-in for a large system font.

const _width = 320.0; // a 360pt phone less the list's gutters
const _scales = [1.0, 1.3];

const _longName = 'Accusure Medical Enterprises Incorporated';
const _bigAmount = 1234567.89;
const _longOutcome = 'Reconciliation Refused to Pay';

final _client = ClientModel(
  id: 'A',
  code: 'NLN-1',
  name: _longName,
  address: 'Tagbilaran City, Bohol, Central Visayas',
  contact: '',
  emailAddress: '',
);

final _history = CollectionHistoryModel(
  date: '2026-09-22T06:24:00',
  collectorName: 'Rodrigo Dela Rosa',
  status: 'Refused to Pay',
  remarks: 'Customer asked to come back after the fifteenth',
  totalCollected: _bigAmount,
);

CollectionItemModel _item({String po = 'ADC-4500012345-2026'}) =>
    CollectionItemModel(
      id: '700013390',
      client: _client,
      toBeCollected: _bigAmount,
      totalCollected: 45678.9,
      poNumber: po,
      postingDate: '2017-09-01',
      dueDate: '2017-10-27', // thousands of days overdue: the longest badge
      status: _longOutcome,
      lastOutcome: _longOutcome,
      documentReferences: const ['DR-000123', 'SI-000456'],
      history: [_history],
    );

/// Pumps [child] at [scale] and returns every overflow reported while it
/// laid out, instead of stopping at the first.
Future<List<String>> _overflows(
  WidgetTester tester,
  Widget child, {
  required double scale,
  Future<void> Function(WidgetTester)? interact,
}) async {
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exceptionAsString();
    if (text.contains('overflowed')) {
      // Name the Row/Column that overflowed by its source line, so a failure
      // points at the widget to fix rather than at this test.
      final full = TextTreeRenderer(wrapWidth: 400)
          .render(details.toDiagnosticsNode(style: DiagnosticsTreeStyle.error));
      final where =
          RegExp(r'lib/features/[\w/]+\.dart:\d+').firstMatch(full)?.group(0);
      final line = '${text.split('\n').first} at ${where ?? 'unknown'}';
      debugPrint('OVERFLOW | $line');
      errors.add(line);
    } else {
      previous?.call(details);
    }
  };
  try {
    await tester.pumpWidget(MaterialApp(
      theme: BCollectionTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(360, 800),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Center(child: SizedBox(width: _width, child: child)),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    if (interact != null) await interact(tester);
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

void main() {
  final cases = <String, Widget Function()>{
    'AccountCard (selecting, P.O.s, overdue)': () => AccountCard(
          client: _client,
          invoiceCount: 128,
          poCount: 37,
          totalAmount: _bigAmount,
          totalCollected: 45678.9,
          overdueCount: 128,
          onTap: () {},
          onInfoTap: () {},
          onSelectTap: () {},
          onPoInvoicesTap: () {},
          isSelectionMode: true,
          isSelected: true,
        ),
    'AccountCard (claim button, settled)': () => AccountCard(
          client: _client,
          invoiceCount: 128,
          poCount: 37,
          totalAmount: 0,
          totalCollected: _bigAmount,
          onTap: () {},
          onInfoTap: () {},
          onClaimTap: () {},
        ),
    'InvoiceCard (selecting, account name, outcome)': () => InvoiceCard(
          item: _item(),
          onTap: () {},
          onInfoTap: () {},
          isSelectionMode: true,
          isSelected: true,
          showAccountName: true,
        ),
    'InvoiceCard (info button)': () =>
        InvoiceCard(item: _item(), onTap: () {}, onInfoTap: () {}),
    'PoInvoiceGroupCard (open, selected)': () => PoInvoiceGroupCard(
          group: PoGrouping.of([_item(), _item()]).groups.single,
          expanded: true,
          onToggle: () {},
          selectedCount: 2,
        ),
    'ActivityHistoryCard (invoice)': () => ActivityHistoryCard(
          history: _history,
          accountName: _longName,
          invoiceId: '700013390',
          item: _item(),
          reconciledOn: '2026-09-21T10:00:00',
        ),
    'ActivityHistoryCard (account first, whole account)': () =>
        ActivityHistoryCard(
          history: _history,
          accountName: _longName,
          invoiceCount: 128,
          accountFirst: true,
          timeOnly: true,
        ),
    'CalendarVisitCard (expanded)': () => CalendarVisitCard(
          accountName: _longName,
          initiallyExpanded: true,
          entries: [
            {
              'history': _history,
              'invoiceId': '700013390',
              'item': _item(),
              'reconciledOn': '2026-09-21T10:00:00',
            },
            {'history': _history, 'invoiceCount': 128},
          ],
        ),
    'EngagementSummary': () => const EngagementSummary(
          accounts: 128,
          invoices: 1095,
          overdue: 1095,
          due: _bigAmount,
          collected: 45678.9,
        ),
    'ActivityInfoCard': () => ActivityInfoCard(item: _item()),
    'CollectionTotalsCardView': () => const CollectionTotalsCardView(
          actual: '₱1,234,567.89',
          actualFootnote: '42% of ₱9,876,543.21',
          collected: '₱1,234,567.89',
        ),
    'CollectionSummaryGrid': () => CollectionSummaryGrid(stats: [
          for (final t in ['Settled', 'Past Due', 'Reconciliation', 'Deposit'])
            CollectionSummaryStat(
              title: t,
              value: '1,095',
              icon: Iconsax.timer,
              color: BCollectionColors.danger,
              onTap: () {},
            ),
        ]),
  };

  for (final scale in _scales) {
    group('at text scale $scale on a ${_width.toInt()}pt column', () {
      cases.forEach((name, build) {
        testWidgets(name, (tester) async {
          final errors = await _overflows(tester, build(), scale: scale);
          expect(errors, isEmpty, reason: '$name overflowed');
        });
      });

      testWidgets('InvoiceDetailsModal', (tester) async {
        final errors = await _overflows(
          tester,
          SizedBox(height: 700, child: InvoiceDetailsModal(item: _item())),
          scale: scale,
        );
        expect(errors, isEmpty, reason: 'InvoiceDetailsModal overflowed');
      });

      testWidgets('Engagement Details sheet (tapping a history card)',
          (tester) async {
        final errors = await _overflows(
          tester,
          ActivityHistoryCard(
            history: _history,
            accountName: _longName,
            invoiceId: '700013390',
            item: _item(),
            reconciledOn: '2026-09-21T10:00:00',
          ),
          scale: scale,
          interact: (tester) async {
            await tester.tap(find.byType(ActivityHistoryCard));
            await tester.pumpAndSettle();
          },
        );
        expect(errors, isEmpty, reason: 'Engagement Details sheet overflowed');
      });
    });
  }
}
