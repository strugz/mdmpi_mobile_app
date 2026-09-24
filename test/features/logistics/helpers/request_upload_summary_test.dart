import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/repositories/standard_delivery/delivery_update_outcome.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/request_upload_summary.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

StandardDeliveryModel _request(String id, String status) =>
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
      createdAt: '2026-09-17 08:54:45',
    );

void main() {
  test('skips New Request rows and tallies each outcome', () async {
    final sent = <String>[];
    final outcomes = {
      '1': const DeliveryUpdateOutcome.updated('Request updated successfully.'),
      '2': const DeliveryUpdateOutcome.rejected(
          'Request 2 is already Delivered on the server and can no longer be updated.'),
      '3': const DeliveryUpdateOutcome.failed('An error occurred: timeout'),
    };

    final summary = await RequestUploadSummary.run(
      [
        _request('0', 'New Request'),
        _request('1', 'Item Prepared'),
        _request('2', 'For Delivery'),
        _request('3', 'Getting supplies ready'),
      ],
      (request) async {
        sent.add(request.id);
        return outcomes[request.id]!;
      },
    );

    expect(sent, ['1', '2', '3']);
    expect(summary.uploaded, 1);
    expect(summary.skipped, [
      'Request 2 is already Delivered on the server and can no longer be updated.'
    ]);
    expect(summary.failed, ['Request 3: An error occurred: timeout']);
    expect(summary.isClean, isFalse);
  });

  test('message shows the uploaded count, skipped count and server reasons',
      () async {
    final summary = await RequestUploadSummary.run(
      [_request('1', 'Item Prepared'), _request('2026090145', 'Item Prepared')],
      (request) async => request.id == '1'
          ? const DeliveryUpdateOutcome.updated()
          : const DeliveryUpdateOutcome.rejected(
              'Request 2026090145 was changed on the server at 2026-09-17 13:38, '
              'after this Item Prepared update was made (2026-09-17 09:09); '
              'this copy is out of date.'),
    );

    expect(summary.title, 'Upload finished with skipped requests');
    expect(summary.message, contains('Uploaded 1 request.'));
    expect(summary.message, contains('Skipped 1'));
    expect(summary.message, contains('• Request 2026090145 was changed'));
    expect(summary.message, isNot(contains('Failed')));
  });

  test('lists at most three reasons, then "+N more"', () async {
    final summary = await RequestUploadSummary.run(
      List.generate(5, (i) => _request('$i', 'Item Prepared')),
      (request) async =>
          DeliveryUpdateOutcome.rejected('Request ${request.id} refused'),
    );

    expect(summary.message, contains('Uploaded 0 requests.'));
    expect(summary.message, contains('Skipped 5'));
    expect(summary.message, contains('• Request 2 refused'));
    expect(summary.message, isNot(contains('Request 3 refused')));
    expect(summary.message, contains('• +2 more'));
  });

  test('a clean upload reads as complete', () async {
    final summary = await RequestUploadSummary.run(
      [_request('1', 'Item Prepared'), _request('2', 'For Delivery')],
      (_) async => const DeliveryUpdateOutcome.updated(),
    );

    expect(summary.isClean, isTrue);
    expect(summary.title, 'Upload complete');
    expect(summary.message, 'Uploaded 2 requests.');
  });

  group('refreshSkipped', () {
    Future<RequestUploadSummary> skippedTwo() => RequestUploadSummary.run(
          [
            _request('1', 'Item Prepared'),
            _request('2026090145', 'Item Prepared'),
            _request('2026090210', 'Getting supplies ready'),
          ],
          (request) async => request.id == '1'
              ? const DeliveryUpdateOutcome.updated()
              : DeliveryUpdateOutcome.rejected('Request ${request.id} refused'),
        );

    test('replaces only the skipped requests with the server copy', () async {
      final summary = await skippedTwo();
      final replaced = <String>[];

      await summary.refreshSkipped(
        fetchServer: () async => [
          _request('1', 'For Delivery'),
          _request('2026090145', 'New Request'),
          _request('2026090210', 'For Delivery'),
          _request('999', 'New Request'),
        ],
        replaceLocal: (serverCopy) async =>
            replaced.add('${serverCopy.id}:${serverCopy.status}'),
      );

      expect(replaced, ['2026090145:New Request', '2026090210:For Delivery']);
      expect(summary.refreshed, 2);
      expect(summary.message,
          contains("This phone now has the server's copy of them."));
    });

    test('a skipped request missing from the server is left alone', () async {
      final summary = await skippedTwo();

      await summary.refreshSkipped(
        fetchServer: () async => [_request('2026090145', 'New Request')],
        replaceLocal: (_) async {},
      );

      expect(summary.refreshed, 1);
      expect(summary.message, contains("server's copy of 1 of them."));
    });

    test('a failed fetch says to hard reset instead', () async {
      final summary = await skippedTwo();

      await summary.refreshSkipped(
        fetchServer: () async => throw Exception('No internet connection'),
        replaceLocal: (_) async => fail('nothing to replace'),
      );

      expect(summary.refreshed, 0);
      expect(summary.refreshError, contains('No internet connection'));
      expect(summary.message, contains('Run Hard Reset Refresh'));
    });

    test('does not fetch when nothing was skipped', () async {
      final summary = await RequestUploadSummary.run(
        [_request('1', 'Item Prepared')],
        (_) async => const DeliveryUpdateOutcome.updated(),
      );
      var fetched = false;

      await summary.refreshSkipped(
        fetchServer: () async {
          fetched = true;
          return [];
        },
        replaceLocal: (_) async {},
      );

      expect(fetched, isFalse);
      expect(summary.message, 'Uploaded 1 request.');
    });
  });

  test('failures make the upload incomplete', () async {
    final summary = await RequestUploadSummary.run(
      [_request('1', 'Item Prepared')],
      (_) async => const DeliveryUpdateOutcome.failed('Status code: 500'),
    );

    expect(summary.title, 'Upload incomplete');
    expect(summary.message, contains('Failed 1 (try again later):'));
  });

  test('onProgress counts only the requests that are sent', () async {
    final progress = <(int, int)>[];

    await RequestUploadSummary.run(
      [
        _request('0', 'New Request'),
        _request('1', 'Item Prepared'),
        _request('2', 'For Delivery'),
      ],
      (request) async => const DeliveryUpdateOutcome.updated(),
      onProgress: (done, total) => progress.add((done, total)),
    );

    expect(progress, [(0, 2), (1, 2), (2, 2)]);
  });

  test('nothing to send says so instead of "Uploaded 0 requests"', () async {
    final summary = await RequestUploadSummary.run(
      [_request('0', 'New Request')],
      (request) async => const DeliveryUpdateOutcome.updated(),
    );

    expect(summary.attempted, 0);
    expect(summary.title, 'Nothing to upload');
    expect(summary.message, isNot(contains('Uploaded')));
  });

  test('same-status replies are counted apart from uploads', () async {
    final summary = await RequestUploadSummary.run(
      [
        _request('1', 'Item Prepared'),
        _request('2', 'Item Prepared'),
        _request('3', 'For Delivery'),
        _request('4', 'Item Prepared'),
        _request('5', 'Item Prepared'),
      ],
      (request) async => request.id == '3'
          ? const DeliveryUpdateOutcome.updated('ok')
          : const DeliveryUpdateOutcome.updated('ok', true),
    );

    expect(summary.uploaded, 1);
    expect(summary.sameStatus, 4);
    expect(summary.attempted, 5);
    expect(summary.title, 'Upload complete');
    expect(summary.message,
        'Uploaded 1 request.\n4 requests have the same status as the server.');
  });

  test('only same-status replies means already up to date', () async {
    final summary = await RequestUploadSummary.run(
      [_request('1', 'Item Prepared')],
      (request) async => const DeliveryUpdateOutcome.updated('ok', true),
    );

    expect(summary.title, 'Already up to date');
    expect(summary.message, contains('1 request has the same status'));
  });

  group('runSkippingSameStatus', () {
    test('does not send requests the server already has at that status',
        () async {
      final sent = <String>[];
      final summary = await RequestUploadSummary.runSkippingSameStatus(
        [
          _request('1', 'Item Prepared'),
          _request('2', 'For Delivery'),
          _request('3', 'New Request'),
        ],
        (request) async {
          sent.add(request.id);
          return const DeliveryUpdateOutcome.updated();
        },
        fetchServer: () async => [
          _request('1', 'item prepared'),
          _request('2', 'Item Prepared'),
          _request('3', 'New Request'),
        ],
      );

      expect(sent, ['2']);
      expect(summary.uploaded, 1);
      expect(summary.sameStatus, 1);
    });

    test('sends everything when the server list cannot be fetched', () async {
      final sent = <String>[];
      final summary = await RequestUploadSummary.runSkippingSameStatus(
        [_request('1', 'Item Prepared')],
        (request) async {
          sent.add(request.id);
          return const DeliveryUpdateOutcome.updated();
        },
        fetchServer: () async => throw Exception('offline'),
      );

      expect(sent, ['1']);
      expect(summary.sameStatus, 0);
    });
  });
}
