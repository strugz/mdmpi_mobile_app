import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'bucket_item_details_screen.dart';
import 'widgets/bucket_item_card.dart';

/// Collection Bucket Screen
///
/// Displays unassigned collection items containing only client details and
/// document details (no assigned personnel). Tapping a card navigates to
/// [BucketItemDetailsScreen] with full details for that account.
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
      ),

      body: Obx(() {
        final items = controller.bucketItems;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_basket_rounded, size: 64, color: BColors.darkGrey),
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
          separatorBuilder: (_, __) => const SizedBox(height: BSizes.spaceBtwItems),
          itemBuilder: (context, index) {
            final item = items[index];
            return BucketItemCard(
              item: item,
              isSelected: false,
              onTap: () => Get.to(() => BucketItemDetailsScreen(item: item)),
            );
          },
        );
      }),
    );
  }
}
