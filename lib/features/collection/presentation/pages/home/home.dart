import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_subheading.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/collection_bucket_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/recent_activities_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/home_appbar.dart';

import '../../../../../base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/collection_bucket_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/cards/collection_summary_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/category_detail_screen.dart';

class CollectionHomeScreen extends StatelessWidget {
  const CollectionHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Non-scrollable header section
          BPrimaryHeaderContainer(
            child: Column(
              children: [
                const BHomeAppBar(),
                const SizedBox(height: BSizes.spaceBtwSections),
              ],
            ),
          ),
          
          // Total Collected Card
          Padding(
            padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
            child: CollectionSummaryCard(
              title: 'Total Collected this Month',
              value: '40,000,000',
              icon: Icons.account_balance,
              color: Colors.green,
              expand: false,
              onTap: () => Get.to(() => const CategoryDetailScreen(title: 'Total Collected', color: Colors.green)),
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
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              );
            }),
          ),

          const SizedBox(height: BSizes.spaceBtwSections),

          // Summary cards grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CollectionSummaryCard(
                        title: 'Core Status',
                        value: '12',
                        icon: Icons.pending_actions,
                        color: Colors.blue,
                        expand: false,
                        onTap: () {
                          CollectionActivityController.instance.setCategoryFilter('Core Status');
                          Get.to(() => const CategoryDetailScreen(title: 'Core Status', color: Colors.blue));
                        },
                      ),
                    ),
                    const SizedBox(width: BSizes.spaceBtwItems),
                    Expanded(
                      child: CollectionSummaryCard(
                        title: 'Delays',
                        value: '3',
                        icon: Icons.error,
                        color: Colors.red,
                        expand: false,
                        onTap: () {
                          CollectionActivityController.instance.setCategoryFilter('Delays');
                          Get.to(() => const CategoryDetailScreen(title: 'Delays', color: Colors.red));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BSizes.spaceBtwItems),
                Row(
                  children: [
                    Expanded(
                      child: CollectionSummaryCard(
                        title: 'Completed',
                        value: '128',
                        icon: Icons.check_circle,
                        color: Colors.green,
                        onTap: () {
                          CollectionActivityController.instance.setCategoryFilter('Completed');
                          Get.to(() => const CategoryDetailScreen(title: 'Completed', color: Colors.green));
                        },
                      ),
                    ),
                    const SizedBox(width: BSizes.spaceBtwItems),
                    Expanded(
                      child: CollectionSummaryCard(
                        title: 'Administrative',
                        value: '3',
                        icon: Icons.verified_user,
                        color: Colors.orange,
                        expand: false,
                        onTap: () {
                          CollectionActivityController.instance.setCategoryFilter('Administrative');
                          Get.to(() => const CategoryDetailScreen(title: 'Administrative', color: Colors.orange));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: BSizes.spaceBtwSections),

          // Recent Activities Header with Show All button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BSectionSubHeading(
                  title: BTexts.collectionHomeSubTitle1,
                  showActionButton: false,
                ),
                TextButton(
                  onPressed: () => Get.to(() => const RecentActivitiesScreen()),
                  child: const Text('Show All'),
                ),
              ],
            ),
          ),

          const SizedBox(height: BSizes.spaceBtwItems),

          Expanded(
            child: Obx(() {
              final controller = CollectionActivityController.instance;
              
              // Combine history from the items to show a unified "Recent Activities" log
              final allHistory = controller.activityItems
                  .expand((item) => item.history)
                  .toList();

              if (allHistory.isEmpty) {
                return const Center(child: Text('No recent activities'));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
                child: ActivityHistoryList(history: allHistory),
              );
            }),
          ),
        ],
      ),
    );
  }
}
