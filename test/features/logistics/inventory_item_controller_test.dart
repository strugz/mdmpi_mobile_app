import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/repositories/inventory/inventory_item_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/inventory_item_controller.dart';

class _FakeRepo extends InventoryItemRepository {
  final Map<String, Future<Result<List<InventoryItemModel>>> Function()>
      responses;
  _FakeRepo(this.responses);

  @override
  Future<Result<List<InventoryItemModel>>> fetchItems(String requestId) =>
      responses[requestId]!();
}

InventoryItemModel _item(String code) =>
    InventoryItemModel(itemCode: code, description: code, qty: 1, unit: 'pc');

void main() {
  test('a request with no items does not show the previous request items',
      () async {
    final ctrl = InventoryItemController(
      repository: _FakeRepo({
        'A': () async => Result.success([_item('OSR6122T')]),
        'B': () async => Result.success(<InventoryItemModel>[]),
      }),
    );

    await ctrl.loadItems('A');
    expect(ctrl.items.map((e) => e.itemCode), ['OSR6122T']);
    expect(ctrl.currentRequestId.value, 'A');

    await ctrl.loadItems('B');
    expect(ctrl.items, isEmpty);
    expect(ctrl.currentRequestId.value, 'B');
  });

  test('a failed fetch clears the previous request items', () async {
    final ctrl = InventoryItemController(
      repository: _FakeRepo({
        'A': () async => Result.success([_item('OSR6122T')]),
        'B': () async => Result.failure('Server error: 500'),
      }),
    );

    await ctrl.loadItems('A');
    final res = await ctrl.loadItems('B');
    expect(res.isSuccess, isFalse);
    expect(ctrl.items, isEmpty);
  });

  test('a slow earlier fetch does not overwrite a newer request', () async {
    final slowA = Completer<Result<List<InventoryItemModel>>>();
    final ctrl = InventoryItemController(
      repository: _FakeRepo({
        'A': () => slowA.future,
        'B': () async => Result.success([_item('B-1')]),
      }),
    );

    final pendingA = ctrl.loadItems('A');
    await ctrl.loadItems('B');
    slowA.complete(Result.success([_item('A-1')]));
    await pendingA;

    expect(ctrl.currentRequestId.value, 'B');
    expect(ctrl.items.map((e) => e.itemCode), ['B-1']);
    expect(ctrl.isLoading.value, isFalse);
  });
}
