import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/dashboard_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_bucket_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/dashboard_hero_card.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/dashboard_stat_grid.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/date_scope_sheet.dart';

/// The Home activity dashboard, aggregating all request modules.
///
/// Layout, top to bottom:
/// - [DashboardHeroCard]: grand total, tappable date scope, share bar, and a
///   back chip when a module is selected
/// - [DashboardStatGrid]: per-module tiles (All) or status tiles (module),
///   filling the remaining height
///
/// Must be given a bounded height (it uses `Expanded`). It only maps
/// controller state to the pure widgets above: it reads [DashboardController]
/// via `Get.find()` and wraps the smallest subtree in `Obx`.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Obx(() {
      if (controller.isLoading.value && controller.entries.isEmpty) {
        return const DashboardSkeleton();
      }

      final module = controller.selectedModule.value;
      final year = controller.selectedYear.value;
      final month = controller.selectedMonth.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardHeroCard(
            title: module?.categoryName ?? BTexts.dashboardAllRequests,
            total: controller.totalCount,
            scopeLabel: dateScopeLabel(year, month),
            icon: module == null
                ? Iconsax.receipt_text
                : DashboardBucketConfig.moduleIcon(module),
            accent: module == null
                ? BColors.primary
                : DashboardBucketConfig.moduleAccent(module),
            segments: _segments(controller, module),
            onBack: module == null ? null : () => controller.selectModule(null),
            onScopeTap: () => showDateScopeSheet(
              context,
              year: year,
              month: month,
              yearOptions: controller.yearOptions,
              onYearChanged: controller.selectYear,
              onMonthChanged: controller.selectMonth,
            ),
          ),
          const SizedBox(height: BSizes.sm + BSizes.xs),
          Expanded(
            child: DashboardStatGrid(
              switchKey: module ?? 'all',
              stats: _stats(controller, module),
            ),
          ),
        ],
      );
    });
  }

  List<ShareSegment> _segments(
      DashboardController controller, FormCategoryType? module) {
    if (module == null) {
      final counts = controller.moduleCounts;
      return [
        for (final type in FormCategoryType.values)
          ShareSegment(
            label: type.categoryName,
            count: counts[type] ?? 0,
            color: DashboardBucketConfig.moduleAccent(type),
          ),
      ];
    }
    final counts = controller.bucketCounts;
    return [
      for (final bucket in controller.buckets)
        ShareSegment(
          label: bucket.label,
          count: counts[bucket.label] ?? 0,
          color: bucket.accent,
        ),
    ];
  }

  List<DashboardStat> _stats(
      DashboardController controller, FormCategoryType? module) {
    if (module == null) {
      final counts = controller.moduleCounts;
      return [
        for (final type in FormCategoryType.values)
          DashboardStat(
            label: type.categoryName,
            count: counts[type] ?? 0,
            icon: DashboardBucketConfig.moduleIcon(type),
            accent: DashboardBucketConfig.moduleAccent(type),
            onTap: () => controller.selectModule(type),
          ),
      ];
    }
    final counts = controller.bucketCounts;
    return [
      for (final bucket in controller.buckets)
        DashboardStat(
          label: bucket.label,
          count: counts[bucket.label] ?? 0,
          icon: bucket.icon,
          accent: bucket.accent,
        ),
    ];
  }
}
