import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/collection_search_filter_bar.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'activity_detail_screen.dart';
import 'batch_activity_detail_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/invoice_card.dart';
import 'widgets/activity_filter_modal.dart';
import 'widgets/defer_reason_sheet.dart';
import 'widgets/invoice_details_modal.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/side_filter_drawer.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

class CollectionActivityAccountInvoicesScreen extends StatefulWidget {
  final ClientModel client;

  const CollectionActivityAccountInvoicesScreen(
      {super.key, required this.client});

  @override
  State<CollectionActivityAccountInvoicesScreen> createState() =>
      _CollectionActivityAccountInvoicesScreenState();
}

class _CollectionActivityAccountInvoicesScreenState
    extends State<CollectionActivityAccountInvoicesScreen> {
  final controller = Get.find<CollectionActivityController>();

  @override
  void dispose() {
    controller.invoiceSearchQuery.value = ''; // Reset search on leave
    controller.exitActivitySelectionMode(); // Exit selection on leave
    super.dispose();
  }

  Future<void> _showUnclaimWithReasonDialog() async {
    final reason = await DeferReasonSheet.show(
      context,
      accountName: widget.client.name,
    );
    if (reason == null || !mounted) return;

    controller.unclaimWithReason(
        widget.client.id, reason.status, reason.remarks);

    Get.back(); // Return to Activity list

    BLoaders.successSnackBar(
      title: 'Account Released',
      message: '${widget.client.name} moved back to bucket.',
    );
  }

  void _clearEngagement() {
    controller.unclaimAccount(widget.client.id);
    Get.back();
    BLoaders.successSnackBar(
      title: 'Engagement cleared',
      message: '${widget.client.name} is no longer assigned to you.',
    );
  }

  /// Closing out the account: both actions release it, so neither is
  /// destructive and neither earns a saturated fill. They used to be two
  /// filled buttons (red and raw Material blue) sitting above the invoices,
  /// louder than the work itself and competing for primacy. Clearing is the
  /// common path, so it leads; deferring is the exception and sits quiet
  /// beside it. Hidden while selecting, where batch recording is the job.
  Widget? _bottomBar() {
    if (controller.isActivitySelectionMode.value) {
      if (controller.selectedActivityInvoiceIds.length < 2) return null;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          child: ElevatedButton.icon(
            onPressed: () {
              final selectedItems = controller.activityItems
                  .where((item) =>
                      controller.selectedActivityInvoiceIds.contains(item.id))
                  .toList();
              Get.to(() => BatchActivityDetailScreen(items: selectedItems));
            },
            icon: const Icon(Iconsax.layer),
            label: Text(
                'Batch Record ${controller.selectedActivityInvoiceIds.length} Invoices'),
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
      );
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
    );

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace,
          BSizes.spaceBtwItemsLight,
          BSizes.defaultSpace,
          BSizes.spaceBtwItemsLight,
        ),
        decoration: const BoxDecoration(
          color: BColors.white,
          border: Border(top: BorderSide(color: BColors.grey)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _showUnclaimWithReasonDialog,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: shape,
                  foregroundColor: BColors.darkerGrey,
                  side: const BorderSide(color: BColors.borderSecondary),
                ),
                child: const Text('Defer', maxLines: 1),
              ),
            ),
            const SizedBox(width: BSizes.spaceBtwItemsLight),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _clearEngagement,
                icon: const Icon(Iconsax.tick_circle, size: 18),
                label: const Text('Clear Engagement', maxLines: 1),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: shape,
                  elevation: 0,
                  backgroundColor: BColors.primary,
                  foregroundColor: BColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          appBar: AppBar(
            leading: controller.isActivitySelectionMode.value
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => controller.exitActivitySelectionMode(),
                  )
                : null,
            title: Text(
              controller.isActivitySelectionMode.value
                  ? '${controller.selectedActivityInvoiceIds.length} Selected'
                  : widget.client.name,
            ),
            actions: [
              if (controller.isActivitySelectionMode.value)
                TextButton(
                  onPressed: () {
                    final invoices = controller
                        .getActivityInvoicesByAccount(widget.client.id);
                    if (controller.selectedActivityInvoiceIds.length ==
                        invoices.length) {
                      controller.selectedActivityInvoiceIds.clear();
                      controller.isActivitySelectionMode.value = false;
                    } else {
                      controller.selectedActivityInvoiceIds
                          .addAll(invoices.map((e) => e.id));
                    }
                  },
                  child: Text(
                    controller.selectedActivityInvoiceIds.length ==
                            controller
                                .getActivityInvoicesByAccount(widget.client.id)
                                .length
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(color: BColors.primary),
                  ),
                ),
            ],
          ),
          // One bottom bar holding the primary action for the current mode:
          // batch recording while selecting, closing the account out otherwise.
          bottomNavigationBar: _bottomBar(),
          body: Obx(() {
            final invoices =
                controller.getActivityInvoicesByAccount(widget.client.id);

            return Column(
              children: [
                /// Search and Filter Bar
                if (!controller.isActivitySelectionMode.value)
                  Obx(() {
                    final hasFilter = controller.activityMinAmount.value > 0 ||
                        controller.activityMaxAmount.value > 0 ||
                        controller.activityMinInvoices.value > 0 ||
                        controller.activityMaxInvoices.value > 0;

                    return CollectionSearchFilterBar(
                      searchHint: 'Search invoice ID or bank...',
                      initialValue: controller.invoiceSearchQuery.value,
                      onSearchChanged: (value) =>
                          controller.invoiceSearchQuery.value = value,
                      hasActiveFilter: hasFilter,
                      onFilterTap: () => showSideFilter(
                          ActivityFilterModal(clientId: widget.client.id)),
                    );
                  }),

                Expanded(
                  child: invoices.isEmpty
                      ? Center(
                          child: Text(
                            controller.invoiceSearchQuery.value.isEmpty
                                ? 'No claimed invoices for this account.'
                                : 'No invoices match your search.',
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(BSizes.defaultSpace),
                          itemCount: invoices.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: BSizes.spaceBtwItems),
                          itemBuilder: (context, index) {
                            final item = invoices[index];
                            final isSelected = controller
                                .selectedActivityInvoiceIds
                                .contains(item.id);

                            return InvoiceCard(
                              item: item,
                              isSelected: isSelected,
                              isSelectionMode:
                                  controller.isActivitySelectionMode.value,
                              onTap: () {
                                if (controller.isActivitySelectionMode.value) {
                                  controller
                                      .toggleActivityInvoiceSelection(item.id);
                                } else {
                                  Get.to(
                                      () => ActivityDetailScreen(item: item));
                                }
                              },
                              onLongPress: () => controller
                                  .toggleActivityInvoiceSelection(item.id),
                              onInfoTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  showDragHandle: false,
                                  backgroundColor: Colors.transparent,
                                  builder: (sheetContext) => Padding(
                                    padding: EdgeInsets.only(
                                        bottom:
                                            MediaQuery.paddingOf(sheetContext)
                                                .bottom),
                                    child: InvoiceDetailsModal(item: item),
                                  ),
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
