import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart'; // For RequestFilter enum reuse

enum PickUpStatusFilter {
  statusNewRequest('New Request'),
  statusItemPrepared('Item Prepared'),
  statusItemPacked('Item Packed'),
  statusReceived('Received'),
  statusCancelled('Cancelled'),
  all('All');

  const PickUpStatusFilter(this.displayName);
  final String displayName;
}

class PickUpFilterManager {
  final Rx<RequestFilter> selectedFilter = RequestFilter.today.obs;

  final Rx<PickUpStatusFilter> selectedStatusFilter = PickUpStatusFilter.all.obs;

  final RxList<PickUpModel> filteredPickUps = <PickUpModel>[].obs;

  /// Reset filter manager to default state.
  ///
  /// If [allPickUps] is provided the default filter is immediately applied
  /// to repopulate `filteredPickUps`.
  void reset([List<PickUpModel>? allPickUps]) {
    selectedFilter.value = RequestFilter.today;
    selectedStatusFilter.value = PickUpStatusFilter.all;
    filteredPickUps.clear();
    if (allPickUps != null) {
      applyFilter(allPickUps);
    }
  }

  void applyFilter(List<PickUpModel> allPickUps) {
    final userController = Get.find<UserController>();
    final filter = selectedFilter.value;
    final statusFilter = selectedStatusFilter.value;
    final currentUser = userController.user.value;

    var tempList = allPickUps.where((item) {
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

      final statusMatches = statusFilter.displayName == PickUpStatusFilter.all.displayName ||
          item.status == statusFilter.displayName;

      bool userMatches = true;
      if (!currentUser.role.contains(',')) {
        if (currentUser.role.contains(BTexts.roleCourier)) {
          userMatches = item.receivedBy == currentUser.initial || item.releasedBy == currentUser.initial;
          logDebug('PickUpFilter: receivedBy=${item.receivedBy}, releasedBy=${item.releasedBy}');
        }
      }

      return dateMatches && statusMatches && userMatches;
    }).toList();

    tempList.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.datePickUp);
        final dateB = DateTime.parse(b.datePickUp);
        return dateB.compareTo(dateA);
      } catch (_) {
        return 0;
      }
    });

    filteredPickUps.assignAll(tempList);
  }

  void selectFilter(RequestFilter filter, RxList<PickUpModel> allPickUps) {
    selectedFilter.value = filter;
    applyFilter(allPickUps.toList());
  }

  void selectStatusFilter(PickUpStatusFilter statusFilter, RxList<PickUpModel> allPickUps) {
    selectedStatusFilter.value = statusFilter;
    applyFilter(allPickUps.toList());
  }
}

