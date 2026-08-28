import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/layouts/grid_layout.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/form_category_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';

import '../../../../base/utils/constants/colors.dart';
import '../../../../base/utils/logger.dart';
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

  /// Accent color per shortcut tile, cycled by index.
  static const List<Color> _tileAccents = [
    Color(0xFF4B68FF), // Standard Delivery - indigo (brand primary)
    Color(0xFFF57C00), // Pull out - orange
    Color(0xFF2E9E6B), // Pick up - green
    Color(0xFF0EA5E9), // Air / Sea - sky blue
    Color(0xFFE0507A), // Hotline Direct - rose
    Color(0xFF8B5CF6), // Stock receive - violet
  ];

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.all(BSizes.spaceBtwItems),
      child: BGridLayout(
        itemCount: labels.length,
        crossAxisCount: 3,
        mainAxisExtent: 116, // keep squares consistent height
        itemBuilder: (context, index) {
          final accent = _tileAccents[index % _tileAccents.length];
          return InkWell(
            borderRadius: BorderRadius.circular(BSizes.cardRadiusLg),
            onTap: () {
              _navigateToFormWithCategory(index);
            },
            child: BRoundedContainer(
              backgroundColor: dark
                  ? accent.withValues(alpha: 0.12)
                  : accent.withValues(alpha: 0.07),
              radius: BSizes.cardRadiusLg,
              showBorder: true,
              borderColor: accent.withValues(alpha: dark ? 0.35 : 0.2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(BSizes.sm),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: dark ? 0.25 : 0.14),
                      borderRadius:
                          BorderRadius.circular(BSizes.cardRadiusLg),
                    ),
                    child: Image.asset(
                      iconPaths[index],
                      width: 36,
                      height: 36,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: BSizes.spaceBtwItems / 2),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: dark ? BColors.white : BColors.textPrimary,
                        ),
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
