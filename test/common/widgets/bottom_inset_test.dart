import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/widgets/layouts/draggable_bottom_sheet.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';

/// Item 15: bottom-anchored widgets must clear the Android navigation bar
/// (`MediaQuery.padding.bottom`) exactly once, and never decide whether it
/// exists from the keyboard height (`viewInsets.bottom`).

const Size _screen = Size(400, 800);
const double _navBar = 48; // 3-button navigation bar

/// Pumps [child] under a MediaQuery that reports a [bottomInset] navigation
/// bar, inside a Scaffold so sheets have a bounded, full-height Stack.
Future<void> pumpWithInset(WidgetTester tester, Widget child,
    {double bottomInset = _navBar}) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: EdgeInsets.only(bottom: bottomInset),
          viewPadding: EdgeInsets.only(bottom: bottomInset),
        ),
        child: Scaffold(body: Stack(children: [child])),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  const actionKey = Key('action');

  group('BDraggableBottomSheet', () {
    Widget sheet() => BDraggableBottomSheet(
          initialChildSize: 0.5,
          minChildSize: 0.1,
          maxChildSize: 0.9,
          body: const SizedBox(height: 40),
          bottomAction: const SizedBox(key: actionKey, height: 40),
        );

    testWidgets('pinned action clears the navigation bar', (tester) async {
      await pumpWithInset(tester, sheet());

      final bottom = tester.getBottomLeft(find.byKey(actionKey)).dy;
      // BSizes.sm (8) of minimum padding, plus the 48 px bar.
      expect(bottom, lessThanOrEqualTo(_screen.height - _navBar - 8));
    });

    testWidgets('with no navigation bar only the minimum padding applies',
        (tester) async {
      await pumpWithInset(tester, sheet(), bottomInset: 0);

      final bottom = tester.getBottomLeft(find.byKey(actionKey)).dy;
      expect(bottom, closeTo(_screen.height - 8, 0.5));
    });
  });

  group('RequestModalScaffold', () {
    testWidgets('bottomAction clears the navigation bar', (tester) async {
      await pumpWithInset(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: RequestModalScaffold(
            title: 'Request',
            bottomAction: const SizedBox(key: actionKey, height: 40),
            children: const [SizedBox(height: 20)],
          ),
        ),
      );

      final bottom = tester.getBottomLeft(find.byKey(actionKey)).dy;
      // Followed by BSizes.xs (4) of spacing, then the 48 px bar.
      expect(bottom, lessThanOrEqualTo(_screen.height - _navBar - 4));
    });

    testWidgets('without a bottomAction the content still pads for the bar',
        (tester) async {
      const lastKey = Key('last');
      await pumpWithInset(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: RequestModalScaffold(
            title: 'Request',
            children: const [SizedBox(key: lastKey, height: 20)],
          ),
        ),
      );

      final bottom = tester.getBottomLeft(find.byKey(lastKey)).dy;
      expect(bottom, lessThanOrEqualTo(_screen.height - _navBar));
    });
  });

  test('no screen decides navigation-bar padding from the keyboard height',
      () {
    // `viewInsets.bottom > 0` is the keyboard, not a nav-style probe. The old
    // `isGestureNavigation` idiom applied SafeArea backwards; keep it out.
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('viewInsets.bottom > 0') ||
            line.contains('viewInsets.bottom != 0') ||
            line.contains('isGestureNavigation')) {
          offenders.add('${entity.path}:${i + 1}: ${line.trim()}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'Use SafeArea / BDevicesUtils.systemBottomInset for the '
            'navigation bar and BDevicesUtils.keyboardInset for the keyboard.');
  });
}
