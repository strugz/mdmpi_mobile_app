import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';

void main() {
  group('BApiEnvironment WebSocket resolution', () {
    test('toWebSocketUri swaps https to wss', () {
      final uri = BApiEnvironment.toWebSocketUri(
        'https://inventory.mdmpi.com.ph',
        '/api/ws',
      );

      expect(uri.scheme, 'wss');
      expect(uri.host, 'inventory.mdmpi.com.ph');
      expect(uri.path, '/api/ws');
    });

    test('toWebSocketUri swaps http to ws and keeps the port', () {
      final uri = BApiEnvironment.toWebSocketUri(
        'http://192.168.1.10:5222',
        'api/ws',
      );

      expect(uri.scheme, 'ws');
      expect(uri.host, '192.168.1.10');
      expect(uri.port, 5222);
      expect(uri.path, '/api/ws');
    });

    test('toWebSocketUri tolerates a trailing slash on the base', () {
      final uri = BApiEnvironment.toWebSocketUri(
        'https://inventory.mdmpi.com.ph/',
        '/api/ws',
      );

      expect(uri.toString(), 'wss://inventory.mdmpi.com.ph/api/ws');
    });

    test('release resolution always targets the live /api2/ws endpoint', () {
      final uri =
          BApiEnvironment.resolveWebSocketBaseUri(allowLocalOverrides: false);

      expect(uri.toString(), 'wss://inventory.mdmpi.com.ph/api2/ws');
    });

    test(
        'debug resolution without api4 overrides falls back to the live /api2/ws',
        () {
      // The live host only serves /api2/ws; /api/ws exists only on MDMPI.App.
      final uri =
          BApiEnvironment.resolveWebSocketBaseUri(allowLocalOverrides: true);

      expect(uri.toString(), 'wss://inventory.mdmpi.com.ph/api2/ws');
    });

    test('debug resolution with an api4 override targets its /api2/ws', () {
      dotenv.testLoad(fileInput: 'API4_URL=http://localhost:5177');
      addTearDown(dotenv.clean);

      final uri =
          BApiEnvironment.resolveWebSocketBaseUri(allowLocalOverrides: true);

      expect(uri.toString(), 'ws://localhost:5177/api2/ws');
    });

    test('an api4 override equal to the live host still uses /api2/ws', () {
      dotenv.testLoad(fileInput: 'API4_URL=https://inventory.mdmpi.com.ph');
      addTearDown(dotenv.clean);

      final uri =
          BApiEnvironment.resolveWebSocketBaseUri(allowLocalOverrides: true);

      expect(uri.toString(), 'wss://inventory.mdmpi.com.ph/api2/ws');
    });
  });
}
