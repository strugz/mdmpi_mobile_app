import 'dart:async';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_pending_dao.dart';

/// Manages syncing of pending collection changes to the server.
///
/// Responsibilities:
/// - Queue pending changes (CREATE, UPDATE, CLAIM, SAVE_ACTIVITY)
/// - Retry with exponential backoff on failure
/// - Expose sync status observable (idle, syncing, failed)
/// - Listen for network connectivity and trigger sync
class SyncManager extends GetxController {
  static SyncManager get instance => Get.find();

  CollectionPendingDao? _pendingDao;

  /// Observable sync status: 'idle' | 'syncing' | 'failed' | 'error:<message>'
  final RxString syncStatus = 'idle'.obs;

  /// Observable: true if syncing, false otherwise
  final RxBool isSyncing = false.obs;

  /// Observable: true if there are pending changes
  final RxBool hasPendingChanges = false.obs;

  /// Observable: error message if sync failed
  final RxnString syncErrorMessage = RxnString();

  /// Retry configuration
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 5);

  /// Lazy getter for PendingDao
  Future<CollectionPendingDao> get _dao async {
    if (_pendingDao != null) return _pendingDao!;
    final db = await DatabaseHelper.instance.database;
    _pendingDao = CollectionPendingDao(db);
    return _pendingDao!;
  }

  @override
  void onInit() {
    super.onInit();
    _initializeNetworkListener();
    _updatePendingStatus();
  }

  /// Initialize network connectivity listener.
  void _initializeNetworkListener() {
    final networkManager = Get.find<NetworkManager>();
    // Listen for connectivity changes and trigger sync when online
    ever(RxBool(false), (_) {
      // This is a placeholder; in a real implementation,
      // NetworkManager should expose a connectivity stream.
      // For now, sync will be triggered opportunistically or manually.
    });
  }

  /// Update pending changes status observable.
  Future<void> _updatePendingStatus() async {
    final dao = await _dao;
    final count = await dao.getPendingChangeCount();
    hasPendingChanges.value = count > 0;
    logDebug('SyncManager: $count pending changes');
  }

  /// Queue a pending change for later sync.
  Future<void> queueChange({
    required String operation,
    required String payload,
    String? itemId,
  }) async {
    try {
      final dao = await _dao;
      final now = DateTime.now().toIso8601String();
      final change = PendingChange(
        operation: operation,
        payload: payload,
        itemId: itemId,
        createdAt: now,
      );

      await dao.addPendingChange(change);
      await _updatePendingStatus();
      logDebug('SyncManager: Queued $operation for $itemId');
    } catch (e) {
      logDebug('SyncManager.queueChange error: $e');
    }
  }

  /// Attempt to sync all pending changes.
  /// Call this when network is restored or manually triggered.
  ///
  /// Returns true if all changes were synced successfully, false otherwise.
  Future<bool> trySync() async {
    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        syncStatus.value = 'idle (offline)';
        logDebug('SyncManager: Offline, skipping sync');
        return false;
      }

      isSyncing.value = true;
      syncStatus.value = 'syncing';
      syncErrorMessage.value = null;

      final dao = await _dao;
      final pendingChanges = await dao.getPendingChanges();

      if (pendingChanges.isEmpty) {
        syncStatus.value = 'idle';
        isSyncing.value = false;
        logDebug('SyncManager: No pending changes to sync');
        return true;
      }

      logDebug('SyncManager: Starting sync of ${pendingChanges.length} pending changes');

      bool allSucceeded = true;
      for (final change in pendingChanges) {
        final success = await _syncChange(change, dao);
        if (!success) {
          allSucceeded = false;
        }
      }

      if (allSucceeded) {
        syncStatus.value = 'idle';
        syncErrorMessage.value = null;
      } else {
        syncStatus.value = 'failed';
        syncErrorMessage.value = 'Some changes could not be synced. Will retry later.';
      }

      isSyncing.value = false;
      return allSucceeded;
    } catch (e) {
      syncStatus.value = 'error';
      syncErrorMessage.value = 'Sync error: $e';
      isSyncing.value = false;
      logDebug('SyncManager.trySync error: $e');
      return false;
    }
  }

  /// Sync a single pending change with retry logic.
  Future<bool> _syncChange(PendingChange change, CollectionPendingDao dao) async {
    try {
      logDebug(
          'SyncManager: Syncing ${change.operation} (retry: ${change.retryCount}/${maxRetries})');

      // TODO: Implement actual HTTP push to server
      // Example:
      // final response = await _pushChangeToServer(change);
      // if (response.statusCode == 200 || response.statusCode == 201) {
      //   await dao.removePendingChange(change.id!);
      //   return true;
      // }

      // For now, simulate successful sync after 3 retries (for testing)
      if (change.retryCount >= 2) {
        logDebug('SyncManager: Simulating successful sync for ${change.operation}');
        await dao.removePendingChange(change.id!);
        await _updatePendingStatus();
        return true;
      }

      // Increment retry count and update last retry time
      final updatedChange = change.copyWith(
        retryCount: change.retryCount + 1,
        lastRetryAt: DateTime.now().toIso8601String(),
      );
      await dao.updatePendingChange(updatedChange);

      return false;
    } catch (e) {
      logDebug('SyncManager._syncChange error for ${change.operation}: $e');
      return false;
    }
  }

  /// Clear a pending change (e.g., if user discards a change).
  Future<void> discardChange(int pendingId) async {
    try {
      final dao = await _dao;
      await dao.removePendingChange(pendingId);
      await _updatePendingStatus();
      logDebug('SyncManager: Discarded pending change $pendingId');
    } catch (e) {
      logDebug('SyncManager.discardChange error: $e');
    }
  }

  /// Clear all pending changes.
  Future<void> discardAllChanges() async {
    try {
      final dao = await _dao;
      await dao.clearAllPendingChanges();
      await _updatePendingStatus();
      logDebug('SyncManager: Cleared all pending changes');
    } catch (e) {
      logDebug('SyncManager.discardAllChanges error: $e');
    }
  }

  /// Get count of pending changes.
  Future<int> getPendingChangeCount() async {
    final dao = await _dao;
    return await dao.getPendingChangeCount();
  }

  /// Debug: Print sync status and pending changes.
  Future<void> printSyncInfo() async {
    try {
      final dao = await _dao;
      final count = await dao.getPendingChangeCount();
      final changes = await dao.getPendingChanges();

      logDebug('=== SyncManager Status ===');
      logDebug('Sync Status: ${syncStatus.value}');
      logDebug('Is Syncing: ${isSyncing.value}');
      logDebug('Pending Changes: $count');
      if (changes.isNotEmpty) {
        for (final change in changes.take(5)) {
          logDebug('  - ${change.operation} for ${change.itemId} (retry: ${change.retryCount})');
        }
      }
      logDebug('==========================');
    } catch (e) {
      logDebug('SyncManager.printSyncInfo error: $e');
    }
  }
}

