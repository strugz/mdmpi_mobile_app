import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
              child: BSectionHeading(
                title: BTexts.homeSubTitle3,
                showActionButton: false,
              ),
            ),

            /// Request Form Shortcuts
            BRequestForm(
              labels: BTexts.requestFormLabels,
              pages: AppRoutes.requestFormPages,
              iconPaths: BImages.requestFormIconPaths,
            ),

            const SizedBox(height: BSizes.spaceBtwItemsLight),
            const Divider(),
            const SizedBox(height: BSizes.spaceBtwItemsLight),

            /// Activity Dashboard Section
            Obx(
              () => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BSizes.spaceBtwItems,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard Header
                    const BSectionHeading(
                      title: BTexts.dashboardTitle,
                      showActionButton: false,
                    ),
                    BSectionHeading(
                      title: controller.currentYear,
                      showActionButton: false,
                    ),
                    const SizedBox(height: BSizes.spaceBtwItems),

                    // Dashboard Statistics
                    DashboardItem(
                      label: BTexts.dashboardTotalRequests,
                      value: controller.totalRequest.toString(),
                    ),
                    DashboardItem(
                      label: BTexts.dashboardGettingSuppliesReady,
                      value: controller.gettingSuppliesReady.toString(),
                    ),
                    DashboardItem(
                      label: BTexts.dashboardItemsPrepared,
                      value: controller.itemPrepared.toString(),
                    ),
                    DashboardItem(
                      label: BTexts.dashboardForDelivery,
                      value: controller.forDelivery.toString(),
                    ),
                    DashboardItem(
                      label: BTexts.dashboardDelivered,
                      value: controller.delivered.toString(),
                    ),

                    const SizedBox(height: BSizes.spaceBtwSections),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
