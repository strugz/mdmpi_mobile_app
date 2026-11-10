import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_actual_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_outcome.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/team_activity_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reports/collectors_summary_report.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reports/report_month.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_settings_controller.dart';

/// Loads the other collectors' rows for a month (`yyyy-MM`), the signed-in
/// collector left out. Fails with a message the screen can show.
typedef OtherCollectorsLoader = Future<Result<List<CollectorSummaryRow>>>
    Function(String yearMonth, DateTime month);

/// Controller for the Total Collected this Month screen and card.
class TotalCollectedController extends GetxController {
  TotalCollectedController({
    OtherCollectorsLoader? loadOthers,
    String Function()? defaultArea,
  })  : _loadOthers = loadOthers ?? _othersFromServer,
        _defaultArea = defaultArea ?? _settingsDefaultArea;

  static TotalCollectedController get instance => Get.find();

  final OtherCollectorsLoader _loadOthers;
  final String Function() _defaultArea;

  static String _settingsDefaultArea() =>
      Get.isRegistered<CollectionSettingsController>()
          ? CollectionSettingsController.instance.defaultArea.value
          : '';

  /// Which Actual Collection and target are shown (update checklist items 3
  /// and 5): '' for the whole team, or an area code (NCR, VIS, … OTHERS). A
  /// collector with a default area starts on it, and can switch to all areas
  /// and back; one without sees the whole team, as before.
  final RxString actualArea = ''.obs;

  /// The collector's default area (Settings), or '' when none is set.
  String get defaultArea => _defaultArea();

  /// Whether there is an area to switch to: only with a default area set.
  bool get canPickArea => defaultArea.isNotEmpty;

  /// Show [area]'s Actual Collection and target ('' = all areas).
  void setActualArea(String area) =>
      actualArea.value = area.trim().toUpperCase();

  /// "Team" for all areas, else the area's name ("NCR", "Visayas").
  String get actualScopeLabel => actualArea.value.isEmpty
      ? 'Team'
      : BCollectionArea.labelFor(actualArea.value);

  /// Currently selected month (use first day of month for comparison)
  final Rx<DateTime> selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1).obs;

  /// Search query for the month entries
  final RxString searchQuery = ''.obs;

  /// Target amount for the selected month. If null or 0 => not set.
  final RxDouble targetAmount = 0.0.obs;

  final _activityController = CollectionActivityController.instance;

  /// yyyy-MM key of the selected month (target storage key).
  String get _yearMonth => DateFormat('yyyy-MM').format(selectedMonth.value);

  @override
  void onInit() {
    super.onInit();
    actualArea.value = defaultArea;
    // A new default area (Settings) moves the view to it.
    if (Get.isRegistered<CollectionSettingsController>()) {
      ever(CollectionSettingsController.instance.defaultArea,
          (String area) => actualArea.value = area);
    }
    ever(actualArea, (_) => reloadTarget());
    reloadTarget();
    reloadActual();
    reloadOthers();
    ever(selectedMonth, (_) {
      reloadTarget();
      reloadActual();
      reloadOthers();
    });
    // A server download may replace the stored targets and the posted
    // Actual Collection; teammates may have uploaded since.
    ever(CollectionRepository.instance.localDataVersion, (_) {
      reloadTarget();
      reloadActual();
      reloadOthers();
    });
    if (Get.isRegistered<CollectionSettingsController>()) {
      ever(CollectionSettingsController.instance.collectedAllCollectors,
          (_) => reloadOthers());
    }
  }

  // ========================================================================
  // All collectors (Settings → Collected this Month)
  // ========================================================================

  /// Whether Collected this Month counts every collector. Off
  /// (me only) when the setting is not available.
  bool get allCollectors =>
      Get.isRegistered<CollectionSettingsController>() &&
      CollectionSettingsController.instance.collectedAllCollectors.value;

  /// The other collectors' month, from the server (only what they have
  /// uploaded). Empty while "me only".
  final RxList<CollectorSummaryRow> otherCollectors =
      <CollectorSummaryRow>[].obs;
  final RxBool othersLoading = false.obs;

  /// Why the other collectors could not be loaded; null when they were.
  final RxnString othersError = RxnString();

  /// The month [otherCollectors] belong to.
  String _othersMonth = '';
  int _othersGeneration = 0;

  /// Load the other collectors for the selected month, when the setting
  /// asks for them. This collector's own figures stay the phone's, which are
  /// exact and include what is not uploaded yet.
  Future<void> reloadOthers() async {
    final generation = ++_othersGeneration;
    othersError.value = null;
    if (!allCollectors) {
      othersLoading.value = false;
      otherCollectors.clear();
      _othersMonth = '';
      return;
    }
    final yearMonth = _yearMonth;
    // Another month's teammates must not be added to this one's total.
    if (_othersMonth != yearMonth) otherCollectors.clear();
    othersLoading.value = true;
    final result = await _loadOthers(yearMonth, selectedMonth.value);
    if (generation != _othersGeneration) return;
    othersLoading.value = false;
    if (result.isFailure) {
      othersError.value = result.error;
      return;
    }
    otherCollectors.assignAll(result.value);
    _othersMonth = yearMonth;
  }

  /// The other collectors' Collected this Month; 0 while "me only".
  double get othersCollected => allCollectors
      ? otherCollectors.fold(0.0, (sum, r) => sum + r.collected)
      : 0;

  /// Collected this Month as the setting asks: this phone's own total, plus
  /// the other collectors' when "all collectors".
  double get scopedTotal => monthlyTotal + othersCollected;

  /// The server's summary, or the team feed where the server is older.
  static Future<Result<List<CollectorSummaryRow>>> _othersFromServer(
      String yearMonth, DateTime month) async {
    if (!Get.isRegistered<TeamActivityRepository>()) {
      return Result.failure('Team totals are not available.');
    }
    final repo = TeamActivityRepository.instance;
    final me = CollectionRepository.instance.collectorCode;
    final summary = await repo.loadSummary(yearMonth);
    if (summary.isFailure) return Result.failure(summary.error);
    if (summary.value case final server?) {
      return Result.success(serverSummaryRows(server, skipCode: me));
    }
    final feed = await repo.load(
        from: BReportMonth.first(month), to: BReportMonth.last(month));
    if (feed.isFailure) return Result.failure(feed.error);
    return Result.success(teamSummaryRows(feed.value, skipCode: me));
  }

  /// The selected month's target from SQLite: the whole team's, or with an
  /// area chosen ([actualArea]) that area's own.
  Future<void> reloadTarget() async {
    final yearMonth = _yearMonth;
    final area = actualArea.value;
    final stored = area.isEmpty
        ? await CollectionRepository.instance.getTarget(yearMonth)
        : await CollectionRepository.instance.getAreaTarget(yearMonth, area);
    // The month or the area moved on while this was reading.
    if (yearMonth != _yearMonth || area != actualArea.value) return;
    targetAmount.value = stored ?? 0.0;
  }

  /// Reads the selected month's posted Actual Collection from SQLite (the
  /// workspace download keeps it there).
  Future<void> reloadActual() async {
    final yearMonth = _yearMonth;
    final records =
        await CollectionRepository.instance.getActualCollections(yearMonth);
    // The month moved on while this was reading; its own load will land.
    if (yearMonth != _yearMonth) return;
    postedActual.assignAll(records.map(MonthlyEntry.fromActual).nonNulls);
  }

  /// Every collection in the selected month, before the search box narrows
  /// it. The headline total reads off this, so typing in the search cannot
  /// change what the month is worth.
  List<MonthlyEntry> get monthEntries => _sortNewestFirst(_collectMonth());

  /// The same month, narrowed by the search box. This is what the list shows.
  List<MonthlyEntry> get monthlyEntries =>
      _filterAndSortEntries(_collectMonth());

  /// The month's collections, read from the engagement archive.
  ///
  /// It used to walk the invoices currently in the bucket and the activity
  /// list. Those are a cache of what the server says today, and an invoice
  /// that settles stops coming back — so a month quietly lost collections as
  /// they were paid off and uploaded, which is the same defect that emptied
  /// the calendar. Both screens now read the one record that is never
  /// rewritten, so they cannot disagree about a month.
  List<MonthlyEntry> _collectMonth() {
    final List<MonthlyEntry> entries = [];
    final month = selectedMonth.value;

    for (final e in _activityController.ownEngagements) {
      if (e.amount <= 0) continue;
      // A For Deposit (banking money already counted) and an unapplied
      // Advanced Payment (float until an invoice takes it; the applied row is
      // what counts, in the month the collector chose) stay in the archive
      // for the calendar and the history, and add nothing here. Both used to
      // count the same pesos twice.
      if (!CollectionOutcome.countsAsCollected(e.status, kind: e.kind)) {
        continue;
      }
      final dt = BFormatter.parseLocal(e.engagedAt);
      if (dt == null) continue;
      if (dt.year != month.year || dt.month != month.month) continue;
      entries.add(MonthlyEntry(
        date: dt,
        amount: e.amount,
        accountName: e.clientName,
        // An office activity has no invoice; the ledger names what it was.
        invoiceNumber: e.itemId.isNotEmpty ? e.itemId : e.status,
        collectorName: e.collectorName,
      ));
    }

    return entries;
  }

  /// Actual Collection as the office posts it on the Collection web, one
  /// entry per deposit slip / OR reference (revisions list item 11). The
  /// workspace download stores it and [reloadActual] fills this for the
  /// selected month.
  ///
  /// Deposits are not in it, and never were meant to be. A *For Deposit*
  /// activity records what the collector did; it is not money the company has
  /// counted. The figure used to be the sum of deposits, so every deposit a
  /// collector logged moved a number the office owns.
  final RxList<MonthlyEntry> postedActual = <MonthlyEntry>[].obs;

  /// The posted Actual Collection in the selected month, before the search
  /// box narrows it.
  List<MonthlyEntry> get postedEntries => _sortNewestFirst(_postedInMonth());

  /// The same, narrowed by the search box (the Actual Collection list).
  List<MonthlyEntry> get actualEntries =>
      _filterAndSortEntries(_postedInMonth());

  /// The selected month's posted entries; with an area chosen, only the ones
  /// posted for that area (entries without an area count for the team only).
  List<MonthlyEntry> _postedInMonth() {
    final month = selectedMonth.value;
    final area = actualArea.value;
    return [
      for (final e in postedActual)
        if (e.date.year == month.year &&
            e.date.month == month.month &&
            (area.isEmpty || e.area == area))
          e,
    ];
  }

  List<MonthlyEntry> _sortNewestFirst(List<MonthlyEntry> entries) =>
      entries..sort((a, b) => b.date.compareTo(a.date));

  List<MonthlyEntry> _filterAndSortEntries(List<MonthlyEntry> entries) {
    // Apply search filter
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return entries..sort((a, b) => b.date.compareTo(a.date));

    return entries.where((e) {
      return e.accountName.toLowerCase().contains(q) ||
          e.invoiceNumber.toLowerCase().contains(q) ||
          e.collectorName.toLowerCase().contains(q) ||
          e.referenceNo.toLowerCase().contains(q) ||
          e.remarks.toLowerCase().contains(q) ||
          NumberFormat('#,##0.00').format(e.amount).contains(q);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Sum of collected amounts for the selected month.
  ///
  /// Off the unfiltered entries. It used to sum the searched list, so the
  /// figure labelled "Total" shrank as the collector typed — while the
  /// deposit total next door ignored the search. Same label, two behaviours.
  double get monthlyTotal => monthEntries.fold(0.0, (p, e) => p + e.amount);

  /// Actual Collection for the selected month: the posted entries, never the
  /// collector's deposits. Off the unfiltered list, like [monthlyTotal].
  double get actualCollectionTotal =>
      postedEntries.fold(0.0, (p, e) => p + e.amount);

  /// Set the selected month using a DateTime (only year+month used)
  void setSelectedMonth(DateTime dt) {
    selectedMonth.value = DateTime(dt.year, dt.month, 1);
  }

  /// The first of the current month — the far edge of what can be browsed.
  static DateTime thisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// The twelve months a collector can step through, newest first.
  List<DateTime> get selectableMonths {
    final head = thisMonth();
    return List.generate(12, (i) => DateTime(head.year, head.month - i, 1));
  }

  /// Nothing has been collected in a month that has not happened yet.
  bool get canGoForward => selectedMonth.value.isBefore(thisMonth());

  /// Kept to the same twelve months the picker offers.
  bool get canGoBack => selectedMonth.value.isAfter(selectableMonths.last);

  void previousMonth() {
    if (!canGoBack) return;
    final m = selectedMonth.value;
    selectedMonth.value = DateTime(m.year, m.month - 1, 1);
  }

  void nextMonth() {
    if (!canGoForward) return;
    final m = selectedMonth.value;
    selectedMonth.value = DateTime(m.year, m.month + 1, 1);
  }

  /// How many different collectors appear in [entries].
  ///
  /// A collector reviewing their own month sees one name on every row — their
  /// own — which carries no information. The screen only prints the name
  /// when there is more than one.
  int distinctCollectors(List<MonthlyEntry> entries) =>
      entries.map((e) => e.collectorName.trim().toLowerCase()).toSet().length;
}

/// Internal DTO representing a flattened monthly collection entry
class MonthlyEntry {
  final DateTime date;
  final double amount;
  final String accountName;
  final String invoiceNumber;
  final String collectorName;

  /// The deposit slip / OR reference of a posted Actual Collection entry.
  final String referenceNo;
  final String remarks;

  /// Who in the office posted an Actual Collection entry.
  final String postedBy;

  /// The area a posted Actual Collection entry counts toward ('' = the team).
  final String area;

  MonthlyEntry({
    required this.date,
    required this.amount,
    required this.accountName,
    required this.invoiceNumber,
    required this.collectorName,
    this.referenceNo = '',
    this.remarks = '',
    this.postedBy = '',
    this.area = '',
  });

  /// A posted Actual Collection entry, dated its collection day. Null when
  /// the stored date does not parse.
  static MonthlyEntry? fromActual(CollectionActualRecord r) {
    final date = DateTime.tryParse(r.collectionDate);
    if (date == null) return null;
    return MonthlyEntry(
      date: DateTime(date.year, date.month, date.day),
      amount: r.amount,
      // The team's figure, posted against a deposit slip / OR: no account, no
      // collector.
      accountName: '',
      invoiceNumber: '',
      collectorName: '',
      referenceNo: r.referenceNo,
      remarks: r.remarks,
      postedBy: r.postedBy,
      area: r.area,
    );
  }
}
