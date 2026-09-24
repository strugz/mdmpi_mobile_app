import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/upload_candidate_classifier.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/upload_candidate.dart';

StandardDeliveryModel _r(String id, String status, {String category = '6'}) =>
    StandardDeliveryModel(
      id: id,
      clientId: 'client-123',
      shippingMethod: 'Land',
      deliveryTerms: 'Full',
      deliveryDate: '2026-09-24',
      preference: 'Medium',
      status: status,
      requestBy: 'MMA',
      createdBy: 'AMG',
      documentReference: const [],
      client: ClientModel.empty(),
      createdAt: '2026-09-24 08:00:00',
      formCategoryID: category,
    );

UploadCandidateGroup _group(String phone, String? server) =>
    BUploadCandidateClassifier.classifyOne(
            _r('1', phone), server == null ? null : _r('1', server))
        .group;

void main() {
  group('classifyOne', () {
    test('phone ahead of server is ready', () {
      expect(
          _group('For Delivery', 'Item Prepared'), UploadCandidateGroup.ready);
      expect(
          _group('Item Prepared', 'New Request'), UploadCandidateGroup.ready);
    });

    test('same status is same status, ignoring case and spaces', () {
      expect(_group('Item Prepared', 'Item Prepared'),
          UploadCandidateGroup.sameStatus);
      expect(_group('Getting supplies ready', ' Getting Supplies Ready '),
          UploadCandidateGroup.sameStatus);
    });

    test('server further along is server ahead', () {
      expect(_group('Item Prepared', 'For Delivery'),
          UploadCandidateGroup.serverAhead);
    });

    test('finished on the server is server ahead whatever the phone says', () {
      expect(_group('For Delivery', 'Delivered'),
          UploadCandidateGroup.serverAhead);
      expect(
          _group('Delivered', 'Cancelled'), UploadCandidateGroup.serverAhead);
      expect(_group('Item Prepared', 'Cancelled'),
          UploadCandidateGroup.serverAhead);
    });

    test('a status outside the flow is left for the server to judge', () {
      expect(_group('Back Load', 'Item Prepared'), UploadCandidateGroup.ready);
    });

    test('missing on the server is not on server', () {
      expect(_group('Item Prepared', null), UploadCandidateGroup.notOnServer);
    });

    test('the reason names both statuses', () {
      final c = BUploadCandidateClassifier.classifyOne(
          _r('7', 'Item Prepared'), _r('7', 'For Delivery'));
      expect(c.reason, 'Item Prepared on phone, For Delivery on server');
    });
  });

  test('classify drops New Request rows and orders ready first, newest first',
      () {
    final result = BUploadCandidateClassifier.classify(
      local: [
        _r('100', 'New Request'),
        _r('101', 'Item Prepared'), // same
        _r('102', 'For Delivery'), // ready
        _r('103', 'For Delivery'), // ready
        _r('104', 'Item Prepared'), // server ahead
        _r('105', 'Item Prepared', category: '8'), // not on server
      ],
      server: [
        _r('100', 'New Request'),
        _r('101', 'Item Prepared'),
        _r('102', 'Item Prepared'),
        _r('103', 'Item Prepared'),
        _r('104', 'Delivered'),
      ],
    );

    expect(result.map((c) => c.id), ['103', '102', '105', '101', '104']);
    expect(result.firstWhere((c) => c.id == '105').isHotlineDirect, isTrue);
  });

  test('only ready and not-on-server rows can be ticked', () {
    expect(UploadCandidateGroup.ready.isSelectable, isTrue);
    expect(UploadCandidateGroup.notOnServer.isSelectable, isTrue);
    expect(UploadCandidateGroup.sameStatus.isSelectable, isFalse);
    expect(UploadCandidateGroup.serverAhead.isSelectable, isFalse);
  });
}
