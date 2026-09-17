import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/area_selection/area_picker_sheet.dart';

/// The area picker was a pushed screen of two-up cards that overflowed by a
/// pixel at the default text size, truncated "Medical Imaging", and buried the
/// Luzon regions one level down. These cases pin the sheet that replaced it:
/// every area one tap, every name whole, nothing overflowing.

const _counts = {
  '': 268,
  'NLN': 128,
  'CLN': 42,
  'SLN': 31,
  'NCR': 55,
  'VIS': 33,
  'MIN': 46,
  'RAD': 45,
  BCollectionArea.others: 6,
};

Widget _host(
  void Function(String?) onResult, {
  String selected = '',
  Map<String, int> counts = _counts,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async => onResult(await AreaPickerSheet.show(
              context,
              selected: selected,
              countFor: (code) => counts[code] ?? 0,
            )),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists every area at one level, with nothing overflowing',
      (tester) async {
    await tester.pumpWidget(_host((_) {}));
    await _open(tester);

    expect(tester.takeException(), isNull);
    // The Luzon regions are headed, not hidden a level down.
    expect(find.text('Luzon'), findsOneWidget);
    for (final name in [
      'All areas',
      'North Luzon',
      'Central Luzon',
      'South Luzon',
      'NCR',
      'Visayas',
      'Mindanao',
      'Others',
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
  });

  // The longest label is what the old tiles cut to "Medical Ima...".
  testWidgets('the longest name is not truncated', (tester) async {
    await tester.pumpWidget(_host((_) {}));
    await _open(tester);

    final label = tester.widget<Text>(find.text('Medical Imaging'));
    expect(label.overflow, TextOverflow.ellipsis);
    final size = tester.getSize(find.text('Medical Imaging'));
    final painter = TextPainter(
      text: TextSpan(text: 'Medical Imaging', style: label.style),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(size.width, greaterThanOrEqualTo(painter.width - 0.5),
        reason: 'the row is wide enough for the whole name');
  });

  testWidgets('a region is one tap, same as any other area', (tester) async {
    String? result;
    await tester.pumpWidget(_host((r) => result = r));
    await _open(tester);

    await tester.tap(find.text('NCR'));
    await tester.pumpAndSettle();

    expect(result, 'NCR');
  });

  testWidgets('All areas resolves to the empty code', (tester) async {
    String? result = 'unset';
    await tester.pumpWidget(_host((r) => result = r, selected: 'NLN'));
    await _open(tester);

    await tester.tap(find.text('All areas'));
    await tester.pumpAndSettle();

    expect(result, isEmpty);
  });

  // Picking an area with nothing in it could only produce an empty list.
  testWidgets('an empty area is inert', (tester) async {
    String? result = 'unset';
    await tester.pumpWidget(_host(
      (r) => result = r,
      counts: {..._counts, 'MIN': 0},
    ));
    await _open(tester);

    expect(find.text('None'), findsOneWidget);
    await tester.tap(find.text('Mindanao'));
    await tester.pumpAndSettle();

    expect(result, 'unset', reason: 'the sheet is still open');
  });

  testWidgets('closing resolves to null, leaving the area as it was',
      (tester) async {
    String? result = 'unset';
    await tester.pumpWidget(_host((r) => result = r, selected: 'VIS'));
    await _open(tester);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
