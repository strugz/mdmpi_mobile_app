import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_heading.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/home_appbar.dart'; // Assuming this exists
import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../controllers/request_controller.dart'; // Assuming this exists

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestController>();
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// -- Header ---
            BPrimaryHeaderContainer(
              child: Column(
                children: [
                  /// -- AppBar ---
                  const BHomeAppBar(),
                  const SizedBox(height: BSizes.spaceBtwSections),
                ],
              ),
            ),

            /// Body
            const SizedBox(height: BSizes.defaultSpace),
            Obx(
              () => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: BSizes.defaultSpace), // Added horizontal padding
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Align items to the start
                  children: [
                    BSectionHeading(
                        title: 'Activity Dashboard', showActionButton: false),
                    BSectionHeading(
                        title: DateTime.now().year.toString(), showActionButton: false),
                    const SizedBox(height: BSizes.spaceBtwItems),
                    /// Create a Dashboard
                    _buildDashboardItem(
                        context, 'Total Requests:', controller.totalRequest.toString()),
                    _buildDashboardItem(context, 'Getting Supplies Ready:',
                        controller.gettingSuppliesReady.toString()),
                    _buildDashboardItem(
                        context, 'Items Prepared:', controller.itemPrepared.toString()),
                    _buildDashboardItem(
                        context, 'For Delivery:', controller.forDelivery.toString()),
                    _buildDashboardItem(
                        context, 'Delivered:', controller.delivered.toString()),
                    const SizedBox(
                        height: BSizes
                            .spaceBtwSections), // Add some space at the bottom
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build individual dashboard items
  Widget _buildDashboardItem(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
