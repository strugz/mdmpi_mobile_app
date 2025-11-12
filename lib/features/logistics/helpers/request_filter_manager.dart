import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

import '../../../base/utils/formatters/formatters.dart';
import '../../../features/logistics/controllers/standard_delivery_controller.dart';
import '../../../features/logistics/models/standard_delivery_model.dart';
import '../../../features/personalization/controller/user_controller.dart';

class RequestFilterManager {
  final Rx<RequestFilter> selectedFilter = RequestFilter.today.obs;
  final Rx<RequestStatusFilter> selectedStatusFilter =
      RequestStatusFilter.all.obs;
  final RxList<StandardDeliveryModel> filteredRequests = <StandardDeliveryModel>[].obs;

  void applyFilter(List<StandardDeliveryModel> allPendingRequests) {
    final userController = Get.find<UserController>();
    final filter = selectedFilter.value;
    final statusFilter = selectedStatusFilter.value;

    final currentUser = userController.user.value;

    var tempList = allPendingRequests.where((item) {
      // Parse targetDate once and handle potential errors
      DateTime? targetDate;
      try {
        targetDate = DateTime.parse(item.deliveryDate);
      } catch (e) {
        // Skip items with invalid dates
        return false;
      }

      // Apply date filter
      bool dateMatches;
      bool userMatches;
      switch (filter) {
        case RequestFilter.today:
          dateMatches = BFormatter.isToday(targetDate);
          break;
        case RequestFilter.yesterday:
          dateMatches = BFormatter.isYesterday(targetDate);
          break;
        case RequestFilter.tomorrow:
          dateMatches = BFormatter.isTomorrow(targetDate);
          break;
        case RequestFilter.fiveDaysAgo:
          dateMatches = BFormatter.isWithinLastNDays(targetDate, 5);
          break;
        case RequestFilter.thirtyDaysAgo:
          dateMatches = BFormatter.isWithinLastNDays(targetDate, 30);
          break;
        case RequestFilter.all:
          dateMatches = true;
          break;
      }

      bool statusMatches =
          statusFilter.displayName == RequestStatusFilter.all.displayName || item.status == statusFilter.displayName;


      userMatches = true;

      if (!currentUser.role.contains(',')) {
        if (currentUser.role.contains(BTexts.roleCourier)) {
          userMatches = item.helper == currentUser.initial || item.deliveredBy == currentUser.initial;
          logDebug('Filter: helper=${item.helper}, deliveredBy=${item.deliveredBy}');

        }
      }
      return dateMatches && statusMatches && userMatches;
    }).toList();

    // Sort by targetDate in descending order
    tempList.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.deliveryDate);
        final dateB = DateTime.parse(b.deliveryDate);
        return dateB.compareTo(dateA); // Newest first
      } catch (e) {
        // Handle invalid dates during sorting
        return 0; // Or define a fallback sorting logic
      }
    });

    filteredRequests.assignAll(tempList);
  }

  /// Filter the list based on the selected status filter
  void applyStatusFilter(RxList<StandardDeliveryModel> allPendingRequests) {
    applyFilter(allPendingRequests.toList());
  }

  /// Filter the list based on the selected status filter
  /*void applyStatusFilter(RxList<RequestModel> allPendingRequests) {
    final filter = selectedFilter.value;
    final statusFilter = selectedStatusFilter.value;

    /// Filter the list based on both date and status filters
    var tempList = allPendingRequests.where((item) {
      final targetDate = DateTime.parse(item.targetDate);

      final matchesDate = switch (filter) {
        RequestFilter.today => BFormatter.isToday(targetDate),
        RequestFilter.yesterday => BFormatter.isYesterday(targetDate),
        RequestFilter.tomorrow => BFormatter.isTomorrow(targetDate),
        RequestFilter.fiveDaysAgo =>
          BFormatter.isWithinLastNDays(targetDate, 5),
        RequestFilter.thirtyDaysAgo =>
          BFormatter.isWithinLastNDays(targetDate, 30),
        RequestFilter.all => true,
      };

      final matchesStatus = statusFilter == RequestStatusFilter.all ||
          item.status == statusFilter.displayName;

      return matchesDate && matchesStatus;
    }).toList();

    // Sort the list by targetDate in ascending order
    tempList.sort((a, b) {
      final dateA = DateTime.parse(a.targetDate);
      final dateB = DateTime.parse(b.targetDate);
      return dateB.compareTo(dateA);
    });

    filteredRequests.assignAll(tempList);
  }*/

  void selectFilter(
      RequestFilter filter, RxList<StandardDeliveryModel> allPendingRequests) {
    selectedFilter.value = filter;
    applyFilter(allPendingRequests);
  }

  void selectStatusFilter(RequestStatusFilter statusFilter,
      RxList<StandardDeliveryModel> allPendingRequests) {
    selectedStatusFilter.value = statusFilter;
    applyStatusFilter(allPendingRequests);
  }
}
