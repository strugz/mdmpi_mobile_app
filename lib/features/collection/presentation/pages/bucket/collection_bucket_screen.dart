import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'collection_account_invoices_screen.dart';
import 'collection_account_information_screen.dart';
import 'widgets/account_item_card.dart';
import 'widgets/bucket_filter_modal.dart';

/// Collection Bucket Screen (Account-Centric)
///
/// Displays unique accounts in the bucket. Tapping an account
/// navigates to [CollectionAccountScreen] to see specific invoices.
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
        final accounts = controller.bucketAccounts;

        return Column(
          children: [
            /// Search and Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BSizes.defaultSpace,
                vertical: BSizes.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      onChanged: (value) => controller.bucketSearchQuery.value = value,
                      decoration: const InputDecoration(
                        hintText: 'Search by account name...',
                        prefixIcon: Icon(Iconsax.search_normal),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: BSizes.sm),
                  
                  // Filter Button
                  Obx(() {
                    final hasFilter = controller.bucketMinAmount.value > 0 || 
                                     controller.bucketMaxAmount.value > 0 ||
                                     controller.bucketMinInvoices.value > 0 ||
                                     controller.bucketMaxInvoices.value > 0;
                    return Container(
                      decoration: BoxDecoration(
                        color: hasFilter ? BColors.primary.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                        border: Border.all(color: hasFilter ? BColors.primary : BColors.grey),
                      ),
                      child: IconButton(
                        onPressed: () => Get.bottomSheet(
                          const BucketFilterModal(),
                          backgroundColor: BColors.white,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(BSizes.borderRadiusLg)),
                          ),
                        ),
                        icon: Icon(
                          Iconsax.filter_edit,
                          color: hasFilter ? BColors.primary : BColors.darkerGrey,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

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
                        return AccountItemCard(
                          client: client,
                          invoiceCount: controller.getAccountInvoiceCount(client.id),
                          totalAmount: controller.getAccountTotalDue(client.id),
                          onTap: () => Get.to(() => CollectionAccountInvoicesScreen(client: client)),
                          onInfoTap: () => Get.to(() => CollectionAccountInformationScreen(client: client)),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}



