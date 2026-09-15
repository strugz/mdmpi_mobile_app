import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/collection_search_filter_bar.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CollectionSearchFilterBar', () {
    testWidgets('clear button is hidden until there is text, then clears it',
        (tester) async {
      String? last;
      await tester.pumpWidget(_host(CollectionSearchFilterBar(
        onSearchChanged: (v) => last = v,
        onFilterTap: () {},
        hasActiveFilter: false,
      )));

      final clear = find.byKey(const ValueKey('search-clear'));
      AnimatedOpacity clearOpacity() => tester.widget<AnimatedOpacity>(clear);

      // Hidden (opacity 0 + ignoring pointer) with no text.
      expect(clearOpacity().opacity, 0);

      await tester.enterText(find.byType(TextField), 'acme');
      await tester.pumpAndSettle();
      expect(last, 'acme');
      expect(clearOpacity().opacity, 1);

      await tester.tap(find.byIcon(Iconsax.close_circle5));
      await tester.pumpAndSettle();
      expect(last, '');
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    });

    testWidgets('external reset of the query empties the visible field',
        (tester) async {
      Widget build(String value) => _host(CollectionSearchFilterBar(
            onSearchChanged: (_) {},
            onFilterTap: () {},
            hasActiveFilter: false,
            initialValue: value,
          ));

      await tester.pumpWidget(build('acme'));
      expect(find.text('acme'), findsOneWidget);

      // Owner cleared the query (e.g. "Clear all filters").
      await tester.pumpWidget(build(''));
      await tester.pumpAndSettle();
      expect(find.text('acme'), findsNothing);
    });
  });

  group('BPressableScale', () {
    testWidgets('scales down while pressed and back on release', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(Center(
        child: BPressableScale(
          onTap: () => taps++,
          child: const SizedBox(width: 100, height: 100),
        ),
      )));

      AnimatedScale scale() => tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale().scale, 1);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(BPressableScale)));
      await tester.pump();
      expect(scale().scale, 0.97);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(scale().scale, 1);
      expect(taps, 1);
    });
  });
}
