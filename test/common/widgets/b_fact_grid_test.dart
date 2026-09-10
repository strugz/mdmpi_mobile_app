import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/b_fact_grid.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BFactGrid', () {
    testWidgets('renders label above value and skips empty facts',
        (tester) async {
      await tester.pumpWidget(host(const BFactGrid(facts: [
        BFact('Shipping', 'Land'),
        BFact('Terms', ''),
        BFact('Requested by', 'RAL'),
      ])));

      expect(find.text('Shipping'), findsOneWidget);
      expect(find.text('Land'), findsOneWidget);
      expect(find.text('Requested by'), findsOneWidget);
      expect(find.text('RAL'), findsOneWidget);
      expect(find.text('Terms'), findsNothing);

      // Label sits above its value.
      expect(tester.getTopLeft(find.text('Shipping')).dy,
          lessThan(tester.getTopLeft(find.text('Land')).dy));
      // Two columns: the second fact is to the right of the first.
      expect(tester.getTopLeft(find.text('Requested by')).dx,
          greaterThan(tester.getTopLeft(find.text('Shipping')).dx));
    });

    testWidgets('renders nothing when every fact is empty', (tester) async {
      await tester.pumpWidget(host(const BFactGrid(facts: [BFact('A', '')])));
      expect(find.byType(Text), findsNothing);
    });
  });

  group('BFormatter time helpers', () {
    test('formatTimeAmPm shows the time of day only', () {
      expect(BFormatter.formatTimeAmPm('2026-09-10 12:46:03.123456'),
          '12:46 PM');
      expect(BFormatter.formatTimeAmPm(''), '');
    });

    test('formatTimeRange collapses a same-day pair onto one line', () {
      expect(
        BFormatter.formatTimeRange(
            '2026-09-10 12:46:03.000', '2026-09-10 12:52:41.000'),
        '12:46 PM → 12:52 PM · Sep 10, 2026',
      );
    });

    test('formatTimeRange keeps both dates when the days differ', () {
      final s = BFormatter.formatTimeRange(
          '2026-09-10 23:50:00.000', '2026-09-11 00:10:00.000');
      expect(s, contains('Sep 10, 2026 11:50 PM'));
      expect(s, contains('Sep 11, 2026 12:10 AM'));
    });

    test('formatTimeRange with one side empty shows that stamp with its date',
        () {
      expect(BFormatter.formatTimeRange('2026-09-10 12:46:00.000', ''),
          'Sep 10, 2026 12:46 PM');
      expect(BFormatter.formatTimeRange('', ''), '');
    });
  });
}
