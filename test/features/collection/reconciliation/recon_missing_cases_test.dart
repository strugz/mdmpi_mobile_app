import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/reconciliation_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// An invoice marked for reconciliation but in no case was in neither the
/// bucket nor the Tracker: acquiring it moved it to the collector's Activity
/// and took over no case. The collector who holds it now gets a case opened
/// for it, and acquiring such an account always lands on a case.

typedef _Marked = ({
  String clientCode,
  String clientName,
  ReconCaseInvoice invoice
});

class _Tracker extends ReconciliationRepository {
  final asked = <List<_Marked>>[];
  final acquired = <String>[];
  int _running = 0;
  int mostAtOnce = 0;

  @override
  Future<Result<int>> openMissingCases(List<_Marked> marked) async {
    asked.add(marked);
    _running++;
    if (_running > mostAtOnce) mostAtOnce = _running;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    _running--;
    return Result.success(1);
  }

  @override
  Future<Result<int>> acquireCasesFor(String clientCode) async {
    acquired.add(clientCode);
    return Result.success(0);
  }
}

class _Stub extends CollectionActivityController {
  @override
  Set<String> endedReconInvoiceIds() => const {};

  @override
  // ignore: must_call_super
  void onInit() {}

  /// Acquiring moves the invoices to Activity, as the real claim does.
  @override
  Future<void> claimItemsByIds(List<String> ids,
      {void Function(int done, int total)? onProgress}) async {
    final moved = bucketItems.where((i) => ids.contains(i.id)).toList();
    bucketItems.removeWhere((i) => ids.contains(i.id));
    activityItems.addAll(
        moved.map((i) => i.copyWith(assignedAt: '2026-10-20T08:00:00')));
  }
}

ClientModel _client(String id, String name) => ClientModel(
    id: id, code: id, name: name, address: '', contact: '', emailAddress: '');

CollectionItemModel _invoice(String id, ClientModel c, double due,
        {String status = 'Reconciliation'}) =>
    CollectionItemModel(id: id, client: c, toBeCollected: due, status: status);

final _amka = _client('NLN-1', 'Amka Trading');
final _ace = _client('NCR-2', 'Ace Diagnostics Corp.');

void main() {
  late _Tracker tracker;
  late _Stub c;

  setUp(() {
    tracker = Get.put<ReconciliationRepository>(_Tracker()) as _Tracker;
    c = Get.put<CollectionActivityController>(_Stub()) as _Stub;
    c.startAggregateTracking();
    c.masterAccountList.assignAll([_amka, _ace]);
  });

  tearDown(Get.reset);

  test('held marked invoices are sent for a case; nothing else is', () async {
    c.activityItems.assignAll([
      _invoice('r1', _amka, 50),
      _invoice('r2', _amka, 70),
      _invoice('a1', _amka, 100, status: ''),
      _invoice('r3', _ace, 0),
    ]);
    c.bucketItems.assignAll([_invoice('r9', _ace, 90)]);

    await c.openMissingReconCases();

    final sent = tracker.asked.single;
    expect(sent.map((m) => m.invoice.invoiceNo), ['r1', 'r2'],
        reason: 'not regular, paid or unheld invoices');
    expect(sent.first.clientCode, 'NLN-1');
    expect(sent.first.clientName, 'Amka Trading');
    expect(sent.first.invoice.amount, 50, reason: 'its balance now');
  });

  test('nothing held and marked: the Tracker is not asked', () async {
    c.bucketItems.assignAll([_invoice('r9', _ace, 90)]);
    await c.openMissingReconCases();
    expect(tracker.asked, isEmpty);
  });

  test('acquiring a marked account takes over its case, or opens one',
      () async {
    c.bucketItems.assignAll([
      _invoice('r1', _amka, 50),
      _invoice('a1', _amka, 100, status: ''),
    ]);

    await c.claimReconciliation(_amka.id);

    expect(tracker.acquired, ['NLN-1']);
    expect(tracker.asked.single.map((m) => m.invoice.invoiceNo), ['r1'],
        reason: 'the acquired invoice is now held, so it gets a case');
  });

  // Update checklist item 22: reconciliation is a status, so the bucket's own
  // Acquire takes the marked invoices and brings the case along.
  test('acquiring the account from the bucket takes over its case too',
      () async {
    c.bucketItems.assignAll([
      _invoice('r1', _amka, 50),
      _invoice('a1', _amka, 100, status: ''),
    ]);

    await c.claimAccount(_amka.id);

    expect(c.activityItems.map((i) => i.id).toSet(), {'r1', 'a1'});
    expect(c.activityItems.firstWhere((i) => i.id == 'r1').status,
        'Reconciliation',
        reason: 'still marked: a status, not a removal');
    expect(tracker.acquired, ['NLN-1']);
    expect(tracker.asked.single.map((m) => m.invoice.invoiceNo), ['r1']);
  });

  test('acquiring ticked accounts takes over the cases of marked ones',
      () async {
    c.bucketItems.assignAll([
      _invoice('r1', _amka, 50),
      _invoice('b1', _ace, 100, status: ''),
    ]);
    c.toggleAccountSelection(_amka.id);
    c.toggleAccountSelection(_ace.id);

    await c.claimSelectedAccounts();

    expect(c.activityItems.map((i) => i.id).toSet(), {'r1', 'b1'});
    expect(tracker.acquired, ['NLN-1'],
        reason: 'Ace has no reconciliation invoice, so no case to take');
  });

  test('an account with nothing marked leaves the Tracker alone', () async {
    c.bucketItems.assignAll([_invoice('b1', _ace, 100, status: '')]);
    await c.claimAccount(_ace.id);
    expect(tracker.acquired, isEmpty);
    expect(tracker.asked, isEmpty);
  });

  test('runs one at a time', () async {
    c.activityItems.assignAll([_invoice('r1', _amka, 50)]);
    await Future.wait([c.openMissingReconCases(), c.openMissingReconCases()]);
    expect(tracker.asked, hasLength(2));
    expect(tracker.mostAtOnce, 1,
        reason: 'two at once would each open a case for the same account');
  });
}
