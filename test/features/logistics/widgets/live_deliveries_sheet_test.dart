import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/rider_location_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/delivery_location/widgets/live_deliveries_sheet.dart';

RiderLocationModel delivery({
  required String requestId,
  String client = 'Alabang Medical Clinic - Main',
  String rider = 'RDR',
  String eta = '1 min',
  String distance = '0.2 km',
  String status = 'en_route',
}) =>
    RiderLocationModel(
      type: 'location_update',
      requestId: requestId,
      latitude: 14.4,
      longitude: 121.0,
      timestamp: DateTime(2026, 9, 10, 14, 33),
      status: status,
      riderInitial: rider,
      eta: eta,
      distance: distance,
      client: client,
    );

Widget host({
  required List<RiderLocationModel> deliveries,
  String? selected,
  ValueChanged<String>? onSelect,
  VoidCallback? onClear,
  ValueChanged<RiderLocationModel>? onCall,
  ValueChanged<String>? onCenter,
}) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LiveDeliveriesBody(
            deliveries: deliveries,
            colorFor: (_) => Colors.blue,
            selectedRequestId: selected,
            onSelect: onSelect ?? (_) {},
            onClearSelection: onClear ?? () {},
            onCall: onCall ?? (_) {},
            onCenter: onCenter ?? (_) {},
          ),
        ),
      ),
    );

void main() {
  group('LiveDeliveriesBody (TODO 23)', () {
    testWidgets('empty state is visible without any gesture', (tester) async {
      await tester.pumpWidget(host(deliveries: const []));

      expect(find.text('Waiting for dispatched deliveries'), findsOneWidget);
      expect(find.textContaining('press Dispatch'), findsOneWidget);
    });

    testWidgets('list puts the client first, then the request number and meta',
        (tester) async {
      await tester.pumpWidget(host(deliveries: [
        delivery(requestId: '2026090071'),
        delivery(requestId: '2026090072', client: 'Eton City Square', rider: 'BPT'),
      ]));

      expect(find.text('2 live deliveries'), findsOneWidget);
      expect(find.text('Alabang Medical Clinic - Main'), findsOneWidget);
      expect(find.text('2026090071'), findsOneWidget);
      expect(find.text('RDR · 1 min · 0.2 km'), findsOneWidget);
      // No label soup and no fake vehicles.
      expect(find.textContaining('Rider:'), findsNothing);
      expect(find.textContaining('Vehicle'), findsNothing);
    });

    testWidgets('tapping a row selects that request', (tester) async {
      String? selected;
      await tester.pumpWidget(host(
        deliveries: [delivery(requestId: '2026090071')],
        onSelect: (id) => selected = id,
      ));

      await tester.tap(find.text('Alabang Medical Clinic - Main'));
      expect(selected, '2026090071');
    });

    testWidgets('selected card shows Call and Center, and X clears it',
        (tester) async {
      RiderLocationModel? called;
      String? centered;
      var cleared = false;
      await tester.pumpWidget(host(
        deliveries: [delivery(requestId: '2026090071')],
        selected: '2026090071',
        onCall: (d) => called = d,
        onCenter: (id) => centered = id,
        onClear: () => cleared = true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 live delivery'), findsOneWidget);
      expect(find.text('En Route'), findsOneWidget);

      await tester.tap(find.byKey(const Key('live_delivery_call')));
      expect(called?.requestId, '2026090071');

      await tester.tap(find.byKey(const Key('live_delivery_center')));
      expect(centered, '2026090071');

      await tester.tap(find.byKey(const Key('live_delivery_close')));
      expect(cleared, isTrue);
    });

    testWidgets('a selection that no longer exists falls back to the list',
        (tester) async {
      await tester.pumpWidget(host(
        deliveries: [delivery(requestId: '2026090071')],
        selected: 'gone',
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('live_delivery_call')), findsNothing);
      expect(find.text('Alabang Medical Clinic - Main'), findsOneWidget);
    });
  });

  test('meta line drops empty parts and never prints labels', () {
    expect(deliveryMetaLine(delivery(requestId: 'a')), 'RDR · 1 min · 0.2 km');
    expect(deliveryMetaLine(delivery(requestId: 'a', eta: '', distance: '')),
        'RDR');
    expect(
        deliveryMetaLine(
            delivery(requestId: 'a', rider: '', eta: '', distance: '')),
        'Waiting for the first position…');
    expect(displayStatus('en_route'), 'En Route');
    expect(displayStatus('In Transit'), 'In Transit');
  });
}
