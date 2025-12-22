import 'dart:convert';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart'; // For RequestFilter enum reuse

/// Status filters specific to Air/Sea requests
enum AirSeaStatusFilter {
  statusNewRequest('New Request'),
  statusGettingSuppliesReady('Getting Supplies Ready'),
  statusItemPacked('Item Packed'),
  statusEndorsedToGuard('Endorsed to Guard'),
  statusReceived('Received'),
  statusCancelled('Cancelled'),
  all('All');

  const AirSeaStatusFilter(this.displayName);
  final String displayName;
}

/// Manages filtering logic for Air/Sea requests.
/// Handles both date-based and status-based filtering with user role awareness.
class AirSeaFilterManager {
  final Rx<RequestFilter> selectedFilter = RequestFilter.today.obs;

  final Rx<AirSeaStatusFilter> selectedStatusFilter =
      AirSeaStatusFilter.all.obs;

  final RxList<AirSeaModel> filteredAirSeaRequests = <AirSeaModel>[].obs;

  /// Reset filter manager to default state.
  ///
  /// If [allRequests] is provided, the default filter is immediately applied
  /// to repopulate `filteredAirSeaRequests`.`
  void reset([List<AirSeaModel>? allRequests]) {
    selectedFilter.value = RequestFilter.today;
    selectedStatusFilter.value = AirSeaStatusFilter.all;
    filteredAirSeaRequests.clear();
    if (allRequests != null) {
      applyFilter(allRequests);
    }
  }

  /// Applies the current date and status filters to the provided list of Air/Sea requests.
  ///
  /// [allRequests] The complete list of Air/Sea requests to filter
  void applyFilter(List<AirSeaModel> allRequests) {
    final filter = selectedFilter.value;
    final statusFilter = selectedStatusFilter.value;

    logDebug('AirSeaFilterManager.applyFilter: ${jsonEncode(allRequests)}');

    var tempList = allRequests.where((item) {
      DateTime? targetDate;
      try {
        if (item.datePickUp.isNotEmpty) {
          targetDate = DateTime.parse(item.datePickUp);
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
          dateMatches =
              targetDate != null && BFormatter.isYesterday(targetDate);
          break;
        case RequestFilter.tomorrow:
          dateMatches = targetDate != null && BFormatter.isTomorrow(targetDate);
          break;
        case RequestFilter.fiveDaysAgo:
          dateMatches =
              targetDate != null && BFormatter.isWithinLastNDays(targetDate, 5);
          break;
        case RequestFilter.thirtyDaysAgo:
          dateMatches = targetDate != null &&
              BFormatter.isWithinLastNDays(targetDate, 30);
          break;
        case RequestFilter.all:
          dateMatches = true;
          break;
      }

      final statusMatches =
          statusFilter.displayName == AirSeaStatusFilter.all.displayName ||
              item.status == statusFilter.displayName;

      // Note: Air/Sea requests don't filter by courier like Standard Delivery does.
      // The mobileId field tracks which courier is assigned, but filtering is handled differently.
      // Users with courier role will see all Air/Sea requests they have access to.
      bool userMatches = true;

      return dateMatches && statusMatches && userMatches;
    }).toList();

    logDebug('AirSeaFilterManager.applyFilter filtered: ${jsonEncode(tempList)}');

    tempList.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.datePickUp);
        final dateB = DateTime.parse(b.datePickUp);
        return dateB.compareTo(dateA);
      } catch (_) {
        return 0;
      }
    });

    filteredAirSeaRequests.assignAll(tempList);
  }

  /// Updates the selected status filter and reapplies filtering.
  ///
  /// [statusFilter] The new status filter to apply
  /// [allRequests] The complete list of Air/Sea requests
  void selectStatusFilter(
      AirSeaStatusFilter statusFilter, List<AirSeaModel> allRequests) {
    selectedStatusFilter.value = statusFilter;
    applyFilter(allRequests);
  }

  /// Updates the selected date filter and reapplies filtering.
  ///
  /// [filter] The new date range filter to apply
  /// [allRequests] The complete list of Air/Sea requests
  void selectFilter(RequestFilter filter, List<AirSeaModel> allRequests) {
    selectedFilter.value = filter;
    applyFilter(allRequests);
  }
}
