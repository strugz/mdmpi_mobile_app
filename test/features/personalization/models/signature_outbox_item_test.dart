import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/signature_outbox_item.dart';

void main() {
  group('SignatureOutboxItem', () {
    test('maps legacy Uploaded status to Failed for outbox visibility', () {
      final item = SignatureOutboxItem.fromMap(const {
        'RequestID': 101,
        'RequestReceiverSignature': 'abc123',
        'ApiStatus': 'Uploaded',
      });

      expect(item.requestId, '101');
      expect(item.apiStatus, 'Failed');
      expect(item.isSynced, isFalse);
      expect(item.canRetry, isTrue);
    });

    test('defaults missing status to Pending and parses captured time', () {
      final item = SignatureOutboxItem.fromMap(const {
        'RequestID': '55',
        'RequestReceiverSignature': 'base64',
        'CreatedAt': '2026-04-30T08:30:00.000Z',
      });

      expect(item.apiStatus, 'Pending');
      expect(item.capturedAt, DateTime.parse('2026-04-30T08:30:00.000Z'));
    });
  });
}

