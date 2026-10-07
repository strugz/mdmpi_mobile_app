import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_attachment_dao.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';

/// How one photo upload ended.
enum ReconAttachmentUploadOutcome {
  uploaded,

  /// The server does not know the case yet: its RECON_OPEN_CASE is still in
  /// the "Upload All" outbox. Not a failure; the photo waits.
  waitForCase,
  failed,
}

/// Sends one photo. [error] explains a failure.
typedef ReconAttachmentUploader
    = Future<({ReconAttachmentUploadOutcome outcome, String? error})> Function(
        ReconAttachmentRecord attachment, List<int> bytes);

/// Uploads reconciliation photos (proof of payment, documents) in the
/// background, the same way [ProofOutboxSyncService] uploads delivery proofs:
/// on app start, when the connection comes back, when the app is resumed, and
/// on [flushNow] (after "Upload All", which is what puts the case on the
/// server).
///
/// A photo stays on the phone and in its row until the server has it. One the
/// server refuses is retried a limited number of times ([maxRetries]); one
/// whose case is not uploaded yet waits without counting.
class ReconAttachmentSyncService extends GetxController
    with WidgetsBindingObserver {
  ReconAttachmentSyncService({
    Future<ReconAttachmentDao> Function()? dao,
    ReconAttachmentUploader? upload,
    Future<bool> Function()? isConnected,
    this.startupDelay = const Duration(seconds: 8),
    this.maxRetries = 10,
    this.observeLifecycle = true,
    this.watchConnectivity = true,
  })  : _dao = dao ?? (() => DatabaseHelper.instance.reconAttachmentDao),
        _upload = upload ?? _defaultUpload,
        _isConnected =
            isConnected ?? (() => NetworkManager.instance.isConnected());

  static ReconAttachmentSyncService get instance => Get.find();

  static const String path = '/api4/Collection/recon/attachment';

  final Future<ReconAttachmentDao> Function() _dao;
  final ReconAttachmentUploader _upload;
  final Future<bool> Function() _isConnected;
  final Duration startupDelay;
  final int maxRetries;

  /// False in tests, where there is no [WidgetsBinding] to observe.
  final bool observeLifecycle;

  /// False in tests, where [NetworkManager] is not registered.
  final bool watchConnectivity;

  final RxBool isFlushing = false.obs;

  /// Photos not yet on the server, after the last pass.
  final RxInt unsent = 0.obs;

  Worker? _connectivityWorker;
  Timer? _startupTimer;

  @override
  void onInit() {
    super.onInit();
    if (watchConnectivity && Get.isRegistered<NetworkManager>()) {
      _connectivityWorker =
          ever<bool>(NetworkManager.instance.isOnline, (online) {
        if (online) unawaited(flush(reason: 'connectivity regained'));
      });
    }
    if (observeLifecycle) WidgetsBinding.instance.addObserver(this);
    _startupTimer =
        Timer(startupDelay, () => unawaited(flush(reason: 'app start')));
  }

  @override
  void onClose() {
    _connectivityWorker?.dispose();
    _startupTimer?.cancel();
    if (observeLifecycle) WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(flush(reason: 'app resumed'));
    }
  }

  Future<int> flushNow() => flush(reason: 'manual');

  /// Upload every photo not yet on the server. Returns how many were
  /// uploaded. Never throws.
  Future<int> flush({required String reason}) async {
    if (isFlushing.value) return 0;
    isFlushing.value = true;
    var uploaded = 0;
    try {
      if (!await _isConnected()) return 0;
      final dao = await _dao();
      final pending = await dao.getUnsent(maxRetries: maxRetries);
      if (pending.isNotEmpty) {
        logDebug('ReconAttachmentSyncService: flush ($reason): '
            '${pending.length} photo(s)');
      }
      for (final a in pending) {
        final file = File(a.filePath);
        if (!await file.exists()) {
          await dao.markFailed(a.attachmentId, 'The photo file is missing');
          continue;
        }
        final r = await _upload(a, await file.readAsBytes());
        switch (r.outcome) {
          case ReconAttachmentUploadOutcome.uploaded:
            await dao.markUploaded(a.attachmentId);
            uploaded++;
          case ReconAttachmentUploadOutcome.waitForCase:
            break;
          case ReconAttachmentUploadOutcome.failed:
            await dao.markFailed(a.attachmentId, r.error ?? 'Upload failed');
        }
      }
      unsent.value = await dao.countUnsent();
    } catch (e) {
      logDebug('ReconAttachmentSyncService: flush ($reason) failed: $e');
    } finally {
      isFlushing.value = false;
    }
    return uploaded;
  }

  static Future<({ReconAttachmentUploadOutcome outcome, String? error})>
      _defaultUpload(ReconAttachmentRecord a, List<int> bytes) async {
    try {
      final request =
          http.MultipartRequest('POST', BApiEnvironment.api4Uri(path))
            ..fields['AttachmentId'] = a.attachmentId
            ..fields['CaseId'] = a.caseId
            ..fields['ActivityId'] = a.activityId
            ..fields['CollectorCode'] = Get.isRegistered<CollectionRepository>()
                ? CollectionRepository.instance.collectorCode
                : ''
            ..files.add(http.MultipartFile.fromBytes('File', bytes,
                filename: '${a.attachmentId}.jpg',
                contentType: MediaType('image', 'jpeg')));
      final response = await http.Response.fromStream(
          await request.send().timeout(const Duration(seconds: 90)));
      if (response.statusCode == 200) {
        return (outcome: ReconAttachmentUploadOutcome.uploaded, error: null);
      }
      if (response.statusCode == 404) {
        return (outcome: ReconAttachmentUploadOutcome.waitForCase, error: null);
      }
      return (
        outcome: ReconAttachmentUploadOutcome.failed,
        error: 'HTTP ${response.statusCode}: ${response.body}',
      );
    } catch (e) {
      return (outcome: ReconAttachmentUploadOutcome.failed, error: '$e');
    }
  }
}
