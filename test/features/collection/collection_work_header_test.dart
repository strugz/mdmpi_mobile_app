import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/collection_work_header.dart';

/// The header on a queue screen competes with the rows underneath it, so the
/// two things worth pinning are that it stays one line and that it still
/// clears the status bar without an AppBar to do it for them.

const double _statusBar = 44;

Future<void> _pump(WidgetTester tester, {Widget? trailing}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(top: _statusBar)),
        child: CollectionWorkHeader(
          title: 'Field Engagement',
          trailing: trailing,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the screen it is, and nothing else', (tester) async {
    await _pump(tester);

    expect(find.text('Field Engagement'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Field Engagement')).maxLines, 1);
  });

  testWidgets('the title clears the status bar', (tester) async {
    await _pump(tester);

    // There is no AppBar here to apply the inset, so the header has to.
    expect(
      tester.getTopLeft(find.text('Field Engagement')).dy,
      greaterThanOrEqualTo(_statusBar),
      reason: 'the title is under the status bar',
    );
  });

  testWidgets('stays compact enough to be worth the space', (tester) async {
    await _pump(tester);

    // The dashboard header this replaces measured 132 here: a screen name
    // over the collector's own name, plus a section gap.
    final height = tester.getSize(find.byType(CollectionWorkHeader)).height;
    expect(height, lessThan(132),
        reason: 'no cheaper than the header it replaced');
  });

  testWidgets('makes room for an action without growing', (tester) async {
    await _pump(tester);
    final bare = tester.getSize(find.byType(CollectionWorkHeader)).height;

    await _pump(tester, trailing: const Icon(Icons.filter_alt, size: 24));

    expect(find.byIcon(Icons.filter_alt), findsOneWidget);
    expect(tester.getSize(find.byType(CollectionWorkHeader)).height, bare);
  });
}
