import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Date filter options shared across logistics modules.
enum RequestFilter {
  today('Today'),
  yesterday('Yesterday'),
  tomorrow('Tomorrow'),
  fiveDaysAgo('5 Days Ago'),
  thirtyDaysAgo('30 Days Ago'),
  all('All');

  const RequestFilter(this.displayName);
  final String displayName;
}

/// Status filter options for Standard Delivery requests.
enum StandardDeliveryStatusFilter {
  statusNewRequest('New Request'),
  statusGettingSuppliesReady('Getting supplies ready'),
  statusItemPrepared('Item Prepared'),
  statusForDelivery('For Delivery'),
  statusDoneDelivery('Delivered'),
  statusCancelled('Cancelled'),
  all('All');

  const StandardDeliveryStatusFilter(this.displayName);
  final String displayName;
}

/// Manages filtering logic for Standard Delivery requests.
///
/// Responsibilities:
/// - Maintains active date and status filters
/// - Applies combined filters (date + status + user role)
/// - Sorts filtered results by delivery date
/// - Provides filter reset functionality
class StandardDeliveryFilterManager {
  final Rx<RequestFilter> selectedFilter = RequestFilter.today.obs;
  final Rx<StandardDeliveryStatusFilter> selectedStatusFilter = StandardDeliveryStatusFilter.all.obs;
  final Rxn<DateTime> selectedDateFrom = Rxn<DateTime>();
  final Rxn<DateTime> selectedDateTo = Rxn<DateTime>();
  final RxString selectedItemCategoryId = ''.obs;
  final RxString clientNameQuery = ''.obs;
  final RxString documentReferenceQuery = ''.obs;
  final RxList<StandardDeliveryModel> filteredRequests = <StandardDeliveryModel>[].obs;

  /// Reset filter manager to default state.
  ///
  /// If [allRequests] is provided, the default filter is immediately applied
  /// to repopulate `filteredRequests`.
  void reset([List<StandardDeliveryModel>? allRequests]) {
    selectedFilter.value = RequestFilter.today;
    selectedStatusFilter.value = StandardDeliveryStatusFilter.all;
    selectedDateFrom.value = null;
    selectedDateTo.value = null;
    selectedItemCategoryId.value = '';
    clientNameQuery.value = '';
    documentReferenceQuery.value = '';
    filteredRequests.clear();
    if (allRequests != null) {
      applyFilter(allRequests);
    }
  }

  /// Apply combined date, status, and user-role filters to the request list.
  ///
  /// Filtering logic:
  /// - Date filter: Today, Yesterday, Tomorrow, Last 5 days, Last 30 days, or All
  /// - Status filter: Matches request status or shows all
  /// - User filter: Couriers see only requests assigned to them (driver/helper)
  ///
  /// Results are sorted by delivery date (newest first).
  void applyFilter(List<StandardDeliveryModel> allRequests) {
    final userController = Get.find<UserController>();
    final filter = selectedFilter.value;
    final statusFilter = selectedStatusFilter.value;
    final dateFrom = selectedDateFrom.value;
    final dateTo = selectedDateTo.value;
    final itemCategoryId = selectedItemCategoryId.value;
    final clientQuery = clientNameQuery.value.trim().toLowerCase();
    final documentQuery = documentReferenceQuery.value.trim().toLowerCase();
    final currentUser = userController.user.value;

    var tempList = allRequests.where((item) {
      DateTime? deliveryDate;
      try {
        if (item.deliveryDate.isNotEmpty) {
          deliveryDate = DateTime.parse(item.deliveryDate);
        }
      } catch (_) {
        return false;
      }

      // Date matching
      bool dateMatches;
      switch (filter) {
        case RequestFilter.today:
          dateMatches = deliveryDate != null && BFormatter.isToday(deliveryDate);
          break;
        case RequestFilter.yesterday:
          dateMatches = deliveryDate != null && BFormatter.isYesterday(deliveryDate);
          break;
        case RequestFilter.tomorrow:
          dateMatches = deliveryDate != null && BFormatter.isTomorrow(deliveryDate);
          break;
        case RequestFilter.fiveDaysAgo:
          dateMatches = deliveryDate != null && BFormatter.isWithinLastNDays(deliveryDate, 5);
          break;
        case RequestFilter.thirtyDaysAgo:
          dateMatches = deliveryDate != null && BFormatter.isWithinLastNDays(deliveryDate, 30);
          break;
        case RequestFilter.all:
          dateMatches = true;
          break;
      }

      // Status matching
      final statusMatches = statusFilter.displayName == StandardDeliveryStatusFilter.all.displayName ||
          item.status == statusFilter.displayName;

      // User role matching (courier sees only their assignments)
      bool userMatches = true;
      if (!currentUser.role.contains(',')) {
        if (currentUser.role.contains(BTexts.roleCourier)) {
          userMatches = item.helper == currentUser.initial ||
                       item.deliveredBy == currentUser.initial;
          logDebug('StandardDeliveryFilter: helper=${item.helper}, deliveredBy=${item.deliveredBy}');
        }
      }

      final dateFromMatches = dateFrom == null ||
          (deliveryDate != null && !deliveryDate.isBefore(DateTime(dateFrom.year, dateFrom.month, dateFrom.day)));
      final dateToMatches = dateTo == null ||
          (deliveryDate != null && !deliveryDate.isAfter(DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59)));

      final itemCategoryMatches = itemCategoryId.isEmpty || item.itemCategoryID == itemCategoryId;

      final clientName = item.client.name.toLowerCase();
      final clientNameMatches = clientQuery.isEmpty || clientName.contains(clientQuery);
      final documentReferenceMatches = documentQuery.isEmpty ||
          item.documentReference.any((ref) => ref.toLowerCase().contains(documentQuery));

      return dateMatches &&
          dateFromMatches &&
          dateToMatches &&
          statusMatches &&
          itemCategoryMatches &&
          clientNameMatches &&
          documentReferenceMatches &&
          userMatches;
    }).toList();

    // Sort by delivery date (newest first)
    tempList.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.deliveryDate);
        final dateB = DateTime.parse(b.deliveryDate);
        return dateB.compareTo(dateA);
      } catch (_) {
        return 0;
      }
    });

    filteredRequests.assignAll(tempList);
  }

  /// Update the active date filter and reapply filters.
  void selectFilter(RequestFilter filter, RxList<StandardDeliveryModel> allRequests) {
    selectedFilter.value = filter;
    applyFilter(allRequests.toList());
  }

  /// Update the active status filter and reapply filters.
  void selectStatusFilter(StandardDeliveryStatusFilter statusFilter, RxList<StandardDeliveryModel> allRequests) {
    selectedStatusFilter.value = statusFilter;
    applyFilter(allRequests.toList());
  }

  void selectDateFrom(DateTime? date, RxList<StandardDeliveryModel> allRequests) {
    selectedDateFrom.value = date;
    applyFilter(allRequests.toList());
  }

  void selectDateTo(DateTime? date, RxList<StandardDeliveryModel> allRequests) {
    selectedDateTo.value = date;
    applyFilter(allRequests.toList());
  }

  void selectItemCategoryId(String categoryId, RxList<StandardDeliveryModel> allRequests) {
    selectedItemCategoryId.value = categoryId;
    applyFilter(allRequests.toList());
  }

  void setClientNameQuery(String query, RxList<StandardDeliveryModel> allRequests) {
    clientNameQuery.value = query;
    applyFilter(allRequests.toList());
  }

  void setDocumentReferenceQuery(String query, RxList<StandardDeliveryModel> allRequests) {
    documentReferenceQuery.value = query;
    applyFilter(allRequests.toList());
  }
}
