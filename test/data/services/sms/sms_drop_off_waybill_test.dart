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
}
