import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_filter_manager.dart';

/// Manages filtering logic for Stock Receive requests.
///
/// Responsibilities:
/// - Maintains active date and status filters
/// - Applies combined filters (date + status + user role)
/// - Sorts filtered results by stock receive date
/// - Provides filter reset functionality
/// - Filters only Stock Receive category requests
class StockReceiveFilterManager {
  final Rx<RequestFilter> selectedFilter = RequestFilter.today.obs;

  final Rx<PullOutStatusFilter> selectedStatusFilter = PullOutStatusFilter.all.obs;
  final Rxn<DateTime> selectedDateFrom = Rxn<DateTime>();
  final Rxn<DateTime> selectedDateTo = Rxn<DateTime>();
  final RxString selectedItemCategoryId = ''.obs;
  final RxString clientNameQuery = ''.obs;
  final RxString documentReferenceQuery = ''.obs;

  final RxList<PullOutModel> filteredStockReceives = <PullOutModel>[].obs;

  /// Reset filter manager to default state.
  ///
  /// If [allStockReceives] is provided the default filter is immediately applied
  /// to repopulate `filteredStockReceives`.
  void reset([List<PullOutModel>? allStockReceives]) {
    selectedFilter.value = RequestFilter.today;
    selectedStatusFilter.value = PullOutStatusFilter.all;
    selectedDateFrom.value = null;
    selectedDateTo.value = null;
    selectedItemCategoryId.value = '';
    clientNameQuery.value = '';
    documentReferenceQuery.value = '';
    filteredStockReceives.clear();
    if (allStockReceives != null) {
      applyFilter(allStockReceives);
    }
  }

  /// Apply combined date, status, and user-role filters to the request list.
  ///
  /// Filtering logic:
  /// - Date filter: Today, Yesterday, Tomorrow, Last 5 days, Last 30 days, or All
  /// - Status filter: Matches request status or shows all
  /// - User filter: Couriers see only requests assigned to them (driver/helper)
  ///
  /// Results are sorted by stock receive date (newest first).
  void applyFilter(List<PullOutModel> allStockReceives) {
    final userController = Get.find<UserController>();
    final filter = selectedFilter.value;
    final statusFilter = selectedStatusFilter.value;
    final dateFrom = selectedDateFrom.value;
    final dateTo = selectedDateTo.value;
    final itemCategoryId = selectedItemCategoryId.value;
    final clientQuery = clientNameQuery.value.trim().toLowerCase();
    final documentQuery = documentReferenceQuery.value.trim().toLowerCase();
    final currentUser = userController.user.value;

    var tempList = allStockReceives.where((item) {
      DateTime? targetDate;
      try {
        if (item.pullOutDate.isNotEmpty) {
          targetDate = DateTime.parse(item.pullOutDate);
        }
      } catch (_) {
        return false;
      }

      // Date matching
      bool dateMatches;
      switch (filter) {
        case RequestFilter.today:
          dateMatches = targetDate != null && BFormatter.isToday(targetDate);
          break;
        case RequestFilter.yesterday:
          dateMatches = targetDate != null && BFormatter.isYesterday(targetDate);
          break;
        case RequestFilter.tomorrow:
          dateMatches = targetDate != null && BFormatter.isTomorrow(targetDate);
          break;
        case RequestFilter.fiveDaysAgo:
          dateMatches = targetDate != null && BFormatter.isWithinLastNDays(targetDate, 5);
          break;
        case RequestFilter.thirtyDaysAgo:
          dateMatches = targetDate != null && BFormatter.isWithinLastNDays(targetDate, 30);
          break;
        case RequestFilter.all:
          dateMatches = true;
          break;
      }

      // Status matching
      final statusMatches = statusFilter.displayName == PullOutStatusFilter.all.displayName ||
          item.requestStatus == statusFilter.displayName;

      // User role matching (courier sees only their assignments)
      bool userMatches = true;
      if (!currentUser.role.contains(',')) {
        if (currentUser.role.contains(BTexts.roleCourier)) {
          userMatches = item.helper == currentUser.initial || item.driver == currentUser.initial;
          logDebug('StockReceiveFilter: helper=${item.helper}, driver=${item.driver}');
        }
      }

      final dateFromMatches = dateFrom == null ||
          (targetDate != null && !targetDate.isBefore(DateTime(dateFrom.year, dateFrom.month, dateFrom.day)));
      final dateToMatches = dateTo == null ||
          (targetDate != null && !targetDate.isAfter(DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59)));
      final itemCategoryMatches = itemCategoryId.isEmpty || item.itemCategoryId == itemCategoryId;
      final clientNameMatches = clientQuery.isEmpty || item.client.name.toLowerCase().contains(clientQuery);
      final documentReferenceMatches = documentQuery.isEmpty ||
          item.documentReference.any((ref) => ref.toLowerCase().contains(documentQuery));

      return dateMatches &&
          statusMatches &&
          dateFromMatches &&
          dateToMatches &&
          itemCategoryMatches &&
          clientNameMatches &&
          documentReferenceMatches &&
          userMatches;
    }).toList();

    // Sort by stock receive date (newest first)
    tempList.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.pullOutDate);
        final dateB = DateTime.parse(b.pullOutDate);
        return dateB.compareTo(dateA);
      } catch (_) {
        return 0;
      }
    });

    filteredStockReceives.assignAll(tempList);
  }

  /// Update the active date filter and reapply filters.
  void selectFilter(RequestFilter filter, RxList<PullOutModel> allStockReceives) {
    selectedFilter.value = filter;
    applyFilter(allStockReceives.toList());
  }

  /// Update the active status filter and reapply filters.
  void selectStatusFilter(PullOutStatusFilter statusFilter, RxList<PullOutModel> allStockReceives) {
    selectedStatusFilter.value = statusFilter;
    applyFilter(allStockReceives.toList());
  }


  void selectDateFrom(DateTime? date, RxList<PullOutModel> allStockReceives) {
    selectedDateFrom.value = date;
    applyFilter(allStockReceives.toList());
  }

  void selectDateTo(DateTime? date, RxList<PullOutModel> allStockReceives) {
    selectedDateTo.value = date;
    applyFilter(allStockReceives.toList());
  }

  void selectItemCategoryId(String categoryId, RxList<PullOutModel> allStockReceives) {
    selectedItemCategoryId.value = categoryId;
    applyFilter(allStockReceives.toList());
  }

  void setClientNameQuery(String query, RxList<PullOutModel> allStockReceives) {
    clientNameQuery.value = query;
    applyFilter(allStockReceives.toList());
  }

  void setDocumentReferenceQuery(String query, RxList<PullOutModel> allStockReceives) {
    documentReferenceQuery.value = query;
    applyFilter(allStockReceives.toList());
  }
}

