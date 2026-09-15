import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/collection_bucket_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/cards/collection_summary_card.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_subheading.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/collection_bucket_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/recent_activities_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/bucket_download_overlay.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/category_detail_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/collection_sync_bar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/collection_totals_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/total_collected_month/monthly_summary_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/home_appbar.dart';

class CollectionHomeScreen extends StatelessWidget {
  const CollectionHomeScreen({super.key});

  /// Phone-sized rhythm for the dashboard. The shared defaults (24px margins,
  /// 32px sections) are desktop-sized and pushed Engagement History below
  /// the fold on a real device.
  static const double _margin = BSizes.md; // 16
  static const double _gap = BSizes.spaceBtwItemsLight; // 12
  static const double _sectionGap = 20;

  /// Respect the system text size, but stop a large setting from wrapping
  /// buttons and truncating tile labels in this fixed dashboard layout.
  static const double _maxTextScale = 1.15;

  static const _pageTransition = Transition.cupertino;
  static const _pageDuration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionActivityController>();

    return Scaffold(
      body: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _maxTextScale,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
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

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _margin),
                    child: Column(
                      children: [
                        // Money at a glance: one card, two figures.
                        CollectionTotalsCard(
                          onActualTap: () => Get.to(
                            () => const MonthlySummaryScreen(type: 'Deposit'),
                            transition: _pageTransition,
                            duration: _pageDuration,
                          ),
                          onCollectedTap: () => Get.to(
                            () => const MonthlySummaryScreen(type: 'Collection'),
                            transition: _pageTransition,
                            duration: _pageDuration,
                          ),
                        ),
                        const SizedBox(height: _gap),

                        // Collection bucket
                        Obx(() => CollectionBucketButton(
                              itemCount: controller.bucketItems.length,
                              onTap: () => Get.to(
                                () => const CollectionBucketScreen(),
                                transition: _pageTransition,
                                duration: _pageDuration,
                                curve: Curves.easeInOut,
                              ),
                            )),
                        const SizedBox(height: _gap),

                        // Download bucket / Upload (offline sync controls)
                        const CollectionSyncBar(),
                        const SizedBox(height: _sectionGap),

                        // Summary tiles
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Obx(() => CollectionSummaryCard(
                                    title: 'Settled',
                                    value: controller.completedItems.length.toString(),
                                    icon: Iconsax.tick_circle,
                                    color: BColors.success,
                                    onTap: () => _openCategory('Settled', BColors.success),
                                  )),
                            ),
                            const SizedBox(width: _gap),
                            Expanded(
                              child: Obx(() => CollectionSummaryCard(
                                    title: 'Due Date',
                                    value: controller.overdueItems.length.toString(),
                                    icon: Iconsax.timer,
                                    color: BColors.error,
                                    expand: false,
                                    onTap: () => _openCategory('Due Date', BColors.error),
                                  )),
                            ),
                          ],
                        ),
                        const SizedBox(height: _gap),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Obx(() => CollectionSummaryCard(
                                    title: 'Reconciliation',
                                    value: controller.reconciliationItems.length.toString(),
                                    icon: Iconsax.status_up,
                                    color: Colors.purple,
                                    onTap: () => _openCategory('Reconciliation', Colors.purple),
                                  )),
                            ),
                            const SizedBox(width: _gap),
                            Expanded(
                              child: Obx(() => CollectionSummaryCard(
                                    title: 'Advanced Payment',
                                    value: controller.advancedPaymentsCount.toString(),
                                    icon: Iconsax.card_send,
                                    color: Colors.orange,
                                    expand: false,
                                    onTap: () => _openCategory('Advanced Payment', Colors.orange),
                                  )),
                            ),
                          ],
                        ),
                        const SizedBox(height: _sectionGap),
                      ],
                    ),
                  ),

                  // Bottom: Recent Activities
                  Container(
                    decoration: BoxDecoration(
                      color: BColors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(BSizes.borderRadiusLg)),
                      boxShadow: [
                        BoxShadow(
                          color: BColors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _margin),
                      child: Column(
                        children: [
                          // Recent Activities Header with Show All button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Expanded bounds the heading's width inside this Row
                              // (its internal Row uses Expanded for ellipsizing).
                              const Expanded(
                                child: BSectionSubHeading(
                                  title: BTexts.collectionHomeSubTitle1,
                                  showActionButton: false,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Get.to(
                                  () => const RecentActivitiesScreen(),
                                  transition: _pageTransition,
                                  duration: _pageDuration,
                                ),
                                child: const Text('Show All'),
                              ),
                            ],
                          ),

                          Obx(() {
                            final recentItems = controller.allRecentHistory;

                            if (recentItems.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: BSizes.lg),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Iconsax.clock, size: 48, color: BColors.darkGrey),
                                    const SizedBox(height: BSizes.sm),
                                    Text(
                                      'No engagement history yet',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: BColors.darkGrey),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Limit to the most recent 3 entries
                            final recentThree = recentItems.take(3).toList();

                            final historyList = recentThree.map((e) => e['history'] as CollectionHistoryModel).toList();
                            final accountNames = { for (var i = 0; i < recentThree.length; i++) i : recentThree[i]['accountName'].toString() };
                            final invoiceIds = { for (var i = 0; i < recentThree.length; i++) i : recentThree[i]['invoiceId']?.toString() };
                            final items = { for (var i = 0; i < recentThree.length; i++) i : recentThree[i]['item'] as CollectionItemModel? };

                            return ActivityHistoryList(
                              history: historyList,
                              accountNames: accountNames,
                              invoiceIds: invoiceIds,
                              items: items,
                            );
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

            // "Download Bucket" transition: server → bucket data-transfer
            // animation over a blurred scrim, resolving to a check / error.
            Obx(() => BucketDownloadOverlay(
                  phase: controller.bucketDownloadPhase.value,
                  itemCount: controller.lastDownloadedCount.value,
                )),
          ],
        ),
      ),
    );
  }

  static void _openCategory(String title, Color color) {
    Get.to(
      () => CategoryDetailScreen(title: title, color: color),
      transition: _pageTransition,
      duration: _pageDuration,
    );
  }
}
