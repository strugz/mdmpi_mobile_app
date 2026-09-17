import 'dart:async';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_pending_dao.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';

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

  /// Observable: number of pending (un-uploaded) changes
  final RxInt pendingCount = 0.obs;

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
    _updatePendingStatus();
  }

  /// Update pending changes status observable.
  Future<void> _updatePendingStatus() async {
    final dao = await _dao;
    final count = await dao.getPendingChangeCount();
    pendingCount.value = count;
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

  /// Upload all pending changes to the backend in one batch (end-of-day
  /// "Upload All"). Delegates the HTTP push and queue reconciliation to
  /// [CollectionRepository.uploadAll].
  ///
  /// Returns the upload result, or null when offline / on error (details land in
  /// [syncErrorMessage]).
  Future<CollectionUploadResult?> uploadAll() async {
    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) {
      syncStatus.value = 'idle (offline)';
      syncErrorMessage.value = 'No internet connection.';
      logDebug('SyncManager: Offline, cannot upload');
      return null;
    }

    isSyncing.value = true;
    syncStatus.value = 'syncing';
    syncErrorMessage.value = null;

    try {
      final result = await CollectionRepository.instance.uploadAll();
      await _updatePendingStatus();

      if (hasPendingChanges.value) {
        syncStatus.value = 'failed';
        syncErrorMessage.value =
            'Uploaded ${result.accepted}. ${result.rejectedCount} rejected — review and retry or discard.';
      } else {
        syncStatus.value = 'idle';
        syncErrorMessage.value = null;
      }
      return result;
    } catch (e) {
      syncStatus.value = 'error';
      syncErrorMessage.value = 'Upload failed: $e';
      logDebug('SyncManager.uploadAll error: $e');
      return null;
    } finally {
      isSyncing.value = false;
    }
  }

  /// Backwards-compatible alias for [uploadAll]; returns true when the queue is
  /// fully drained.
  Future<bool> trySync() async {
    final result = await uploadAll();
    return result != null && !hasPendingChanges.value;
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
          logDebug(
              '  - ${change.operation} for ${change.itemId} (retry: ${change.retryCount})');
        }
      }
      logDebug('==========================');
    } catch (e) {
      logDebug('SyncManager.printSyncInfo error: $e');
    }
  }
}
