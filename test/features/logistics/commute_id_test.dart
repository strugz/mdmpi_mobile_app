import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/api_response_keys.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/commute_id.dart';
import 'package:mdmpi_mobile_app/features/logistics/widgets/trip_ticket_input.dart';

void main() {
  group('BCommuteId.isCommuteId', () {
    test('accepts yyyyMMdd + 4-digit sequence', () {
      expect(BCommuteId.isCommuteId('202610200001'), isTrue);
      expect(BCommuteId.isCommuteId(' 202612319999 '), isTrue);
    });

    test('rejects real trip tickets and malformed values', () {
      for (final value in [
        '01019',
        '12345',
        '',
        null,
        '20261020001', // 11 digits
        '2026102000001', // 13 digits
        '202613010001', // month 13
        '202602300001', // 30 Feb
        '202610200000', // sequence 0000
        '19991231 0001',
        'C-202610200001',
      ]) {
        expect(BCommuteId.isCommuteId(value), isFalse, reason: '$value');
      }
    });

    test('label names the value', () {
      expect(BCommuteId.label('202610200001'), 'Commute ID');
      expect(BCommuteId.label('01019'), 'Trip Ticket No');
    });
  });

  group('BApiResponse.commuteId', () {
    test('reads the pinned and camelCase keys', () {
      expect(BApiResponse.commuteId({'CommuteID': '202610200001'}),
          '202610200001');
      expect(BApiResponse.commuteId({'commuteId': '202610200002'}),
          '202610200002');
      expect(BApiResponse.commuteId({'other': 'x'}), isNull);
      expect(BApiResponse.commuteId('202610200001'), isNull);
    });
  });

  group('CommuteTicketToggle', () {
    test('on: fills the trip ticket and clears the vehicle', () async {
      final toggle = CommuteTicketToggle(
          issue: () async => Result.success('202610200001'));
      final trip = TextEditingController();
      final vehicle = TextEditingController(text: '7');

      final error =
          await toggle.setCommute(true, tripTicket: trip, vehicle: vehicle);

      expect(error, isNull);
      expect(toggle.isOn.value, isTrue);
      expect(trip.text, '202610200001');
      expect(vehicle.text, isEmpty);
    });

    test('off: clears the trip ticket for typing', () async {
      final toggle = CommuteTicketToggle(
          issue: () async => Result.success('202610200001'));
      final trip = TextEditingController();
      await toggle.setCommute(true, tripTicket: trip);

      await toggle.setCommute(false, tripTicket: trip);

      expect(toggle.isOn.value, isFalse);
      expect(trip.text, isEmpty);
    });

    test('flipping again reuses the issued ID instead of drawing a new one',
        () async {
      var calls = 0;
      final toggle = CommuteTicketToggle(issue: () async {
        calls++;
        return Result.success('20261020000$calls');
      });
      final trip = TextEditingController();

      await toggle.setCommute(true, tripTicket: trip);
      await toggle.setCommute(false, tripTicket: trip);
      await toggle.setCommute(true, tripTicket: trip);

      expect(calls, 1);
      expect(trip.text, '202610200001');
    });

    test('reset forgets the ID, so the next request gets a new one', () async {
      var calls = 0;
      final toggle = CommuteTicketToggle(issue: () async {
        calls++;
        return Result.success('20261020000$calls');
      });
      final trip = TextEditingController();

      await toggle.setCommute(true, tripTicket: trip);
      toggle.reset();
      await toggle.setCommute(true, tripTicket: trip);

      expect(calls, 2);
      expect(trip.text, '202610200002');
    });

    test('server failure: stays off, returns the message, keeps fields',
        () async {
      final toggle = CommuteTicketToggle(
          issue: () async => Result.failure('offline'));
      final trip = TextEditingController(text: '01019');
      final vehicle = TextEditingController(text: '7');

      final error =
          await toggle.setCommute(true, tripTicket: trip, vehicle: vehicle);

      expect(error, 'offline');
      expect(toggle.isOn.value, isFalse);
      expect(toggle.isIssuing.value, isFalse);
      expect(trip.text, '01019');
      expect(vehicle.text, '7');
    });
  });

  group('TripTicketInput', () {
    tearDown(Get.reset);

    testWidgets('switch swaps the label and locks the field', (tester) async {
      final toggle = CommuteTicketToggle(
          issue: () async => Result.success('202610200001'));
      final trip = TextEditingController();

      await tester.pumpWidget(GetMaterialApp(
        home: Scaffold(
          body: TripTicketInput(tripTicket: trip, commute: toggle),
        ),
      ));

      expect(find.text('Trip Ticket No'), findsOneWidget);
      expect(find.text('Commuting (no trip ticket)'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Commute ID'), findsOneWidget);
      expect(find.text('No vehicle needed'), findsOneWidget);
      expect(trip.text, '202610200001');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.readOnly, isTrue);
    });
  });
}
