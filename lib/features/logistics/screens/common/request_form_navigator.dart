import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/form_category_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';

/// Opens a request form by home-grid index and pre-selects its category in
/// [RequestController]. Shared by the Home quick actions and the request
/// form grid so both routes behave identically.
class RequestFormNavigator {
  RequestFormNavigator._();

  /// Navigate to `pages[index]`, matching the category by name against the
  /// local form-category table so the form opens on the right tab.
  static Future<void> open(int index, List<Widget> pages) async {
    if (index < 0 || index >= pages.length) return;

    try {
      final formCategoryRepo = Get.find<FormCategoryRepository>();
      final localCategories = await formCategoryRepo.getFromLocal();

      if (localCategories.isEmpty) {
        Get.to(() => pages[index]);
        return;
      }

      final categoryType = FormCategoryConstants.fromIndex(index);
      if (categoryType == null) {
        Get.to(() => pages[index]);
        return;
      }

      final targetCategoryName = categoryType.categoryName;
      final category = localCategories.firstWhereOrNull(
          (c) => c.name.toLowerCase() == targetCategoryName.toLowerCase());

      if (category != null) {
        try {
          final requestController = Get.find<RequestController>();
          requestController.currentSelectedCategory.value = category;

          final categoryIndex = requestController.formCategories
              .indexWhere((c) => c.id == category.id);
          if (categoryIndex >= 0) {
            requestController.updateTabIndex(categoryIndex);
          }
        } catch (e) {
          logDebug(
              'RequestController not found, but category will still be available: $e');
        }

        final formPageIndex = categoryType.actualFormPageIndex;
        if (formPageIndex >= 0 && formPageIndex < pages.length) {
          Get.to(() => pages[formPageIndex]);
          return;
        }
      } else {
        logDebug('Category "$targetCategoryName" not found in local DB');
      }
    } catch (e) {
      logDebug('Error loading categories from local DB: $e');
    }
    Get.to(() => pages[index]);
  }
}
