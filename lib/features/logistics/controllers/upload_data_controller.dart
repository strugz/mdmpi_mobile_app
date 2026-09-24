import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/repositories/standard_delivery/delivery_update_outcome.dart';
import 'package:mdmpi_mobile_app/data/repositories/standard_delivery/standard_delivery_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/hotline_direct_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/request_upload_summary.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/upload_candidate_classifier.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/upload_date_filter.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/upload_candidate.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Settings > Upload Data: compares the phone's saved Standard Delivery and
/// Hotline Direct requests with the server, lets the user tick which to send,
/// and sends only those.
///
/// Requests whose status the server already has are never sent. Re-sending
/// them changed nothing but could put the phone's older driver, helper or
/// trip ticket back over the server's.
///
/// The data sources are injectable so the rules can be tested without a
/// device database or network; left null they resolve the app's own.
class UploadDataController extends GetxController {
  UploadDataController({
    Future<List<StandardDeliveryModel>> Function()? loadLocal,
    Future<List<StandardDeliveryModel>> Function()? loadServer,
    Future<DeliveryUpdateOutcome> Function(StandardDeliveryModel request)? send,
    Future<void> Function(StandardDeliveryModel serverCopy)? replaceLocal,
    Future<bool> Function()? isOnline,
    DateTime Function()? now,
  })  : _loadLocal = loadLocal ?? (() => DatabaseHelper.instance.getRequests()),
        _loadServer = loadServer ??
            (() => Get.find<StandardDeliveryRepository>()
                .getAllPending(allowLocalFallback: false)),
        _send = send ??
            ((request) => Get.find<StandardDeliveryRepository>().sendUpdate(
                request, Get.find<UserController>().user.value.initial)),
        _replaceLocal = replaceLocal ??
            ((serverCopy) => DatabaseHelper.instance
                .replaceRequestWithServerCopy(serverCopy)),
        _isOnline = isOnline ?? (() => NetworkManager.instance.isConnected()),
        _now = now ?? DateTime.now;

  final Future<List<StandardDeliveryModel>> Function() _loadLocal;
  final Future<List<StandardDeliveryModel>> Function() _loadServer;
  final Future<DeliveryUpdateOutcome> Function(StandardDeliveryModel) _send;
  final Future<void> Function(StandardDeliveryModel) _replaceLocal;
  final Future<bool> Function() _isOnline;
  final DateTime Function() _now;

  final RxBool isLoading = false.obs;
  final RxBool isOffline = false.obs;
  final RxnString loadError = RxnString();
  final RxList<UploadCandidate> candidates = <UploadCandidate>[].obs;
  final RxSet<String> selectedIds = <String>{}.obs;

  /// Delivery-date filter. Counts, rows, "Select all" and the upload itself
  /// all apply to the requests inside it only, so what is ticked but hidden
  /// is never sent.
  final Rx<UploadDateFilter> dateFilter = UploadDateFilter.all.obs;
  final Rxn<UploadDateRange> dateRange = Rxn<UploadDateRange>();

  bool _inFilter(UploadCandidate c) => BUploadDateFilter.matches(
        dateFilter.value,
        c.local.deliveryDate,
        now: _now(),
        range: dateRange.value,
      );

  /// The requests inside the date filter.
  List<UploadCandidate> get visible => candidates.where(_inFilter).toList();

  void setDateFilter(UploadDateFilter filter, {UploadDateRange? range}) {
    if (filter == UploadDateFilter.range && range == null) return;
    dateRange.value = filter == UploadDateFilter.range ? range : null;
    dateFilter.value = filter;
  }

  int countOf(UploadCandidateGroup group) =>
      visible.where((c) => c.group == group).length;

  List<UploadCandidate> inGroup(UploadCandidateGroup group) =>
      visible.where((c) => c.group == group).toList();

  List<UploadCandidate> get selected =>
      visible.where((c) => selectedIds.contains(c.id)).toList();

  bool isSelected(String id) => selectedIds.contains(id);

  /// Compares the phone with the server. Ready requests start ticked;
  /// not-on-server ones start unticked because they are unusual.
  Future<void> load() async {
    isLoading.value = true;
    loadError.value = null;
    isOffline.value = false;
    try {
      if (!await _isOnline()) {
        isOffline.value = true;
        candidates.clear();
        selectedIds.clear();
        return;
      }
      final local = await _loadLocal();
      final server = await _loadServer();
      candidates.assignAll(
          BUploadCandidateClassifier.classify(local: local, server: server));
      selectedIds
        ..clear()
        ..addAll(inGroup(UploadCandidateGroup.ready).map((c) => c.id));
    } catch (e) {
      logDebug('UploadDataController.load failed: $e');
      loadError.value = 'Could not compare with the server: $e';
      candidates.clear();
      selectedIds.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void toggle(UploadCandidate candidate) {
    if (!candidate.group.isSelectable) return;
    if (!selectedIds.remove(candidate.id)) selectedIds.add(candidate.id);
  }

  bool get allReadySelected {
    final ready = inGroup(UploadCandidateGroup.ready);
    return ready.isNotEmpty && ready.every((c) => selectedIds.contains(c.id));
  }

  /// Ticks every ready request, or unticks them when all already are.
  void toggleAllReady() {
    final ids = inGroup(UploadCandidateGroup.ready).map((c) => c.id);
    if (allReadySelected) {
      selectedIds.removeAll(ids);
    } else {
      selectedIds.addAll(ids);
    }
  }

  /// Sends the ticked requests, reports (done, total) through [onProgress],
  /// then reloads the comparison so uploaded rows move to Same status.
  ///
  /// The summary also counts the same-status requests found by the
  /// comparison, which were not sent, so the result says "N requests have the
  /// same status as the server".
  Future<Result<RequestUploadSummary>> uploadSelected(
      void Function(int done, int total) onProgress) async {
    try {
      final summary = await RequestUploadSummary.run(
        selected.map((c) => c.local),
        _send,
        onProgress: onProgress,
      );
      summary.sameStatus += countOf(UploadCandidateGroup.sameStatus);
      await summary.refreshSkipped(
        fetchServer: _loadServer,
        replaceLocal: _replaceLocal,
      );
      await _refreshDeliveryLists();
      await load();
      return Result.success(summary);
    } catch (e) {
      logDebug('UploadDataController.uploadSelected failed: $e');
      return Result.failure('Could not upload requests: $e');
    }
  }

  /// Replaces every server-ahead request on the phone with the server's
  /// copy. They are never sent, so without this the stale copies would stay
  /// on the phone and show up here every time. Returns how many were taken.
  Future<Result<int>> takeServerCopies() async {
    try {
      var taken = 0;
      for (final candidate in inGroup(UploadCandidateGroup.serverAhead)) {
        final serverCopy = candidate.server;
        if (serverCopy == null) continue;
        await _replaceLocal(serverCopy);
        taken++;
      }
      await _refreshDeliveryLists();
      await load();
      return Result.success(taken);
    } catch (e) {
      logDebug('UploadDataController.takeServerCopies failed: $e');
      return Result.failure("Could not take the server's copies: $e");
    }
  }

  /// Replaces one request on the phone with the server's copy (from the
  /// comparison sheet).
  Future<Result<void>> takeServerCopy(UploadCandidate candidate) async {
    final serverCopy = candidate.server;
    if (serverCopy == null) {
      return Result.failure('The server has no request ${candidate.id}.');
    }
    try {
      await _replaceLocal(serverCopy);
      await _refreshDeliveryLists();
      await load();
      return Result.success(null);
    } catch (e) {
      logDebug('UploadDataController.takeServerCopy failed: $e');
      return Result.failure("Could not take the server's copy: $e");
    }
  }

  /// The delivery tabs read the local table; reload them so they show the
  /// server copies taken for skipped requests.
  Future<void> _refreshDeliveryLists() async {
    try {
      if (Get.isRegistered<StandardDeliveryController>()) {
        await Get.find<StandardDeliveryController>().loadRequests();
      }
      if (Get.isRegistered<HotlineDirectController>()) {
        await Get.find<HotlineDirectController>().loadRequests();
      }
    } catch (e) {
      logDebug('UploadDataController: could not refresh delivery lists: $e');
    }
  }
}
