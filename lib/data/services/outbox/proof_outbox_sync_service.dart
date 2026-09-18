import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/image_outbox_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/signature_dao.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/repositories/image/image_repository.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/image_outbox_item.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/signature_outbox_item.dart';
import 'package:sqflite/sqflite.dart';

/// Uploads one queued file. Mirrors [ImageRepository.uploadFile].
typedef ProofUploader = Future<Result<void>> Function({
  required String requestId,
  required String base64Image,
  required String type,
});

/// Outcome of one flush pass.
class ProofOutboxFlushSummary {
  const ProofOutboxFlushSummary({
    required this.attempted,
    required this.uploaded,
    this.skippedReason,
  });

  const ProofOutboxFlushSummary.skipped(String reason)
      : attempted = 0,
        uploaded = 0,
        skippedReason = reason;

  final int attempted;
  final int uploaded;

  /// Non-null when the pass did not run (offline, already running, throttled).
  final String? skippedReason;

  int get failed => attempted - uploaded;
  bool get ran => skippedReason == null;
}

/// Drains the proof-image and receiver-signature outboxes in the background.
///
/// Before this service nothing uploaded a queued proof automatically:
/// `workmanager` was declared but never wired, and no worker watched
/// connectivity. Recovery needed a human to open Settings > Developer Tools,
/// so the user-facing "it will be uploaded when connection is available"
/// message was not true.
///
/// Triggers: app start (after a short settle delay), connectivity regained,
/// app resumed from background, and explicit [flushNow] calls. Runs only while
/// the app process is alive. There is no OS-scheduled background job, so a
/// proof captured offline uploads the next time the app is open and online.
///
/// Rows are shared with the developer outbox screens. Both sides delete on
/// success and re-mark `Failed` on failure, so an overlap is harmless.
class ProofOutboxSyncService extends GetxController
    with WidgetsBindingObserver {
  ProofOutboxSyncService({
    Future<Database> Function()? database,
    ProofUploader? upload,
    Future<bool> Function()? isConnected,
    this.startupDelay = const Duration(seconds: 5),
    this.minInterval = const Duration(seconds: 30),
    this.retryDelayAfterTotalFailure = const Duration(minutes: 5),
    this.observeLifecycle = true,
    this.watchConnectivity = true,
  })  : _database = database ?? (() => DatabaseHelper.instance.database),
        _upload = upload ?? _defaultUpload,
        _isConnected =
            isConnected ?? (() => NetworkManager.instance.isConnected());

  static ProofOutboxSyncService get instance => Get.find();

  final Future<Database> Function() _database;
  final ProofUploader _upload;
  final Future<bool> Function() _isConnected;

  /// Wait after start-up before the first pass, so bootstrap traffic settles.
  final Duration startupDelay;

  /// Minimum gap between automatic passes.
  final Duration minInterval;

  /// Back-off applied when every item in a pass failed. The server is then
  /// the likely problem, so retrying on each connectivity blip is waste.
  final Duration retryDelayAfterTotalFailure;

  /// False in tests, where there is no [WidgetsBinding] to observe.
  final bool observeLifecycle;

  /// False in tests, where [NetworkManager] is not registered.
  final bool watchConnectivity;

  final RxBool isFlushing = false.obs;
  final Rxn<DateTime> lastFlushAt = Rxn<DateTime>();
  final Rxn<ProofOutboxFlushSummary> lastSummary =
      Rxn<ProofOutboxFlushSummary>();

  Worker? _connectivityWorker;
  Timer? _startupTimer;
  DateTime? _nextAllowedAt;

  static Future<Result<void>> _defaultUpload({
    required String requestId,
    required String base64Image,
    required String type,
  }) {
    // ImageRepository is registered inside the Firebase guard in
    // GeneralBindings, so it can be absent on desktop.
    if (!Get.isRegistered<ImageRepository>()) {
      return Future.value(Result<void>.failure(
          'ImageRepository is not registered on this platform'));
    }
    return ImageRepository.instance.uploadFile(
      requestId: requestId,
      base64Image: base64Image,
      type: type,
      showFeedback: false,
    );
  }

  @override
  void onInit() {
    super.onInit();

    if (watchConnectivity && Get.isRegistered<NetworkManager>()) {
      _connectivityWorker =
          ever<bool>(NetworkManager.instance.isOnline, (online) {
        if (online) unawaited(flush(reason: 'connectivity regained'));
      });
    }

    if (observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
    }

    _startupTimer = Timer(startupDelay, () {
      unawaited(flush(reason: 'app start'));
    });
  }

  @override
  void onClose() {
    _connectivityWorker?.dispose();
    _startupTimer?.cancel();
    if (observeLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(flush(reason: 'app resumed'));
    }
  }

  /// Flush immediately, ignoring the automatic throttle.
  Future<ProofOutboxFlushSummary> flushNow() =>
      flush(reason: 'manual', force: true);

  /// Upload every queued proof image and signature that is not yet synced.
  ///
  /// Never throws. Returns what happened so callers and tests can inspect it.
  Future<ProofOutboxFlushSummary> flush({
    required String reason,
    bool force = false,
  }) async {
    if (isFlushing.value) {
      return _finish(const ProofOutboxFlushSummary.skipped('already running'));
    }

    final now = DateTime.now();
    final nextAllowedAt = _nextAllowedAt;
    if (!force && nextAllowedAt != null && now.isBefore(nextAllowedAt)) {
      return _finish(const ProofOutboxFlushSummary.skipped('throttled'));
    }

    if (!await _isConnected()) {
      return _finish(const ProofOutboxFlushSummary.skipped('offline'));
    }

    isFlushing.value = true;
    var attempted = 0;
    var uploaded = 0;
    try {
      final db = await _database();
      final imageDao = ImageOutboxDao(db);
      final signatureDao = SignatureDao(db);

      final images = (await imageDao.getPendingImageOutboxItems())
          .map(ImageOutboxItem.fromMap)
          .where((item) => !item.isSynced && item.canRetry)
          .toList();
      final signatures = (await signatureDao.getAllReceiverSignatures())
          .map(SignatureOutboxItem.fromMap)
          .where((item) => !item.isSynced && item.canRetry)
          .toList();

      logDebug('ProofOutboxSyncService: flush ($reason): '
          '${images.length} image(s), ${signatures.length} signature(s)');

      for (final item in images) {
        attempted++;
        if (await _uploadImage(imageDao, item)) uploaded++;
      }
      for (final item in signatures) {
        attempted++;
        if (await _uploadSignature(signatureDao, item)) uploaded++;
      }

      final summary =
          ProofOutboxFlushSummary(attempted: attempted, uploaded: uploaded);
      _scheduleNext(summary, now);
      return _finish(summary);
    } catch (e, st) {
      logDebug('ProofOutboxSyncService: flush ($reason) failed: $e\n$st');
      _nextAllowedAt = now.add(minInterval);
      return _finish(
          ProofOutboxFlushSummary(attempted: attempted, uploaded: uploaded));
    } finally {
      isFlushing.value = false;
    }
  }

  Future<bool> _uploadImage(ImageOutboxDao dao, ImageOutboxItem item) async {
    final label = 'image ${item.requestId}/${item.imageType}';
    try {
      final result = await _upload(
        requestId: item.requestId,
        base64Image: item.imageBase64,
        type: item.imageType,
      );
      if (result.isSuccess) {
        await dao.deleteImageOutboxItem(
          requestId: item.requestId,
          imageType: item.imageType,
          imageLookupKey: item.imageLookupKey,
        );
        logDebug('ProofOutboxSyncService: uploaded $label');
        return true;
      }
      logDebug('ProofOutboxSyncService: $label failed: ${result.error}');
    } catch (e) {
      logDebug('ProofOutboxSyncService: $label threw: $e');
    }
    await dao.insertImageOutboxItem(
      requestId: item.requestId,
      imageType: item.imageType,
      imageLookupKey: item.imageLookupKey,
      imageBase64: item.imageBase64,
      apiStatus: 'Failed',
      capturedAt: item.capturedAt?.toIso8601String(),
    );
    return false;
  }

  Future<bool> _uploadSignature(
      SignatureDao dao, SignatureOutboxItem item) async {
    final label = 'signature ${item.requestId}';
    try {
      final result = await _upload(
        requestId: item.requestId,
        base64Image: item.signatureBase64,
        type: 'Signature',
      );
      if (result.isSuccess) {
        await dao.deleteReceiverSignatureByRequestId(item.requestId);
        logDebug('ProofOutboxSyncService: uploaded $label');
        return true;
      }
      logDebug('ProofOutboxSyncService: $label failed: ${result.error}');
    } catch (e) {
      logDebug('ProofOutboxSyncService: $label threw: $e');
    }
    await dao.insertReceiverSignature(
      requestID: item.requestId,
      signature: item.signatureBase64,
      apiStatus: 'Failed',
    );
    return false;
  }

  void _scheduleNext(ProofOutboxFlushSummary summary, DateTime ranAt) {
    final everythingFailed = summary.attempted > 0 && summary.uploaded == 0;
    _nextAllowedAt = ranAt
        .add(everythingFailed ? retryDelayAfterTotalFailure : minInterval);
  }

  ProofOutboxFlushSummary _finish(ProofOutboxFlushSummary summary) {
    if (summary.ran) {
      lastFlushAt.value = DateTime.now();
    }
    lastSummary.value = summary;
    return summary;
  }

  /// Exposed so tests can assert the throttle without waiting.
  @visibleForTesting
  DateTime? get nextAllowedAt => _nextAllowedAt;
}
