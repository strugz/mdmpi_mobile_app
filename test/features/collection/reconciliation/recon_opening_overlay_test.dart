import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/reconciliation_form.dart';

/// Opening a reconciliation case takes a few seconds (the case, the marks on
/// its invoices, the remarks). The form is covered meanwhile, says what it is
/// doing, and takes no second tap.

Widget _host({required bool visible, required VoidCallback onTap}) =>
    MaterialApp(
      theme: BCollectionTheme.light,
      home: Scaffold(
        body: Stack(
          children: [
            Center(
              child: ElevatedButton(
                  onPressed: onTap, child: const Text('Open case')),
            ),
            OpeningCaseOverlay(
                visible: visible, step: 'Marking 8 invoices', invoiceCount: 8),
          ],
        ),
      ),
    );

void main() {
  testWidgets('while saving: says what it is doing and takes no taps',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(visible: true, onTap: () => taps++));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Opening reconciliation case'), findsOneWidget);
    expect(find.text('Marking 8 invoices'), findsOneWidget);
    expect(find.text('8 invoices · please wait'), findsOneWidget);

    await tester.tap(find.text('Open case'), warnIfMissed: false);
    expect(taps, 0, reason: 'a second tap could open a second case');
  });

  testWidgets('idle: nothing shown, the form works', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(visible: false, onTap: () => taps++));
    await tester.pumpAndSettle();

    expect(find.text('Opening reconciliation case'), findsNothing);
    await tester.tap(find.text('Open case'));
    expect(taps, 1);
  });
}
