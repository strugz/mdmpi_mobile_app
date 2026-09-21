import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/collection_account_information_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/account_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/collection_search_filter_bar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/collection_work_header.dart';
import 'activity_account_invoices_screen.dart';
import 'widgets/activity_filter_sheet.dart';
import 'widgets/quick_filter_bar.dart';
import 'widgets/engagement_summary.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

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
      body: SingleChildScrollView(
        child: Obx(() {
          final accounts = controller.activityAccounts;

          return Column(
            children: [
              const CollectionWorkHeader(title: 'Field Engagement'),

              /// Search and Filter Bar
              Obx(() => CollectionSearchFilterBar(
                    searchHint: 'Search accounts',
                    initialValue: controller.activitySearchQuery.value,
                    onSearchChanged: (value) =>
                        controller.activitySearchQuery.value = value,
                    hasActiveFilter: controller.hasActiveActivityFilter,
                    onFilterTap: () => _openFilter(context, controller),
                  )),

              // The filters reached for every morning, one tap each. Also
              // shows anything set in the sheet that has no preset here.
              Obx(() => QuickFilterBar(
                    filter: controller.activityFilterSpec.value,
                    areas: controller.activityAreas,
                    onChanged: (f) => controller.activityFilterSpec.value = f,
                  )),

              if (accounts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(BSizes.defaultSpace,
                      BSizes.defaultSpace, BSizes.defaultSpace, 0),
                  child: Builder(builder: (context) {
                    final summary = controller.activitySummary;
                    return EngagementSummary(
                      accounts: summary.accounts,
                      invoices: summary.invoices,
                      overdue: summary.overdue,
                      due: summary.due,
                      collected: summary.collected,
                    );
                  }),
                ),

              accounts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              (controller.activitySearchQuery.value.isEmpty &&
                                      !controller.hasActiveActivityFilter)
                                  ? Iconsax.activity
                                  : Iconsax.search_status,
                              size: 64,
                              color: BCollectionColors.inkMuted,
                            ),
                            const SizedBox(height: BSizes.spaceBtwItems),
                            Text(
                              controller.activitySearchQuery.value.isEmpty &&
                                      !controller.hasActiveActivityFilter
                                  ? 'No field engagements yet'
                                  : 'No accounts match your criteria',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: BCollectionColors.inkMuted,
                                  ),
                            ),
                            const SizedBox(height: BSizes.xs),
                            if (controller
                                    .activitySearchQuery.value.isNotEmpty ||
                                controller.hasActiveActivityFilter)
                              TextButton(
                                onPressed: () {
                                  controller.clearActivityFilters();
                                  controller.activitySearchQuery.value = '';
                                },
                                child: const Text('Clear all filters'),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: BSizes.lg),
                                child: Text(
                                  'Select items from the Collection Bucket\nto start your field engagement.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: BCollectionColors.inkMuted),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(BSizes.defaultSpace),
                      itemCount: accounts.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: BSizes.spaceBtwItems),
                      itemBuilder: (context, index) {
                        final client = accounts[index];
                        return AccountCard(
                          client: client,
                          invoiceCount: controller
                              .getActivityAccountInvoiceCount(client.id),
                          totalAmount:
                              controller.getActivityAccountTotalDue(client.id),
                          // The engagement's own collected figure. This read
                          // the app-wide one, so a card could report money
                          // taken against invoices that are not in this
                          // engagement at all.
                          totalCollected: controller
                              .getActivityAccountTotalCollected(client.id),
                          overdueCount: controller
                              .getActivityAccountOverdueCount(client.id),
                          onTap: () => Get.to(() =>
                              CollectionActivityAccountInvoicesScreen(
                                  client: client)),
                          onInfoTap: () => Get.to(() =>
                              CollectionAccountInformationScreen(
                                  client: client)),
                        );
                      },
                    ),
            ],
          );
        }),
      ),
    );
  }

  static Future<void> _openFilter(
      BuildContext context, CollectionActivityController controller) async {
    final chosen = await ActivityFilterSheet.show(
      context,
      initial: controller.activityFilterSpec.value,
      count: controller.countActivityAccounts,
      areas: controller.activityAreas,
    );
    if (chosen != null) controller.activityFilterSpec.value = chosen;
  }
}
