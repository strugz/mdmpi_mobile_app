import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_subheading.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/collection_bucket_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/recent_activities_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/home_appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/total_collected_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/total_collected_month/total_collected_month_screen.dart';

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top: Dashboard Area
            Column(
              children: [
                // Header
                const BPrimaryHeaderContainer(
                  child: Column(
                    children: [
                      BHomeAppBar(),
                      SizedBox(height: BSizes.spaceBtwSections),
                    ],
                  ),
                ),

                // Total Collected Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
                  child: TotalCollectedCard(
                    color: Colors.green,
                    onTap: () => Get.to(
                      () => const TotalCollectedMonthScreen(),
                      transition: Transition.cupertino,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ),
                ),
                const SizedBox(height: BSizes.spaceBtwItems),

                // Collection bucket button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
                  child: Obx(() {
                    final controller = Get.find<CollectionActivityController>();
                    return CollectionBucketButton(
                      itemCount: controller.bucketItems.length,
                      onTap: () => Get.to(
                        () => const CollectionBucketScreen(),
                        transition: Transition.cupertino,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: BSizes.spaceBtwSections),

                // Summary cards grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
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
                                Get.to(
                                  () => const CategoryDetailScreen(title: 'Core Status', color: Colors.blue),
                                  transition: Transition.cupertino,
                                  duration: const Duration(milliseconds: 300),
                                );
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
                                Get.to(
                                  () => const CategoryDetailScreen(title: 'Delays', color: Colors.red),
                                  transition: Transition.cupertino,
                                  duration: const Duration(milliseconds: 300),
                                );
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
                                Get.to(
                                  () => const CategoryDetailScreen(title: 'Completed', color: Colors.green),
                                  transition: Transition.cupertino,
                                  duration: const Duration(milliseconds: 300),
                                );
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
                                Get.to(
                                  () => const CategoryDetailScreen(title: 'Administrative', color: Colors.orange),
                                  transition: Transition.cupertino,
                                  duration: const Duration(milliseconds: 300),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: BSizes.spaceBtwSections),
              ],
            ),

            // Bottom: Recent Activities
            Container(
              decoration: BoxDecoration(
                color: BColors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(BSizes.borderRadiusLg)),
                boxShadow: [
                  BoxShadow(
                    color: BColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
                child: Column(
                  children: [
                    // Recent Activities Header with Show All button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const BSectionSubHeading(
                          title: BTexts.collectionHomeSubTitle1,
                          showActionButton: false,
                        ),
                        TextButton(
                          onPressed: () => Get.to(
                            () => const RecentActivitiesScreen(),
                            transition: Transition.cupertino,
                            duration: const Duration(milliseconds: 300),
                          ),
                          child: const Text('Show All'),
                        ),
                      ],
                    ),

                    Obx(() {
                      final controller = CollectionActivityController.instance;

                      // Combine history from the items to show a unified "Recent Activities" log
                      final allHistory = controller.activityItems
                          .expand((item) => item.history)
                          .toList();

                      if (allHistory.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: BSizes.lg),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.clock, size: 48, color: BColors.darkGrey),
                              const SizedBox(height: BSizes.sm),
                              Text(
                                'No recent activities yet',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: BColors.darkGrey),
                              ),
                            ],
                          ),
                        );
                      }

                      // Sort all history chronologically first
                      allHistory.sort((a, b) => a.date.compareTo(b.date));

                      // Limit to the most recent 3 entries
                      final recentThree = allHistory.length > 3 
                          ? allHistory.sublist(allHistory.length - 3) 
                          : allHistory;

                      return ActivityHistoryList(history: recentThree);
                    }),
                    
                    // Add extra space at the bottom for scrolling comfort
                    const SizedBox(height: BSizes.spaceBtwSections * 2),
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
