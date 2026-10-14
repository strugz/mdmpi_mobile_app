import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_pending_dao.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/reconciliation_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/pending_discard_plan.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/sync_manager.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

/// Backs the Upload Outbox screen: lists the queued (un-uploaded) collection
/// changes and lets the collector Upload All, retry, or discard.
///
/// Mirrors the Signature/Image outbox dev-tool pattern (list pending → act →
/// refresh), but drives the real batched upload via [SyncManager]/repository.
class CollectionUploadController extends GetxController {
  static CollectionUploadController get instance => Get.find();

  final RxList<PendingChange> pending = <PendingChange>[].obs;
  final RxBool isLoading = false.obs;

  SyncManager get _sync => Get.find<SyncManager>();

  /// Flipped on the tap itself (before the connectivity check and request),
  /// so the button acknowledges the press immediately.
  final RxBool isUploading = false.obs;

  /// The banner over the list after a run (done, done with issues,
  /// stopped); null when there is nothing to say.
  final Rxn<UploadBanner> banner = Rxn<UploadBanner>();

  /// An upload is running: one the collector started, or one SyncManager
  /// resumed by itself when the phone came back online.
  bool get busy => isUploading.value || _sync.isSyncing.value;

  /// Changes answered so far in the running upload, of [uploadTotal].
  RxInt get uploadDone => _sync.uploadDone;
  RxInt get uploadTotal => _sync.uploadTotal;

  final List<Worker> _workers = [];

  @override
  void onInit() {
    super.onInit();
    load();
    // Rows leave the list as their batch is accepted, so the list itself
    // shows the upload moving; and a run resumed by SyncManager when the
    // phone came back online gets its banner here too.
    _workers
      ..add(ever<int>(_sync.uploadDone, (_) => load()))
      ..add(ever<CollectionUploadResult?>(_sync.lastUploadResult, (r) {
        if (r != null) banner.value = UploadBanner.from(r);
      }))
      ..add(ever<bool>(_sync.isSyncing, (syncing) {
        if (syncing) banner.value = null;
      }));
    if (_sync.uploadInterrupted.value && _sync.lastUploadResult.value != null) {
      banner.value = UploadBanner.from(_sync.lastUploadResult.value!);
    }
  }

  @override
  void onClose() {
    for (final w in _workers) {
      w.dispose();
    }
    super.onClose();
  }

  void dismissBanner() => banner.value = null;

  Future<CollectionPendingDao> get _dao async =>
      DatabaseHelper.instance.collectionPendingDao;

  /// Load the current pending queue.
  Future<void> load() async {
    try {
      isLoading.value = true;
      final dao = await _dao;
      final rows = await dao.getPendingChanges();
      pending.assignAll(rows);
    } catch (e) {
      logDebug('CollectionUploadController.load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Upload every queued change, a batch at a time, then refresh the list.
  /// The outcome shows as [banner] (not a snackbar): it stays until read
  /// when something needs doing.
  Future<void> uploadAll() async {
    if (isUploading.value) return;
    isUploading.value = true;
    banner.value = null;
    try {
      final result = await _sync.uploadAll();
      if (result == null) {
        banner.value = UploadBanner.couldNotStart(
            _sync.syncErrorMessage.value ?? 'The upload could not start.');
      } else if (!result.interrupted &&
          !result.hasRejections &&
          result.accepted > 0 &&
          Get.isRegistered<CollectionActivityController>()) {
        // The queue is clear: bring the bucket up to date.
        await CollectionActivityController.instance.loadBucket();
      }
      await load();
    } finally {
      isUploading.value = false;
    }
  }

  /// Discard one queued change (e.g. a permanently-rejected duplicate claim).
  Future<void> discard(int pendingId) async {
    await _sync.discardChange(pendingId);
    await load();
  }

  /// True while [discardAll] runs (clean up, then download).
  final RxBool isResetting = false.obs;

  /// Discard every queued change and put the phone back to the server's copy.
  ///
  /// Deleting the queue alone left the work showing elsewhere: cases on the
  /// Reconciliation list, entries on the calendar and in "Collected this
  /// Month", invoices still claimed or marked for reconciliation. So:
  /// 1. Online first. The reset ends in a download; offline it would empty
  ///    the queue and leave everything else as it was.
  /// 2. Remove what the discarded changes created on this phone and the
  ///    download does not replace ([PendingDiscardPlan]): their engagement
  ///    rows, reconciliation cases and steps, and those steps' photos. Work
  ///    already uploaded is never touched.
  /// 3. Empty the queue, then download the bucket: claims, invoice statuses,
  ///    advances, office activities and account history become the server's.
  ///
  /// Success carries what happened, for the collector; a failure says what
  /// was left undone.
  Future<Result<String>> discardAll() async {
    if (isResetting.value || isUploading.value) {
      return Result.failure('Wait for the current upload to finish.');
    }
    isResetting.value = true;
    try {
      if (!await _isOnline()) {
        return Result.failure('Connect to the internet to discard and reset. '
            'Nothing was removed.');
      }
      final plan =
          PendingDiscardPlan.from(await (await _dao).getPendingChanges());

      if (Get.isRegistered<CollectionRepository>()) {
        final r = await CollectionRepository.instance
            .discardLocalEngagements(plan.engagedAts);
        if (r.isFailure) return Result.failure(r.error);
      }
      if (Get.isRegistered<ReconciliationRepository>()) {
        final r = await ReconciliationRepository.instance
            .discardLocal(caseIds: plan.caseIds, activityIds: plan.activityIds);
        if (r.isFailure) return Result.failure(r.error);
      }
      await _sync.discardAllChanges();

      if (Get.isRegistered<CollectionActivityController>()) {
        final activity = CollectionActivityController.instance;
        await activity.downloadBucket();
        if (activity.errorMessage.value != null) {
          return Result.failure('Discarded, but the bucket could not be '
              'downloaded: download it again from Home.');
        }
      }
      return Result.success(
          "Discarded. This phone now shows the server's copy.");
    } catch (e) {
      logDebug('CollectionUploadController.discardAll error: $e');
      return Result.failure('Could not discard and reset: $e');
    } finally {
      isResetting.value = false;
      await load();
    }
  }

  static Future<bool> _isOnline() async {
    if (!Get.isRegistered<NetworkManager>()) return true;
    return NetworkManager.instance.isConnected();
  }
}

enum UploadBannerKind { done, issues, stopped }

/// What the Upload screen says after a run.
class UploadBanner {
  const UploadBanner({
    required this.kind,
    required this.title,
    required this.message,
  });

  final UploadBannerKind kind;
  final String title;
  final String message;

  /// Done banners leave by themselves; the others wait to be read.
  bool get autoDismiss => kind == UploadBannerKind.done;

  /// Whether Retry is offered.
  bool get canRetry => kind == UploadBannerKind.stopped;

  factory UploadBanner.from(CollectionUploadResult r) {
    String n(int count) => count == 1 ? '1 item' : '$count items';
    if (r.interrupted) {
      return UploadBanner(
        kind: UploadBannerKind.stopped,
        title: 'Upload stopped · ${r.done} of ${r.total} sent',
        message: '${r.error} What was sent is saved. The rest goes when you '
            'retry, or by itself once you are back online.',
      );
    }
    if (r.hasRejections) {
      return UploadBanner(
        kind: UploadBannerKind.issues,
        title: '${r.accepted} uploaded · ${r.rejectedCount} need attention',
        message: 'The server refused ${n(r.rejectedCount)}; each one below '
            'says why. Fix or discard them.',
      );
    }
    return UploadBanner(
      kind: UploadBannerKind.done,
      title: r.accepted == 1 ? '1 item uploaded' : 'All ${r.accepted} uploaded',
      message: 'The office has your work.',
    );
  }

  factory UploadBanner.couldNotStart(String reason) => UploadBanner(
        kind: UploadBannerKind.stopped,
        title: 'Upload not started',
        message: '$reason Nothing was sent; it goes by itself once you are '
            'back online, or tap Retry.',
      );
}
