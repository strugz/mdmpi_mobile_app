import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/mirror_carousel.dart';

/// BMirrorCarousel drives the Engagement History on the dashboard. It was only
/// ever tested through the summary carousel that used to sit above it; when
/// that became a grid, these moved onto the widget itself.
///
/// The carousel lives inside a SingleChildScrollView, where the vertical
/// constraint is UNBOUNDED. Every case pumps it under that exact condition.

Widget _host(
  Widget child, {
  bool disableAnimations = false,
}) {
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

const _labels = ['Alpha', 'Bravo', 'Charlie', 'Delta'];

Widget _carousel({
  int itemCount = 4,
  int initialPage = 0,
  ValueChanged<int>? onSettleTap,
  void Function(int)? onItemTap,
}) =>
    BMirrorCarousel(
      itemCount: itemCount,
      height: 100,
      initialPage: initialPage,
      onSettleTap: onSettleTap,
      itemBuilder: (context, i) => GestureDetector(
        onTap: () => onItemTap?.call(i),
        child: Container(
          color: Colors.white,
          alignment: Alignment.center,
          child: Text(_labels[i]),
        ),
      ),
    );

/// The turn matrices around [label]. Any press-scale inside an item also uses
/// a Transform, so match on the perspective entry, which only the turn sets.
List<Matrix4> _turns(WidgetTester tester, String label) => tester
    .widgetList<Transform>(find.ancestor(
      of: find.text(label),
      matching: find.byType(Transform),
    ))
    .map((w) => w.transform)
    .where((m) => m.entry(3, 2) != 0)
    .toList();

Future<void> _swipe(WidgetTester tester, {required bool forward}) async {
  await tester.fling(
      find.byType(PageView), Offset(forward ? -300 : 300, 0), 1200);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lays out inside a scroll view and shows the first item',
      (tester) async {
    await tester.pumpWidget(_host(_carousel()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('swiping brings the next item into view', (tester) async {
    await tester.pumpWidget(_host(_carousel()));
    await tester.pumpAndSettle();

    await _swipe(tester, forward: true);

    expect(find.text('Bravo'), findsOneWidget);
    // The edge-on item is fully transparent, never a visible sliver.
    final gone = tester.widget<Opacity>(find
        .ancestor(of: find.text('Alpha'), matching: find.byType(Opacity))
        .first);
    expect(gone.opacity, 0);
  });

  testWidgets('an item mid-swipe is turned on its vertical axis',
      (tester) async {
    await tester.pumpWidget(_host(_carousel()));
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(PageView)));
    await tester.pump();
    // Past touch slop first so the PageView claims the horizontal drag.
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();

    // At rest the X basis is (1,0,0); a turn about Y shrinks it.
    expect(_turns(tester, 'Alpha').single.getRow(0).x, lessThan(0.99));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('with animations disabled the item does not turn',
      (tester) async {
    await tester.pumpWidget(_host(_carousel(), disableAnimations: true));
    await tester.pumpAndSettle();

    expect(_turns(tester, 'Alpha'), isEmpty);
  });

  testWidgets('tapping the visible item fires its callback', (tester) async {
    var tapped = -1;
    await tester.pumpWidget(_host(_carousel(onItemTap: (i) => tapped = i)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(tapped, 0);
  });

  // Scrollable ignores pointer events on its children for the whole settle
  // after a swipe, which once swallowed a quick tap on the new item.
  testWidgets('a tap right after a swipe still reaches the new item',
      (tester) async {
    var settleTapped = -1;
    await tester
        .pumpWidget(_host(_carousel(onSettleTap: (i) => settleTapped = i)));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
    // A few frames in: the new item is mostly on screen but still settling.
    // (The first pump only starts the ticker; the second advances it.)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final page = tester.widget<PageView>(find.byType(PageView)).controller!;
    final fraction = page.page! - page.page!.floorToDouble();
    expect(fraction, greaterThan(0.5));
    expect(fraction, lessThan(1.0));

    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();
    expect(settleTapped, 1);
  });

  testWidgets('settles in under 300ms after a swipe', (tester) async {
    await tester.pumpWidget(_host(_carousel()));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
    await tester.pump(); // starts the ticker
    await tester.pump(const Duration(milliseconds: 300));

    final controller =
        tester.widget<PageView>(find.byType(PageView)).controller!;
    expect(controller.position.isScrollingNotifier.value, isFalse);
    expect(controller.page, controller.page!.roundToDouble());
    expect(find.text('Bravo'), findsOneWidget);
  });

  group('looping', () {
    testWidgets('past the last item comes the first', (tester) async {
      await tester.pumpWidget(_host(_carousel(initialPage: 3)));
      await tester.pumpAndSettle();
      expect(find.text('Delta'), findsOneWidget);

      await _swipe(tester, forward: true);
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('back from the first comes the last', (tester) async {
      await tester.pumpWidget(_host(_carousel()));
      await tester.pumpAndSettle();

      await _swipe(tester, forward: false);
      expect(find.text('Delta'), findsOneWidget);
    });

    testWidgets('a full lap returns to the first, one dot active',
        (tester) async {
      await tester.pumpWidget(_host(_carousel()));
      await tester.pumpAndSettle();

      for (var i = 0; i < 4; i++) {
        await _swipe(tester, forward: true);
      }

      expect(find.text('Alpha'), findsOneWidget);
      final wide = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .where((c) => c.constraints?.maxWidth == 16)
          .toList();
      expect(wide, hasLength(1));
    });

    testWidgets('a single item shows one page and does not loop',
        (tester) async {
      await tester.pumpWidget(_host(_carousel(itemCount: 1)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await _swipe(tester, forward: true);
      expect(find.text('Alpha'), findsOneWidget);
    });
  });
}
