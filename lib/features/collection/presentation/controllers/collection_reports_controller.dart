import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/csv_writer.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_engagement_dao.dart';
import 'package:mdmpi_mobile_app/data/models/report_table.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/team_activity_repository.dart';
import 'package:mdmpi_mobile_app/data/services/report_export_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_roles.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reports/activity_report.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reports/collectors_summary_report.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reports/recon_detail_report.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reports/report_month.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_evaluation.dart';
import 'package:mdmpi_mobile_app/features/collection/models/team_engagement.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/team_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// The collector's archive for one month (`yyyy-MM`).
typedef OwnEngagementsLoader = Future<Result<List<CollectionEngagementRecord>>>
    Function(String yearMonth);

/// Backs Settings → Reports: the month-end Activity report, the Collectors
/// summary and the Reconciliation detail, each exportable as CSV (saved or
/// shared). The rows come from the pure builders in `helpers/reports/`;
/// this only loads their inputs and keeps the month and scope on screen.
class CollectionReportsController extends GetxController {
  CollectionReportsController({
    OwnEngagementsLoader? loadOwn,
    TeamFeedLoader? loadTeam,
    List<ReconCaseView> Function(ReconScope scope)? cases,
    RxInterface? casesChanged,
    String Function()? collectorCode,
    String Function()? collectorName,
    bool Function()? isHead,
    ReportExportService? exporter,
    DateTime Function()? now,
  })  : _loadOwn = loadOwn ?? _ownFromRepository,
        _loadTeam = loadTeam ?? _teamFromRepository,
        _cases = cases ?? _casesFromTracker,
        _casesChangedOverride = casesChanged,
        _collectorCode = collectorCode ?? _defaultCode,
        _collectorName = collectorName ?? _defaultName,
        _isHead = isHead ?? _defaultIsHead,
        _exporterOverride = exporter,
        _now = now ?? DateTime.now;

  static CollectionReportsController get instance => Get.find();

  final OwnEngagementsLoader _loadOwn;
  final TeamFeedLoader _loadTeam;
  final List<ReconCaseView> Function(ReconScope scope) _cases;

  /// Fires when the cases change, so the Reconciliation detail rebuilds;
  /// the Tracker's own list by default.
  final RxInterface? _casesChangedOverride;
  final String Function() _collectorCode;
  final String Function() _collectorName;
  final bool Function() _isHead;
  final ReportExportService? _exporterOverride;
  final DateTime Function() _now;

  ReportExportService get _exporter =>
      _exporterOverride ?? ReportExportService.instance;

  /// The first day of the month the Activity and Collectors reports cover.
  late final Rx<DateTime> month = BReportMonth.first(_now()).obs;

  String get yearMonth => BReportMonth.key(month.value);

  bool get isHead => _isHead();

  final activityTable = Rxn<ReportTable>();
  final activityLoading = false.obs;
  final activityError = RxnString();

  final collectorsTable = Rxn<ReportTable>();
  final collectorsLoading = false.obs;
  final collectorsError = RxnString();

  /// The team feed could not be read; the collector's own row still shows.
  final teamError = RxnString();

  late final Rx<ReconScope> reconScope =
      (_isHead() ? ReconScope.team : ReconScope.mine).obs;
  final reconFilter = ReconDashboardFilter.all.obs;

  final isExporting = false.obs;

  int _activityGeneration = 0;
  int _collectorsGeneration = 0;

  /// The Reconciliation detail for [reconScope] and [reconFilter], rebuilt
  /// when either or the cases change (not on every read).
  final reconTable = Rx<ReportTable>(buildReconDetail(const []));

  final List<Worker> _workers = [];

  @override
  void onInit() {
    super.onInit();
    refreshRecon();
    final casesChanged = _casesChangedOverride ??
        (Get.isRegistered<ReconciliationController>()
            ? ReconciliationController.instance.cases
            : null);
    _workers.add(everAll([
      reconScope,
      reconFilter,
      if (casesChanged != null) casesChanged,
    ], (_) => refreshRecon()));
  }

  @override
  void onClose() {
    for (final w in _workers) {
      w.dispose();
    }
    super.onClose();
  }

  void refreshRecon() {
    final scoped = _cases(reconScope.value);
    final filtered = switch (reconFilter.value) {
      ReconDashboardFilter.open => scoped.where((c) => !c.evaluation.isClosed),
      ReconDashboardFilter.closed => scoped.where((c) => c.evaluation.isClosed),
      ReconDashboardFilter.all => scoped,
    };
    reconTable.value = buildReconDetail(filtered.map((c) => c.asRecord));
  }

  /// Moves the month by [delta]; never past the current month.
  void stepMonth(int delta) {
    final next = DateTime(month.value.year, month.value.month + delta);
    if (next.isAfter(BReportMonth.first(_now()))) return;
    month.value = next;
  }

  bool get canStepForward => month.value.isBefore(BReportMonth.first(_now()));

  Future<void> loadActivity() async {
    final generation = ++_activityGeneration;
    final ym = yearMonth;
    activityLoading.value = true;
    activityError.value = null;
    final result = await _loadOwn(ym);
    if (generation != _activityGeneration) return;
    activityLoading.value = false;
    if (result.isFailure) {
      activityError.value = result.error;
      activityTable.value = null;
      return;
    }
    activityTable.value = buildActivityReport(ActivityReportInput(
      collectorCode: _collectorCode(),
      yearMonth: ym,
      engagements: result.value,
      cases: [for (final c in _cases(ReconScope.team)) c.bundle],
    ));
  }

  /// The collector's own row at once; for the Head, the team's after the
  /// feed answers. A feed failure keeps the own row and says why.
  Future<void> loadCollectors() async {
    final generation = ++_collectorsGeneration;
    final ym = yearMonth;
    final m = month.value;
    collectorsLoading.value = true;
    collectorsError.value = null;
    teamError.value = null;

    final own = await _loadOwn(ym);
    if (generation != _collectorsGeneration) return;
    if (own.isFailure) {
      collectorsLoading.value = false;
      collectorsError.value = own.error;
      collectorsTable.value = null;
      return;
    }
    // A collector sees their own row; the Head sees the whole team, like the
    // Team Activity tab.
    final head = _isHead();
    final cases = head
        ? [for (final c in _cases(ReconScope.team)) c.asRecord]
        : const <({ReconCaseBundle bundle, ReconEvaluation evaluation})>[];
    ReportTable table(List<CollectorSummaryRow> rows) =>
        buildCollectorsSummary(withReconCounts(rows, cases, yearMonth: ym),
            yearMonth: ym);
    final rows = [
      ownSummaryRow(
          code: _collectorCode(),
          name: _collectorName(),
          engagements: own.value),
    ];
    collectorsTable.value = table(rows);
    if (!head) {
      collectorsLoading.value = false;
      return;
    }

    final team =
        await _loadTeam(from: BReportMonth.first(m), to: BReportMonth.last(m));
    if (generation != _collectorsGeneration) return;
    collectorsLoading.value = false;
    if (team.isFailure) {
      teamError.value = team.error;
      return;
    }
    collectorsTable.value = table(
        [...rows, ...teamSummaryRows(team.value, skipCode: _collectorCode())]);
  }

  String activityFileName() => BReportFileName.build('activity',
      collector: _collectorCode(), period: yearMonth);

  String collectorsFileName() => BReportFileName.build('collectors_summary',
      collector: isHead ? 'team' : _collectorCode(), period: yearMonth);

  String reconFileName() => BReportFileName.build('reconciliation_detail',
      collector:
          reconScope.value == ReconScope.team ? 'team' : _collectorCode(),
      period: DateFormat('yyyyMMdd').format(_now()));

  /// Saves [table]; Success(path), Success(null) when cancelled.
  Future<Result<String?>> save(ReportTable table, String fileName) =>
      _exporting(() => _exporter.saveCsv(table, fileName: fileName));

  /// Shares [table]; Success(false) when the sheet was dismissed.
  Future<Result<bool>> share(ReportTable table, String fileName) =>
      _exporting(() => _exporter.shareCsv(table, fileName: fileName));

  Future<T> _exporting<T>(Future<T> Function() run) async {
    isExporting.value = true;
    try {
      return await run();
    } finally {
      isExporting.value = false;
    }
  }

  static Future<Result<List<CollectionEngagementRecord>>> _ownFromRepository(
          String yearMonth) =>
      CollectionRepository.instance.loadOwnEngagements(yearMonth: yearMonth);

  static Future<Result<TeamActivityFeed>> _teamFromRepository(
          {required DateTime from, required DateTime to, String? collector}) =>
      TeamActivityRepository.instance
          .load(from: from, to: to, collector: collector);

  static List<ReconCaseView> _casesFromTracker(ReconScope scope) =>
      Get.isRegistered<ReconciliationController>()
          ? ReconciliationController.instance.casesIn(scope)
          : const [];

  static String _defaultCode() => Get.isRegistered<CollectionRepository>()
      ? CollectionRepository.instance.collectorCode
      : '';

  static String _defaultName() => Get.isRegistered<CollectionRepository>()
      ? CollectionRepository.instance.collectorName
      : '';

  static bool _defaultIsHead() =>
      Get.isRegistered<UserController>() &&
      BCollectionRoles.isHead(UserController.instance.user.value);
}
