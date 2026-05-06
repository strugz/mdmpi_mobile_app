import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/collection_account_information_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/account_item_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/collection_search_filter_bar.dart';
import 'activity_account_invoices_screen.dart';
import 'widgets/activity_filter_modal.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/side_filter_drawer.dart';

/// Collection Activity Screen
///
/// Shows accounts that have invoices claimed by the user.
/// Items appear here after being selected in the bucket screen.
class CollectionActivityScreen extends StatelessWidget {
  const CollectionActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionActivityController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Activity',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        final accounts = controller.activityAccounts;

        return Column(
          children: [
            /// Search and Filter Bar
            Obx(() {
              final hasFilter = controller.activityMinAmount.value > 0 || 
                               controller.activityMaxAmount.value > 0 ||
                               controller.activityMinInvoices.value > 0 ||
                               controller.activityMaxInvoices.value > 0;
              
               return CollectionSearchFilterBar(
                searchHint: 'Search by account name...',
                initialValue: controller.activitySearchQuery.value,
                onSearchChanged: (value) => controller.activitySearchQuery.value = value,
                hasActiveFilter: hasFilter,
                onFilterTap: () => showSideFilter(ActivityFilterModal()),
              );
            }),

            Expanded(
              child: accounts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            (controller.activitySearchQuery.value.isEmpty && 
                             controller.activityMinAmount.value == 0 && 
                             controller.activityMinInvoices.value == 0)
                                ? Iconsax.activity
                                : Iconsax.search_status,
                            size: 64,
                            color: BColors.darkGrey,
                          ),
                          const SizedBox(height: BSizes.spaceBtwItems),
                          Text(
                            controller.activitySearchQuery.value.isEmpty && 
                             controller.activityMinAmount.value == 0 && 
                             controller.activityMinInvoices.value == 0
                                ? 'No activities yet'
                                : 'No accounts match your criteria',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: BColors.darkGrey,
                                ),
                          ),
                          const SizedBox(height: BSizes.xs),
                          if (controller.activitySearchQuery.value.isNotEmpty || 
                              controller.activityMinAmount.value > 0 || 
                              controller.activityMinInvoices.value > 0)
                            TextButton(
                              onPressed: () {
                                controller.activityMinAmount.value = 0;
                                controller.activityMaxAmount.value = 0;
                                controller.activityMinInvoices.value = 0;
                                controller.activityMaxInvoices.value = 0;
                                controller.activitySearchQuery.value = '';
                              },
                              child: const Text('Clear all filters'),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: BSizes.lg),
                              child: Text(
                                'Select items from the Collection Bucket\nto start your activity.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: BColors.darkGrey),
                              ),
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
                          invoiceCount: controller.getActivityAccountInvoiceCount(client.id),
                          totalAmount: controller.getActivityAccountTotalDue(client.id),
                          onTap: () => Get.to(() => CollectionActivityAccountInvoicesScreen(client: client)),
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
