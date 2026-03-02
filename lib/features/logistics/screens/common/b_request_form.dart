import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/layouts/grid_layout.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/form_category_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';

import '../../../../base/utils/constants/colors.dart';
import '../../../../base/utils/constants/sizes.dart';
import '../../../../base/utils/helpers/helper_functions.dart';

class BRequestForm extends StatelessWidget {
  const BRequestForm({
    super.key,
    required this.labels,
    required this.pages,
    required this.iconPaths,
  });

  final List<String> labels;
  final List<StatelessWidget> pages;
  final List<String> iconPaths;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.all(BSizes.spaceBtwItems),
      child: BGridLayout(
        itemCount: labels.length,
        crossAxisCount: 3,
        mainAxisExtent: 110, // keep squares consistent height
        itemBuilder: (context, index) {
          return InkWell(
            borderRadius: BorderRadius.circular(BSizes.cardRadiusLg),
            onTap: () {
              _navigateToFormWithCategory(index);
            },
            child: BRoundedContainer(
              backgroundColor: dark ? BColors.black : BColors.light,
              radius: BSizes.cardRadiusLg,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    iconPaths[index],
                    width: 52,
                    height: 52,
                    color: dark ? BColors.white : BColors.black,
                  ),
                  const SizedBox(height: BSizes.spaceBtwItems / 2),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Navigate to the form page and set the appropriate form category in RequestController.
  /// Loads form categories directly from local database to ensure data consistency.
  Future<void> _navigateToFormWithCategory(int index) async {
    if (index < 0 || index >= pages.length) {
      return;
    }

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
          print(
              'RequestController not found, but category will still be available: $e');
        }

        final formPageIndex = categoryType.actualFormPageIndex;

        if (formPageIndex >= 0 && formPageIndex < pages.length) {
          Get.to(() => pages[formPageIndex]);
          return;
        }
      } else {
        print('Category "$targetCategoryName" not found in local DB');
      }
    } catch (e) {
      print('Error loading categories from local DB: $e');
    }
    Get.to(() => pages[index]);
  }
}
