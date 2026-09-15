import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/collection_bucket_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/cards/collection_summary_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/collection_totals_card.dart';

/// The Collection home dashboard lays these widgets out inside a
/// SingleChildScrollView, where the vertical constraint is UNBOUNDED. A Row
/// using CrossAxisAlignment.stretch there fails layout and blanks the screen
/// (it shipped that way once). Every case below pumps the widget under that
/// exact condition, so a reintroduction fails the suite instead of the phone.
Widget _inUnboundedColumn(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [child]),
      ),
    ),
  );
}

Widget _summaryTileRow() {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: CollectionSummaryCard(
            title: 'Settled',
            value: '0',
            icon: Iconsax.tick_circle,
            color: BColors.success,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CollectionSummaryCard(
            // Two-word label that used to truncate; it must wrap instead.
            title: 'Advanced Payment',
            value: '3868',
            icon: Iconsax.card_send,
            color: Colors.orange,
            expand: false,
            onTap: () {},
          ),
        ),
      ],
    ),
  );
}

void main() {
  group('summary tile row', () {
    testWidgets('lays out inside a scroll view', (tester) async {
      await tester.pumpWidget(_inUnboundedColumn(_summaryTileRow()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Settled'), findsOneWidget);
      expect(find.text('Advanced Payment'), findsOneWidget);
      expect(find.text('3868'), findsOneWidget);
    });

    testWidgets('both tiles share one height', (tester) async {
      await tester.pumpWidget(_inUnboundedColumn(_summaryTileRow()));
      await tester.pumpAndSettle();

      final heights = tester
          .widgetList<CollectionSummaryCard>(find.byType(CollectionSummaryCard))
          .map((w) => tester.getSize(find.byWidget(w)).height)
          .toList();
      expect(heights, hasLength(2));
      expect(heights.first, heights.last);
    });

    testWidgets('survives a large system text scale', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: SingleChildScrollView(
                child: Column(children: [_summaryTileRow()])),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Advanced Payment'), findsOneWidget);
    });
  });

  group('CollectionBucketButton', () {
    testWidgets('leads with the item count and pluralises it', (tester) async {
      await tester.pumpWidget(_inUnboundedColumn(
        CollectionBucketButton(itemCount: 3870, onTap: () {}),
      ));
      await tester.pump();

      expect(find.text('Collection Bucket'), findsOneWidget);
      expect(find.text('3870 items to collect'), findsOneWidget);
    });

    testWidgets('reads as empty with no items', (tester) async {
      await tester.pumpWidget(_inUnboundedColumn(
        CollectionBucketButton(itemCount: 0, onTap: () {}),
      ));
      await tester.pump();

      expect(find.text('No items in bucket'), findsOneWidget);
    });

    testWidgets('one item is singular', (tester) async {
      await tester.pumpWidget(_inUnboundedColumn(
        CollectionBucketButton(itemCount: 1, onTap: () {}),
      ));
      await tester.pump();

      expect(find.text('1 item to collect'), findsOneWidget);
    });
  });

  group('CollectionTotalsCardView', () {
    testWidgets('lays out inside a scroll view and shows both figures',
        (tester) async {
      await tester.pumpWidget(_inUnboundedColumn(
        const CollectionTotalsCardView(
          actual: '₱1,200.00',
          actualFootnote: 'Target ₱5,000.00',
          collected: '₱3,400.00',
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('₱1,200.00'), findsOneWidget);
      expect(find.text('₱3,400.00'), findsOneWidget);
      expect(find.text('Target ₱5,000.00'), findsOneWidget);
    });

    testWidgets('each half is independently tappable', (tester) async {
      var actualTaps = 0;
      var collectedTaps = 0;

      await tester.pumpWidget(_inUnboundedColumn(
        CollectionTotalsCardView(
          actual: '₱1,200.00',
          actualFootnote: 'No target set',
          collected: '₱3,400.00',
          onActualTap: () => actualTaps++,
          onCollectedTap: () => collectedTaps++,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('₱1,200.00'));
      await tester.pumpAndSettle();
      expect(actualTaps, 1);
      expect(collectedTaps, 0);

      await tester.tap(find.text('₱3,400.00'));
      await tester.pumpAndSettle();
      expect(collectedTaps, 1);
    });
  });
}
