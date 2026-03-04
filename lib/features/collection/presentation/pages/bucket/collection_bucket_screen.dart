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
        final items = controller.bucketItems;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_basket_rounded,
                    size: 64, color: BColors.darkGrey),
                const SizedBox(height: BSizes.spaceBtwItems),
                Text(
                  'Bucket is empty',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: BColors.darkGrey,
                      ),
                ),
                const SizedBox(height: BSizes.xs),
                Text(
                  'No unassigned collection items available.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BColors.darkGrey,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          itemCount: items.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: BSizes.spaceBtwItems),
          itemBuilder: (context, index) {
            final item = items[index];
            return Obx(() => BucketItemCard(
                  item: item,
                  isSelected: controller.isSelected(item.id),
                  onTap: () => controller.toggleBucketSelection(item.id),
                ));
          },
        );
      }),
    );
  }
}



