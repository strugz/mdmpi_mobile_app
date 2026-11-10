import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/unfinished/unfinished_requests.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/unfinished/unfinished_request.dart';

/// Which Logistics requests count as unfinished, and who hears about them
/// (docs/application/UNFINISHED_REQUESTS_REMINDER_PLAN.md).

UnfinishedRequest _req(
  FormCategoryType type,
  String status, {
  String id = '1',
  String createdBy = '',
  String driver = '',
  String helper = '',
  String createdAt = '',
}) =>
    UnfinishedRequest(
      type: type,
      id: id,
      client: 'ABC Trading',
      status: status,
      createdAt: createdAt,
      createdBy: createdBy,
      driver: driver,
      helper: helper,
    );

UnfinishedSummary _for(List<UnfinishedRequest> all, String roles,
        {String initial = 'JDC'}) =>
    BUnfinishedRequests.summarize(all, roleField: roles, initial: initial);

void main() {
  group('isFinished', () {
    const finals = {
      FormCategoryType.standardDelivery: ['Delivered', 'Cancelled'],
      FormCategoryType.hotlineDirect: ['Delivered', 'Cancelled'],
      FormCategoryType.pullOutReturn: ['Taken Out', 'Picked-up', 'Cancelled'],
      FormCategoryType.stockReceive: ['Taken Out', 'Picked-up', 'Cancelled'],
      FormCategoryType.pickUp: ['Received', 'Cancelled'],
      FormCategoryType.airSea: [
        'Received',
        'Drop Off',
        'Provincial Delivered',
        'Cancelled'
      ],
      FormCategoryType.airSeaHd: [
        'Received',
        'Drop Off',
        'Provincial Delivered',
        'Cancelled'
      ],
    };

    test('every final status of every type is finished, in any case', () {
      for (final entry in finals.entries) {
        for (final status in entry.value) {
          expect(BUnfinishedRequests.isFinished(entry.key, status), isTrue,
              reason: '${entry.key} $status');
          expect(
              BUnfinishedRequests.isFinished(
                  entry.key, ' ${status.toUpperCase()} '),
              isTrue,
              reason: '${entry.key} $status upper-cased');
        }
      }
    });

    test('middle statuses and Back Load are unfinished', () {
      const middle = {
        FormCategoryType.standardDelivery: [
          'New Request',
          'Getting supplies ready',
          'Getting Supplies Ready',
          'Item Prepared',
          'For Delivery',
          'Back Load',
        ],
        FormCategoryType.pullOutReturn: [
          'New Request',
          'For Pull Out',
          'In Transit'
        ],
        FormCategoryType.stockReceive: ['New Request', 'In Transit'],
        FormCategoryType.pickUp: [
          'New Request',
          'Getting supplies ready',
          'Item Packed'
        ],
        FormCategoryType.airSea: [
          'New Request',
          'Item Packed',
          'Endorsed to Guard',
          'For Dispatch',
          'Dispatch',
          'Provincial Pick Up',
          'Provincial In Transit',
        ],
      };
      for (final entry in middle.entries) {
        for (final status in entry.value) {
          expect(BUnfinishedRequests.isFinished(entry.key, status), isFalse,
              reason: '${entry.key} $status');
        }
      }
    });

    test('a blank status is not reported', () {
      expect(
          BUnfinishedRequests.isFinished(FormCategoryType.pickUp, '  '), isTrue);
    });
  });

  group('who hears about what', () {
    final all = [
      _req(FormCategoryType.standardDelivery, 'New Request', id: 'sd-new'),
      _req(FormCategoryType.standardDelivery, 'For Delivery',
          id: 'sd-mine', driver: 'jdc'),
      _req(FormCategoryType.standardDelivery, 'For Delivery',
          id: 'sd-other', driver: 'MRS'),
      _req(FormCategoryType.standardDelivery, 'Delivered', id: 'sd-done'),
      _req(FormCategoryType.stockReceive, 'New Request',
          id: 'sr-helper', helper: 'JDC'),
      _req(FormCategoryType.pickUp, 'Item Packed',
          id: 'pu-mine', createdBy: 'JDC'),
      _req(FormCategoryType.airSea, 'Provincial Pick Up', id: 'as-prov'),
      _req(FormCategoryType.airSea, 'Drop Off', id: 'as-done'),
    ];

    List<String> ids(UnfinishedSummary s) =>
        s.requests.map((r) => r.id).toList()..sort();

    test('Admin and Viewer see every unfinished request', () {
      const expected = [
        'as-prov',
        'pu-mine',
        'sd-mine',
        'sd-new',
        'sd-other',
        'sr-helper'
      ];
      expect(ids(_for(all, 'Admin')), expected);
      expect(ids(_for(all, 'Viewer')), expected);
    });

    test('Courier sees only the ones they are crew on, awaiting a courier',
        () {
      expect(ids(_for(all, 'Courier')), ['sd-mine', 'sr-helper']);
    });

    test('Release sees the ones waiting on preparation', () {
      expect(ids(_for(all, 'Release')), ['pu-mine', 'sd-new']);
    });

    test('Request sees the ones they raised', () {
      expect(ids(_for(all, 'Request')), ['pu-mine']);
    });

    test('Provincial sees the provincial leg', () {
      expect(ids(_for(all, 'Provincial')), ['as-prov']);
    });

    test('several roles combine without counting a request twice', () {
      final s = _for(all, 'Request, Release, Courier');
      expect(ids(s), ['pu-mine', 'sd-mine', 'sd-new', 'sr-helper']);
      expect(s.total, 4);
    });

    test('no roles or no initial sees nothing of their own', () {
      expect(_for(all, '').total, 0);
      expect(_for(all, 'Courier', initial: '').total, 0);
    });
  });

  group('summary', () {
    test('oldest first, counts by type, and the notification text', () {
      final s = _for([
        _req(FormCategoryType.pullOutReturn, 'For Pull Out',
            id: 'b', createdAt: '2026-10-05T09:00:00'),
        _req(FormCategoryType.standardDelivery, 'For Delivery',
            id: 'c', createdAt: '2026-10-07T09:00:00'),
        _req(FormCategoryType.standardDelivery, 'Item Prepared',
            id: 'a', createdAt: '2026-10-01T09:00:00'),
      ], 'Admin');
      expect(s.requests.map((r) => r.id), ['a', 'b', 'c']);
      expect(s.byType, {
        FormCategoryType.standardDelivery: 2,
        FormCategoryType.pullOutReturn: 1,
      });
      expect(s.title, '3 unfinished requests');
      expect(s.body, 'Standard Delivery 2 · Pull Out 1. Tap to see them.');
    });

    test('one request reads in the singular', () {
      final s = _for(
          [_req(FormCategoryType.pickUp, 'New Request')], 'Admin');
      expect(s.title, '1 unfinished request');
      expect(s.body, 'Pick Up 1. Tap to see it.');
    });
  });

  group('from the request models', () {
    test('Hotline Direct and Standard Delivery split by form category', () {
      final sd = StandardDeliveryModel.empty()
        ..id = '10'
        ..status = 'For Delivery'
        ..deliveredBy = 'JDC'
        ..formCategoryID = '6';
      final hd = StandardDeliveryModel.empty()..formCategoryID = '8';
      final r = BUnfinishedRequests.fromStandardDelivery(sd);
      expect(r.type, FormCategoryType.standardDelivery);
      expect(r.driver, 'JDC');
      expect(r.source, same(sd));
      expect(BUnfinishedRequests.fromStandardDelivery(hd).type,
          FormCategoryType.hotlineDirect);
    });

    test('Stock Receive and Pull Out split by form category', () {
      expect(
          BUnfinishedRequests.fromPullOut(PullOutModel(formCategoryId: '9'))
              .type,
          FormCategoryType.stockReceive);
      expect(
          BUnfinishedRequests.fromPullOut(PullOutModel(formCategoryId: '4'))
              .type,
          FormCategoryType.pullOutReturn);
    });

    test('Air / Sea / Land HD splits from the base tab', () {
      expect(
          BUnfinishedRequests.fromAirSea(AirSeaModel(formCategoryID: '21'))
              .type,
          FormCategoryType.airSeaHd);
      expect(BUnfinishedRequests.fromAirSea(AirSeaModel()).type,
          FormCategoryType.airSea);
    });
  });
}
