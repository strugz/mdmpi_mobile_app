import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/repositories/inventory/inventory_item_repository.dart';

/// Controller that manages inventory items and expansion state for the
/// `InventoryItemView` widget.
///
/// Follow project conventions: lightweight controller, no inline repository
/// instantiation (accepts optional repo for testability), and registered in
/// `GeneralBindings` via `Get.lazyPut(..., fenix: true)`.
class InventoryItemController extends GetxController {
  static InventoryItemController get instance => Get.find();

  final InventoryItemRepository _repo;

  /// Observable list of inventory items.
  final RxList<InventoryItemModel> items = <InventoryItemModel>[].obs;

  /// Map of expansion flags keyed by a stable string (ideally itemCode).
  final RxMap<String, bool> expanded = <String, bool>{}.obs;

  /// Loading flag for fetch operations.
  final RxBool isLoading = false.obs;

  /// Nullable error message observable.
  final RxnString errorMessage = RxnString();

  /// Request id that [items] currently belongs to. The controller is a shared
  /// singleton, so pages must check this before trusting [items].
  final RxnString currentRequestId = RxnString();

  InventoryItemController({InventoryItemRepository? repository})
      : _repo = repository ?? Get.find<InventoryItemRepository>();

  // Cache loaded items per request id to avoid redundant API calls.
  final Map<String, List<InventoryItemModel>> _requestCache = {};

  /// Loads items from the repository for a specific request id.
  ///
  /// The inventory service expects a path-style endpoint: `/items/{requestId}`.
  /// This method calls the repository with the path `/items/{requestId}`.
  Future<Result<List<InventoryItemModel>>> loadItems(String requestId) async {
    // Drop the previous request's items up front so a failed or empty fetch
    // never leaves another request's items on screen.
    currentRequestId.value = requestId;
    items.clear();
    expanded.clear();
    try {
      isLoading.value = true;
      errorMessage.value = null;

      // Return cached result if available
      if (_requestCache.containsKey(requestId)) {
        final cached = _requestCache[requestId]!;
        items.assignAll(cached);
        return Result.success(cached);
      }

      final res = await _repo.fetchItems(requestId);
      // A newer loadItems call for another request owns the list now.
      final isStale = currentRequestId.value != requestId;

      if (res.isSuccess) {
        final list = res.value;
        _requestCache[requestId] = List<InventoryItemModel>.from(list);
        if (!isStale) {
          items.assignAll(list);
          expanded.clear();
        }
        return Result.success(list);
      }

      if (!isStale) errorMessage.value = res.error;
      return Result.failure(res.error);
    } catch (e, st) {
      logDebug('InventoryItemController.loadItems error: $e\n$st');
      BLoaders.errorSnackBar(title: 'Error', message: e.toString());
      if (currentRequestId.value == requestId) {
        errorMessage.value = e.toString();
      }
      return Result.failure(e.toString());
    } finally {
      if (currentRequestId.value == requestId) isLoading.value = false;
    }
  }

  /// Returns cached items for [requestId] if present.
  List<InventoryItemModel> getCachedItems(String requestId) {
    return _requestCache[requestId] ?? <InventoryItemModel>[];
  }

  /// Replace the current items with [newItems] and reset expansion flags.
  void setItems(List<InventoryItemModel> newItems) {
    items.assignAll(newItems);
    expanded.clear();
  }

  /// Toggle expansion flag for [key]. If key is absent it will be created
  /// and set to true.
  void toggleExpanded(String key) {
    final current = expanded[key] ?? false;
    expanded[key] = !current;
  }

  /// Returns whether the given [key] is expanded.
  bool isExpanded(String key) => expanded[key] ?? false;

  /// Expand all known items (sets flags for current items to true).
  void expandAll() {
    for (final it in items) {
      final k = _keyForItem(it);
      expanded[k] = true;
    }
  }

  /// Collapse all items.
  void collapseAll() {
    for (final it in items) {
      final k = _keyForItem(it);
      expanded[k] = false;
    }
  }

  /// Update a single item by matching its itemCode. If not found, append it.
  void updateItem(InventoryItemModel item) {
    try {
      final idx = items.indexWhere((e) => e.itemCode == item.itemCode);
      if (idx >= 0) {
        items[idx] = item;
      } else {
        items.add(item);
      }
    } catch (e) {
      logDebug('InventoryItemController.updateItem error: $e');
    }
  }

  /// Clear all state.
  void clear() {
    currentRequestId.value = null;
    items.clear();
    expanded.clear();
    errorMessage.value = null;
  }

  String _keyForItem(InventoryItemModel item) {
    if (item.itemCode.isNotEmpty) return item.itemCode;
    if (item.description.isNotEmpty) return item.description;
    return item.toString();
  }
}
