import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart'; // For RequestFilter enum reuse

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

  final RxList<PullOutModel> filteredPullOuts = <PullOutModel>[].obs;

  /// Reset filter manager to default state.
  ///
  /// If [allPullOuts] is provided the default filter is immediately applied
  /// to repopulate `filteredPullOuts`.
  void reset([List<PullOutModel>? allPullOuts]) {
    selectedFilter.value = RequestFilter.today;
    selectedStatusFilter.value = PullOutStatusFilter.all;
    filteredPullOuts.clear();
    if (allPullOuts != null) {
      applyFilter(allPullOuts);
    }
  }

  void applyFilter(List<PullOutModel> allPullOuts) {
    final userController = Get.find<UserController>();
    final filter = selectedFilter.value;
    final statusFilter = selectedStatusFilter.value;
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
          userMatches = item.helper == currentUser.initial || item.driver == currentUser.initial;
          logDebug('PullOutFilter: helper=${item.helper}, driver=${item.driver}');
        }
      }

      return dateMatches && statusMatches && userMatches;
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
}
