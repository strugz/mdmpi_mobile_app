import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/voucher_invoice_repository.dart';
import 'package:mdmpi_mobile_app/data/services/outbox/voucher_reread_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/voucher_si_matcher.dart';
import 'package:mdmpi_mobile_app/features/collection/models/scanned_invoice.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

/// Queues a page read on the phone for the AI to read again online.
typedef RereadQueue = Future<void> Function({
  required String clientId,
  String clientName,
  required File page,
  required List<String> offlineIds,
});

/// The voucher / SI scan on a claimed account (meeting of 2026-10-07,
/// item 2): a scanned page's invoice numbers are ticked straight in the
/// account's list ([scanAndSelect]); every number read is kept here for the
/// Scanned Invoices screen, where misreads are corrected or removed.
///
/// One account at a time: opening another account starts a new list, and
/// leaving the account (which empties the cart) clears it.
class VoucherScanController extends GetxController {
  VoucherScanController({
    VoucherInvoiceRepository? repository,
    CollectionActivityController Function()? activity,
    RereadQueue? queueReread,
  })  : _repositoryOverride = repository,
        _activity = activity ?? (() => CollectionActivityController.instance),
        _queueReread = queueReread ?? _defaultQueue;

  static VoucherScanController get instance => Get.find();

  final VoucherInvoiceRepository? _repositoryOverride;
  final CollectionActivityController Function() _activity;
  final RereadQueue? _queueReread;

  static RereadQueue? get _defaultQueue =>
      Get.isRegistered<VoucherRereadService>()
          ? VoucherRereadService.instance.enqueue
          : null;

  VoucherInvoiceRepository get _repository =>
      _repositoryOverride ?? VoucherInvoiceRepository.instance;

  final tiles = <ScannedInvoice>[].obs;
  final isAnalyzing = false.obs;
  final error = RxnString();

  /// What the last scan did, for the banner on the account's list.
  final lastScan = Rxn<VoucherScanSummary>();

  String _clientId = '';

  String _clientName() =>
      _activity()
          .masterAccountList
          .firstWhereOrNull((c) => c.id == _clientId)
          ?.name ??
      '';
  String get clientId => _clientId;

  Worker? _cartEnded;

  @override
  void onInit() {
    super.onInit();
    // The scan's banner and list belong to the cart it filled: once the cart
    // ends (its invoices recorded, the cart cleared, every one unticked),
    // they go too, instead of announcing a selection that is gone.
    try {
      _cartEnded = ever<bool>(_activity().isActivitySelectionMode, (carting) {
        if (!carting) reset();
      });
    } catch (_) {
      // No account screens (some tests): nothing to follow.
    }
  }

  @override
  void onClose() {
    _cartEnded?.dispose();
    super.onClose();
  }

  /// The last scan's summary for [clientId]'s banner, or null when there is
  /// nothing to show: no scan, another account's, or a scan whose selected
  /// invoices are all out of the cart now (recorded, cleared, unticked). A
  /// scan that selected nothing keeps its banner until dismissed. Read inside
  /// an Obx it follows both the scan and the cart.
  VoucherScanSummary? bannerFor(String clientId) {
    final last = lastScan.value;
    if (last == null || _clientId != clientId) return null;
    if (last.selectedIds.isEmpty) return last;
    final cart = _activity().selectedActivityInvoiceIds;
    return last.selectedIds.any(cart.contains) ? last : null;
  }

  /// Starts (or resumes) the list for [clientId].
  void openFor(String clientId) {
    if (clientId != _clientId) reset();
    _clientId = clientId;
  }

  void reset() {
    tiles.clear();
    error.value = null;
    lastScan.value = null;
    _clientId = '';
  }

  /// Some numbers were read by the phone itself, without the AI.
  bool get anyOffline => tiles.any((t) => t.offline);

  /// The open invoices of this account the list names, ready for the cart.
  List<String> get addableIds => [
        for (final t in tiles)
          if (t.status.canAdd && t.invoiceId != null) t.invoiceId!,
      ];

  ScannedInvoiceClassifier get _classifier =>
      classifierFor(_activity(), _clientId);

  /// Checks numbers against [clientId]'s invoices as [activity] holds them:
  /// its open ones, the client's others, and its P.O.s and references.
  static ScannedInvoiceClassifier classifierFor(
      CollectionActivityController activity, String clientId) {
    final open = activity.getActivityOpenInvoices(clientId);
    final openIds = {for (final i in open) i.id};
    return ScannedInvoiceClassifier(
      knownIds: openIds,
      elsewhereIds: [
        for (final i in activity.allItems)
          if (i.client.id == clientId && !openIds.contains(i.id)) i.id,
      ],
      // The voucher's own P.O. and references are not missing invoices.
      ignore: [
        for (final i in open) ...[i.poNumber, ...i.documentReferences],
      ],
    );
  }

  /// Reads the [pages] of one scan and ticks their open invoices in the
  /// account's list; null when nothing could be read ([error] says why).
  /// [useAi] false reads every page on the phone (Scan with camera).
  Future<VoucherScanSummary?> scanAndSelect(List<File> pages,
      {bool useAi = true}) async {
    final found = <ScannedInvoice>[];
    String? lastError;
    for (final page in pages) {
      found.addAll(await analyze(page, useAi: useAi));
      lastError = error.value ?? lastError;
    }
    if (found.isEmpty) {
      error.value = lastError ?? 'No invoice numbers were found.';
      return null;
    }
    error.value = null;
    final ids = [
      for (final t in found)
        if (t.status.canAdd && t.invoiceId != null) t.invoiceId!,
    ];
    _activity().addFromVoucher(ids);
    final summary = VoucherScanSummary(
      selectedIds: ids,
      notFound: [
        for (final t in found)
          if (t.status == ScannedInvoiceStatus.notFound) t.read,
      ],
      unsure: found
          .where((t) =>
              t.status == ScannedInvoiceStatus.likely ||
              t.status == ScannedInvoiceStatus.elsewhere ||
              t.status == ScannedInvoiceStatus.ambiguous)
          .length,
      offline: found.any((t) => t.offline),
    );
    lastScan.value = summary;
    return summary;
  }

  /// Reads one page and lists what it names; a number already listed is not
  /// listed twice. Returns the new tiles.
  Future<List<ScannedInvoice>> analyze(File file, {bool useAi = true}) async {
    isAnalyzing.value = true;
    error.value = null;
    try {
      final result = await _repository.read(file, useAi: useAi);
      if (result.isFailure) {
        error.value = result.error;
        return const [];
      }
      final read = result.value;
      final classifier = _classifier;
      final found = read.isOffline
          ? classifier.offlineLines(read.offlineLines!)
          : read.lines.map(classifier.line).toList();
      // Read on the phone: keep the page for the AI to read again online.
      if (read.isOffline && !file.path.toLowerCase().endsWith('.pdf')) {
        final queue = _queueReread;
        if (queue != null) {
          unawaited(queue(
            clientId: _clientId,
            clientName: _clientName(),
            page: file,
            offlineIds: [
              for (final t in found)
                if (t.invoiceId != null) t.invoiceId!,
            ],
          ));
        }
      }
      final seen = {for (final t in tiles) t.key};
      final added = found.where((t) => seen.add(t.key)).toList();
      tiles.addAll(added);
      if (found.isEmpty) {
        error.value = 'No invoice numbers were found on that page.';
      }
      return added;
    } finally {
      isAnalyzing.value = false;
    }
  }

  /// The collector's correction of tile [index]: matched again, keeping the
  /// label and amount the voucher printed.
  void edit(int index, String number) {
    if (index < 0 || index >= tiles.length) return;
    final old = tiles[index];
    final typed = number.trim();
    if (typed.isEmpty) return;
    tiles[index] = _classifier.line(VoucherInvoiceLine(
        invoiceNo: typed, label: old.label, amount: old.amount));
  }

  void remove(int index) {
    if (index >= 0 && index < tiles.length) tiles.removeAt(index);
  }

  /// Ticks every open invoice on the list in the account's list; how many.
  int addToCart() {
    final ids = addableIds;
    _activity().addFromVoucher(ids);
    return ids.length;
  }
}
