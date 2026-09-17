import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';
import 'package:mdmpi_mobile_app/features/collection/models/activity_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The count beside an area is a promise: pick it and the list holds this
/// many. It broke that promise by counting the master account list, which
/// carries every client the server has sent, including ones whose invoices
/// are already claimed into an engagement or settled to zero. The area picker
/// offered "Medical Imaging 45" and the list then showed 44.

/// onInit resolves the repository and sync manager from DI and starts a load;
/// none of that belongs in a counting test, so it is deliberately not called.
class _Stub extends CollectionActivityController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

ClientModel _client(String id, String code) => ClientModel(
      id: id,
      code: code,
      name: 'Account $id',
      address: '',
      contact: '',
      emailAddress: '',
    );

CollectionItemModel _invoice(
  String id,
  ClientModel c,
  double due, {
  String dueDate = '2999-01-01',
}) =>
    CollectionItemModel(
        id: id, client: c, toBeCollected: due, dueDate: dueDate);

void main() {
  late _Stub controller;

  setUp(() {
    controller = Get.put<CollectionActivityController>(_Stub()) as _Stub;
    controller.startAggregateTracking();
  });

  tearDown(Get.reset);

  test('the count equals the list an area produces', () {
    final withInvoice = _client('1', 'RAD-1');
    final claimedAway = _client('2', 'RAD-2');
    final settled = _client('3', 'RAD-3');

    // All three are known accounts, but only one has something to collect in
    // the bucket: the second is claimed into an engagement, the third is paid.
    controller.masterAccountList.assignAll([withInvoice, claimedAway, settled]);
    controller.bucketItems.assignAll([
      _invoice('a', withInvoice, 20000),
      _invoice('c', settled, 0),
    ]);
    controller.activityItems.assignAll([_invoice('b', claimedAway, 34000)]);

    expect(controller.accountCountForArea('RAD'), 1);

    controller.selectedArea.value = 'RAD';
    expect(controller.bucketAccounts.length,
        controller.accountCountForArea('RAD'));
  });

  test('counts follow the filters in force, so the promise holds', () {
    final late = _client('1', 'NLN-1');
    final future = _client('2', 'NLN-2');
    controller.masterAccountList.assignAll([late, future]);
    controller.bucketItems.assignAll([
      _invoice('a', late, 5000, dueDate: '2020-01-01'),
      _invoice('b', future, 5000),
    ]);

    expect(controller.accountCountForArea('NLN'), 2);

    controller.bucketFilterSpec.value =
        const ActivityFilter(due: DueBand.overdue, sort: ActivitySort.name);
    expect(controller.accountCountForArea('NLN'), 1,
        reason: 'only the overdue one survives the filter');

    controller.selectedArea.value = 'NLN';
    expect(controller.bucketAccounts.length, 1);
  });

  test('an empty area reports none, and shows none', () {
    final luzon = _client('1', 'NLN-1');
    controller.masterAccountList.assignAll([luzon]);
    controller.bucketItems.assignAll([_invoice('a', luzon, 5000)]);

    expect(controller.accountCountForArea('VIS'), 0);
    expect(controller.accountCountForArea(BCollectionArea.others), 0);

    controller.selectedArea.value = 'VIS';
    expect(controller.bucketAccounts, isEmpty);
  });

  test('all areas counts every account the bucket can show', () {
    final a = _client('1', 'NLN-1');
    final b = _client('2', 'VIS-1');
    final claimed = _client('3', 'MIN-1');
    controller.masterAccountList.assignAll([a, b, claimed]);
    controller.bucketItems.assignAll([
      _invoice('a', a, 100),
      _invoice('b', b, 200),
    ]);
    controller.activityItems.assignAll([_invoice('c', claimed, 300)]);

    expect(controller.accountCountForArea(''), 2);
    expect(controller.bucketAccounts.length, 2);
  });
}
