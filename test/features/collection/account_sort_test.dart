import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/models/activity_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// Ordering a list of accounts by amount means the account's total, the
/// figure printed on its card, not one of its invoices.
///
/// The bucket used to place each account by its leading invoice under the
/// chosen order. Under "amount low to high" that was the account's cheapest
/// invoice, so an account holding thirty-eight invoices worth ₱1.5M sat above
/// one holding a single ₱7,578 invoice, because it happened to own something
/// smaller. These pin the account-level rule on both lists.

ClientModel _client(String id) => ClientModel(
      id: id,
      code: 'NLN-$id',
      name: 'Client $id',
      address: '',
      contact: '',
      emailAddress: '',
    );

CollectionItemModel _item(String id, String clientId, double due) =>
    CollectionItemModel(
      id: id,
      client: _client(clientId),
      toBeCollected: due,
      dueDate: '2026-01-01',
    );

CollectionActivityController _bare() {
  // onInit needs the repository and sync manager from DI; nothing here does.
  final c = CollectionActivityController();
  c.startAggregateTracking();
  return c;
}

/// A: many invoices, ₱1,500,000 in total, one of them tiny.
/// B: one invoice worth ₱7,578.
/// C: two invoices worth ₱500,000 in total.
List<CollectionItemModel> _threeAccounts() => [
      _item('a1', 'A', 1),
      _item('a2', 'A', 999999),
      _item('a3', 'A', 500000),
      _item('b1', 'B', 7578),
      _item('c1', 'C', 250000),
      _item('c2', 'C', 250000),
    ];

void main() {
  group('bucket', () {
    CollectionActivityController controllerWith(ActivitySort sort) {
      final c = _bare();
      final items = _threeAccounts();
      c.bucketItems.assignAll(items);
      c.masterAccountList.assignAll([_client('A'), _client('B'), _client('C')]);
      c.bucketFilterSpec.value = ActivityFilter(sort: sort);
      return c;
    }

    test('amount low to high orders by the account total', () {
      final c = controllerWith(ActivitySort.amountLow);
      expect(c.bucketAccounts.map((a) => a.id), ['B', 'C', 'A'],
          reason: "A owns a ₱1 invoice but is worth the most");
    });

    test('amount high to low is the exact reverse', () {
      final c = controllerWith(ActivitySort.amountHigh);
      expect(c.bucketAccounts.map((a) => a.id), ['A', 'C', 'B']);
    });

    test('name stays the catalogue default', () {
      final c = controllerWith(ActivitySort.name);
      expect(c.bucketAccounts.map((a) => a.id), ['A', 'B', 'C']);
    });
  });

  group('engagement list', () {
    CollectionActivityController controllerWith(ActivitySort sort) {
      final c = _bare();
      c.activityItems.assignAll(_threeAccounts());
      c.masterAccountList.assignAll([_client('A'), _client('B'), _client('C')]);
      c.activityFilterSpec.value = ActivityFilter(sort: sort);
      return c;
    }

    test('amount low to high orders by the account total', () {
      final c = controllerWith(ActivitySort.amountLow);
      expect(c.activityAccounts.map((a) => a.id), ['B', 'C', 'A']);
    });

    test('amount high to low is the exact reverse', () {
      final c = controllerWith(ActivitySort.amountHigh);
      expect(c.activityAccounts.map((a) => a.id), ['A', 'C', 'B']);
    });
  });

  // Inside one account the question changes: every invoice shares the
  // account's total, so there the amount orders mean the invoice's own value.
  test('within an account the amount orders rank single invoices', () {
    final invoices = [
      _item('big', 'A', 999999),
      _item('small', 'A', 1),
      _item('mid', 'A', 500000),
    ];

    final low = [...invoices]
      ..sort(const ActivityFilter(sort: ActivitySort.amountLow).compare);
    expect(low.map((i) => i.id), ['small', 'mid', 'big']);

    final high = [...invoices]
      ..sort(const ActivityFilter(sort: ActivitySort.amountHigh).compare);
    expect(high.map((i) => i.id), ['big', 'mid', 'small']);
  });

  test('the sort classifies itself so the two lists cannot drift', () {
    expect(ActivitySort.amountHigh.isByAmount, isTrue);
    expect(ActivitySort.amountLow.isByAmount, isTrue);
    expect(ActivitySort.mostInvoices.isByAmount, isFalse);
    expect(ActivitySort.amountHigh.isDescending, isTrue);
    expect(ActivitySort.amountLow.isDescending, isFalse);
    expect(ActivitySort.mostInvoices.isDescending, isTrue);
    expect(ActivitySort.fewestInvoices.isDescending, isFalse);
  });
}
