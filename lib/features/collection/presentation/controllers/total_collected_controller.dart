import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

/// Controller for the Total Collected this Month screen and card.
class TotalCollectedController extends GetxController {
  static TotalCollectedController get instance => Get.find();

  /// Currently selected month (use first day of month for comparison)
  final Rx<DateTime> selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;

  /// Search query for the month entries
  final RxString searchQuery = ''.obs;

  /// Target amount for the selected month. If null or 0 => not set.
  final RxDouble targetAmount = 0.0.obs;

  final _activityController = CollectionActivityController.instance;

  /// Returns a list of flattened history entries for the selected month.
  List<MonthlyEntry> get monthlyEntries {
    final List<MonthlyEntry> entries = [];

    // Combine activity and bucket items to ensure we capture all history
    final allItems = <CollectionItemModel>[..._activityController.activityItems, ..._activityController.bucketItems];

    for (final item in allItems) {
      for (final h in item.history) {
        final dt = _parseDateSafe(h.date);
        if (dt == null) continue;
        if (dt.year == selectedMonth.value.year && dt.month == selectedMonth.value.month) {
          final amount = h.totalCollected ?? 0.0;
          entries.add(MonthlyEntry(
            date: dt,
            amount: amount,
            accountName: item.client.name,
            invoiceNumber: item.id,
            collectorName: h.collectorName ?? item.collectorName ?? 'Unknown',
          ));
        }
      }
    }

    // Apply search filter
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return entries..sort((a, b) => b.date.compareTo(a.date));

    return entries
        .where((e) {
          return e.accountName.toLowerCase().contains(q) ||
              e.invoiceNumber.toLowerCase().contains(q) ||
              e.collectorName.toLowerCase().contains(q) ||
              NumberFormat('#,##0.00').format(e.amount).contains(q);
        })
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Sum of collected amounts for the selected month
  double get monthlyTotal => monthlyEntries.fold(0.0, (p, e) => p + e.amount);

  /// Sum of deposits for the selected month (Actual Collection)
  double get actualCollectionTotal {
    double total = 0;
    for (final entry in _activityController.globalActivities) {
      final history = entry['history'];
      if (entry['type'] == 'Deposit' || history.status == 'Deposit') {
        final dt = _parseDateSafe(history.date);
        if (dt != null && dt.year == selectedMonth.value.year && dt.month == selectedMonth.value.month) {
          total += (history.totalCollected ?? 0.0);
        }
      }
    }
    return total;
  }

  /// Helper to parse a date string safely using BFormatter normalization
  DateTime? _parseDateSafe(String? s) {
    if (s == null) return null;
    try {
      final norm = BFormatter.normalizeToIsoDatetime(s);
      if (norm == null) return null;
      return DateTime.parse(norm);
    } catch (_) {
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }
  }

  /// Set the selected month using a DateTime (only year+month used)
  void setSelectedMonth(DateTime dt) {
    selectedMonth.value = DateTime(dt.year, dt.month, 1);
  }

  /// Set target amount for the month
  void setTargetAmount(double value) {
    targetAmount.value = value;
  }

  /// Clear target amount
  void clearTargetAmount() {
    targetAmount.value = 0.0;
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


