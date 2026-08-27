import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/image_outbox_item.dart';

void main() {
  group('ImageOutboxItem', () {
    test('maps legacy Uploaded status to Failed for outbox visibility', () {
      final item = ImageOutboxItem.fromMap(const {
        'RequestID': 101,
        'ImageType': 'Proof',
        'ImageLookupKey': '101',
        'RequestImage': 'abc123',
        'ApiStatus': 'Uploaded',
      });

      expect(item.requestId, '101');
      expect(item.imageType, 'Proof');
      expect(item.imageLookupKey, '101');
      expect(item.apiStatus, 'Failed');
      expect(item.isSynced, isFalse);
      expect(item.canRetry, isTrue);
    });

    test('defaults missing status to Pending and parses captured time', () {
      final item = ImageOutboxItem.fromMap(const {
        'RequestID': '55',
        'ImageType': 'Provincial_PickUp_Proof',
        'ImageLookupKey': '55_provincial_pick_up',
        'RequestImage': 'base64',
        'CapturedAt': '2026-04-30T08:30:00.000Z',
      });

      expect(item.apiStatus, 'Pending');
      expect(item.capturedAt, DateTime.parse('2026-04-30T08:30:00.000Z'));
      expect(item.canRetry, isTrue);
    });

    test('requires request id, image type, and image payload to retry', () {
      final missingType = ImageOutboxItem.fromMap(const {
        'RequestID': '55',
        'ImageLookupKey': '55',
        'RequestImage': 'base64',
      });
      final missingImage = ImageOutboxItem.fromMap(const {
        'RequestID': '55',
        'ImageType': 'Proof',
        'ImageLookupKey': '55',
      });

      expect(missingType.canRetry, isFalse);
      expect(missingImage.canRetry, isFalse);
    });
  });
}
