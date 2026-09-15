import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_pending_dao.dart';
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

  @override
  void onInit() {
    super.onInit();
    load();
  }

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

  /// Upload every queued change, then refresh the list.
  Future<void> uploadAll() async {
    if (isUploading.value) return;
    isUploading.value = true;
    try {
      // Route through the activity controller so the bucket refreshes on success
      // and user feedback is consistent.
      await Get.find<CollectionActivityController>().uploadAll();
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

  /// Discard all queued changes.
  Future<void> discardAll() async {
    await _sync.discardAllChanges();
    await load();
  }
}
