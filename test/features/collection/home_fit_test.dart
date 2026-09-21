import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The home dashboard lays a fixed set of blocks out to fit the viewport and
/// lets the last block take the remaining height. This pins the layout
/// recipe the screen uses (scroll view, min-height box, intrinsic height,
/// Expanded tail) so it keeps working: on a tall screen nothing scrolls and
/// the tail reaches the bottom; on a short screen it scrolls instead of
/// overflowing.
Widget _fitLayout({required double topHeight, required double tailMin}) {
  return MaterialApp(
    home: Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(children: [
                SizedBox(height: topHeight, key: const Key('top')),
                Expanded(
                  child: Container(
                    key: const Key('tail'),
                    constraints: BoxConstraints(minHeight: tailMin),
                    color: Colors.white,
                  ),
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
  testWidgets('on a tall screen the tail fills to the bottom, no scroll',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_fitLayout(topHeight: 500, tailMin: 100));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final tail = tester.getRect(find.byKey(const Key('tail')));
    expect(tail.bottom, 800, reason: 'tail reaches the viewport bottom');
    expect(tail.height, 300);
    final scroll = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
    final position =
        Scrollable.of(tester.element(find.byKey(const Key('top')))).position;
    expect(position.maxScrollExtent, 0, reason: 'nothing to scroll');
    expect(scroll.physics, isA<ClampingScrollPhysics>());
  });

  testWidgets('on a short screen it scrolls instead of overflowing',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_fitLayout(topHeight: 450, tailMin: 200));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'no overflow');
    final position =
        Scrollable.of(tester.element(find.byKey(const Key('top')))).position;
    expect(position.maxScrollExtent, 150);
  });
}
