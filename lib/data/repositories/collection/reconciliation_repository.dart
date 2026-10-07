import 'dart:io';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_attachment_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_case_dao.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_clock.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_rules.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_validator.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Queues one change for "Upload All" (CollectionRepository.queueChange).
typedef ReconChangeQueue = Future<void> Function(
    String operation, String itemId, Map<String, dynamic> fields);

/// The Reconciliation Tracker's data on the phone
/// (docs/application/COLLECTION_RECONCILIATION_TRACKER_PLAN.md, Stage 3).
///
/// Every write is checked by the same rules the screens and the server use
/// ([canAppendReconActivity]), stored locally first (it works offline), and
/// queued for "Upload All" as RECON_OPEN_CASE / RECON_ACTIVITY, the upload
/// operations MDMPI.App accepts. Photos go to a file, a row, and their own
/// outbox (ReconAttachmentSyncService), uploaded once the case is on the server.
class ReconciliationRepository extends GetxController {
  ReconciliationRepository({
    Future<ReconCaseDao> Function()? caseDao,
    Future<ReconAttachmentDao> Function()? attachmentDao,
    ReconChangeQueue? queue,
    String Function()? collectorCode,
    String Function()? collectorName,
    DateTime Function()? now,
    Future<Directory> Function()? attachmentDirectory,
    Map<String, double> Function()? liveBalances,
    this.settings = const ReconSettings(),
  })  : _liveBalances = liveBalances ?? (() => const {}),
        _caseDao = caseDao ?? (() => DatabaseHelper.instance.reconCaseDao),
        _attachmentDao =
            attachmentDao ?? (() => DatabaseHelper.instance.reconAttachmentDao),
        _queue = queue ?? _defaultQueue,
        _collectorCode = collectorCode ??
            (() => CollectionRepository.instance.collectorCode),
        _collectorName = collectorName ??
            (() => CollectionRepository.instance.collectorName),
        _now = now ?? DateTime.now,
        _attachmentDirectory = attachmentDirectory ?? _defaultDirectory;

  static ReconciliationRepository get instance => Get.find();

  final Future<ReconCaseDao> Function() _caseDao;
  final Future<ReconAttachmentDao> Function() _attachmentDao;
  final ReconChangeQueue _queue;
  final String Function() _collectorCode;
  final String Function() _collectorName;
  final DateTime Function() _now;
  final Future<Directory> Function() _attachmentDirectory;
  final Map<String, double> Function() _liveBalances;
  final ReconSettings settings;

  /// Bumped on every write, so a screen can reload with one `ever`.
  final RxInt version = 0.obs;

  static Future<void> _defaultQueue(
          String operation, String itemId, Map<String, dynamic> fields) =>
      CollectionRepository.instance.queueChange(operation, itemId, fields);

  /// [bundle] with the phone's live balances (see [liveBalances] on the
  /// constructor: every invoice's balance on the phone now, bucket and
  /// Activity, so a collection recorded here counts before it is uploaded).
  ReconCaseBundle _live(ReconCaseBundle bundle) {
    try {
      return bundle.withBalances(_liveBalances());
    } catch (e) {
      logDebug('ReconciliationRepository: live balances unavailable: $e');
      return bundle;
    }
  }

  static Future<Directory> _defaultDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'recon_attachments'));
  }

  // ------------------------------------------------------------------
  // Reads
  // ------------------------------------------------------------------

  /// The folder this phone's reconciliation photos are saved in, as
  /// `<attachmentId>.jpg`.
  Future<String> photoDirectoryPath() async =>
      (await _attachmentDirectory()).path;

  Future<Result<List<ReconCaseBundle>>> loadCases() async {
    try {
      return Result.success(
          (await (await _caseDao()).getAll()).map(_live).toList());
    } catch (e) {
      logDebug('ReconciliationRepository.loadCases error: $e');
      return Result.failure('Could not read the reconciliation cases: $e');
    }
  }

  Future<Result<ReconCaseBundle>> loadCase(String caseId) async {
    try {
      final stored = await (await _caseDao()).getCase(caseId);
      final bundle = stored == null ? null : _live(stored);
      return bundle == null
          ? Result.failure('Case $caseId is not on this phone.')
          : Result.success(bundle);
    } catch (e) {
      logDebug('ReconciliationRepository.loadCase error: $e');
      return Result.failure('Could not read case $caseId: $e');
    }
  }

  /// The account's open case, if it has one on this phone.
  Future<Result<ReconCaseBundle?>> openCaseFor(String clientCode) async {
    final all = await loadCases();
    if (all.isFailure) return Result.failure(all.error);
    final now = _now();
    return Result.success(all.value.firstWhereOrNull((b) =>
        b.reconCase.clientCode == clientCode &&
        !b.evaluate(now: now, settings: settings).isClosed));
  }

  // ------------------------------------------------------------------
  // Writes
  // ------------------------------------------------------------------

  /// Open a case for [clientCode] over [invoices] (each with its balance now).
  /// An account has at most one open case, and an invoice is in at most one.
  Future<Result<ReconCaseBundle>> openCase({
    required String clientCode,
    required String clientName,
    required List<ReconCaseInvoice> invoices,
  }) async {
    final code = clientCode.trim();
    if (code.isEmpty) return Result.failure('Pick the account.');
    final picked = {for (final i in invoices) i.invoiceNo.trim(): i}
      ..removeWhere((no, _) => no.isEmpty);
    if (picked.isEmpty) return Result.failure('Pick at least one invoice.');

    try {
      final dao = await _caseDao();
      final now = _now();
      for (final b in (await dao.getAll()).map(_live)) {
        if (b.evaluate(now: now, settings: settings).isClosed) continue;
        if (b.reconCase.clientCode == code) {
          return Result.failure(
              '${b.reconCase.clientName.isEmpty ? code : b.reconCase.clientName} '
              'already has an open case (${b.caseId}).');
        }
        final taken = b.invoices
            .map((i) => i.invoiceNo)
            .where(picked.containsKey)
            .toList();
        if (taken.isNotEmpty) {
          return Result.failure(
              'Already in open case ${b.caseId}: ${taken.join(', ')}.');
        }
      }

      final collector = _collectorCode();
      final bundle = ReconCaseBundle(
        reconCase: ReconCase(
          caseId: _newId('RC', collector, now),
          clientCode: code,
          clientName: clientName.trim(),
          collectorCode: collector,
          collectorName: _collectorName(),
          dateOpened: BReconClock.stamp(now),
        ),
        invoices: [
          for (final i in picked.values)
            ReconCaseInvoice(invoiceNo: i.invoiceNo.trim(), amount: i.amount),
        ],
        activities: const [],
      );
      await dao.saveLocalCase(
          bundle, bundle.evaluate(now: now, settings: settings));
      await _queue('RECON_OPEN_CASE', bundle.caseId, {
        'CaseId': bundle.caseId,
        'ClientCode': code,
        'DocumentIds': bundle.invoices.map((i) => i.invoiceNo).toList(),
        'EngagementDate': bundle.reconCase.dateOpened,
      });
      version.value++;
      logDebug('ReconciliationRepository: opened ${bundle.caseId} for $code '
          '(${bundle.invoices.length} invoices)');
      return Result.success(bundle);
    } catch (e) {
      logDebug('ReconciliationRepository.openCase error: $e');
      return Result.failure('Could not open the case: $e');
    }
  }

  /// Log one step of case [caseId], with its [photos] (JPEG bytes).
  ///
  /// Refused with the reason when the rules would not apply it (the case has
  /// ended, an invoice is not in the case, there is no proof to validate…).
  Future<Result<ReconActivity>> appendActivity({
    required String caseId,
    required ReconActivityType type,
    List<String> invoiceNos = const [],
    String remarks = '',
    double? amount,
    ReconValidationResult? validationResult,
    String nextAction = '',
    String? nextActionDueDate,
    List<Uint8List> photos = const [],
  }) async {
    try {
      final dao = await _caseDao();
      final stored = await dao.getCase(caseId);
      final bundle = stored == null ? null : _live(stored);
      if (bundle == null) {
        return Result.failure('Case $caseId is not on this phone.');
      }

      final now = _now();
      final names =
          invoiceNos.map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
      final allowed = canAppendReconActivity(
        bundle.evaluate(now: now, settings: settings),
        ReconActivityDraft(
            type: type, invoiceNos: names, validationResult: validationResult),
      );
      if (allowed.isFailure) return Result.failure(allowed.error);

      final collector = _collectorCode();
      final activityId = _newId('RA', collector, now);
      final attachments = <ReconAttachmentRecord>[];
      if (photos.isNotEmpty) {
        final dir = await _attachmentDirectory();
        if (!await dir.exists()) await dir.create(recursive: true);
        for (var i = 0; i < photos.length; i++) {
          final attachmentId = '${_newId('RP', collector, now)}-$i';
          final file = File(p.join(dir.path, '$attachmentId.jpg'));
          await file.writeAsBytes(photos[i], flush: true);
          attachments.add(ReconAttachmentRecord(
            attachmentId: attachmentId,
            caseId: caseId,
            activityId: activityId,
            filePath: file.path,
            createdAt: now.toIso8601String(),
          ));
        }
      }

      final activity = ReconActivity(
        activityId: activityId,
        caseId: caseId,
        dateTime: BReconClock.stamp(now),
        type: type,
        invoiceNos: names,
        remarks: remarks.trim(),
        amount: type == ReconActivityType.soaSent ||
                type == ReconActivityType.paymentRecorded
            ? amount
            : null,
        validationResult:
            type == ReconActivityType.proofValidated ? validationResult : null,
        nextAction: nextAction.trim(),
        nextActionDueDate: (nextActionDueDate ?? '').trim().isEmpty
            ? null
            : nextActionDueDate!.trim(),
        attachmentRefs: attachments.map((a) => a.attachmentId).toList(),
        recordedBy: collector,
      );

      await dao.addLocalActivity(activity,
          bundle.withActivity(activity).evaluate(now: now, settings: settings));
      final attachmentDao = await _attachmentDao();
      for (final a in attachments) {
        await attachmentDao.insert(a);
      }
      await _queue('RECON_ACTIVITY', activityId, {
        'CaseId': caseId,
        'ActivityType': type.code,
        'DocumentIds': names,
        'Remarks': activity.remarks,
        'EngagementDate': activity.dateTime,
        'ReconAmount': activity.amount,
        'ValidationResult': activity.validationResult?.code,
        'NextAction': activity.nextAction,
        'NextActionDueDate': activity.nextActionDueDate,
        'AttachmentIds': activity.attachmentRefs,
      });
      version.value++;
      logDebug('ReconciliationRepository: $caseId ${type.code} logged '
          '($activityId, ${attachments.length} photo(s))');
      return Result.success(activity);
    } catch (e) {
      logDebug('ReconciliationRepository.appendActivity error: $e');
      return Result.failure('Could not log the step: $e');
    }
  }

  // ------------------------------------------------------------------
  // Logged by the app: what happened around a case
  // ------------------------------------------------------------------

  /// The open cases on the phone, evaluated now.
  Future<List<ReconCaseBundle>> _openCases() async {
    final now = _now();
    return [
      for (final b in (await (await _caseDao()).getAll()).map(_live))
        if (!b.evaluate(now: now, settings: settings).isClosed) b,
    ];
  }

  /// A collection saved on [invoiceId] goes on its open case's timeline, if it
  /// is in one. Does nothing for no case, or for no amount.
  Future<Result<ReconActivity?>> recordPayment({
    required String invoiceId,
    required double amount,
    String outcome = '',
    String? bankName,
    String? checkNumber,
  }) async {
    if (amount <= 0) return Result.success(null);
    try {
      final cases = (await _openCases())
          .where((b) => b.invoices.any((i) => i.invoiceNo == invoiceId));
      if (cases.isEmpty) return Result.success(null);
      final remarks = [
        if (outcome.trim().isNotEmpty) outcome.trim(),
        if ((bankName ?? '').trim().isNotEmpty) bankName!.trim(),
        if ((checkNumber ?? '').trim().isNotEmpty)
          'check ${checkNumber!.trim()}',
      ].join(' · ');
      final r = await appendActivity(
        caseId: cases.first.caseId,
        type: ReconActivityType.paymentRecorded,
        invoiceNos: [invoiceId],
        amount: amount,
        remarks: remarks,
      );
      return r.isSuccess ? Result.success(r.value) : Result.failure(r.error);
    } catch (e) {
      logDebug('ReconciliationRepository.recordPayment error: $e');
      return Result.failure('Could not log the payment on its case: $e');
    }
  }

  /// The holder released [clientCode] (Done Engagement or Defer): its open
  /// case has no holder until someone acquires the account.
  Future<Result<int>> releaseCasesFor(String clientCode,
      {String remarks = ''}) async {
    try {
      final me = _collectorCode().trim().toUpperCase();
      var released = 0;
      for (final b in await _openCases()) {
        if (b.reconCase.clientCode != clientCode ||
            b.reconCase.collectorCode.trim().toUpperCase() != me) {
          continue;
        }
        final r = await appendActivity(
            caseId: b.caseId,
            type: ReconActivityType.caseReleased,
            remarks: remarks);
        if (r.isFailure) return Result.failure(r.error);
        await (await _caseDao()).setCollector(b.caseId, '', '');
        released++;
      }
      if (released > 0) version.value++;
      return Result.success(released);
    } catch (e) {
      logDebug('ReconciliationRepository.releaseCasesFor error: $e');
      return Result.failure('Could not release the case: $e');
    }
  }

  /// This collector acquired [clientCode]: they hold its open case now.
  Future<Result<int>> acquireCasesFor(String clientCode) async {
    try {
      final me = _collectorCode().trim();
      var acquired = 0;
      for (final b in await _openCases()) {
        if (b.reconCase.clientCode != clientCode ||
            b.reconCase.collectorCode.trim().toUpperCase() ==
                me.toUpperCase()) {
          continue;
        }
        final r = await appendActivity(
            caseId: b.caseId, type: ReconActivityType.caseAcquired);
        if (r.isFailure) return Result.failure(r.error);
        await (await _caseDao()).setCollector(b.caseId, me, _collectorName());
        acquired++;
      }
      if (acquired > 0) version.value++;
      return Result.success(acquired);
    } catch (e) {
      logDebug('ReconciliationRepository.acquireCasesFor error: $e');
      return Result.failure('Could not take over the case: $e');
    }
  }

  /// A device-made id, unique across phones and taps:
  /// `RC-<collector>-<microseconds>`.
  static String _newId(String prefix, String collector, DateTime now) {
    final who =
        collector.trim().isEmpty ? 'NA' : collector.trim().toUpperCase();
    return '$prefix-$who-${now.microsecondsSinceEpoch}';
  }
}
