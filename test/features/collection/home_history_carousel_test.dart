import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/mirror_carousel.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';

/// The home dashboard shows the seven most recent engagement entries as
/// pages of a [BMirrorCarousel] at a fixed height. These cases pump that
/// exact arrangement, inside an unbounded scroll view, at the text scale the
/// dashboard clamps to, so a card that outgrows its page fails here first.
const double _historyCardHeight = 172;

List<ActivityHistoryCard> _cards(int count) => [
      for (var i = 0; i < count; i++)
        ActivityHistoryCard(
          history: CollectionHistoryModel(
            date: '2026-09-1${i}T10:19:22.215179',
            collectorName: 'Juan Dela Cruz',
            status: 'Collected',
            remarks: 'Paid in full, receipt issued to the pharmacist on duty',
            totalCollected: 121208.04,
          ),
          accountName: 'Accusure Medical Enterprises $i',
          invoiceId: '70001339$i',
          margin: EdgeInsets.zero,
        ),
    ];

Widget _homeHistory(List<ActivityHistoryCard> cards, {double textScale = 1}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [
              BMirrorCarousel(
                itemCount: cards.length,
                height: _historyCardHeight,
                itemBuilder: (context, i) =>
                    Align(alignment: Alignment.topCenter, child: cards[i]),
              ),
            ]),
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
    expect(find.text('Invoice #700013390'), findsOneWidget);
    // Seven dots, one per entry.
    expect(find.byType(AnimatedContainer), findsNWidgets(7));
  });

  testWidgets('a card fits its page at the dashboard text-scale clamp',
      (tester) async {
    await tester.pumpWidget(_homeHistory(_cards(7), textScale: 1.15));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final card = tester.getSize(find.byType(ActivityHistoryCard).first);
    expect(card.height, lessThanOrEqualTo(_historyCardHeight));
  });

  testWidgets('swiping moves to the next entry and loops from the last',
      (tester) async {
    await tester.pumpWidget(_homeHistory(_cards(7)));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Invoice #700013391'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(300, 0), 1200);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(300, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Invoice #700013396'), findsOneWidget);
  });

  // The engagement stamp is stored as ISO and used to be shown raw, with the
  // "T" between date and time. It is a date a person reads now.
  testWidgets('the stamp reads as a date, not an ISO string', (tester) async {
    await tester.pumpWidget(_homeHistory(_cards(1)));
    await tester.pumpAndSettle();

    expect(find.text('Sep 10, 2026 10:19 AM'), findsOneWidget);
    expect(find.textContaining('T10:19'), findsNothing);
  });

  testWidgets('a single entry shows one page and no loop', (tester) async {
    await tester.pumpWidget(_homeHistory(_cards(1)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ActivityHistoryCard), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Invoice #700013390'), findsOneWidget);
  });
}
