import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/account_item_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/bucket_filter_modal.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/side_filter_drawer.dart';
import 'collection_account_information_screen.dart';
import 'widgets/collection_search_filter_bar.dart';

import 'package:mdmpi_mobile_app/features/collection/presentation/pages/area_selection/widgets/filter_by_area_button.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

/// Collection Bucket Screen (Account-Centric)
///
/// Displays unique accounts in the bucket.
/// Multi-select accounts with long press.
class CollectionBucketScreen extends StatelessWidget {
  const CollectionBucketScreen({super.key});

  /// Shared by every state change on this screen (filter bar collapse, list ↔
  /// empty swap) so the whole surface moves at one tempo.
  static const Duration _stateDuration = Duration(milliseconds: 200);

  void _acquireSelected(CollectionActivityController controller) {
    final count = controller.selectedAccountIds.length;
    controller.claimSelectedAccounts();
    BLoaders.successSnackBar(
      title: 'Accounts Acquired',
      message:
          '$count account${count == 1 ? '' : 's'} moved to Field Engagement.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionActivityController>();

    return Obx(() => Scaffold(
      appBar: AppBar(
        leading: controller.isSelectionMode.value
            ? IconButton(
                tooltip: 'Exit selection',
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
              tooltip: 'Acquire selected',
              icon: const Icon(Iconsax.tick_circle),
              onPressed: controller.selectedAccountIds.isEmpty
                  ? null
                  : () => _acquireSelected(controller),
            )
          else
            IconButton(
              tooltip: 'Add to bucket',
              icon: const Icon(Iconsax.add_circle),
              onPressed: () => Get.toNamed(BRoutes.addToBucket),
            ),
        ],
      ),
      bottomNavigationBar: controller.isSelectionMode.value
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(BSizes.defaultSpace),
                child: ElevatedButton.icon(
                  onPressed: controller.selectedAccountIds.isEmpty
                      ? null
                      : () => _acquireSelected(controller),
                  icon: const Icon(Iconsax.tick_circle),
                  label: Text(
                    'Acquire ${controller.selectedAccountIds.length} '
                    'Account${controller.selectedAccountIds.length == 1 ? '' : 's'}',
                  ),
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
        final selectionMode = controller.isSelectionMode.value;

        return Column(
          children: [
            /// Search and Filter Bar. Collapses (rather than vanishing) when
            /// entering selection mode so the list slides up instead of jumping.
            AnimatedSize(
              duration: _stateDuration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: selectionMode
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      children: [
                        Obx(() {
                          final hasFilter = controller.bucketMinAmount.value > 0 ||
                              controller.bucketMaxAmount.value > 0 ||
                              controller.bucketMinInvoices.value > 0 ||
                              controller.bucketMaxInvoices.value > 0;

                          return CollectionSearchFilterBar(
                            searchHint: 'Search by account name…',
                            initialValue: controller.bucketSearchQuery.value,
                            onSearchChanged: (value) => controller.bucketSearchQuery.value = value,
                            hasActiveFilter: hasFilter,
                            onFilterTap: () => showSideFilter(BucketFilterModal()),
                          );
                        }),
                        const BFilterByAreaButton(),
                        const SizedBox(height: BSizes.spaceBtwItems),
                      ],
                    ),
            ),

            Expanded(
              // Cross-fade between the list and the empty state so a filter
              // that empties the list doesn't hard-cut to a different layout.
              child: AnimatedSwitcher(
                duration: _stateDuration,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: accounts.isEmpty
                    ? _BucketEmptyState(
                        key: const ValueKey('empty'),
                        filtered: controller.hasActiveBucketFilter,
                        onClearFilters: controller.clearBucketFilters,
                        onAddAccount: () => Get.toNamed(BRoutes.addToBucket),
                      )
                    : ListView.separated(
                        key: const ValueKey('list'),
                        padding: const EdgeInsets.all(BSizes.defaultSpace),
                        itemCount: accounts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: BSizes.spaceBtwItems),
                        itemBuilder: (context, index) {
                          final client = accounts[index];
                          final isSelected = controller.selectedAccountIds.contains(client.id);

                          return AccountItemCard(
                            client: client,
                            invoiceCount: controller.getAccountInvoiceCount(client.id),
                            totalAmount: controller.getAccountTotalDue(client.id),
                            totalCollected: controller.getAccountTotalCollected(client.id),
                            isSelected: isSelected,
                            isSelectionMode: selectionMode,
                            onTap: () {
                              if (controller.isSelectionMode.value) {
                                controller.toggleAccountSelection(client.id);
                              } else {
                                Get.to(() => CollectionAccountInformationScreen(client: client));
                              }
                            },
                            onLongPress: () => controller.toggleAccountSelection(client.id),
                            onInfoTap: () =>
                                Get.to(() => CollectionAccountInformationScreen(client: client)),
                            onClaimTap: () {
                              controller.claimAccount(client.id);
                              BLoaders.successSnackBar(
                                title: 'Account Acquired',
                                message:
                                    'All invoices for ${client.name} moved to Field Engagement.',
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      }),
    ));
  }
}

/// Empty bucket / no-match state.
///
/// Copy and action depend on *why* it is empty: an empty bucket offers a way to
/// add an account; an over-filtered bucket offers to clear the filters. Enters
/// with a short fade + 8px rise (nothing appears from nowhere).
class _BucketEmptyState extends StatelessWidget {
  const _BucketEmptyState({
    super.key,
    required this.filtered,
    required this.onClearFilters,
    required this.onAddAccount,
  });

  final bool filtered;
  final VoidCallback onClearFilters;
  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BColors.primary.withValues(alpha: 0.06),
                ),
                alignment: Alignment.center,
                child: Icon(
                  filtered ? Iconsax.search_status : Icons.shopping_basket_rounded,
                  size: 40,
                  color: BColors.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text(
                filtered ? 'No accounts match your filters' : 'Your bucket is empty',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: BColors.darkerGrey,
                ),
              ),
              const SizedBox(height: BSizes.xs),
              Text(
                filtered
                    ? 'Try a different name, amount range, or area.'
                    : 'Download a bucket from Home, or add an account to get started.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: BColors.darkGrey),
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              if (filtered)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Iconsax.close_circle, size: 18),
                  label: const Text('Clear all filters'),
                )
              else
                OutlinedButton.icon(
                  onPressed: onAddAccount,
                  icon: const Icon(Iconsax.add_circle, size: 18),
                  label: const Text('Add an account'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
