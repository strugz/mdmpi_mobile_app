import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart'; // For RequestFilter enum reuse

enum PullOutStatusFilter {
  statusNewRequest('New Request'),
  statusInTransit('In Transit'),
  statusTakenOut('Taken Out'),
  statusCancelled('Cancelled'),
  all('All');

  const PullOutStatusFilter(this.displayName);
  final String displayName;
}

class PullOutFilterManager {
  final Rx<RequestFilter> selectedFilter = RequestFilter.today.obs;

  final Rx<PullOutStatusFilter> selectedStatusFilter = PullOutStatusFilter.all.obs;
  final Rxn<DateTime> selectedDateFrom = Rxn<DateTime>();
  final Rxn<DateTime> selectedDateTo = Rxn<DateTime>();
  final RxString selectedItemCategoryId = ''.obs;
  final RxString clientNameQuery = ''.obs;
  final RxString documentReferenceQuery = ''.obs;

  final RxList<PullOutModel> filteredPullOuts = <PullOutModel>[].obs;

  /// Reset filter manager to default state.
  ///
  /// If [allPullOuts] is provided the default filter is immediately applied
  /// to repopulate `filteredPullOuts`.
  void reset([List<PullOutModel>? allPullOuts]) {
    selectedFilter.value = RequestFilter.today;
    selectedStatusFilter.value = PullOutStatusFilter.all;
    selectedDateFrom.value = null;
    selectedDateTo.value = null;
    selectedItemCategoryId.value = '';
    clientNameQuery.value = '';
    documentReferenceQuery.value = '';
    filteredPullOuts.clear();
    if (allPullOuts != null) {
      applyFilter(allPullOuts);
    }
  }

  void applyFilter(List<PullOutModel> allPullOuts) {
    final userController = Get.find<UserController>();
    final filter = selectedFilter.value;
    final statusFilter = selectedStatusFilter.value;
    final dateFrom = selectedDateFrom.value;
    final dateTo = selectedDateTo.value;
    final itemCategoryId = selectedItemCategoryId.value;
    final clientQuery = clientNameQuery.value.trim().toLowerCase();
    final documentQuery = documentReferenceQuery.value.trim().toLowerCase();
    final currentUser = userController.user.value;

    var tempList = allPullOuts.where((item) {
      DateTime? targetDate;
      try {
        if (item.pullOutDate.isNotEmpty) {
          targetDate = DateTime.parse(item.pullOutDate);
        }
      } catch (_) {
        return false;
      }

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

      final statusMatches = statusFilter.displayName == PullOutStatusFilter.all.displayName ||
          item.requestStatus == statusFilter.displayName;

      bool userMatches = true;
      if (!currentUser.role.contains(',')) {
        if (currentUser.role.contains(BTexts.roleCourier)) {
          // Couriers can view all items in New Request and Taken Out statuses
          // For other statuses, only show items where they are assigned as driver or helper
          final isOpenStatus = item.requestStatus == BTexts.statusNewRequest ||
              item.requestStatus == BTexts.statusTakenOut;
          userMatches = isOpenStatus ||
              item.helper == currentUser.initial ||
              item.driver == currentUser.initial;
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

    tempList.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.pullOutDate);
        final dateB = DateTime.parse(b.pullOutDate);
        return dateB.compareTo(dateA);
      } catch (_) {
        return 0;
      }
    });

    filteredPullOuts.assignAll(tempList);
  }

  void selectFilter(RequestFilter filter, RxList<PullOutModel> allPullOuts) {
    selectedFilter.value = filter;
    applyFilter(allPullOuts.toList());
  }

  void selectStatusFilter(PullOutStatusFilter statusFilter, RxList<PullOutModel> allPullOuts) {
    selectedStatusFilter.value = statusFilter;
    applyFilter(allPullOuts.toList());
  }

  void selectDateFrom(DateTime? date, RxList<PullOutModel> allPullOuts) {
    selectedDateFrom.value = date;
    applyFilter(allPullOuts.toList());
  }

  void selectDateTo(DateTime? date, RxList<PullOutModel> allPullOuts) {
    selectedDateTo.value = date;
    applyFilter(allPullOuts.toList());
  }

  void selectItemCategoryId(String categoryId, RxList<PullOutModel> allPullOuts) {
    selectedItemCategoryId.value = categoryId;
    applyFilter(allPullOuts.toList());
  }

  void setClientNameQuery(String query, RxList<PullOutModel> allPullOuts) {
    clientNameQuery.value = query;
    applyFilter(allPullOuts.toList());
  }

  void setDocumentReferenceQuery(String query, RxList<PullOutModel> allPullOuts) {
    documentReferenceQuery.value = query;
    applyFilter(allPullOuts.toList());
  }
}
