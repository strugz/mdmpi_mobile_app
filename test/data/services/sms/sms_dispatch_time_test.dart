import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_message_template_service.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_payload_builder.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

import '../../../fixtures/sms_payload_fixtures.dart';

void main() {
  final service = SmsMessageTemplateService();
  // Exactly what the data managers stamp: DateTime.now().toString().
  final stamped = DateTime(2026, 9, 9, 15, 3, 12, 123, 456).toString();

  group('SmsMessageTemplateService dispatch time', () {
    test('formatTimeForSms renders the phone timestamp with AM/PM', () {
      expect(service.formatTimeForSms(stamped), 'Sep 9, 2026 03:03 PM');
      expect(service.formatTimeForSms('2026-09-09T07:45:00'),
          'Sep 9, 2026 07:45 AM');
      expect(service.formatTimeForSms(''), '');
      // Unparsable input falls back to the raw text rather than dropping it.
      expect(service.formatTimeForSms('not a date'), 'not a date');
    });

    test('For Delivery (Standard Delivery / Hotline Dispatch) prints the time',
        () {
      final message = service.createMessage(
        BTexts.statusForDelivery,
        SmsPayloadFixtures.base(dispatchAt: stamped),
      );
      expect(message, contains('Status: For Delivery.'));
      expect(message, contains('Dispatched At: Sep 9, 2026 03:03 PM.'));
      expect(message, contains('Target Date: 2026-05-13.'));
    });

    test('Dispatch (Air / Sea / Land) prints the time', () {
      final message = service.createMessage(
        BTexts.statusDispatch,
        SmsPayloadFixtures.base(dispatchAt: stamped),
      );
      expect(message, contains('Status: Dispatch.'));
      expect(message, contains('Dispatched At: Sep 9, 2026 03:03 PM.'));
    });

    test('omits the line when no dispatch time is known', () {
      for (final status in [BTexts.statusForDelivery, BTexts.statusDispatch]) {
        final message =
            service.createMessage(status, SmsPayloadFixtures.base());
        expect(message, isNot(contains('Dispatched At')), reason: status);
      }
    });

    test('other statuses in the shared branch are unchanged', () {
      final message = service.createMessage(
        BTexts.statusForDispatch,
        SmsPayloadFixtures.base(dispatchAt: stamped),
      );
      expect(message, isNot(contains('Dispatched At')));
      expect(message, contains('Status: For Dispatch.'));
    });

    test('completion time is now human-readable too', () {
      final message = service.createMessage(
        BTexts.statusDoneDelivery,
        SmsPayloadFixtures.base(completionAt: stamped),
      );
      expect(message, contains('Date Time Received: Sep 9, 2026 03:03 PM'));
    });
  });

  group('SmsPayloadBuilder dispatchAt', () {
    test('Standard Delivery maps deliveredAt (the Dispatch stamp)', () async {
      final model = StandardDeliveryModel(
        id: '1',
        clientId: 'C1',
        shippingMethod: 'Land',
        deliveryTerms: 'Full',
        deliveryDate: '2026-09-10',
        preference: 'Medium',
        status: BTexts.statusForDelivery,
        requestBy: 'JCA',
        createdBy: 'JCA',
        documentReference: const ['DR1'],
        client: ClientModel.empty(),
        createdAt: stamped,
        deliveredAt: stamped,
      );
      final payload =
          await const SmsPayloadBuilder().build(BTexts.statusForDelivery, model);
      expect(payload!.dispatchAt, stamped);
    });

    test('Air / Sea maps dispatchedAt', () async {
      final model = AirSeaModel(
        id: '2',
        clientId: 'C1',
        status: BTexts.statusDispatch,
        dispatchedAt: stamped,
      );
      final payload =
          await const SmsPayloadBuilder().build(BTexts.statusDispatch, model);
      expect(payload!.dispatchAt, stamped);
    });

    test('Pull Out / Stock Receive map pullOutDateStartAt', () async {
      final model = PullOutModel(
        id: '3',
        clientId: 'C1',
        requestStatus: BTexts.statusInTransit,
        pullOutDateStartAt: stamped,
      );
      final payload =
          await const SmsPayloadBuilder().build(BTexts.statusInTransit, model);
      expect(payload!.dispatchAt, stamped);
    });
  });

  test('In Transit (Pull Out / Stock Receive) prints the time', () {
    final message = service.createMessage(
      BTexts.statusInTransit,
      SmsPayloadFixtures.base(dispatchAt: stamped),
    );
    expect(message, contains('Status: In Transit.'));
    expect(message, contains('Dispatched At: Sep 9, 2026 03:03 PM.'));

    // A paused request has its start time cleared: no line.
    final paused =
        service.createMessage(BTexts.statusInTransit, SmsPayloadFixtures.base());
    expect(paused, isNot(contains('Dispatched At')));
  });
}
