import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/acquiring_overlay.dart';

Widget _host({required int done}) => MaterialApp(
      home: Scaffold(
        body: Stack(children: [
          AcquiringOverlay(
            visible: true,
            invoiceCount: 1095,
            accountCount: 1,
            doneCount: done,
          ),
        ]),
      ),
    );

void main() {
  testWidgets('shows a running count and fills the ring', (tester) async {
    await tester.pumpWidget(_host(done: 312));
    await tester.pump(AcquiringOverlay.fadeDuration);

    expect(find.text('312 of 1,095 · 28%'), findsOneWidget);
    expect(find.text('1,095 invoices across 1 account'), findsOneWidget);
    final ring = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator));
    expect(ring.value, closeTo(312 / 1095, 1e-9));
  });

  testWidgets('ring is indeterminate before the first invoice lands',
      (tester) async {
    await tester.pumpWidget(_host(done: 0));
    await tester.pump(AcquiringOverlay.fadeDuration);

    expect(find.text('0 of 1,095 · 0%'), findsOneWidget);
    final ring = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator));
    expect(ring.value, isNull);
  });
}
