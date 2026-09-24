import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/mirror_carousel.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The home dashboard shows the seven most recent engagement entries as
/// pages of a [BMirrorCarousel] with no fixed height: it takes its tallest
/// card's. These pump that arrangement inside the dashboard's IntrinsicHeight
/// and an unbounded scroll view, at the text scale the dashboard clamps to.
///
/// The page was once a fixed 172, and a card with an overdue invoice (date,
/// due row, badge, collector) outgrew it by 2px when its labels grew a point.
/// These cards carry that invoice, so a card that outgrows its page fails.

CollectionItemModel _item(int i) => CollectionItemModel(
      id: '70001339$i',
      client: ClientModel(
        id: 'A$i',
        code: 'NLN-$i',
        name: 'Accuteqs Diagnostics Corp. $i',
        address: '',
        contact: '',
        emailAddress: '',
      ),
      toBeCollected: 0,
      totalCollected: 10780,
      postingDate: '2023-02-23',
      dueDate: '2023-03-25', // long overdue: the due row carries its badge
    );

List<ActivityHistoryCard> _cards(int count) => [
      for (var i = 0; i < count; i++)
        ActivityHistoryCard(
          history: CollectionHistoryModel(
            date: '2026-09-1${i}T10:19:22.215179',
            collectorName: 'RDR',
            status: 'Collected',
            remarks: 'Paid in full, receipt issued to the pharmacist on duty',
            totalCollected: 10780,
          ),
          accountName: 'Accuteqs Diagnostics Corp. $i',
          invoiceId: '70001339$i',
          item: _item(i),
          margin: EdgeInsets.zero,
        ),
    ];

/// The measuring copies stay in the tree, invisible; look only at the pages.
Finder _inPage(Finder f) =>
    find.descendant(of: find.byType(PageView), matching: f);

Widget _homeHistory(List<ActivityHistoryCard> cards, {double textScale = 1}) {
  return MaterialApp(
    theme: BCollectionTheme.light,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: const Size(360, 800),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            // As on the dashboard, which fits itself to the screen this way.
            child: IntrinsicHeight(
              child: Column(children: [
                BMirrorCarousel(
                  itemCount: cards.length,
                  itemBuilder: (context, i) =>
                      Align(alignment: Alignment.topCenter, child: cards[i]),
                ),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('seven history cards lay out as pages without overflow',
      (tester) async {
    await tester.pumpWidget(_homeHistory(_cards(7)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_inPage(find.text('Invoice #700013390')), findsOneWidget);
    // Seven dots, one per entry.
    expect(find.byType(AnimatedContainer), findsNWidgets(7));
  });

  for (final scale in [1.0, 1.15]) {
    testWidgets('the page is as tall as its card at text scale $scale',
        (tester) async {
      await tester.pumpWidget(_homeHistory(_cards(7), textScale: scale));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final page = tester.getSize(find.byType(PageView)).height;
      final card =
          tester.getSize(_inPage(find.byType(ActivityHistoryCard)).first);
      expect(card.height, lessThanOrEqualTo(page),
          reason: 'the card is clipped by its page');
      // Sized to the content, not padded to a guess.
      expect(page - card.height, lessThan(1));
    });
  }

  testWidgets('swiping moves to the next entry and loops from the last',
      (tester) async {
    await tester.pumpWidget(_homeHistory(_cards(7)));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(_inPage(find.text('Invoice #700013391')), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(300, 0), 1200);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(300, 0), 1200);
    await tester.pumpAndSettle();
    expect(_inPage(find.text('Invoice #700013396')), findsOneWidget);
  });

  // The engagement stamp is stored as ISO and used to be shown raw, with the
  // "T" between date and time. It is a date a person reads now.
  testWidgets('the stamp reads as a date, not an ISO string', (tester) async {
    await tester.pumpWidget(_homeHistory(_cards(1)));
    await tester.pumpAndSettle();

    expect(_inPage(find.text('Sep 10, 2026 10:19 AM')), findsOneWidget);
    expect(find.textContaining('T10:19'), findsNothing);
  });

  testWidgets('a single entry shows one page and no loop', (tester) async {
    await tester.pumpWidget(_homeHistory(_cards(1)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_inPage(find.byType(ActivityHistoryCard)), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(_inPage(find.text('Invoice #700013390')), findsOneWidget);
  });

  testWidgets('the measuring copies are never tappable', (tester) async {
    await tester.pumpWidget(_homeHistory(_cards(1)));
    await tester.pumpAndSettle();

    // Two cards in the tree (page + copy), but only the page's is hit.
    expect(find.byType(ActivityHistoryCard), findsNWidgets(2));
    expect(find.byType(ActivityHistoryCard).hitTestable(), findsOneWidget);
  });
}
