import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_outcome.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// A reconciled invoice collected through the bucket (update checklist item
/// 25): paid in full, it is Settled and out of Reconciliation (no badge, not
/// in the Reconciliation list or count); partly paid, it stays one.

const _recon = CollectionStatusColors.statusReconciliation;
const _collected = CollectionStatusColors.statusCollected;
const _partial = CollectionStatusColors.statusPartial;

final _client = ClientModel(
    id: 'C1',
    code: 'NLN-1',
    name: 'Amka Trading',
    address: '',
    contact: '',
    emailAddress: '');

CollectionItemModel _invoice(String id, double due, {String status = _recon}) =>
    CollectionItemModel(
      id: id,
      client: _client,
      bpCode: 'NLN-1',
      toBeCollected: due,
      status: status,
      assignedAt: '2026-10-20T08:00:00',
      collectorName: 'Jay',
    );

class _Repo extends CollectionRepository {
  final saved = <String>[];

  @override
  String get collectorName => 'Jay';

  @override
  Future<void> saveActivity({
    required String id,
    required String status,
    required String remarks,
    double? totalCollected,
    String? bankName,
    String? checkNumber,
    String? checkDate,
    String? purposeOfVisit,
    bool silent = false,
  }) async =>
      saved.add(id);

  @override
  Future<void> saveBatchActivity({
    required List<String> ids,
    required Map<String, String> statuses,
    required Map<String, String> remarks,
    required Map<String, double> amounts,
    double totalAmountReceived = 0,
    String? bankName,
    String? checkNumber,
    String? checkDate,
    String? purposeOfVisit,
    bool silent = false,
  }) async =>
      saved.addAll(ids);
}

class _Activity extends CollectionActivityController {
  _Activity(this._repo);
  final _Repo _repo;

  @override
  // ignore: must_call_super
  void onInit() => repository = _repo;
}

_Activity _seeded(List<CollectionItemModel> held) {
  final c =
      Get.put<CollectionActivityController>(_Activity(_Repo())) as _Activity;
  c.startAggregateTracking();
  c.masterAccountList.assignAll([_client]);
  c.activityItems.assignAll(held);
  return c;
}

CollectionItemModel _find(_Activity c, String id) =>
    c.allItems.firstWhere((i) => i.id == id);

void main() {
  tearDown(Get.reset);

  group('the rule', () {
    test('paid in full leaves Reconciliation for Collected', () {
      expect(CollectionOutcome.statusAfterPayment(_recon, fullyPaid: true),
          _collected);
    });

    test('partly paid keeps Reconciliation', () {
      expect(CollectionOutcome.statusAfterPayment(_recon, fullyPaid: false),
          _recon);
    });

    test('an ordinary invoice is Collected or plain open', () {
      expect(CollectionOutcome.statusAfterPayment('', fullyPaid: true),
          _collected);
      expect(CollectionOutcome.statusAfterPayment('', fullyPaid: false), '');
      expect(CollectionOutcome.statusAfterPayment(_collected, fullyPaid: false),
          '',
          reason: 'a stale Collected on an open balance is not kept');
    });
  });

  group('a single save', () {
    test('paid in full: Settled, back in the bucket, out of Reconciliation',
        () async {
      final c = _seeded([_invoice('R1', 1500), _invoice('R2', 800)]);
      expect(c.reconciliationItems.map((i) => i.id), ['R1', 'R2']);

      await c.saveActivity(
          id: 'R1', status: _collected, remarks: 'x', totalCollected: 1500);

      final r1 = _find(c, 'R1');
      expect(r1.status, _collected);
      expect(r1.toBeCollected, 0);
      expect(CollectionActivityController.isReconciliation(r1), isFalse,
          reason: 'no Reconciliation badge');
      expect(c.activityItems.map((i) => i.id), ['R2']);
      expect(c.bucketItems.map((i) => i.id), ['R1']);
      expect(c.reconciliationItems.map((i) => i.id), ['R2'],
          reason: 'the Reconciliation list and Home count drop it');
      expect(
          c.getReconciliationInvoicesByAccount('C1').map((i) => i.id), ['R2']);
    });

    test('partly paid: still a reconciliation invoice', () async {
      final c = _seeded([_invoice('R1', 1500)]);

      await c.saveActivity(
          id: 'R1', status: _partial, remarks: 'x', totalCollected: 500);

      final r1 = c.activityItems.single;
      expect(r1.status, _recon);
      expect(r1.toBeCollected, 1000);
      expect(CollectionActivityController.isReconciliation(r1), isTrue);
      expect(c.reconciliationItems.map((i) => i.id), ['R1']);
    });
  });

  group('a batch', () {
    test('settles the paid-off one, keeps the partly paid one', () async {
      final c = _seeded([
        _invoice('R1', 1500),
        _invoice('R2', 800),
        _invoice('O1', 300, status: ''),
      ]);

      await c.saveBatchActivity(
        ids: ['R1', 'R2', 'O1'],
        statuses: {'R1': _collected, 'R2': _partial, 'O1': _collected},
        remarks: const {},
        amounts: {'R1': 1500, 'R2': 200, 'O1': 300},
        totalAmountReceived: 2000,
      );

      expect(_find(c, 'R1').status, _collected);
      expect(_find(c, 'O1').status, _collected);
      expect(_find(c, 'R2').status, _recon);
      expect(_find(c, 'R2').toBeCollected, 600);
      expect(c.reconciliationItems.map((i) => i.id), ['R2']);
      expect(c.bucketItems.map((i) => i.id).toSet(), {'R1', 'O1'});
    });
  });
}
