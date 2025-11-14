import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';

class RequestFilterManager {
  final Rx<RequestFilter> selectedFilter = RequestFilter.today.obs;
  final Rx<RequestStatusFilter> selectedStatusFilter = RequestStatusFilter.all.obs;
  final RxList<StandardDeliveryModel> filteredRequests = <StandardDeliveryModel>[].obs;

  void applyFilter(List<StandardDeliveryModel> allPendingRequests) {
    final userController = Get.find<UserController>();
    final filter = selectedFilter.value;
    final statusFilter = selectedStatusFilter.value;
    final currentUser = userController.user.value;

    final tempList = allPendingRequests.where((item) {
      if (item.targetDate.isEmpty) return false;
      DateTime targetDate;
      try {
        targetDate = DateTime.parse(item.targetDate);
      } catch (_) {
        return false; // skip invalid date format
      }

      bool dateMatches = false;
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

      final bool statusMatches =
          statusFilter.displayName == RequestStatusFilter.all.displayName ||
          item.status == statusFilter.displayName;

      bool userMatches = true;
      if (!currentUser.role.contains(',')) {
        if (currentUser.role.contains(BTexts.roleCourier)) {
          userMatches = item.helper == currentUser.initial || item.deliveredBy == currentUser.initial;
        }
      }

      return dateMatches && statusMatches && userMatches;
    }).toList();

    tempList.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.targetDate);
        final dateB = DateTime.parse(b.targetDate);
        return dateB.compareTo(dateA);
      } catch (_) {
        return 0;
      }
    });

    filteredRequests.assignAll(tempList);
  }

  void applyStatusFilter(RxList<StandardDeliveryModel> allPendingRequests) {
    applyFilter(allPendingRequests.toList());
  }

  void selectFilter(RequestFilter filter, RxList<StandardDeliveryModel> allPendingRequests) {
    selectedFilter.value = filter;
    applyFilter(allPendingRequests);
  }

  void selectStatusFilter(RequestStatusFilter statusFilter, RxList<StandardDeliveryModel> allPendingRequests) {
    selectedStatusFilter.value = statusFilter;
    applyStatusFilter(allPendingRequests);
  }
}
