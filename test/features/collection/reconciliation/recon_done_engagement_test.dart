import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_account_history_dao.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/reconciliation_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// Done Engagement ends the visit, not the reconciliation: the account's
/// case stays with the collector, in Mine, for its next steps. Only Defer
/// releases it.

class _Tracker extends ReconciliationRepository {
  final released = <String>[];

  @override
  Future<Result<int>> releaseCasesFor(String clientCode,
      {String remarks = ''}) async {
    released.add(clientCode);
    return Result.success(1);
  }
}

class _Repo extends CollectionRepository {
  @override
  String get collectorName => 'Jay';

  @override
  Future<CollectionAccountHistoryRecord?> releaseInvoices({
    required String clientId,
    required List<CollectionItemModel> releasedInvoices,
    String? reason,
    String remarks = '',
  }) async =>
      null;
}

class _Activity extends CollectionActivityController {
  @override
  // ignore: must_call_super
  void onInit() => repository = _Repo();
}

final _ace = ClientModel(
    id: 'RAD-022',
    code: 'RAD-022',
    name: 'Allied Care Experts (ACE) Medical Center - Bohol, Inc.',
    address: '',
    contact: '',
    emailAddress: '');

void main() {
  late _Tracker tracker;
  late _Activity c;

  setUp(() {
    tracker = Get.put<ReconciliationRepository>(_Tracker()) as _Tracker;
    c = Get.put<CollectionActivityController>(_Activity()) as _Activity;
    c.activityItems.assignAll([
      CollectionItemModel(
          id: '700004695',
          client: _ace,
          toBeCollected: 308089.68,
          status: 'Reconciliation',
          assignedAt: '2026-10-20T08:00:00'),
    ]);
  });

  tearDown(Get.reset);

  test('Done Engagement keeps the case with the collector', () async {
    await c.unclaimAccount('RAD-022');

    expect(c.activityItems, isEmpty, reason: 'the account is released');
    expect(tracker.released, isEmpty, reason: 'its case is not');
  });

  test('Defer releases the case', () async {
    await c.unclaimWithReason('RAD-022', 'Not Available', '');

    expect(tracker.released, ['RAD-022']);
  });
}
