import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

import 'widgets/bucket_item_card.dart';

/// Collection Bucket Screen
///
/// Displays unassigned collection items containing only client details and
/// document details (no assigned personnel). The user multi-selects items
/// and taps **Claim** to move them into the Activity screen.
class CollectionBucketScreen extends StatelessWidget {
  const CollectionBucketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionActivityController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Collection Bucket',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          /// Select-all toggle
          Obx(() => TextButton(
                onPressed: controller.toggleSelectAll,
                child: Text(
                  controller.allSelected ? 'Deselect All' : 'Select All',
                  style: TextStyle(
                    color: BColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
        ],
      ),

      /// Claim button fixed at the bottom
      bottomNavigationBar: Obx(() {
        final count = controller.selectedBucketIds.length;
        if (count == 0) return const SizedBox.shrink();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(BSizes.defaultSpace),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  controller.claimSelectedItems();
                  Get.back();
                  Get.snackbar(
                    'Items Claimed',
                    '$count item${count == 1 ? '' : 's'} moved to Activity.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: BColors.success,
                    colorText: BColors.white,
                    margin: const EdgeInsets.all(BSizes.defaultSpace),
                  );
                },
                icon: const Icon(Iconsax.tick_circle),
                label: Text(
                  'Claim $count item${count == 1 ? '' : 's'}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BColors.primary,
                  foregroundColor: BColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(BSizes.borderRadiusLg),
                  ),
                ),
              ),
            ),
          ),
        );
      }),

      body: Obx(() {
        final items = controller.filteredBucketItems;

        return Column(
          children: [
            /// Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BSizes.defaultSpace,
                vertical: BSizes.md,
              ),
              child: TextFormField(
                onChanged: (value) => controller.bucketSearchQuery.value = value,
                decoration: const InputDecoration(
                  hintText: 'Search by client, ID, bank...',
                  prefixIcon: Icon(Iconsax.search_normal),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),

            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            controller.bucketSearchQuery.value.isEmpty
                                ? Icons.shopping_basket_rounded
                                : Iconsax.search_status,
                            size: 64,
                            color: BColors.darkGrey,
                          ),
                          const SizedBox(height: BSizes.spaceBtwItems),
                          Text(
                            controller.bucketSearchQuery.value.isEmpty
                                ? 'Bucket is empty'
                                : 'No results found',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: BColors.darkGrey,
                                ),
                          ),
                          const SizedBox(height: BSizes.xs),
                          Text(
                            controller.bucketSearchQuery.value.isEmpty
                                ? 'No unassigned collection items available.'
                                : 'Try searching for something else.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: BColors.darkGrey,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        BSizes.defaultSpace,
                        0,
                        BSizes.defaultSpace,
                        BSizes.defaultSpace,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: BSizes.spaceBtwItems),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Obx(() => BucketItemCard(
                              item: item,
                              isSelected: controller.isSelected(item.id),
                              onTap: () =>
                                  controller.toggleBucketSelection(item.id),
                            ));
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}



