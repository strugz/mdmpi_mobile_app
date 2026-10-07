import 'dart:async';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/reconciliation_repository.dart';
import 'package:mdmpi_mobile_app/data/services/collection_sms_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_roles.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_posting.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_summary.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_evaluation.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

/// A case and where it stands now.
class ReconCaseView {
  const ReconCaseView(this.bundle, this.evaluation);

  final ReconCaseBundle bundle;
  final ReconEvaluation evaluation;

  ReconCase get reconCase => bundle.reconCase;
  String get caseId => bundle.caseId;
}

/// Which of the collector's cases the dashboard lists.
enum ReconDashboardFilter {
  open('Open'),
  closed('Closed'),
  all('All');

  const ReconDashboardFilter(this.label);

  final String label;
}

/// The Reconciliation Tracker's screens: the dashboard, the case screen and
/// the log sheet (docs/application/COLLECTION_RECONCILIATION_TRACKER_PLAN.md,
/// Stage 4). Reads and writes through [ReconciliationRepository]; every
/// status shown is evaluated from the log at load time.
class ReconciliationController extends GetxController {
  ReconciliationController({
    ReconciliationRepository? repository,
    String Function()? collectorCode,
    Set<String> Function()? heldInvoiceIds,
    bool Function()? isHead,
    DateTime Function()? now,
  })  : _repositoryOverride = repository,
        _isHead = isHead ?? _defaultIsHead,
        _collectorCode = collectorCode ?? _defaultCollector,
        _heldInvoiceIds = heldInvoiceIds ?? _defaultHeld,
        _now = now ?? DateTime.now;

  static ReconciliationController get instance => Get.find();

  final ReconciliationRepository? _repositoryOverride;
  final String Function() _collectorCode;
  final Set<String> Function() _heldInvoiceIds;
  final bool Function() _isHead;
  final DateTime Function() _now;

  ReconciliationRepository get _repository =>
      _repositoryOverride ?? ReconciliationRepository.instance;

  /// Every case on the phone, as last loaded.
  final RxList<ReconCaseView> cases = <ReconCaseView>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  /// Where this phone's photos are, for thumbnails; null until known.
  final RxnString photoDirectory = RxnString();

  Worker? _versionWorker;
  final List<Worker> _itemWorkers = [];

  static String _defaultCollector() => Get.isRegistered<CollectionRepository>()
      ? CollectionRepository.instance.collectorCode
      : '';

  static bool _defaultIsHead() =>
      Get.isRegistered<UserController>() &&
      BCollectionRoles.isHead(UserController.instance.user.value);

  /// Invoices this collector holds now (Activity): a case on them is theirs
  /// even before the server has moved it to them.
  static Set<String> _defaultHeld() =>
      Get.isRegistered<CollectionActivityController>()
          ? CollectionActivityController.instance.activityItems
              .map((i) => i.id)
              .toSet()
          : const {};

  @override
  void onInit() {
    super.onInit();
    _versionWorker = ever(_repository.version, (_) => unawaited(load()));
    // A payment or release changes an invoice's balance, and the case shows
    // it; debounced, since the bucket holds thousands of rows.
    if (Get.isRegistered<CollectionActivityController>()) {
      final items = CollectionActivityController.instance;
      for (final list in [items.activityItems, items.bucketItems]) {
        _itemWorkers.add(debounce(list, (_) => unawaited(load()),
            time: const Duration(milliseconds: 400)));
      }
    }
    unawaited(load());
    unawaited(_resolvePhotoDirectory());
  }

  Future<void> _resolvePhotoDirectory() async {
    try {
      photoDirectory.value = await _repository.photoDirectoryPath();
    } catch (e) {
      logDebug('ReconciliationController: no photo folder: $e');
    }
  }

  @override
  void onClose() {
    _versionWorker?.dispose();
    for (final w in _itemWorkers) {
      w.dispose();
    }
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    final result = await _repository.loadCases();
    isLoading.value = false;
    if (result.isFailure) {
      error.value = result.error;
      return;
    }
    error.value = null;
    final now = _now();
    cases.assignAll([
      for (final b in result.value)
        ReconCaseView(b, b.evaluate(now: now, settings: _repository.settings)),
    ]);
  }

  /// The dashboard's filter; open cases unless the collector asks for more.
  final Rx<ReconDashboardFilter> dashboardFilter =
      ReconDashboardFilter.open.obs;

  /// This collector's cases (Step 1 of every round): open ones first, the
  /// one untouched longest at the top. Mine: I hold it, I hold one of its
  /// invoices, or it has ended and I logged a step on it (a paid case stays
  /// in my history after the account has left my bucket). An open case I
  /// worked on that someone else holds now is theirs.
  List<ReconCaseView> get myCases {
    final me = _collectorCode().trim().toUpperCase();
    final held = _heldInvoiceIds();
    bool workedOn(ReconCaseView c) =>
        c.evaluation.isClosed &&
        c.bundle.activities
            .any((a) => a.recordedBy.trim().toUpperCase() == me);
    final mine = cases
        .where((c) =>
            c.reconCase.collectorCode.trim().toUpperCase() == me ||
            c.bundle.invoices.any((i) => held.contains(i.invoiceNo)) ||
            (me.isNotEmpty && workedOn(c)))
        .toList()
      ..sort((a, b) => compareForReconDashboard(a.evaluation, b.evaluation));
    return mine;
  }

  List<ReconCaseView> get myOpenCases =>
      myCases.where((c) => !c.evaluation.isClosed).toList();

  /// [myCases] through [dashboardFilter].
  List<ReconCaseView> get dashboardCases => switch (dashboardFilter.value) {
        ReconDashboardFilter.open => myOpenCases,
        ReconDashboardFilter.closed =>
          myCases.where((c) => c.evaluation.isClosed).toList(),
        ReconDashboardFilter.all => myCases,
      };

  /// Invoices whose case has ended (completed, not completed, escalated) and
  /// that no open case has taken up since: nobody may acquire them from
  /// Reconciliation, since a closed case takes no more steps.
  Set<String> get endedCaseInvoiceIds {
    final open = <String>{};
    final ended = <String>{};
    for (final c in cases) {
      final target = c.evaluation.isClosed ? ended : open;
      target.addAll(c.bundle.invoices.map((i) => i.invoiceNo));
    }
    return ended.difference(open);
  }

  ReconCaseView? caseById(String caseId) =>
      cases.firstWhereOrNull((c) => c.caseId == caseId);

  /// Whose cases the reports cover: the Head sees every case on the phone
  /// (the whole team's, as the download carries them), a collector their own.
  bool get reportsCoverTeam => _isHead();

  List<ReconCaseView> get reportCases {
    if (!_isHead()) return myCases;
    return [...cases]
      ..sort((a, b) => compareForReconDashboard(a.evaluation, b.evaluation));
  }

  ReconSummary get summary =>
      ReconSummary.of(reportCases.map((c) => c.evaluation));

  /// Step 9: validated paid, waiting for Accounting to post.
  List<ReconAwaitingPosting> get awaitingPosting => reconAwaitingPosting(
      reportCases.map((c) => (bundle: c.bundle, evaluation: c.evaluation)));

  /// Escalated: the Head is told by SMS (Android; the escalation is logged
  /// either way). Never blocks or undoes the step.
  void _textHeadAboutEscalation(String caseId, String remarks) {
    if (!Get.isRegistered<CollectionSmsService>()) return;
    final view = caseById(caseId);
    if (view == null) return;
    final open = view.evaluation.openInvoices;
    unawaited(Get.find<CollectionSmsService>()
        .notifyReconEscalated(
      clientName: view.reconCase.clientName,
      openInvoices: open.length,
      openAmount: view.evaluation.amountUnderReconciliation,
      remarks: remarks,
    )
        .then((_) {}, onError: (Object e) {
      logDebug('ReconciliationController: escalation SMS failed: $e');
    }));
  }

  Future<Result<ReconCaseBundle>> openCase({
    required String clientCode,
    required String clientName,
    required List<ReconCaseInvoice> invoices,
  }) async {
    final r = await _repository.openCase(
        clientCode: clientCode, clientName: clientName, invoices: invoices);
    if (r.isSuccess) await load();
    return r;
  }

  Future<Result<ReconActivity>> logActivity({
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
    final r = await _repository.appendActivity(
      caseId: caseId,
      type: type,
      invoiceNos: invoiceNos,
      remarks: remarks,
      amount: amount,
      validationResult: validationResult,
      nextAction: nextAction,
      nextActionDueDate: nextActionDueDate,
      photos: photos,
    );
    if (r.isSuccess) {
      await load();
      if (type == ReconActivityType.caseEscalated) {
        _textHeadAboutEscalation(caseId, remarks);
      }
    } else {
      logDebug('ReconciliationController.logActivity refused: ${r.error}');
    }
    return r;
  }
}
