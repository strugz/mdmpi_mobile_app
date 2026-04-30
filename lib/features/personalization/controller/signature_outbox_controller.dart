import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/repositories/image/image_repository.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/signature_outbox_item.dart';

/// Controller for the developer-facing Signature Outbox screen.
class SignatureOutboxController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImageRepository _imageRepository = Get.find<ImageRepository>();

  final RxList<SignatureOutboxItem> items = <SignatureOutboxItem>[].obs;
  final RxList<String> busyRequestIds = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRetryingAll = false.obs;
  final RxBool isClearingAll = false.obs;

  int get pendingCount =>
      items.where((item) => item.apiStatus.toLowerCase() == 'pending').length;

  int get failedCount =>
      items.where((item) => item.apiStatus.toLowerCase() == 'failed').length;

  bool isBusy(String requestId) =>
      isRetryingAll.value || isClearingAll.value || busyRequestIds.contains(requestId);

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  /// Load locally persisted signature rows that still need attention.
  Future<void> loadItems() async {
    try {
      isLoading.value = true;
      final dao = await _dbHelper.signatureDao;
      final rows = await dao.getAllReceiverSignatures();
      final mapped = rows
          .map(SignatureOutboxItem.fromMap)
          .where((item) => !item.isSynced && item.signatureBase64.isNotEmpty)
          .toList()
        ..sort(_sortItems);

      items.assignAll(mapped);
      logDebug('SignatureOutboxController.loadItems: loaded ${mapped.length} rows');
    } catch (e) {
      logDebug('SignatureOutboxController.loadItems error: $e');
      BLoaders.errorSnackBar(
        title: 'Load Failed',
        message: 'Could not load signature outbox entries.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Retry a single pending signature upload.
  Future<bool> retryItem(
    SignatureOutboxItem item, {
    bool showFeedback = true,
  }) async {
    return _retryItem(
      item,
      showFeedback: showFeedback,
      reloadAfterFailure: true,
    );
  }

  /// Retry all pending/failed signature uploads.
  Future<void> retryAll() async {
    if (items.isEmpty) {
      BLoaders.warningSnackBar(
        title: 'Nothing to Retry',
        message: 'There are no pending signature uploads.',
      );
      return;
    }

    isRetryingAll.value = true;
    final snapshot = List<SignatureOutboxItem>.from(items);
    var successCount = 0;

    try {
      for (final item in snapshot) {
        final success = await _retryItem(
          item,
          showFeedback: false,
          reloadAfterFailure: false,
        );
        if (success) {
          successCount++;
        }
      }

      await loadItems();
      final failureCount = snapshot.length - successCount;
      if (failureCount == 0) {
        BLoaders.successSnackBar(
          title: 'Retry Complete',
          message: 'All signature uploads were retried successfully.',
        );
      } else if (successCount > 0) {
        BLoaders.warningSnackBar(
          title: 'Retry Complete',
          message:
              '$successCount signature upload(s) succeeded. $failureCount still need attention.',
          duration: 4,
        );
      } else {
        BLoaders.errorSnackBar(
          title: 'Retry Failed',
          message: 'All signature uploads are still pending.',
          duration: 4,
        );
      }
    } finally {
      isRetryingAll.value = false;
    }
  }

  /// Remove a single outbox entry without uploading it.
  Future<void> ignoreItem(SignatureOutboxItem item) async {
    try {
      _setBusy(item.requestId, true);
      await _dbHelper.deleteReceiverSignatureByRequestId(item.requestId);
      items.removeWhere((entry) => entry.requestId == item.requestId);
      logDebug('SignatureOutboxController.ignoreItem: removed ${item.requestId}');
      BLoaders.successSnackBar(
        title: 'Ignored',
        message: 'Signature outbox entry removed.',
      );
    } catch (e) {
      logDebug('SignatureOutboxController.ignoreItem error: $e');
      BLoaders.errorSnackBar(
        title: 'Remove Failed',
        message: 'Could not remove the signature outbox entry.',
      );
    } finally {
      _setBusy(item.requestId, false);
    }
  }

  /// Clear the entire signature outbox.
  Future<void> clearAll() async {
    if (items.isEmpty) {
      BLoaders.warningSnackBar(
        title: 'Nothing to Clear',
        message: 'There are no signature outbox entries to remove.',
      );
      return;
    }

    isClearingAll.value = true;
    final snapshot = List<SignatureOutboxItem>.from(items);

    try {
      for (final item in snapshot) {
        await _dbHelper.deleteReceiverSignatureByRequestId(item.requestId);
      }
      items.clear();
      logDebug('SignatureOutboxController.clearAll: removed ${snapshot.length} rows');
      BLoaders.successSnackBar(
        title: 'Cleared',
        message: 'Signature outbox cleared successfully.',
      );
    } catch (e) {
      logDebug('SignatureOutboxController.clearAll error: $e');
      BLoaders.errorSnackBar(
        title: 'Clear Failed',
        message: 'Could not clear the signature outbox.',
      );
      await loadItems();
    } finally {
      isClearingAll.value = false;
    }
  }

  Future<bool> _retryItem(
    SignatureOutboxItem item, {
    required bool showFeedback,
    required bool reloadAfterFailure,
  }) async {
    if (!item.canRetry) {
      if (showFeedback) {
        BLoaders.errorSnackBar(
          title: 'Retry Failed',
          message: 'This signature entry is missing required upload data.',
        );
      }
      return false;
    }

    try {
      _setBusy(item.requestId, true);
      logDebug('SignatureOutboxController.retryItem: starting ${item.requestId}');

      final result = await _imageRepository.uploadFile(
        requestId: item.requestId,
        base64Image: item.signatureBase64,
        type: 'Signature',
        showFeedback: false,
      );

      if (result.isSuccess) {
        await _dbHelper.deleteReceiverSignatureByRequestId(item.requestId);
        items.removeWhere((entry) => entry.requestId == item.requestId);
        logDebug('SignatureOutboxController.retryItem: success ${item.requestId}');

        if (showFeedback) {
          BLoaders.successSnackBar(
            title: 'Upload Complete',
            message: 'Signature uploaded successfully.',
          );
        }
        return true;
      }

      await _persistFailedItem(item);
      logDebug(
        'SignatureOutboxController.retryItem: failed ${item.requestId} - ${result.error}',
      );

      if (reloadAfterFailure) {
        await loadItems();
      }

      if (showFeedback) {
        BLoaders.errorSnackBar(
          title: 'Upload Failed',
          message: 'Signature upload is still pending. Please try again later.',
          duration: 4,
        );
      }
      return false;
    } catch (e) {
      await _persistFailedItem(item);
      logDebug('SignatureOutboxController.retryItem error: ${item.requestId} - $e');

      if (reloadAfterFailure) {
        await loadItems();
      }

      if (showFeedback) {
        BLoaders.errorSnackBar(
          title: 'Upload Error',
          message: 'An unexpected error occurred while retrying the upload.',
          duration: 4,
        );
      }
      return false;
    } finally {
      _setBusy(item.requestId, false);
    }
  }

  Future<void> _persistFailedItem(SignatureOutboxItem item) async {
    await _dbHelper.insertReceiverSignature(
      requestID: item.requestId,
      signature: item.signatureBase64,
      apiStatus: 'Failed',
    );
  }

  void _setBusy(String requestId, bool value) {
    if (value) {
      if (!busyRequestIds.contains(requestId)) {
        busyRequestIds.add(requestId);
      }
      return;
    }

    busyRequestIds.remove(requestId);
  }

  int _sortItems(SignatureOutboxItem a, SignatureOutboxItem b) {
    final statusPriority = {'failed': 0, 'pending': 1};
    final aPriority = statusPriority[a.apiStatus.toLowerCase()] ?? 99;
    final bPriority = statusPriority[b.apiStatus.toLowerCase()] ?? 99;
    if (aPriority != bPriority) {
      return aPriority.compareTo(bPriority);
    }

    final aCaptured = a.capturedAt?.millisecondsSinceEpoch ?? 0;
    final bCaptured = b.capturedAt?.millisecondsSinceEpoch ?? 0;
    if (aCaptured != bCaptured) {
      return bCaptured.compareTo(aCaptured);
    }

    return a.requestId.compareTo(b.requestId);
  }
}

