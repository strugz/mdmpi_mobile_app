import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';

void main() {
  group('PullOutModel.fromJson', () {
    test('reads PascalCase API keys', () {
      final model = PullOutModel.fromJson({
        'RequestID': 2025110001,
        'ClientID': '5efee5641f22272f3c7b49ba',
        'ClientContactPerson': 'Juan',
        'IRRFNumber': 'IRRF-001',
        'ReasonForReturn': 'Defective',
        'PullOutDate': '2025-11-14',
        'RequestStatus': 'For Pull Out',
        'TripTicketNumber': '1112223333',
        'Driver': 'JCA',
        'MobileID': 3,
        'MobileName': 'Isuzu',
        'DocumentReference': ['DRNo.:690005196', null],
      });

      expect(model.id, '2025110001');
      expect(model.clientId, '5efee5641f22272f3c7b49ba');
      expect(model.clientContactPerson, 'Juan');
      expect(model.irrfNumber, 'IRRF-001');
      expect(model.reasonForReturn, 'Defective');
      expect(model.pullOutDate, '2025-11-14');
      expect(model.requestStatus, 'For Pull Out');
      expect(model.tripTicketNumber, '1112223333');
      expect(model.driver, 'JCA');
      expect(model.mobileID, 3);
      expect(model.mobileName, 'Isuzu');
      expect(model.documentReference, ['DRNo.:690005196', '']);
    });

    test('falls back to camelCase keys and parses a string MobileID', () {
      final model = PullOutModel.fromJson({
        'requestId': 'R-1',
        'clientId': 'C-1',
        'releasedBy': 'Warehouse',
        'mobileID': '7',
      });

      expect(model.id, 'R-1');
      expect(model.clientId, 'C-1');
      expect(model.releasedBy, 'Warehouse');
      expect(model.mobileID, 7);
    });

    test('missing or null fields use empty defaults', () {
      final model = PullOutModel.fromJson({
        'RequestID': null,
        'MobileID': 'not-a-number',
        'DocumentReference': 'not-a-list',
      });

      expect(model.id, '');
      expect(model.clientId, '');
      expect(model.mobileID, isNull);
      expect(model.documentReference, isEmpty);
    });
  });
}
