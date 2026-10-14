import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_notification_service.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/voucher_reread_dao.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/voucher_invoice_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/voucher_si_matcher.dart';
import 'package:mdmpi_mobile_app/features/collection/models/scanned_invoice.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The AI's reading of one page.
typedef VoucherAiPageReader = Future<Result<List<VoucherInvoiceLine>>> Function(
    File page);

/// How to check numbers against an account's invoices as they stand now;
/// null while the invoices are not loaded yet (the page then waits).
typedef ClassifierFor = ScannedInvoiceClassifier? Function(String clientId);

/// Tells the collector a re-read found invoices (a local notification).
typedef RereadNotifier = Future<void> Function(VoucherRereadRecord found);

/// Re-reads with the AI the voucher pages the phone read by itself
/// (meeting of 2026-10-07, item 2): a scan made without a connection, or
/// with Scan with camera, is kept and read again once the phone is online,
/// the way reconciliation photos are uploaded: on app start, when the
/// connection comes back, when the app is resumed, and right after a page
/// is queued. Invoices of the account the AI finds that the phone's reading
/// missed are reported: a notification, and a banner on the account's list
/// that selects them. Pages are kept a week at most.
class VoucherRereadService extends GetxController with WidgetsBindingObserver {
  VoucherRereadService({
    Future<VoucherRereadDao> Function()? dao,
    VoucherAiPageReader? readWithAi,
    ClassifierFor? classifierFor,
    RereadNotifier? notify,
    Future<bool> Function()? isConnected,
    Future<Directory> Function()? pagesDirectory,
    DateTime Function()? now,
    this.startupDelay = const Duration(seconds: 10),
    this.maxRetries = 10,
    this.keepFor = const Duration(days: 7),
    this.observeLifecycle = true,
    this.watchConnectivity = true,
  })  : _dao = dao ?? (() => DatabaseHelper.instance.voucherRereadDao),
        _readWithAi = readWithAi ??
            ((page) => VoucherInvoiceRepository.instance.readWithAi(page)),
        _classifierFor = classifierFor ?? ((_) => null),
        _notify = notify ?? _localNotification,
        _isConnected =
            isConnected ?? (() => NetworkManager.instance.isConnected()),
        _pagesDirectory = pagesDirectory ?? _defaultDirectory,
        _now = now ?? DateTime.now;

  static VoucherRereadService get instance => Get.find();

  final Future<VoucherRereadDao> Function() _dao;
  final VoucherAiPageReader _readWithAi;
  final ClassifierFor _classifierFor;
  final RereadNotifier _notify;
  final Future<bool> Function() _isConnected;
  final Future<Directory> Function() _pagesDirectory;
  final DateTime Function() _now;
  final Duration startupDelay;
  final int maxRetries;
  final Duration keepFor;

  /// False in tests, where there is no [WidgetsBinding] to observe.
  final bool observeLifecycle;

  /// False in tests, where [NetworkManager] is not registered.
  final bool watchConnectivity;

  final RxBool isFlushing = false.obs;
  final RxInt pending = 0.obs;

  /// Finished re-reads that found invoices the collector has not seen.
  final RxList<VoucherRereadRecord> unseen = <VoucherRereadRecord>[].obs;

  Worker? _connectivityWorker;
  Timer? _startupTimer;
  var _seq = 0;

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

  /// Keeps a copy of [page] (read on the phone for [clientId]; the phone
  /// found [offlineIds]) to read again online. Never throws.
  Future<void> enqueue({
    required String clientId,
    String clientName = '',
    required File page,
    required List<String> offlineIds,
  }) async {
    try {
      final dir = await _pagesDirectory();
      if (!await dir.exists()) await dir.create(recursive: true);
      final now = _now();
      final id = 'VR-${now.microsecondsSinceEpoch}-${_seq++}';
      final ext =
          p.extension(page.path).isEmpty ? '.jpg' : p.extension(page.path);
      final copy = await page.copy(p.join(dir.path, '$id$ext'));
      final dao = await _dao();
      await dao.insert(VoucherRereadRecord(
        rereadId: id,
        clientId: clientId,
        clientName: clientName,
        pagePath: copy.path,
        offlineIds: offlineIds,
        createdAt: now.toIso8601String(),
      ));
      pending.value = await dao.countPending();
      unawaited(flush(reason: 'page queued'));
    } catch (e) {
      logDebug('VoucherRereadService.enqueue error: $e');
    }
  }

  /// Re-reads every waiting page while online. Returns how many pages were
  /// read. Never throws.
  ///
  /// A call while one is running waits for it; a page queued meanwhile is
  /// read by one more pass straight after.
  Future<int> flush({required String reason}) {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    return _running = _passes(reason);
  }

  Future<int>? _running;
  var _again = false;

  Future<int> _passes(String reason) async {
    isFlushing.value = true;
    var total = 0;
    try {
      do {
        _again = false;
        total += await _pass(reason);
      } while (_again);
    } finally {
      isFlushing.value = false;
      _running = null;
    }
    return total;
  }

  Future<int> _pass(String reason) async {
    var read = 0;
    try {
      final dao = await _dao();
      await _dropOld(dao);
      unseen.assignAll(await dao.getUnseen());
      if (!await _isConnected()) return 0;
      final waiting = await dao.getPending(maxRetries: maxRetries);
      if (waiting.isNotEmpty) {
        logDebug('VoucherRereadService: flush ($reason): '
            '${waiting.length} page(s)');
      }
      for (final r in waiting) {
        final classifier = _classifierFor(r.clientId);
        if (classifier == null) continue; // invoices not loaded yet
        final page = File(r.pagePath);
        if (!await page.exists()) {
          await dao.markRetry(r.rereadId, 'The page file is missing',
              maxRetries: 0);
          continue;
        }
        final result = await _readWithAi(page);
        if (result.isFailure) {
          await dao.markRetry(r.rereadId, result.error, maxRetries: maxRetries);
          continue;
        }
        final tiles = result.value.map(classifier.line).toList();
        final already = r.offlineIds.toSet();
        final found = [
          for (final t in tiles)
            if (t.status.canAdd && t.invoiceId != null)
              if (!already.contains(t.invoiceId)) t.invoiceId!,
        ];
        final notFound = [
          for (final t in tiles)
            if (t.status == ScannedInvoiceStatus.notFound) t.read,
        ];
        await dao.markDone(r.rereadId, foundIds: found, notFound: notFound);
        await _deleteFile(page);
        read++;
        if (found.isNotEmpty) {
          unawaited(_notify(VoucherRereadRecord(
            rereadId: r.rereadId,
            clientId: r.clientId,
            clientName: r.clientName,
            pagePath: r.pagePath,
            foundIds: found,
            notFound: notFound,
            status: VoucherRereadStatus.done,
          )).catchError((Object e) =>
              logDebug('VoucherRereadService: notify failed: $e')));
        }
      }
      pending.value = await dao.countPending();
      unseen.assignAll(await dao.getUnseen());
    } catch (e) {
      logDebug('VoucherRereadService.flush error: $e');
    }
    return read;
  }

  /// What re-reads found for [clientId] that the collector has not seen.
  List<VoucherRereadRecord> unseenFor(String clientId) =>
      unseen.where((r) => r.clientId == clientId).toList();

  /// The collector selected or dismissed [records]' findings.
  Future<void> markSeen(Iterable<VoucherRereadRecord> records) async {
    final ids = records.map((r) => r.rereadId).toSet();
    unseen.removeWhere((r) => ids.contains(r.rereadId));
    try {
      await (await _dao()).markSeen(ids);
    } catch (e) {
      logDebug('VoucherRereadService.markSeen error: $e');
    }
  }

  Future<void> _dropOld(VoucherRereadDao dao) async {
    final cutoff = _now().subtract(keepFor).toIso8601String();
    for (final path in await dao.deleteOlderThan(cutoff)) {
      await _deleteFile(File(path));
    }
  }

  static Future<void> _deleteFile(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  static Future<Directory> _defaultDirectory() async => Directory(p.join(
      (await getApplicationDocumentsDirectory()).path, 'voucher_rereads'));

  static Future<void> _localNotification(VoucherRereadRecord r) async {
    if (!Get.isRegistered<INotificationService>()) return;
    final n = r.foundIds.length;
    await Get.find<INotificationService>().showSimple(
      id: r.rereadId.hashCode & 0x7fffffff,
      title: 'Voucher re-read online',
      body: '$n more invoice${n == 1 ? '' : 's'} found'
          '${r.clientName.isEmpty ? '' : ' for ${r.clientName}'}: '
          '${r.foundIds.join(', ')}. Open the account to select '
          '${n == 1 ? 'it' : 'them'}.',
      payload: 'voucher-reread:${r.clientId}',
    );
  }
}
