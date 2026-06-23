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
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
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

  void _showUnclaimWithReasonDialog() {
    final reasons = [
      CollectionStatusColors.statusFollowUp,
      CollectionStatusColors.statusUnavailable,
      CollectionStatusColors.statusRefused,
      CollectionStatusColors.statusOthers,
    ];

    final RxString selectedReason = CollectionStatusColors.statusFollowUp.obs;
    final othersController = TextEditingController();

    Get.defaultDialog(
      title: 'Unclaim Account',
      content: Obx(() => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: Get.height * 0.5),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select reason for no collection:', textAlign: TextAlign.center),
              const SizedBox(height: BSizes.md),
              ...reasons.map((reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: selectedReason.value,
                onChanged: (val) => selectedReason.value = val!,
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
              if (selectedReason.value == CollectionStatusColors.statusOthers)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: BSizes.md),
                  child: TextField(
                    controller: othersController,
                    decoration: const InputDecoration(hintText: 'Enter custom reason...'),
                    maxLines: 2,
                  ),
                ),
            ],
          ),
        ),
      )),
      textConfirm: 'Confirm',
      textCancel: 'Cancel',
      confirmTextColor: BColors.white,
      buttonColor: BColors.error,
      onConfirm: () {
        final rawReason = selectedReason.value;
        final customRemark = othersController.text.trim();
        
        if (rawReason == CollectionStatusColors.statusOthers && customRemark.isEmpty) {
          Get.snackbar('Required', 'Please enter a reason', backgroundColor: BColors.warning);
          return;
        }

        final status = rawReason == CollectionStatusColors.statusOthers ? 'Others' : rawReason;
        final remarks = rawReason == CollectionStatusColors.statusOthers 
            ? customRemark 
            : 'No collection done: $rawReason';

        controller.unclaimWithReason(widget.client.id, status, remarks);
        
        Get.back(); // Close dialog
        Get.back(); // Return to Activity list
        
        Get.snackbar(
          'Account Unclaimed', 
          '${widget.client.name} moved back to bucket.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: BColors.success,
          colorText: Colors.white,
        );
      },
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
            /// Action Buttons
            if (!controller.isActivitySelectionMode.value)
              Padding(
                padding: const EdgeInsets.fromLTRB(BSizes.defaultSpace, BSizes.defaultSpace, BSizes.defaultSpace, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showUnclaimWithReasonDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BColors.error,
                          side: const BorderSide(color: BColors.error),
                        ),
                        child: const Text('No Collection'),
                      ),
                    ),
                    const SizedBox(width: BSizes.spaceBtwItems),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          controller.unclaimAccount(widget.client.id);
                          Get.back();
                          Get.snackbar(
                            'Success',
                            'Collection marked as done for ${widget.client.name}',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.blue,
                            colorText: Colors.white,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                        child: const Text('Done Collection'),
                      ),
                    ),
                  ],
                ),
              ),

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
                              showDragHandle: false,
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
