import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/repositories/image/image_repository.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/image_outbox_item.dart';

/// Controller for the developer-facing Image Outbox screen.
class ImageOutboxController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImageRepository _imageRepository = Get.find<ImageRepository>();

  final RxList<ImageOutboxItem> items = <ImageOutboxItem>[].obs;
  final RxList<String> busyKeys = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRetryingAll = false.obs;
  final RxBool isClearingAll = false.obs;

  int get pendingCount =>
      items.where((item) => item.apiStatus.toLowerCase() == 'pending').length;

  int get failedCount =>
      items.where((item) => item.apiStatus.toLowerCase() == 'failed').length;

  bool isBusy(ImageOutboxItem item) =>
      isRetryingAll.value ||
      isClearingAll.value ||
      busyKeys.contains(_key(item));

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  Future<void> loadItems() async {
    try {
      isLoading.value = true;
      final rows = await _dbHelper.getPendingImageOutboxItems();
      final mapped = rows
          .map(ImageOutboxItem.fromMap)
          .where((item) => !item.isSynced && item.imageBase64.isNotEmpty)
          .toList()
        ..sort(_sortItems);

      items.assignAll(mapped);
      logDebug('ImageOutboxController.loadItems: loaded ${mapped.length} rows');
    } catch (e) {
      logDebug('ImageOutboxController.loadItems error: $e');
      BLoaders.errorSnackBar(
        title: 'Load Failed',
        message: 'Could not load image outbox entries.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> retryItem(
    ImageOutboxItem item, {
    bool showFeedback = true,
  }) {
    return _retryItem(
      item,
      showFeedback: showFeedback,
      reloadAfterFailure: true,
    );
  }

  Future<void> retryAll() async {
    if (items.isEmpty) {
      BLoaders.warningSnackBar(
        title: 'Nothing to Retry',
        message: 'There are no pending image uploads.',
      );
      return;
    }

    isRetryingAll.value = true;
    final snapshot = List<ImageOutboxItem>.from(items);
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
          message: 'All image uploads were retried successfully.',
        );
      } else if (successCount > 0) {
        BLoaders.warningSnackBar(
          title: 'Retry Complete',
          message:
              '$successCount image upload(s) succeeded. $failureCount still need attention.',
          duration: 4,
        );
      } else {
        BLoaders.errorSnackBar(
          title: 'Retry Failed',
          message: 'All image uploads are still pending.',
          duration: 4,
        );
      }
    } finally {
      isRetryingAll.value = false;
    }
  }

  Future<void> ignoreItem(ImageOutboxItem item) async {
    try {
      _setBusy(item, true);
      await _deleteItem(item);
      items.removeWhere((entry) => _key(entry) == _key(item));
      logDebug('ImageOutboxController.ignoreItem: removed ${_key(item)}');
      BLoaders.successSnackBar(
        title: 'Ignored',
        message: 'Image outbox entry removed.',
      );
    } catch (e) {
      logDebug('ImageOutboxController.ignoreItem error: $e');
      BLoaders.errorSnackBar(
        title: 'Remove Failed',
        message: 'Could not remove the image outbox entry.',
      );
    } finally {
      _setBusy(item, false);
    }
  }

  Future<void> clearAll() async {
    if (items.isEmpty) {
      BLoaders.warningSnackBar(
        title: 'Nothing to Clear',
        message: 'There are no image outbox entries to remove.',
      );
      return;
    }

    isClearingAll.value = true;

    try {
      await _dbHelper.clearImageOutbox();
      items.clear();
      logDebug('ImageOutboxController.clearAll: cleared image outbox');
      BLoaders.successSnackBar(
        title: 'Cleared',
        message: 'Image outbox cleared successfully.',
      );
    } catch (e) {
      logDebug('ImageOutboxController.clearAll error: $e');
      BLoaders.errorSnackBar(
        title: 'Clear Failed',
        message: 'Could not clear the image outbox.',
      );
      await loadItems();
    } finally {
      isClearingAll.value = false;
    }
  }

  Future<bool> _retryItem(
    ImageOutboxItem item, {
    required bool showFeedback,
    required bool reloadAfterFailure,
  }) async {
    if (!item.canRetry) {
      if (showFeedback) {
        BLoaders.errorSnackBar(
          title: 'Retry Failed',
          message: 'This image entry is missing required upload data.',
        );
      }
      return false;
    }

    try {
      _setBusy(item, true);
      logDebug('ImageOutboxController.retryItem: starting ${_key(item)}');

      final result = await _imageRepository.uploadFile(
        requestId: item.requestId,
        base64Image: item.imageBase64,
        type: item.imageType,
        showFeedback: false,
      );

      if (result.isSuccess) {
        await _deleteItem(item);
        items.removeWhere((entry) => _key(entry) == _key(item));
        logDebug('ImageOutboxController.retryItem: success ${_key(item)}');

        if (showFeedback) {
          BLoaders.successSnackBar(
            title: 'Upload Complete',
            message: 'Image uploaded successfully.',
          );
        }
        return true;
      }

      await _persistFailedItem(item);
      logDebug(
        'ImageOutboxController.retryItem: failed ${_key(item)} - ${result.error}',
      );

      if (reloadAfterFailure) {
        await loadItems();
      }

      if (showFeedback) {
        BLoaders.errorSnackBar(
          title: 'Upload Failed',
          message: 'Image upload is still pending. Please try again later.',
          duration: 4,
        );
      }
      return false;
    } catch (e) {
      await _persistFailedItem(item);
      logDebug('ImageOutboxController.retryItem error: ${_key(item)} - $e');

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
      _setBusy(item, false);
    }
  }

  Future<void> _persistFailedItem(ImageOutboxItem item) {
    return _dbHelper.insertImageOutboxItem(
      requestId: item.requestId,
      imageType: item.imageType,
      imageLookupKey: item.imageLookupKey,
      imageBase64: item.imageBase64,
      apiStatus: 'Failed',
      capturedAt: item.capturedAt?.toIso8601String(),
    );
  }

  Future<void> _deleteItem(ImageOutboxItem item) {
    return _dbHelper.deleteImageOutboxItem(
      requestId: item.requestId,
      imageType: item.imageType,
      imageLookupKey: item.imageLookupKey,
    );
  }

  void _setBusy(ImageOutboxItem item, bool value) {
    final itemKey = _key(item);
    if (value) {
      if (!busyKeys.contains(itemKey)) {
        busyKeys.add(itemKey);
      }
      return;
    }

    busyKeys.remove(itemKey);
  }

  String _key(ImageOutboxItem item) =>
      '${item.requestId}|${item.imageType}|${item.imageLookupKey}';

  int _sortItems(ImageOutboxItem a, ImageOutboxItem b) {
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

    final requestCompare = a.requestId.compareTo(b.requestId);
    if (requestCompare != 0) return requestCompare;
    return a.imageType.compareTo(b.imageType);
  }
}
