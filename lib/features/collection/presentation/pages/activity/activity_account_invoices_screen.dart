import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/collection_search_filter_bar.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'activity_detail_screen.dart';
import 'batch_activity_detail_screen.dart';
import 'widgets/activity_filter_modal.dart';
import 'widgets/activity_list_tile.dart';
import 'widgets/invoice_details_modal.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/side_filter_drawer.dart';
import 'package:iconsax/iconsax.dart';

class CollectionActivityAccountInvoicesScreen extends StatefulWidget {
  final ClientModel client;

  const CollectionActivityAccountInvoicesScreen({super.key, required this.client});

  @override
  State<CollectionActivityAccountInvoicesScreen> createState() => _CollectionActivityAccountInvoicesScreenState();
}

class _CollectionActivityAccountInvoicesScreenState extends State<CollectionActivityAccountInvoicesScreen> {
  final controller = Get.find<CollectionActivityController>();

  @override
  void dispose() {
    controller.invoiceSearchQuery.value = ''; // Reset search on leave
    controller.exitActivitySelectionMode();   // Exit selection on leave
    super.dispose();
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
                final invoices = controller.getActivityInvoicesByAccount(widget.client.id);
                if (controller.selectedActivityInvoiceIds.length == invoices.length) {
                  controller.selectedActivityInvoiceIds.clear();
                  controller.isActivitySelectionMode.value = false;
                } else {
                  controller.selectedActivityInvoiceIds.addAll(invoices.map((e) => e.id));
                }
              },
              child: Text(
                controller.selectedActivityInvoiceIds.length == controller.getActivityInvoicesByAccount(widget.client.id).length
                    ? 'Deselect All'
                    : 'Select All',
                style: const TextStyle(color: BColors.primary),
              ),
            )
          else
            TextButton(
              onPressed: () {
                Get.defaultDialog(
                  title: 'Unclaim Account',
                  middleText: 'Move all invoices back to the bucket?',
                  textConfirm: 'Unclaim',
                  textCancel: 'Cancel',
                  confirmTextColor: BColors.white,
                  buttonColor: BColors.error,
                  onConfirm: () {
                    controller.unclaimAccount(widget.client.id);
                    Get.back(); // Close dialog
                    Get.back(); // Return to Activity list
                  },
                );
              },
              child: const Text('Unclaim', style: TextStyle(color: BColors.error)),
            ),
        ],
      ),
      bottomNavigationBar: (controller.isActivitySelectionMode.value && controller.selectedActivityInvoiceIds.length >= 2)
        ? SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(BSizes.defaultSpace),
              child: ElevatedButton.icon(
                onPressed: () {
                  final selectedItems = controller.activityItems
                      .where((item) => controller.selectedActivityInvoiceIds.contains(item.id))
                      .toList();
                  Get.to(() => BatchActivityDetailScreen(items: selectedItems));
                },
                icon: const Icon(Iconsax.layer),
                label: Text('Batch Record ${controller.selectedActivityInvoiceIds.length} Invoices'),
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
        final invoices = controller.getActivityInvoicesByAccount(widget.client.id);

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
                  onSearchChanged: (value) => controller.invoiceSearchQuery.value = value,
                  hasActiveFilter: hasFilter,
                  onFilterTap: () => showSideFilter(ActivityFilterModal(clientId: widget.client.id)),
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
                      separatorBuilder: (_, __) => const SizedBox(height: BSizes.spaceBtwItems),
                      itemBuilder: (context, index) {
                        final item = invoices[index];
                        final isSelected = controller.selectedActivityInvoiceIds.contains(item.id);

                        return ActivityListTile(
                          item: item,
                          isSelected: isSelected,
                          isSelectionMode: controller.isActivitySelectionMode.value,
                          onTap: () {
                            if (controller.isActivitySelectionMode.value) {
                              controller.toggleActivityInvoiceSelection(item.id);
                            } else {
                              Get.to(() => ActivityDetailScreen(item: item));
                            }
                          },
                          onLongPress: () => controller.toggleActivityInvoiceSelection(item.id),
                          onInfoTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => InvoiceDetailsModal(item: item),
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
