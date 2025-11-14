import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart'; // For RequestFilter enum reuse

/// Status filter options for Pull-out requests.
/// Display names must match the underlying `requestStatus` values returned
/// by backend/DB for correct filtering.
enum PullOutStatusFilter {
  statusNew('New'),
  statusPendingRelease('Pending Release'),
  statusReleased('Released'),
  statusForPickUp('For Pick-up'),
  statusPickedUp('Picked-up'),
  statusCancelled('Cancelled'),
  all('All');

  const PullOutStatusFilter(this.displayName);
  final String displayName;
}

/// Handles date (reusing [RequestFilter]) and status ([PullOutStatusFilter])
/// filtering for the pull-out requests list. Keeps filtering logic out of
/// widgets and the main controller.
class PullOutFilterManager {
  /// Currently selected date filter.
  final Rx<RequestFilter> selectedFilter = RequestFilter.today.obs;

  /// Currently selected status filter.
  final Rx<PullOutStatusFilter> selectedStatusFilter = PullOutStatusFilter.all.obs;

  /// Result list after applying both filters.
  final RxList<PullOutModel> filteredPullOuts = <PullOutModel>[].obs;

  /// Apply both date and status filters to the provided list and update
  /// [filteredPullOuts]. Invalid dates are skipped gracefully.
  void applyFilter(List<PullOutModel> allPullOuts) {
    final userController = Get.find<UserController>();
    final filter = selectedFilter.value;
    final statusFilter = selectedStatusFilter.value;
    final currentUser = userController.user.value;

    var tempList = allPullOuts.where((item) {
      // Parse pullOutDate safely
      DateTime? targetDate;
      try {
        if (item.pullOutDate.isNotEmpty) {
          targetDate = DateTime.parse(item.pullOutDate);
        }
      } catch (_) {
        return false; // skip invalid dates
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

    // Sort newest first based on pullOutDate
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

  /// Select a new date filter and re-apply.
  void selectFilter(RequestFilter filter, RxList<PullOutModel> allPullOuts) {
    selectedFilter.value = filter;
    applyFilter(allPullOuts.toList());
  }

  /// Select a new status filter and re-apply.
  void selectStatusFilter(PullOutStatusFilter statusFilter, RxList<PullOutModel> allPullOuts) {
    selectedStatusFilter.value = statusFilter;
    applyFilter(allPullOuts.toList());
  }
}
