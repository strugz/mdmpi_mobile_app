import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/collection_summary_carousel.dart';

/// The carousel lives inside the dashboard's SingleChildScrollView, where the
/// vertical constraint is unbounded. Every case pumps it under that condition.
Widget _inUnboundedColumn(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        // Keep the real view metrics (size, gesture slop); only flip the flag.
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: Scaffold(
          body: SingleChildScrollView(child: Column(children: [child])),
        ),
      ),
    ),
  );
}

List<CollectionSummaryPage> _pages({VoidCallback? onSettledTap}) => [
      CollectionSummaryPage(
        title: 'Settled',
        value: '1',
        icon: Iconsax.tick_circle,
        color: BColors.success,
        onTap: onSettledTap,
      ),
      const CollectionSummaryPage(
        title: 'Due Date',
        value: '3767',
        icon: Iconsax.timer,
        color: BColors.error,
      ),
      const CollectionSummaryPage(
        title: 'Reconciliation',
        value: '0',
        icon: Iconsax.status_up,
        color: Colors.purple,
      ),
      const CollectionSummaryPage(
        title: 'Advanced Payment',
        value: '0',
        icon: Iconsax.card_send,
        color: Colors.orange,
      ),
    ];

/// The carousel's turn matrices around [title]. The press-scale inside the
/// card also uses a Transform, so match on the perspective entry instead
/// (non-zero only on the turn; the rotation scales it, so no exact compare).
List<Matrix4> _mirrorTransforms(WidgetTester tester, String title) {
  return tester
      .widgetList<Transform>(find.ancestor(
        of: find.text(title),
        matching: find.byType(Transform),
      ))
      .map((w) => w.transform)
      .where((m) => m.entry(3, 2) != 0)
      .toList();
}

Matrix4 _mirrorOf(WidgetTester tester, String title) =>
    _mirrorTransforms(tester, title).single;

void main() {
  testWidgets('lays out inside a scroll view and shows the first card',
      (tester) async {
    await tester.pumpWidget(
        _inUnboundedColumn(CollectionSummaryCarousel(pages: _pages())));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Settled'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('swiping left brings the next card into view', (tester) async {
    await tester.pumpWidget(
        _inUnboundedColumn(CollectionSummaryCarousel(pages: _pages())));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();

    expect(find.text('Due Date'), findsOneWidget);
    expect(find.text('3767'), findsOneWidget);
    // The edge-on card is fully transparent, never a visible sliver.
    final settled = tester.widget<Opacity>(find
        .ancestor(
          of: find.text('Settled'),
          matching: find.byType(Opacity),
        )
        .first);
    expect(settled.opacity, 0);
  });

  testWidgets('a card mid-swipe is turned on its vertical axis',
      (tester) async {
    await tester.pumpWidget(
        _inUnboundedColumn(CollectionSummaryCarousel(pages: _pages())));
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(PageView)));
    await tester.pump();
    // Past touch slop first so the PageView claims the horizontal drag.
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();

    // The card is at rest with the X basis at (1,0,0); a Y turn shrinks it.
    expect(_mirrorOf(tester, 'Settled').getRow(0).x, lessThan(0.99));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('with animations disabled the card does not turn',
      (tester) async {
    await tester.pumpWidget(_inUnboundedColumn(
      CollectionSummaryCarousel(pages: _pages()),
      disableAnimations: true,
    ));
    await tester.pumpAndSettle();

    expect(_mirrorTransforms(tester, 'Settled'), isEmpty);
  });

  testWidgets('tapping the visible card fires its callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_inUnboundedColumn(
        CollectionSummaryCarousel(pages: _pages(onSettledTap: () => taps++))));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settled'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  // Scrollable ignores pointer events on its children for the whole settle
  // after a swipe, which once swallowed a quick tap on the new card.
  testWidgets('a tap right after a swipe still opens the new card',
      (tester) async {
    var taps = 0;
    final pages = _pages();
    pages[1] = CollectionSummaryPage(
      title: 'Due Date',
      value: '3767',
      icon: Iconsax.timer,
      color: BColors.error,
      onTap: () => taps++,
    );
    await tester.pumpWidget(
        _inUnboundedColumn(CollectionSummaryCarousel(pages: pages)));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
    // A few frames in: the new card is mostly on screen but still settling.
    // (The first pump only starts the ticker; the second advances it.)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Pages are virtual and start far from zero, so check the fraction.
    final page = tester.widget<PageView>(find.byType(PageView)).controller!;
    final fraction = page.page! - page.page!.floorToDouble();
    expect(fraction, greaterThan(0.5));
    expect(fraction, lessThan(1.0));
    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('settles in under 300ms after a swipe', (tester) async {
    await tester.pumpWidget(
        _inUnboundedColumn(CollectionSummaryCarousel(pages: _pages())));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
    await tester.pump(); // starts the ticker
    await tester.pump(const Duration(milliseconds: 300));

    final controller =
        tester.widget<PageView>(find.byType(PageView)).controller!;
    expect(controller.position.isScrollingNotifier.value, isFalse);
    expect(controller.page, controller.page!.roundToDouble());
    expect(find.text('Due Date'), findsOneWidget);
  });

  Future<void> swipe(WidgetTester tester, {required bool forward}) async {
    await tester.fling(
        find.byType(PageView), Offset(forward ? -300 : 300, 0), 1200);
    await tester.pumpAndSettle();
  }

  testWidgets('swiping past the last card loops back to the first',
      (tester) async {
    await tester.pumpWidget(_inUnboundedColumn(
        CollectionSummaryCarousel(pages: _pages(), initialPage: 3)));
    await tester.pumpAndSettle();
    expect(find.text('Advanced Payment'), findsOneWidget);

    await swipe(tester, forward: true);

    expect(find.text('Settled'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('swiping back from the first card shows the last',
      (tester) async {
    await tester.pumpWidget(
        _inUnboundedColumn(CollectionSummaryCarousel(pages: _pages())));
    await tester.pumpAndSettle();

    await swipe(tester, forward: false);

    expect(find.text('Advanced Payment'), findsOneWidget);
  });

  testWidgets('a full lap returns to the first card with its dot active',
      (tester) async {
    await tester.pumpWidget(
        _inUnboundedColumn(CollectionSummaryCarousel(pages: _pages())));
    await tester.pumpAndSettle();

    for (var i = 0; i < 4; i++) {
      await swipe(tester, forward: true);
    }

    expect(find.text('Settled'), findsOneWidget);
    // The active dot is the wide one; only one dot should be wide.
    final wide = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .where((c) => c.constraints?.maxWidth == 16)
        .toList();
    expect(wide, hasLength(1));
  });

  testWidgets('a tap that lands during the loop-around opens the first card',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_inUnboundedColumn(CollectionSummaryCarousel(
        pages: _pages(onSettledTap: () => taps++), initialPage: 3)));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('survives a large system text scale', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [
              CollectionSummaryCarousel(pages: _pages(), initialPage: 3),
            ]),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Advanced Payment'), findsOneWidget);
  });
}
