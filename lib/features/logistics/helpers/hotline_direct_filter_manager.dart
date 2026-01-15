import 'dart:convert';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';

/// Manages filtering logic for Hotline Direct requests.
///
/// Responsibilities:
/// - Maintains active date and status filters
/// - Applies combined filters (date + status + user role)
/// - Sorts filtered results by delivery date
/// - Provides filter reset functionality
/// - Filters only Hotline Direct category requests
class HotlineDirectFilterManager {
  final Rx<RequestFilter> selectedFilter = RequestFilter.today.obs;
  final Rx<StandardDeliveryStatusFilter> selectedStatusFilter = StandardDeliveryStatusFilter.all.obs;
  final RxList<StandardDeliveryModel> filteredRequests = <StandardDeliveryModel>[].obs;

  /// Reset filter manager to default state.
  ///
  /// If [allRequests] is provided, the default filter is immediately applied
  /// to repopulate `filteredRequests`.
  void reset([List<StandardDeliveryModel>? allRequests]) {
    selectedFilter.value = RequestFilter.today;
    selectedStatusFilter.value = StandardDeliveryStatusFilter.all;
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
          logDebug('HotlineDirectFilter: helper=${item.helper}, deliveredBy=${item.deliveredBy}');
        }
      }

      return dateMatches && statusMatches && userMatches;
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
}

