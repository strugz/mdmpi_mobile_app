import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/defer_reason_sheet.dart';

/// Opens the sheet from a button, the way the account screen does, and
/// captures what it resolves to.
Widget _host(void Function(DeferReason?) onResult) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              onResult(await DeferReasonSheet.show(context,
                  accountName: 'Alexis Yu Best Care Pharmacy'));
            },
            child: const Text('Defer'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Defer'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('names the account and lists the four reasons', (tester) async {
    await tester.pumpWidget(_host((_) {}));
    await _open(tester);

    expect(find.textContaining('Alexis Yu Best Care Pharmacy'), findsOneWidget);
    for (final reason in DeferReasonSheet.reasons) {
      expect(find.text(reason), findsOneWidget);
    }
    expect(find.text('What happened?'), findsNothing);
  });

  testWidgets('confirming the default returns Follow Up with a stock remark',
      (tester) async {
    DeferReason? result;
    await tester.pumpWidget(_host((r) => result = r));
    await _open(tester);

    await tester.tap(find.text('Defer account'));
    await tester.pumpAndSettle();

    expect(result?.status, CollectionStatusColors.statusFollowUp);
    expect(result?.remarks, 'No collection done: Follow Up');
  });

  testWidgets('a tapped reason becomes the result', (tester) async {
    DeferReason? result;
    await tester.pumpWidget(_host((r) => result = r));
    await _open(tester);

    await tester.tap(find.text(CollectionStatusColors.statusRefused));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Defer account'));
    await tester.pumpAndSettle();

    expect(result?.status, CollectionStatusColors.statusRefused);
    expect(result?.remarks, 'No collection done: Refused to Pay');
  });

  testWidgets('Others unfolds a field and holds confirm until it has text',
      (tester) async {
    DeferReason? result;
    await tester.pumpWidget(_host((r) => result = r));
    await _open(tester);

    await tester.tap(find.text(CollectionStatusColors.statusOthers));
    await tester.pumpAndSettle();
    expect(find.text('What happened?'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.ancestor(
      of: find.text('Defer account'),
      matching: find.byType(ElevatedButton),
    ));
    expect(button.onPressed, isNull, reason: 'no remark yet');

    await tester.enterText(find.byType(TextField), '  Store closed early  ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Defer account'));
    await tester.pumpAndSettle();

    expect(result?.status, CollectionStatusColors.statusOthers);
    expect(result?.remarks, 'Store closed early');
  });

  testWidgets('closing resolves to null', (tester) async {
    DeferReason? result = const DeferReason(status: 'x', remarks: 'x');
    await tester.pumpWidget(_host((r) => result = r));
    await _open(tester);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
