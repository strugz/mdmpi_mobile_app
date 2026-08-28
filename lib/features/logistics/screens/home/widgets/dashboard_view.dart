import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/filter_dropdown.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_heading.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/dashboard_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_bucket_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/dashboard_item.dart';

/// Reusable activity dashboard aggregating all six request modules.
///
/// Filters:
/// - Module: All Requests, or one of the six request types
/// - Date: Year dropdown (All Time + years in data) and, when a year is
///   selected, a Month dropdown (Whole Year + Jan..Dec)
///
/// Views:
/// - All Requests: grand total plus one tappable row per module (tap drills
///   into that module)
/// - Single module: total plus the module's own status buckets
///
/// [chartBuilder] is an optional slot for a future chart (e.g. fl_chart pie)
/// rendered between the filters and the count rows.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key, this.chartBuilder});

  final Widget Function(BuildContext, DashboardController)? chartBuilder;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final dark = BHelperFunctions.isDarkMode(context);

    return BRoundedContainer(
      width: double.infinity,
      backgroundColor: dark ? BColors.darkContainer : BColors.white,
      showBorder: true,
      borderColor:
          dark ? BColors.darkerGrey : BColors.grey.withValues(alpha: 0.6),
      padding: const EdgeInsets.all(BSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BSectionHeading(
            title: BTexts.dashboardTitle,
            showActionButton: false,
          ),
          const SizedBox(height: BSizes.spaceBtwItems),

          /// Module filter
          FilterDropdown<FormCategoryType?>(
            selectedFilter: controller.selectedModule,
            filterValues: <FormCategoryType?>[
              null,
              ...FormCategoryType.values,
            ],
            getDisplayName: (module) =>
                module?.categoryName ?? BTexts.dashboardAllRequests,
            onFilterChanged: controller.selectModule,
          ),
          const SizedBox(height: BSizes.spaceBtwItems / 2),

          /// Date filters (year + month)
          Obx(
            () {
              final year = controller.selectedYear.value;
              return Row(
                children: [
                  Expanded(
                    child: FilterDropdown<int?>(
                      key: ValueKey('dashboard-year-${controller.yearOptions.length}'),
                      selectedFilter: controller.selectedYear,
                      filterValues: <int?>[null, ...controller.yearOptions],
                      getDisplayName: (y) =>
                          y?.toString() ?? BTexts.dashboardAllTime,
                      onFilterChanged: controller.selectYear,
                    ),
                  ),
                  if (year != null) ...[
                    const SizedBox(width: BSizes.sm),
                    Expanded(
                      child: FilterDropdown<int?>(
                        key: ValueKey('dashboard-month-$year'),
                        selectedFilter: controller.selectedMonth,
                        filterValues: <int?>[
                          null,
                          for (var m = 1; m <= 12; m++) m,
                        ],
                        getDisplayName: (m) => m == null
                            ? BTexts.dashboardWholeYear
                            : DateFormat('MMMM').format(DateTime(2000, m)),
                        onFilterChanged: controller.selectMonth,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: BSizes.spaceBtwItems),

          if (chartBuilder != null) ...[
            chartBuilder!(context, controller),
            const SizedBox(height: BSizes.spaceBtwItems),
          ],

          /// Counts
          Obx(() => _buildCounts(context, controller)),
        ],
      ),
    );
  }

  Widget _buildCounts(BuildContext context, DashboardController controller) {
    final module = controller.selectedModule.value;

    final totalRow = DashboardItem(
      label: BTexts.dashboardTotalRequests,
      value: controller.totalCount.toString(),
      icon: module == null
          ? Iconsax.receipt_text
          : DashboardBucketConfig.moduleIcon(module),
      accent: module == null
          ? BColors.primary
          : DashboardBucketConfig.moduleAccent(module),
    );

    if (module == null) {
      final counts = controller.moduleCounts;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          totalRow,
          const Divider(),
          for (final type in FormCategoryType.values)
            DashboardItem(
              label: type.categoryName,
              value: (counts[type] ?? 0).toString(),
              icon: DashboardBucketConfig.moduleIcon(type),
              accent: DashboardBucketConfig.moduleAccent(type),
              onTap: () => controller.selectModule(type),
            ),
        ],
      );
    }

    final bucketCounts = controller.bucketCounts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        totalRow,
        const Divider(),
        for (final bucket in controller.buckets)
          DashboardItem(
            label: bucket.label,
            value: (bucketCounts[bucket.label] ?? 0).toString(),
            icon: bucket.icon,
            accent: bucket.accent,
          ),
      ],
    );
  }
}
