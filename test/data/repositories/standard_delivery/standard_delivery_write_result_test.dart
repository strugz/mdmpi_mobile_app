import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mdmpi_mobile_app/data/repositories/standard_delivery/delivery_update_outcome.dart';
import 'package:mdmpi_mobile_app/data/repositories/standard_delivery/standard_delivery_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

/// The SMS a create, status update or cancellation triggers must never go out
/// when the server rejected the write — the recipient would be told about a
/// delivery, a status or a cancellation that does not exist. The data managers
/// gate on these return values, so each one has to be honest about what the
/// API answered.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Snackbars have no overlay here; BLoaders short-circuits in test mode.
  Get.testMode = true;

  setUp(() {
    dotenv.testLoad(fileInput: 'API4_URL=https://example.invalid');
  });
  tearDown(dotenv.clean);

  StandardDeliveryModel newRequest() => StandardDeliveryModel(
        id: '2025110006',
        clientId: 'client-123',
        shippingMethod: 'Land',
        deliveryTerms: 'Full',
        deliveryDate: '2025-11-06',
        preference: 'Medium',
        status: 'New Request',
        requestBy: 'JCA',
        createdBy: 'JCA',
        documentReference: const ['DR1'],
        client: ClientModel.empty(),
        createdAt: DateTime.now().toString(),
      );

  test('returns true when the server created the request', () async {
    final client = MockClient((_) async => http.Response('', 201));

    final saved = await StandardDeliveryRepository()
        .insertDelivery(newRequest(), null, client);

    expect(saved, isTrue);
  });

  test('returns false when the server rejects the request', () async {
    final client = MockClient((_) async => http.Response('boom', 500));

    final saved = await StandardDeliveryRepository()
        .insertDelivery(newRequest(), null, client);

    expect(saved, isFalse);
  });

  test('returns false when the POST never reaches the server', () async {
    final client = MockClient((_) async => throw const SocketLikeFailure());

    final saved = await StandardDeliveryRepository()
        .insertDelivery(newRequest(), null, client);

    expect(saved, isFalse);
  });

  group('updateDelivery', () {
    test('returns true when the server confirms the update', () async {
      final client = MockClient(
          (_) async => http.Response('"Request updated successfully."', 200));

      final updated = await StandardDeliveryRepository()
          .updateDelivery(newRequest(), 'JCA', client: client);

      expect(updated, isTrue);
    });

    test('returns false when the server rejects the update', () async {
      final client =
          MockClient((_) async => http.Response('"Request not found."', 404));

      final updated = await StandardDeliveryRepository()
          .updateDelivery(newRequest(), 'JCA', client: client);

      expect(updated, isFalse);
    });

    // The backend answers a successful update with exactly
    // "Request updated successfully." (RequestController.UpdateRequest), so a
    // 200 saying anything else is not a confirmed update and must not text
    // the client.
    test('returns false on a 200 that does not confirm the update', () async {
      final client = MockClient(
          (_) async => http.Response('{"error":"Nothing was updated."}', 200));

      final updated = await StandardDeliveryRepository()
          .updateDelivery(newRequest(), 'JCA', client: client);

      expect(updated, isFalse);
    });

    test('returns false when the PATCH never reaches the server', () async {
      final client = MockClient((_) async => throw const SocketLikeFailure());

      final updated = await StandardDeliveryRepository()
          .updateDelivery(newRequest(), 'JCA', client: client);

      expect(updated, isFalse);
    });

    test('returns false when the server refuses a stale copy (409)', () async {
      final client = MockClient((_) async => http.Response(
          '{"error":"Request 2025110006 is already Delivered on the server and can no longer be updated."}',
          409));

      final updated = await StandardDeliveryRepository()
          .updateDelivery(newRequest(), 'JCA', client: client);

      expect(updated, isFalse);
    });
  });

  // Settings > Upload Data summarises many of these, so each answer has to be
  // classified: refused by the server (skipped, with its reason) or failed.
  group('sendUpdate', () {
    test('a 409 is rejected, carrying the server reason', () async {
      final client = MockClient((_) async => http.Response(
          '{"error":"Request 2025110006 is already Delivered on the server and can no longer be updated."}',
          409));

      final outcome = await StandardDeliveryRepository()
          .sendUpdate(newRequest(), 'JCA', client: client);

      expect(outcome.status, DeliveryUpdateStatus.rejected);
      expect(outcome.message, contains('already Delivered'));
    });

    test('a confirmed 200 is updated', () async {
      final client = MockClient(
          (_) async => http.Response('"Request updated successfully."', 200));

      final outcome = await StandardDeliveryRepository()
          .sendUpdate(newRequest(), 'JCA', client: client);

      expect(outcome.status, DeliveryUpdateStatus.updated);
    });

    test('reads sameStatus from the server reply', () async {
      Future<DeliveryUpdateOutcome> reply(String body) =>
          StandardDeliveryRepository().sendUpdate(newRequest(), 'JCA',
              client: MockClient((_) async => http.Response(body, 200)));

      final same = await reply(
          '{"message":"Request updated successfully.","sameStatus":true}');
      final moved = await reply(
          '{"message":"Request updated successfully.","sameStatus":false}');
      final olderServer = await reply('"Request updated successfully."');

      expect(same.isUpdated, isTrue);
      expect(same.sameStatus, isTrue);
      expect(moved.sameStatus, isFalse);
      expect(olderServer.isUpdated, isTrue);
      expect(olderServer.sameStatus, isFalse);
    });

    test('other errors are failed, not rejected', () async {
      final notFound = await StandardDeliveryRepository().sendUpdate(
          newRequest(), 'JCA',
          client: MockClient((_) async => http.Response('"nope"', 404)));
      final offline = await StandardDeliveryRepository().sendUpdate(
          newRequest(), 'JCA',
          client: MockClient((_) async => throw const SocketLikeFailure()));

      expect(notFound.status, DeliveryUpdateStatus.failed);
      expect(offline.status, DeliveryUpdateStatus.failed);
    });
  });

  group('cancelDelivery', () {
    test('returns true when the server accepts the cancellation', () async {
      final client = MockClient((_) async =>
          http.Response('{"message":"Request cancelled successfully."}', 200));

      final cancelled = await StandardDeliveryRepository()
          .cancelDelivery('2025110006', 'Client moved', 'JCA', client: client);

      expect(cancelled, isTrue);
    });

    test('returns false when the server rejects the cancellation', () async {
      final client =
          MockClient((_) async => http.Response('"Request not found."', 404));

      final cancelled = await StandardDeliveryRepository()
          .cancelDelivery('2025110006', 'Client moved', 'JCA', client: client);

      expect(cancelled, isFalse);
    });

    test('returns false when the PATCH never reaches the server', () async {
      final client = MockClient((_) async => throw const SocketLikeFailure());

      final cancelled = await StandardDeliveryRepository()
          .cancelDelivery('2025110006', 'Client moved', 'JCA', client: client);

      expect(cancelled, isFalse);
    });
  });
}

class SocketLikeFailure implements Exception {
  const SocketLikeFailure();
  @override
  String toString() => 'Connection failed';
}
