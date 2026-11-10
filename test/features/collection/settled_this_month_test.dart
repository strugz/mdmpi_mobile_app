import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_engagement_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The Settled tile on the Collection home reads on the calendar month, like
/// Collected this Month beside it: a zero-balance invoice counts only when its
/// last collection landed this month.

CollectionHistoryModel _entry(DateTime date,
        {double amount = 0, String status = 'Collected'}) =>
    CollectionHistoryModel(
      date: date.toIso8601String(),
      collectorName: 'Jay',
      status: status,
      remarks: '',
      totalCollected: amount,
    );

CollectionItemModel _settled(String id, List<CollectionHistoryModel> history) =>
    CollectionItemModel(
      id: id,
      client: ClientModel(
        id: 'A',
        code: 'NLN-1',
        name: 'Acme',
        address: '',
        contact: '',
        emailAddress: '',
      ),
      toBeCollected: 0,
      totalCollected: 500,
      history: history,
    );

CollectionEngagementRecord _record(
  String invoice,
  DateTime at, {
  String status = 'Collected',
  String kind = 'INVOICE',
  double amount = 500,
  bool settled = false,
}) =>
    CollectionEngagementRecord(
      settled: settled,
      localRef: 'ref-$invoice-${at.millisecondsSinceEpoch}',
      collectorCode: 'JCA',
      collectorName: 'Jay',
      kind: kind,
      itemId: invoice,
      clientId: 'A',
      clientName: 'Acme',
      engagedAt: at.toIso8601String(),
      engagedOn: at.toIso8601String().substring(0, 10),
      status: status,
      amount: amount,
      createdAt: at.toIso8601String(),
    );

CollectionActivityController _bareController() {
  final c = CollectionActivityController();
  c.startAggregateTracking();
  return c;
}

void main() {
  final now = DateTime.now();
  final lastMonth = DateTime(now.year, now.month - 1, 15, 10);
  final thisMonth = DateTime(now.year, now.month, 1, 9);

  test('settledOn is the latest paying history entry', () {
    final item = _settled('INV-1', [
      _entry(lastMonth, amount: 200, status: 'Partial'),
      _entry(thisMonth, amount: 300),
      // A later note that collected nothing does not move the settle date.
      _entry(thisMonth.add(const Duration(hours: 1)), status: 'Follow-up'),
    ]);
    expect(CollectionActivityController.settledOn(item), thisMonth);
  });

  test('settledOn falls back to the latest entry when none carries money', () {
    final item = _settled('INV-1', [
      _entry(lastMonth, status: 'Follow-up'),
      _entry(thisMonth, status: 'Advanced Payment Applied'),
    ]);
    expect(CollectionActivityController.settledOn(item), thisMonth);
  });

  test('settledOn is null without dated history', () {
    expect(CollectionActivityController.settledOn(_settled('INV-1', [])),
        isNull);
  });

  test('completedItems counts only invoices settled this calendar month', () {
    final c = _bareController();
    c.bucketItems.addAll([
      _settled('THIS', [_entry(thisMonth, amount: 500)]),
      _settled('LAST', [_entry(lastMonth, amount: 500)]),
      _settled('UNDATED', []),
    ]);
    expect(c.completedItems.map((e) => e.id), ['THIS']);
  });

  test('settlesInvoice is a full collection on an invoice', () {
    expect(CollectionActivityController.settlesInvoice(_record('I', thisMonth)),
        isTrue);
    expect(
        CollectionActivityController.settlesInvoice(
            _record('I', thisMonth, status: 'Partially Collected')),
        isFalse);
    expect(
        CollectionActivityController.settlesInvoice(
            _record('I', thisMonth, status: 'Follow Up', amount: 0)),
        isFalse);
    expect(
        CollectionActivityController.settlesInvoice(
            _record('', thisMonth, kind: 'OFFICE')),
        isFalse);
  });

  test('an advance applied in full settles through the archive flag', () {
    final applied = _record('ADV-INV', thisMonth,
        status: 'Advanced Payment Applied', settled: true);
    final reduced = _record('ADV-PART', thisMonth,
        status: 'Advanced Payment Applied', settled: false);
    expect(CollectionActivityController.settlesInvoice(applied), isTrue);
    expect(CollectionActivityController.settlesInvoice(reduced), isFalse);

    final c = _bareController();
    c.ownEngagements.addAll([applied, reduced]);
    expect(c.completedItems.map((e) => e.id), ['ADV-INV']);
  });

  test('an invoice settled this month counts from the archive alone', () {
    // After a download the settled invoice is no longer in the bucket or the
    // activity list; only the archive remembers it.
    final c = _bareController();
    c.ownEngagements.addAll([
      _record('ARCHIVED-THIS', thisMonth),
      _record('ARCHIVED-LAST', lastMonth),
      _record('ARCHIVED-PARTIAL', thisMonth, status: 'Partially Collected'),
    ]);

    final settled = c.completedItems;
    expect(settled.map((e) => e.id), ['ARCHIVED-THIS']);
    expect(settled.single.toBeCollected, 0);
    expect(settled.single.totalCollected, 500);
    expect(settled.single.client.name, 'Acme');
    // The Settled screen lists the account even though the master list no
    // longer carries it.
    expect(c.settledAccounts.map((a) => a.name), ['Acme']);
    expect(c.getSettledInvoicesByAccount('A').map((e) => e.id),
        ['ARCHIVED-THIS']);
  });

  test('the same invoice in the list and the archive counts once', () {
    final c = _bareController();
    c.bucketItems.add(_settled('INV-1', [_entry(thisMonth, amount: 500)]));
    c.ownEngagements.add(_record('INV-1', thisMonth));

    expect(c.completedItems.map((e) => e.id), ['INV-1']);
  });
}
