import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/app_routes.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_heading.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/home_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_request_form.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/dashboard_item.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/home_appbar.dart';

import '../../../../base/utils/constants/image_strings.dart';

/// Home screen displaying request form shortcuts and activity dashboard.
///
/// Architecture:
/// - Uses HomeController for business logic and dashboard statistics
/// - Pure UI layer - no data logic in build methods
/// - Extracted reusable DashboardItem widget
/// - Uses centralized constants from BTexts
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final dark = BHelperFunctions.isDarkMode(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Header
            const BPrimaryHeaderContainer(
              child: Column(
                children: [
                  BHomeAppBar(),
                  SizedBox(height: BSizes.spaceBtwSections),
                ],
              ),
            ),

            /// Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
              child: Column(
                children: [
                  const BSectionHeading(
                    title: BTexts.homeSubTitle3,
                    showActionButton: false,
                  ),

                  /// Request Form Shortcuts
                  BRequestForm(
                    labels: BTexts.requestFormLabels,
                    pages: AppRoutes.requestFormPages,
                    iconPaths: BImages.requestFormIconPaths,
                  ),

                  const SizedBox(height: BSizes.spaceBtwItemsLight),

                  /// Activity Dashboard Section
                  Obx(
                    () => BRoundedContainer(
                      width: double.infinity,
                      backgroundColor:
                          dark ? BColors.darkContainer : BColors.white,
                      showBorder: true,
                      borderColor: dark
                          ? BColors.darkerGrey
                          : BColors.grey.withValues(alpha: 0.6),
                      padding: const EdgeInsets.all(BSizes.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dashboard Header with year badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: BSectionHeading(
                                  title: BTexts.dashboardTitle,
                                  showActionButton: false,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: BSizes.sm,
                                  vertical: BSizes.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: BColors.primary
                                      .withValues(alpha: dark ? 0.25 : 0.1),
                                  borderRadius: BorderRadius.circular(
                                      BSizes.cardRadiusLg),
                                ),
                                child: Text(
                                  controller.currentYear,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(
                                        color: BColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: BSizes.spaceBtwItems),

                          // Dashboard Statistics
                          DashboardItem(
                            label: BTexts.dashboardTotalRequests,
                            value: controller.totalRequest.toString(),
                            icon: Iconsax.receipt_text,
                            accent: BColors.primary,
                          ),
                          DashboardItem(
                            label: BTexts.dashboardGettingSuppliesReady,
                            value: controller.gettingSuppliesReady.toString(),
                            icon: Iconsax.box,
                            accent: BColors.warning,
                          ),
                          DashboardItem(
                            label: BTexts.dashboardItemsPrepared,
                            value: controller.itemPrepared.toString(),
                            icon: Iconsax.box_tick,
                            accent: const Color(0xFF8B5CF6),
                          ),
                          DashboardItem(
                            label: BTexts.dashboardForDelivery,
                            value: controller.forDelivery.toString(),
                            icon: Iconsax.truck_fast,
                            accent: BColors.info,
                          ),
                          DashboardItem(
                            label: BTexts.dashboardDelivered,
                            value: controller.delivered.toString(),
                            icon: Iconsax.tick_circle,
                            accent: BColors.success,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Extra space at the bottom to ensure visibility on all devices
                  const SizedBox(height: BSizes.spaceBtwSections * 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
