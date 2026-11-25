import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_message_template_service.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_payload_builder.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_ids.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';

import '../../../fixtures/sms_payload_fixtures.dart';

void main() {
  final service = SmsMessageTemplateService();

  group('Drop Off SMS carries the waybill number', () {
    test('prints the waybill line when the request has one', () {
      final message = service.createMessage(
        BTexts.statusDropOff,
        SmsPayloadFixtures.base(waybillNumber: 'WB-12345'),
      );
      expect(message, contains('Waybill Number: WB-12345'));
      expect(message, contains('Status: Drop Off.'));
      // The line sits between the references and the status.
      expect(
        message.indexOf('Waybill Number:'),
        greaterThan(message.indexOf('Document References:')),
      );
      expect(
        message.indexOf('Waybill Number:'),
        lessThan(message.indexOf('Status:')),
      );
    });

    test('omits the line when the request has no waybill', () {
      final message = service.createMessage(
        BTexts.statusDropOff,
        SmsPayloadFixtures.base(),
      );
      expect(message, isNot(contains('Waybill')));
      expect(message, contains('Status: Drop Off.'));
    });

    test('blank-only waybills do not print an empty line', () {
      final message = service.createMessage(
        BTexts.statusDropOff,
        SmsPayloadFixtures.base(waybillNumber: '   '),
      );
      expect(message, isNot(contains('Waybill')));
    });

    test('other statuses in the shared branch stay unchanged', () {
      for (final status in [
        BTexts.statusItemPacked,
        BTexts.statusForDispatch,
        BTexts.statusEndorsedToGuard,
        BTexts.statusDispatch,
        BTexts.statusProvincialPickUp,
      ]) {
        final message = service.createMessage(
          status,
          SmsPayloadFixtures.base(waybillNumber: 'WB-12345'),
        );
        expect(message, isNot(contains('Waybill')), reason: status);
      }
    });
  });

  group('SmsPayloadBuilder maps the Air / Sea waybill', () {
    test('base Air / Sea / Land', () async {
      final model = AirSeaModel(
        id: '1',
        clientId: 'C1',
        status: BTexts.statusDropOff,
        waybillNumber: 'WB-BASE',
      );
      final payload =
          await const SmsPayloadBuilder().build(BTexts.statusDropOff, model);
      expect(payload!.waybillNumber, 'WB-BASE');
      expect(
        service.createMessage(BTexts.statusDropOff, payload),
        contains('Waybill Number: WB-BASE'),
      );
    });

    test('Air / Sea / Land HD', () async {
      final model = AirSeaModel(
        id: '2',
        clientId: 'C1',
        status: BTexts.statusDropOff,
        formCategoryID: FormCategoryIds.airSeaHd,
        waybillNumber: 'WB-HD',
      );
      final payload =
          await const SmsPayloadBuilder().build(BTexts.statusDropOff, model);
      expect(payload!.waybillNumber, 'WB-HD');
      expect(
        service.createMessage(BTexts.statusDropOff, payload),
        contains('Waybill Number: WB-HD'),
      );
    });
  });

  group('Air / Sea / Land Drop Off SMS carries the departure time', () {
    AirSeaModel hd({String departureAt = ''}) => AirSeaModel(
          id: '3',
          clientId: 'C1',
          status: BTexts.statusDropOff,
          formCategoryID: FormCategoryIds.airSeaHd,
          waybillNumber: 'WB-HD',
          departureAt: departureAt,
        );

    test('prints the time right under the waybill', () async {
      final payload = await const SmsPayloadBuilder()
          .build(BTexts.statusDropOff, hd(departureAt: '2026-11-25 15:30:00.000'));
      final message = service.createMessage(BTexts.statusDropOff, payload!);
      expect(message,
          contains('Waybill Number: WB-HD\nDeparture Time: 03:30 PM\nStatus: Drop Off.'));
    });

    test('base Air / Sea / Land prints it too', () async {
      final base = AirSeaModel(
        id: '4',
        clientId: 'C1',
        status: BTexts.statusDropOff,
        waybillNumber: 'WB-BASE',
        departureAt: '2026-11-25 09:05:00.000',
      );
      final payload =
          await const SmsPayloadBuilder().build(BTexts.statusDropOff, base);
      expect(service.createMessage(BTexts.statusDropOff, payload!),
          contains('Waybill Number: WB-BASE\nDeparture Time: 09:05 AM\n'));
    });

    test('omits the line when no departure was entered', () async {
      final payload =
          await const SmsPayloadBuilder().build(BTexts.statusDropOff, hd());
      expect(service.createMessage(BTexts.statusDropOff, payload!),
          isNot(contains('Departure')));
    });

    test('a blank or odd value never breaks the message', () async {
      for (final value in ['   ', 'N/A']) {
        final payload = await const SmsPayloadBuilder()
            .build(BTexts.statusDropOff, hd(departureAt: value));
        final message = service.createMessage(BTexts.statusDropOff, payload!);
        expect(message, contains('Waybill Number: WB-HD'), reason: value);
        expect(message, contains('Status: Drop Off.'), reason: value);
      }
    });

    test('other statuses never print it', () async {
      final payload = await const SmsPayloadBuilder()
          .build(BTexts.statusDispatch, hd(departureAt: '2026-11-25 15:30:00'));
      expect(service.createMessage(BTexts.statusDispatch, payload!),
          isNot(contains('Departure')));
    });
  });
}
