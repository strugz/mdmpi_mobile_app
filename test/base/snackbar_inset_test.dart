import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

/// Android runs edge-to-edge, so the gesture pill and the three-button strip
/// sit on top of the bottom of every screen. A snackbar that does not account
/// for that has its last line covered by the system navigation bar.

void main() {
  group('snackBarMargin', () {
    test('always clears the system navigation bar', () {
      // 0 is a desktop window or an old Android; 24 is a gesture pill; 48 is
      // the three-button strip.
      for (final inset in [0.0, 24.0, 48.0]) {
        expect(
          BLoaders.snackBarMargin(inset).bottom,
          greaterThan(inset),
          reason: 'a $inset inset must not reach the snackbar',
        );
      }
    });

    test('leaves the same gap on both sides and none on top', () {
      final margin = BLoaders.snackBarMargin(24);
      expect(margin.left, margin.right);
      expect(margin.top, 0);
    });
  });

  group('on screen', () {
    testWidgets('sits above a 48px navigation bar', (tester) async {
      const navBar = 48.0;

      await tester.pumpWidget(
        GetMaterialApp(
          builder: (context, child) => MediaQuery(
            // What an edge-to-edge Android build reports.
            data: const MediaQueryData(
              padding: EdgeInsets.only(bottom: navBar),
            ),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => BLoaders.successSnackBar(
                      title: 'Account Acquired',
                      message: 'All invoices moved to Field Engagement.'),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      // Not pumpAndSettle: a snackbar holds a dismiss timer for its whole
      // lifetime, so settling would wait it out. Pump past the entrance only.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final screenHeight = tester.view.physicalSize.height /
          tester.view.devicePixelRatio;
      final message = find.text('All invoices moved to Field Engagement.');
      expect(message, findsOneWidget);

      final bottomOfMessage = tester.getBottomLeft(message).dy;
      expect(
        bottomOfMessage,
        lessThan(screenHeight - navBar),
        reason: 'the last line of the message is under the navigation bar',
      );

      // Let it dismiss so no timer outlives the test.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });
}
