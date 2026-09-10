import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/utils/role_resolver.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/crew_assignment.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

StandardDeliveryModel _request({
  required String status,
  String driver = 'BPT',
  String helper = '',
}) =>
    StandardDeliveryModel(
      id: '01002',
      clientId: 'C1',
      shippingMethod: 'Land',
      deliveryTerms: 'Full',
      deliveryDate: '2026-09-10',
      preference: 'Medium',
      status: status,
      requestBy: 'EBP',
      createdBy: 'EBP',
      deliveredBy: driver,
      helper: helper,
      documentReference: const ['DR1'],
      client: ClientModel.empty(),
      createdAt: '2026-09-10 12:00:00',
    );

void main() {
  group('CrewAssignment.isCrew', () {
    test('matches the driver', () {
      expect(
          CrewAssignment.isCrew(driver: 'BPT', helper: '', userInitial: 'BPT'),
          isTrue);
    });

    test('matches the helper', () {
      expect(
          CrewAssignment.isCrew(
              driver: 'BPT', helper: 'JDC', userInitial: 'JDC'),
          isTrue);
    });

    test('trims and ignores case (API values can carry whitespace)', () {
      expect(
          CrewAssignment.isCrew(
              driver: ' bpt ', helper: '', userInitial: 'BPT'),
          isTrue);
    });

    test('someone else is not crew', () {
      expect(
          CrewAssignment.isCrew(
              driver: 'BPT', helper: 'JDC', userInitial: 'JCA'),
          isFalse);
    });

    test('an empty helper slot never matches an empty initial', () {
      // Today `'' == ''` is true; that must not grant access.
      expect(CrewAssignment.isCrew(driver: 'BPT', helper: '', userInitial: ''),
          isFalse);
      expect(CrewAssignment.isCrew(driver: '', helper: '', userInitial: ''),
          isFalse);
    });
  });

  group('CrewAssignment.isCourierOnly', () {
    test('sole Courier, with or without Viewer', () {
      expect(CrewAssignment.isCourierOnly(RoleResolver.parseRoles('Courier')),
          isTrue);
      expect(
          CrewAssignment.isCourierOnly(
              RoleResolver.parseRoles('Courier, Viewer')),
          isTrue);
    });

    test('a back-office role lifts the restriction', () {
      expect(
          CrewAssignment.isCourierOnly(
              RoleResolver.parseRoles('Release,Courier')),
          isFalse);
      expect(CrewAssignment.isCourierOnly(RoleResolver.parseRoles('Release')),
          isFalse);
      expect(CrewAssignment.isCourierOnly(const <String>[]), isFalse);
    });
  });

  group('CrewAssignment.canOperate / isCrewOnlyStatus', () {
    test('only Item Prepared and For Delivery are crew-only', () {
      expect(CrewAssignment.isCrewOnlyStatus(BTexts.statusItemPrepared), isTrue);
      expect(CrewAssignment.isCrewOnlyStatus(BTexts.statusForDelivery), isTrue);
      expect(CrewAssignment.isCrewOnlyStatus(BTexts.statusNewRequest), isFalse);
      expect(CrewAssignment.isCrewOnlyStatus(BTexts.statusGettingSuppliesReady),
          isFalse);
      expect(CrewAssignment.isCrewOnlyStatus(BTexts.statusDoneDelivery), isFalse);
    });

    test('the screenshot case: For Delivery, driver BPT, user JCA → no', () {
      final r = _request(status: BTexts.statusForDelivery);
      expect(CrewAssignment.canOperate(r, userInitial: 'JCA'), isFalse);
      expect(CrewAssignment.canOperate(r, userInitial: 'BPT'), isTrue);
    });

    test('helper may operate at Item Prepared and For Delivery', () {
      for (final s in [BTexts.statusItemPrepared, BTexts.statusForDelivery]) {
        final r = _request(status: s, helper: 'JDC');
        expect(CrewAssignment.canOperate(r, userInitial: 'JDC'), isTrue,
            reason: s);
      }
    });

    test('earlier statuses are open to any courier', () {
      final r = _request(status: BTexts.statusGettingSuppliesReady, driver: '');
      expect(CrewAssignment.canOperate(r, userInitial: 'JCA'), isTrue);
    });

    test('describeCrew joins driver and helper', () {
      expect(CrewAssignment.describeCrew(_request(status: 'x')), 'BPT');
      expect(
          CrewAssignment.describeCrew(_request(status: 'x', helper: 'JDC')),
          'BPT / JDC');
    });
  });
}
