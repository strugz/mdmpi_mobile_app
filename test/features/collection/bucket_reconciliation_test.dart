import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// An invoice marked for reconciliation lives under Home → Reconciliation
/// only. It used to sit in the regular bucket as well, and acquiring its
/// account from the bucket took only the marked invoices and left the rest.

class _Stub extends CollectionActivityController {
  final claimed = <String>[];
  Set<String> ended = {};

  @override
  Set<String> endedReconInvoiceIds() => ended;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> claimItemsByIds(List<String> ids) async => claimed.addAll(ids);
}

ClientModel _client(String id, String name) => ClientModel(
    id: id,
    code: 'NLN-1',
    name: name,
    address: '',
    contact: '',
    emailAddress: '');

CollectionItemModel _invoice(String id, ClientModel c, double due,
        {String status = ''}) =>
    CollectionItemModel(
        id: id,
        client: c,
        toBeCollected: due,
        status: status,
        dueDate: '2999-01-01');

final _amka = _client('1', 'Amka Trading');
final _ace = _client('2', 'Ace Diagnostics Corp.');
final _only = _client('3', 'Only Reconciliation Inc.');

_Stub _seeded() {
  final c = Get.put<CollectionActivityController>(_Stub()) as _Stub;
  c.startAggregateTracking();
  c.masterAccountList.assignAll([_amka, _ace, _only]);
  c.bucketItems.assignAll([
    _invoice('a1', _amka, 100),
    _invoice('a2', _amka, 200),
    _invoice('r1', _amka, 50, status: 'Reconciliation'),
    _invoice('b1', _ace, 20000),
    _invoice('r2', _only, 75, status: 'Reconciliation'),
  ]);
  return c;
}

void main() {
  tearDown(Get.reset);

  test('the bucket leaves out invoices marked for reconciliation', () {
    final c = _seeded();
    expect(c.bucketAccounts.map((a) => a.name),
        ['Ace Diagnostics Corp.', 'Amka Trading'],
        reason: 'an account with only marked invoices is not in the bucket');
    expect(c.getAccountInvoiceCount(_amka.id), 2);
    expect(c.getBucketOpenInvoices(_amka.id).map((i) => i.id), ['a1', 'a2']);
    expect(c.getInvoicesByAccount(_amka.id).map((i) => i.id).toSet(),
        {'a1', 'a2'});
    expect(c.regularBucketItemCount, 3);
  });

  test('Reconciliation lists the marked ones', () {
    final c = _seeded();
    expect(c.reconciliationAccounts.map((a) => a.name).toSet(),
        {'Amka Trading', 'Only Reconciliation Inc.'});
    expect(c.getReconciliationInvoicesByAccount(_amka.id).map((i) => i.id),
        ['r1']);
  });

  test('acquiring from the bucket takes the regular invoices', () {
    final c = _seeded();
    c.claimAccount(_amka.id);
    expect(c.claimed, ['a1', 'a2']);
  });

  test('acquiring ticked accounts takes their regular invoices', () async {
    final c = _seeded();
    c.toggleAccountSelection(_amka.id);
    c.toggleAccountSelection(_ace.id);
    await c.claimSelectedAccounts();
    expect(c.claimed.toSet(), {'a1', 'a2', 'b1'});
  });

  test('acquiring from Reconciliation takes only the marked invoices', () {
    final c = _seeded();
    c.claimReconciliation(_amka.id);
    expect(c.claimed, ['r1']);
  });

  test('an invoice whose case has ended cannot be acquired', () async {
    final c = _seeded()..ended = {'r2'};
    expect(c.reconciliationAccounts.map((a) => a.name), ['Amka Trading'],
        reason: 'its only marked invoice is in a closed case');
    await c.claimReconciliation(_only.id);
    expect(c.claimed, isEmpty);
    expect(c.getReconciliationInvoicesByAccount(_only.id).map((i) => i.id),
        ['r2'],
        reason: 'still marked; the closed case keeps its history');
  });
}
