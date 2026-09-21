import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';

/// Controller for the Total Collected this Month screen and card.
class TotalCollectedController extends GetxController {
  static TotalCollectedController get instance => Get.find();

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
    reloadTarget();
    ever(selectedMonth, (_) => reloadTarget());
    // A server download may replace the stored targets.
    ever(CollectionRepository.instance.localDataVersion, (_) => reloadTarget());
  }

  /// Targets used to live only in memory; now read from SQLite per month.
  Future<void> reloadTarget() async {
    final stored = await CollectionRepository.instance.getTarget(_yearMonth);
    targetAmount.value = stored ?? 0.0;
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

  /// Every deposit in the selected month, before the search box narrows it.
  List<MonthlyEntry> get depositEntries => _sortNewestFirst(_collectDeposits());

  /// The same, narrowed by the search box (Actual Collection list).
  List<MonthlyEntry> get actualEntries =>
      _filterAndSortEntries(_collectDeposits());

  List<MonthlyEntry> _collectDeposits() {
    final List<MonthlyEntry> entries = [];

    for (final entry in _activityController.globalActivities) {
      final history = entry['history'];
      if (entry['type'] == 'Deposit' || history.status == 'Deposit') {
        final dt = _parseDateSafe(history.date);
        if (dt != null &&
            dt.year == selectedMonth.value.year &&
            dt.month == selectedMonth.value.month) {
          entries.add(MonthlyEntry(
            date: dt,
            amount: history.totalCollected ?? 0.0,
            accountName: entry['accountName'] ?? 'N/A',
            invoiceNumber: 'Deposit',
            collectorName: history.collectorName ?? 'Unknown',
          ));
        }
      }
    }

    return entries;
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

  /// Sum of deposits for the selected month (Actual Collection).
  double get actualCollectionTotal =>
      depositEntries.fold(0.0, (p, e) => p + e.amount);

  /// Helper to parse a date string safely, in the reader's own timezone.
  ///
  /// The `.toLocal()` inside [BFormatter.parseLocal] matters here as much as
  /// on the calendar: a server stamp carrying a 'Z' parsed to UTC, and a
  /// collection late on the last day of the month was filed under the next
  /// one.
  DateTime? _parseDateSafe(String? s) => BFormatter.parseLocal(s);

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

  /// Set target amount for the month
  void setTargetAmount(double value) {
    targetAmount.value = value;
    // Persist + queue SET_TARGET for the selected month.
    CollectionRepository.instance.setTarget(_yearMonth, value);
  }

  /// Clear target amount
  void clearTargetAmount() {
    targetAmount.value = 0.0;
    CollectionRepository.instance.setTarget(_yearMonth, 0.0);
  }
}

/// Internal DTO representing a flattened monthly collection entry
class MonthlyEntry {
  final DateTime date;
  final double amount;
  final String accountName;
  final String invoiceNumber;
  final String collectorName;

  MonthlyEntry({
    required this.date,
    required this.amount,
    required this.accountName,
    required this.invoiceNumber,
    required this.collectorName,
  });
}
