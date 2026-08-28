import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/web_socket_client_identity.dart';

class FakeGetStorage implements GetStorage {
  final Map<String, dynamic> data = {};

  @override
  T? read<T>(String key) => data[key] as T?;

  @override
  Future<void> write(String key, dynamic value) async {
    data[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('WebSocketClientIdentity.resolve', () {
    test('generates, persists, and reuses a fallback id', () {
      final storage = FakeGetStorage();

      final first = WebSocketClientIdentity.resolve(storage: storage);
      final second = WebSocketClientIdentity.resolve(storage: storage);

      expect(first, isNotEmpty);
      expect(first, startsWith('anon.'));
      expect(second, first);
      expect(storage.data[WebSocketClientIdentity.storageKey], first);
    });

    test('sanitizes a stored id before using it', () {
      final storage = FakeGetStorage();
      storage.data[WebSocketClientIdentity.storageKey] = 'stored id!';

      expect(WebSocketClientIdentity.resolve(storage: storage), 'storedid');
    });

    test('regenerates when the stored id sanitizes to empty', () {
      final storage = FakeGetStorage();
      storage.data[WebSocketClientIdentity.storageKey] = '###';

      final resolved = WebSocketClientIdentity.resolve(storage: storage);

      expect(resolved, startsWith('anon.'));
      expect(storage.data[WebSocketClientIdentity.storageKey], resolved);
    });
  });
}
