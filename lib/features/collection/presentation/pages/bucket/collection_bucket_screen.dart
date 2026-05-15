import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/account_item_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/bucket_filter_modal.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/side_filter_drawer.dart';
import 'collection_account_information_screen.dart';
import 'widgets/collection_search_filter_bar.dart';

/// Collection Bucket Screen (Account-Centric)
///
/// Displays unique accounts in the bucket.
/// Multi-select accounts with long press.
class CollectionBucketScreen extends StatelessWidget {
  const CollectionBucketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionActivityController>();

    return Obx(() => Scaffold(
      appBar: AppBar(
        leading: controller.isSelectionMode.value 
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => controller.exitSelectionMode(),
            )
          : null,
        title: Text(
          controller.isSelectionMode.value 
            ? '${controller.selectedAccountIds.length} Selected'
            : 'Collection Bucket',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          if (controller.isSelectionMode.value)
            IconButton(
              icon: const Icon(Iconsax.tick_circle),
              onPressed: () {
                final count = controller.selectedAccountIds.length;
                controller.claimSelectedAccounts();
                Get.snackbar(
                  'Accounts Claimed',
                  '$count account(s) moved to Activity.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: BColors.success,
                  colorText: BColors.white,
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: controller.isSelectionMode.value 
        ? SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(BSizes.defaultSpace),
              child: ElevatedButton.icon(
                onPressed: () {
                  final count = controller.selectedAccountIds.length;
                  controller.claimSelectedAccounts();
                  Get.snackbar(
                    'Accounts Claimed',
                    '$count account(s) moved to Activity.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: BColors.success,
                    colorText: BColors.white,
                  );
                },
                icon: const Icon(Iconsax.tick_circle),
                label: Text('Claim ${controller.selectedAccountIds.length} Account(s)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BColors.primary,
                  foregroundColor: BColors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
                  ),
                ),
              ),
            ),
          )
        : null,
      body: Obx(() {
        final accounts = controller.bucketAccounts;

        return Column(
          children: [
            /// Search and Filter Bar (Hidden in selection mode for cleaner UI)
            if (!controller.isSelectionMode.value)
              Obx(() {
                final hasFilter = controller.bucketMinAmount.value > 0 || 
                                 controller.bucketMaxAmount.value > 0 ||
                                 controller.bucketMinInvoices.value > 0 ||
                                 controller.bucketMaxInvoices.value > 0;
                
                  return CollectionSearchFilterBar(
                  searchHint: 'Search by account name...',
                  initialValue: controller.bucketSearchQuery.value,
                  onSearchChanged: (value) => controller.bucketSearchQuery.value = value,
                  hasActiveFilter: hasFilter,
                      onFilterTap: () => showSideFilter(BucketFilterModal()),
                );
              }),

            Expanded(
              child: accounts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            (controller.bucketSearchQuery.value.isEmpty && 
                             controller.bucketMinAmount.value == 0 && 
                             controller.bucketMinInvoices.value == 0)
                                ? Icons.shopping_basket_rounded
                                : Iconsax.search_status,
                            size: 64,
                            color: BColors.darkGrey,
                          ),
                          const SizedBox(height: BSizes.spaceBtwItems),
                          Text(
                            'No accounts match your criteria',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: BColors.darkGrey,
                                ),
                          ),
                          const SizedBox(height: BSizes.xs),
                          TextButton(
                            onPressed: () {
                              controller.bucketMinAmount.value = 0;
                              controller.bucketMaxAmount.value = 0;
                              controller.bucketMinInvoices.value = 0;
                              controller.bucketMaxInvoices.value = 0;
                              controller.bucketSearchQuery.value = '';
                            },
                            child: const Text('Clear all filters'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(BSizes.defaultSpace),
                      itemCount: accounts.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: BSizes.spaceBtwItems),
                      itemBuilder: (context, index) {
                        final client = accounts[index];
                        final isSelected = controller.selectedAccountIds.contains(client.id);
                        
                        return AccountItemCard(
                          client: client,
                          invoiceCount: controller.getAccountInvoiceCount(client.id),
                          totalAmount: controller.getAccountTotalDue(client.id),
                          totalCollected: controller.getAccountTotalCollected(client.id),
                          isSelected: isSelected,
                          isSelectionMode: controller.isSelectionMode.value,
                          onTap: () {
                            if (controller.isSelectionMode.value) {
                              controller.toggleAccountSelection(client.id);
                            } else {
                              Get.to(() => CollectionAccountInformationScreen(client: client));
                            }
                          },
                          onLongPress: () => controller.toggleAccountSelection(client.id),
                          onInfoTap: () => Get.to(() => CollectionAccountInformationScreen(client: client)),
                          onClaimTap: () {
                            controller.claimAccount(client.id);
                            Get.snackbar(
                              'Account Claimed',
                              'All invoices for ${client.name} moved to Activity.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: BColors.success,
                              colorText: BColors.white,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    ));
  }
}
