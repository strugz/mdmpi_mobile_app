import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_heading.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_subheading.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/collection_bucket_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/home_appbar.dart';

import '../../../../../base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/collection_bucket_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/cards/collection_summary_card.dart';

class CollectionHomeScreen extends StatelessWidget {
  const CollectionHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            BPrimaryHeaderContainer(
              child: Column(
                children: [
                  const BHomeAppBar(),
                  const SizedBox(height: BSizes.spaceBtwSections),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
              child: BSectionHeading(
                title: BTexts.collectionHomeTitle1,
                showActionButton: false,
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwSections),

            // Summary cards - Pending and Overdue on the same row, Completed below
            Padding(
              padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
              child: Column(
                children: const [
                  Row(
                    children: [
                      Expanded(
                        child: CollectionSummaryCard(
                          title: 'Pending',
                          value: '12',
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                          expand: false,
                        ),
                      ),
                      SizedBox(width: BSizes.spaceBtwItems),
                      Expanded(
                        child: CollectionSummaryCard(
                          title: 'Overdue',
                          value: '3',
                          icon: Icons.error,
                          color: Colors.red,
                          expand: false,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: BSizes.spaceBtwItems),
                  CollectionSummaryCard(
                    title: 'Completed',
                    value: '128',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: BSizes.spaceBtwItems),

            // Collection bucket button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
              child: Obx(() {
                final controller = Get.find<CollectionActivityController>();
                return CollectionBucketButton(
                  itemCount: controller.bucketItems.length,
                  onTap: () => Get.to(
                    () => const CollectionBucketScreen(),
                    transition: Transition.fade,
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                  ),
                );
              }),
            ),

            const SizedBox(height: BSizes.spaceBtwSections),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
              child: BSectionSubHeading(
                title: BTexts.collectionHomeSubTitle1,
                showActionButton: false,
              ),
            ),

          ],
        ),
      ),
    );
  }
}
