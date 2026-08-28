import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_connection_config.dart';

void main() {
  group('WebSocketConnectionConfig.sanitizeClientId', () {
    test('passes a Firebase-uid-shaped id unchanged', () {
      const uid = 'aB3dE5fG7hI9jK1lM3nO5pQ7rS9t';

      expect(WebSocketConnectionConfig.sanitizeClientId(uid), uid);
    });

    test('keeps the full allowed character set', () {
      const id = 'user_1.device:2@site-3';

      expect(WebSocketConnectionConfig.sanitizeClientId(id), id);
    });

    test('strips illegal characters', () {
      expect(
        WebSocketConnectionConfig.sanitizeClientId('user id/#%ñ!'),
        'userid',
      );
    });

    test('trims and truncates to 64 characters', () {
      final long = 'a' * 100;

      expect(WebSocketConnectionConfig.sanitizeClientId(' $long '), 'a' * 64);
    });

    test('returns empty when nothing survives', () {
      expect(WebSocketConnectionConfig.sanitizeClientId('  ###  '), '');
    });
  });

  group('WebSocketConnectionConfig.endpointFor', () {
    test('includes apiKey, clientId, and role', () {
      final uri = WebSocketConnectionConfig.endpointFor(
        clientId: 'rider-01',
        role: 'rider',
      );

      expect(uri.queryParameters['apiKey'], isNotEmpty);
      expect(uri.queryParameters['clientId'], 'rider-01');
      expect(uri.queryParameters['role'], 'rider');
    });

    test('omits role when null', () {
      final uri = WebSocketConnectionConfig.endpointFor(clientId: 'rider-01');

      expect(uri.queryParameters.containsKey('role'), false);
    });

    test('omits clientId when it sanitizes to empty', () {
      final uri = WebSocketConnectionConfig.endpointFor(
        clientId: '###',
        role: 'watcher',
      );

      expect(uri.queryParameters.containsKey('clientId'), false);
      expect(uri.queryParameters['role'], 'watcher');
    });

    test('sanitizes the clientId it embeds', () {
      final uri = WebSocketConnectionConfig.endpointFor(
        clientId: 'user id!',
        role: 'watcher',
      );

      expect(uri.queryParameters['clientId'], 'userid');
    });
  });
}
