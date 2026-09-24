import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/repositories/standard_delivery/delivery_update_outcome.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/upload_data_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/upload_date_filter.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/upload_candidate.dart';

StandardDeliveryModel _r(String id, String status,
        [String date = '2026-09-24']) =>
    StandardDeliveryModel(
      id: id,
      clientId: 'client-123',
      shippingMethod: 'Land',
      deliveryTerms: 'Full',
      deliveryDate: date,
      preference: 'Medium',
      status: status,
      requestBy: 'MMA',
      createdBy: 'AMG',
      documentReference: const [],
      client: ClientModel.empty(),
      createdAt: '2026-09-24 08:00:00',
    );

/// Phone: 1 ready, 2 ready (due tomorrow), 3 same, 4 server ahead,
/// 5 not on server. "Today" is pinned to 24 Sep.
final _local = [
  _r('1', 'For Delivery'),
  _r('2', 'Item Prepared', '2026-09-25'),
  _r('3', 'Item Prepared'),
  _r('4', 'Item Prepared'),
  _r('5', 'Item Prepared'),
];
final _server = [
  _r('1', 'Item Prepared'),
  _r('2', 'Getting supplies ready'),
  _r('3', 'Item Prepared'),
  _r('4', 'Delivered'),
];

void main() {
  late List<String> sent;
  late List<String> replaced;
  late bool online;

  UploadDataController build() => UploadDataController(
        loadLocal: () async => _local,
        loadServer: () async => _server,
        send: (request) async {
          sent.add(request.id);
          return const DeliveryUpdateOutcome.updated(
              'Request updated successfully.');
        },
        replaceLocal: (copy) async => replaced.add(copy.id),
        isOnline: () async => online,
        now: () => DateTime(2026, 9, 24, 10),
      );

  setUp(() {
    Get.testMode = true;
    sent = [];
    replaced = [];
    online = true;
  });

  tearDown(Get.reset);

  test('load groups the requests and ticks only the ready ones', () async {
    final c = build();
    await c.load();

    expect(c.countOf(UploadCandidateGroup.ready), 2);
    expect(c.countOf(UploadCandidateGroup.sameStatus), 1);
    expect(c.countOf(UploadCandidateGroup.serverAhead), 1);
    expect(c.countOf(UploadCandidateGroup.notOnServer), 1);
    expect(c.selectedIds, {'1', '2'});
  });

  test('same-status and server-ahead rows cannot be ticked', () async {
    final c = build();
    await c.load();
    for (final id in ['3', '4']) {
      c.toggle(c.candidates.firstWhere((x) => x.id == id));
    }
    expect(c.selectedIds, {'1', '2'});

    c.toggle(c.candidates.firstWhere((x) => x.id == '5'));
    expect(c.selectedIds, {'1', '2', '5'});
  });

  test('select all toggles the ready group only', () async {
    final c = build();
    await c.load();
    expect(c.allReadySelected, isTrue);
    c.toggleAllReady();
    expect(c.selectedIds, isEmpty);
    c.toggleAllReady();
    expect(c.selectedIds, {'1', '2'});
  });

  test('upload sends only the ticked requests and reports same status',
      () async {
    final c = build();
    await c.load();
    c.toggle(c.candidates.firstWhere((x) => x.id == '2')); // untick 2

    final progress = <(int, int)>[];
    final result = await c.uploadSelected((d, t) => progress.add((d, t)));

    expect(sent, ['1']);
    expect(progress, [(0, 1), (1, 1)]);
    final summary = result.value;
    expect(summary.uploaded, 1);
    expect(summary.sameStatus, 1);
    expect(summary.message,
        contains('1 request has the same status as the server.'));
  });

  test('offline shows the offline state and nothing to tick', () async {
    online = false;
    final c = build();
    await c.load();
    expect(c.isOffline.value, isTrue);
    expect(c.candidates, isEmpty);
    expect(c.selectedIds, isEmpty);
  });

  test('a failed comparison is reported, not thrown', () async {
    final c = UploadDataController(
      loadLocal: () async => _local,
      loadServer: () async => throw Exception('502'),
      send: (_) async => const DeliveryUpdateOutcome.updated(),
      replaceLocal: (_) async {},
      isOnline: () async => true,
    );
    await c.load();
    expect(c.loadError.value, contains('502'));
    expect(c.candidates, isEmpty);
  });

  test('take server copy replaces the server-ahead rows on the phone',
      () async {
    final c = build();
    await c.load();
    final result = await c.takeServerCopies();
    expect(result.value, 1);
    expect(replaced, ['4']);
  });

  test('the date filter narrows counts, ticks and the upload', () async {
    final c = build();
    await c.load();
    c.setDateFilter(UploadDateFilter.today);

    // Request 2 is due tomorrow: hidden, so not counted or sent even though
    // it is still ticked.
    expect(c.countOf(UploadCandidateGroup.ready), 1);
    expect(c.selectedIds, contains('2'));
    expect(c.selected.map((x) => x.id), ['1']);

    await c.uploadSelected((_, __) {});
    expect(sent, ['1']);
  });

  test('a range filter needs a range, and All clears it', () async {
    final c = build();
    await c.load();
    c.setDateFilter(UploadDateFilter.range);
    expect(c.dateFilter.value, UploadDateFilter.all);

    c.setDateFilter(UploadDateFilter.range,
        range: UploadDateRange(DateTime(2026, 9, 25), DateTime(2026, 9, 25)));
    expect(c.visible.map((x) => x.id), ['2']);

    c.setDateFilter(UploadDateFilter.all);
    expect(c.dateRange.value, isNull);
    expect(c.visible, hasLength(5));
  });
}
