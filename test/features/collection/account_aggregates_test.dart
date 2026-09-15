import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The per-account totals used to be recomputed on every call, merging and
/// scanning every invoice each time. Listing N accounts over M invoices cost
/// N x M and stalled the transition into the bucket screen. They are cached
/// now, so these tests pin two things: the cached numbers match the original
/// formulas exactly, and the cache never serves stale values.

ClientModel _client(String id) => ClientModel(
      id: id,
      code: '$id-001',
      name: 'Client $id',
      address: '',
      contact: '',
      emailAddress: '',
    );

CollectionItemModel _item(
  String id,
  String clientId, {
  double toBeCollected = 0,
  double totalCollected = 0,
}) =>
    CollectionItemModel(
      id: id,
      client: _client(clientId),
      toBeCollected: toBeCollected,
      totalCollected: totalCollected,
    );

// The formulas exactly as they were before caching, used as the oracle.
double _oldTotalDue(List<CollectionItemModel> all, String clientId) => all
    .where((i) => i.client.id == clientId)
    .fold(0.0, (sum, i) => sum + i.toBeCollected);

double _oldTotalCollected(List<CollectionItemModel> all, String clientId) => all
    .where((i) => i.client.id == clientId)
    .fold(0.0, (sum, i) => sum + i.totalCollected);

int _oldInvoiceCount(List<CollectionItemModel> bucket, String clientId) =>
    bucket.where((i) => i.client.id == clientId && i.toBeCollected > 0).length;

CollectionActivityController _controllerWith({
  required List<CollectionItemModel> bucket,
  List<CollectionItemModel> activity = const [],
}) {
  // Built bare: onInit needs the repository and sync manager from DI, and
  // nothing here touches them.
  final c = CollectionActivityController();
  c.startAggregateTracking();
  c.bucketItems.assignAll(bucket);
  c.activityItems.assignAll(activity);
  return c;
}

void main() {
  group('cached per-account aggregates', () {
    test('match the original formulas across bucket and activity', () {
      final bucket = [
        _item('INV-1', 'A', toBeCollected: 1000, totalCollected: 250),
        _item('INV-2', 'A', toBeCollected: 500),
        // Settled: counts for money, not for the invoice count.
        _item('INV-3', 'A', toBeCollected: 0, totalCollected: 900),
        _item('INV-4', 'B', toBeCollected: 250, totalCollected: 50),
      ];
      final activity = [
        _item('INV-5', 'A', toBeCollected: 700, totalCollected: 300),
      ];

      final c = _controllerWith(bucket: bucket, activity: activity);
      final all = CollectionActivityController.mergeUnique(bucket, activity);

      for (final id in ['A', 'B', 'UNKNOWN']) {
        expect(c.getAccountTotalDue(id), _oldTotalDue(all, id),
            reason: 'due $id');
        expect(c.getAccountTotalCollected(id), _oldTotalCollected(all, id),
            reason: 'collected $id');
        expect(c.getAccountInvoiceCount(id), _oldInvoiceCount(bucket, id),
            reason: 'count $id');
      }

      // Spot-check the actual numbers, not just self-consistency.
      // Money spans both lists: 1000 + 500 + 0 + 700 (activity).
      expect(c.getAccountTotalDue('A'), 2200);
      expect(c.getAccountTotalCollected('A'), 1450);
      // Count is bucket-only and skips the settled invoice, so INV-1 and
      // INV-2 only: not the settled INV-3, not the activity INV-5.
      expect(c.getAccountInvoiceCount('A'), 2);
      expect(c.getAccountInvoiceCount('UNKNOWN'), 0);
      expect(c.getAccountTotalDue('UNKNOWN'), 0);
    });

    test('an id in both lists is counted once, activity winning', () {
      final shared =
          _item('INV-1', 'A', toBeCollected: 100, totalCollected: 10);
      final fresher =
          _item('INV-1', 'A', toBeCollected: 40, totalCollected: 70);

      final c = _controllerWith(bucket: [shared], activity: [fresher]);

      expect(c.allItems.length, 1);
      expect(c.getAccountTotalDue('A'), 40);
      expect(c.getAccountTotalCollected('A'), 70);
    });
  });

  group('cache invalidation', () {
    test('adding an invoice updates the totals', () {
      final c =
          _controllerWith(bucket: [_item('INV-1', 'A', toBeCollected: 100)]);
      expect(c.getAccountTotalDue('A'), 100);

      c.bucketItems.add(_item('INV-2', 'A', toBeCollected: 250));

      expect(c.getAccountTotalDue('A'), 350);
      expect(c.getAccountInvoiceCount('A'), 2);
    });

    test('replacing an invoice in place updates the totals', () {
      final c =
          _controllerWith(bucket: [_item('INV-1', 'A', toBeCollected: 100)]);
      expect(c.getAccountTotalDue('A'), 100);

      // How a recorded collection is applied: the model is replaced, never
      // mutated, so the list notifies and the cache drops.
      c.bucketItems[0] =
          _item('INV-1', 'A', toBeCollected: 30, totalCollected: 70);

      expect(c.getAccountTotalDue('A'), 30);
      expect(c.getAccountTotalCollected('A'), 70);
      expect(c.getAccountInvoiceCount('A'), 1);
    });

    test('settling an invoice drops it from the count but not the money', () {
      final c =
          _controllerWith(bucket: [_item('INV-1', 'A', toBeCollected: 100)]);
      expect(c.getAccountInvoiceCount('A'), 1);

      c.bucketItems[0] =
          _item('INV-1', 'A', toBeCollected: 0, totalCollected: 100);

      expect(c.getAccountInvoiceCount('A'), 0);
      expect(c.getAccountTotalCollected('A'), 100);
    });

    test('removing an invoice updates the totals', () {
      final c = _controllerWith(bucket: [
        _item('INV-1', 'A', toBeCollected: 100),
        _item('INV-2', 'A', toBeCollected: 250),
      ]);
      expect(c.getAccountTotalDue('A'), 350);

      c.bucketItems.removeAt(0);

      expect(c.getAccountTotalDue('A'), 250);
      expect(c.getAccountInvoiceCount('A'), 1);
    });

    test('moving an invoice bucket to activity keeps the money once', () {
      final item = _item('INV-1', 'A', toBeCollected: 100, totalCollected: 20);
      final c = _controllerWith(bucket: [item]);
      expect(c.getAccountTotalDue('A'), 100);
      expect(c.getAccountInvoiceCount('A'), 1);

      c.activityItems.add(item);
      c.bucketItems.removeAt(0);

      expect(c.getAccountTotalDue('A'), 100, reason: 'not double counted');
      expect(c.getAccountTotalCollected('A'), 20);
      expect(c.getAccountInvoiceCount('A'), 0, reason: 'count is bucket-only');
    });
  });
}
