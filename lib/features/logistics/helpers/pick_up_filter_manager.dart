import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

enum PickUpStatusFilter {
  statusNewRequest('New Request'),
  statusGettingSuppliesReady('Getting Supplies Ready'),
  statusItemPacked('Item Packed'),
  statusReceived('Received'),
  statusCancelled('Cancelled'),
  all('All');

  const PickUpStatusFilter(this.displayName);
  final String displayName;
}

class PickUpFilterManager {
  final Rx<RequestFilter> selectedFilter = RequestFilter.today.obs;
  final Rx<PickUpStatusFilter> selectedStatusFilter =
      PickUpStatusFilter.all.obs;
  final Rxn<DateTime> selectedDateFrom = Rxn<DateTime>();
  final Rxn<DateTime> selectedDateTo = Rxn<DateTime>();
  final RxString selectedItemCategoryId = ''.obs;
  final RxString clientNameQuery = ''.obs;
  final RxString documentReferenceQuery = ''.obs;

  final RxList<PickUpModel> filteredPickUps = <PickUpModel>[].obs;

  void reset([List<PickUpModel>? allPickUps]) {
    selectedFilter.value = RequestFilter.today;
    selectedStatusFilter.value = PickUpStatusFilter.all;
    selectedDateFrom.value = null;
    selectedDateTo.value = null;
    selectedItemCategoryId.value = '';
    clientNameQuery.value = '';
    documentReferenceQuery.value = '';
    filteredPickUps.clear();
    if (allPickUps != null) {
      applyFilter(allPickUps);
    }
  }

  void applyFilter(List<PickUpModel> allPickUps) {
    final userController = Get.find<UserController>();
    final filter = selectedFilter.value;
    final statusFilter = selectedStatusFilter.value;
    final dateFrom = selectedDateFrom.value;
    final dateTo = selectedDateTo.value;
    final itemCategoryId = selectedItemCategoryId.value;
    final clientQuery = clientNameQuery.value.trim().toLowerCase();
    final documentQuery = documentReferenceQuery.value.trim().toLowerCase();
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
          statusFilter.displayName == PickUpStatusFilter.all.displayName ||
              item.status == statusFilter.displayName;

      bool userMatches = true;
      if (!currentUser.role.contains(',') &&
          currentUser.role.contains(BTexts.roleCourier)) {
        userMatches = item.receivedBy == currentUser.initial ||
            item.releasedBy == currentUser.initial;
        logDebug(
            'PickUpFilter: receivedBy=${item.receivedBy}, releasedBy=${item.releasedBy}');
      }

      final dateFromMatches = dateFrom == null ||
          (targetDate != null &&
              !targetDate.isBefore(
                  DateTime(dateFrom.year, dateFrom.month, dateFrom.day)));
      final dateToMatches = dateTo == null ||
          (targetDate != null &&
              !targetDate.isAfter(DateTime(
                  dateTo.year, dateTo.month, dateTo.day, 23, 59, 59)));
      final itemCategoryMatches =
          itemCategoryId.isEmpty || item.itemCategoryId == itemCategoryId;
      final clientNameMatches =
          clientQuery.isEmpty || item.client.name.toLowerCase().contains(clientQuery);
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

  void selectStatusFilter(
      PickUpStatusFilter statusFilter, RxList<PickUpModel> allPickUps) {
    selectedStatusFilter.value = statusFilter;
    applyFilter(allPickUps.toList());
  }

  void selectDateFrom(DateTime? date, RxList<PickUpModel> allPickUps) {
    selectedDateFrom.value = date;
    applyFilter(allPickUps.toList());
  }

  void selectDateTo(DateTime? date, RxList<PickUpModel> allPickUps) {
    selectedDateTo.value = date;
    applyFilter(allPickUps.toList());
  }

  void selectItemCategoryId(String categoryId, RxList<PickUpModel> allPickUps) {
    selectedItemCategoryId.value = categoryId;
    applyFilter(allPickUps.toList());
  }

  void setClientNameQuery(String query, RxList<PickUpModel> allPickUps) {
    clientNameQuery.value = query;
    applyFilter(allPickUps.toList());
  }

  void setDocumentReferenceQuery(String query, RxList<PickUpModel> allPickUps) {
    documentReferenceQuery.value = query;
    applyFilter(allPickUps.toList());
  }
}
