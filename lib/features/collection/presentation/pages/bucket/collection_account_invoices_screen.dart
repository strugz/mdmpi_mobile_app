import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'widgets/collection_search_filter_bar.dart';
import 'widgets/invoice_item_card.dart';
import 'widgets/bucket_filter_modal.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/side_filter_drawer.dart';

class CollectionAccountInvoicesScreen extends StatefulWidget {
  final ClientModel client;

  const CollectionAccountInvoicesScreen({super.key, required this.client});

  @override
  State<CollectionAccountInvoicesScreen> createState() => _CollectionAccountInvoicesScreenState();
}

class _CollectionAccountInvoicesScreenState extends State<CollectionAccountInvoicesScreen> {
  final controller = Get.find<CollectionActivityController>();
  final RxSet<String> localSelectedIds = <String>{}.obs;

  @override
  void dispose() {
    controller.invoiceSearchQuery.value = ''; // Reset search on leave
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client.name),
        actions: [
          Obx(() {
            final invoices = controller.getInvoicesByAccount(widget.client.id);
            if (invoices.isEmpty) return const SizedBox.shrink();
            
            final allSelected = localSelectedIds.length == invoices.length;
            return TextButton(
              onPressed: () {
                if (allSelected) {
                  localSelectedIds.clear();
                } else {
                  localSelectedIds.assignAll(invoices.map((e) => e.id));
                }
              },
              child: Text(
                allSelected ? 'Deselect All' : 'Select All',
                style: const TextStyle(color: BColors.primary, fontWeight: FontWeight.w600),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: Obx(() {
        if (localSelectedIds.isEmpty) return const SizedBox.shrink();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(BSizes.defaultSpace),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  final count = localSelectedIds.length;
                  controller.claimItemsByIds(localSelectedIds.toList());
                  Get.back();
                  Get.snackbar(
                    'Invoices Claimed',
                    '$count invoice${count == 1 ? '' : 's'} claimed for ${widget.client.name}.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: BColors.success,
                    colorText: BColors.white,
                  );
                },
                icon: const Icon(Iconsax.tick_circle),
                label: Text('Claim ${localSelectedIds.length} Invoices'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BColors.primary,
                  foregroundColor: BColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
      body: Obx(() {
        final invoices = controller.getInvoicesByAccount(widget.client.id);

        return Column(
          children: [
            /// Search and Filter Bar
            Obx(() {
              final hasFilter = controller.bucketMinAmount.value > 0 || 
                               controller.bucketMaxAmount.value > 0 ||
                               controller.bucketMinInvoices.value > 0 ||
                               controller.bucketMaxInvoices.value > 0;
              
               return CollectionSearchFilterBar(
                searchHint: 'Search invoice ID or bank...',
                initialValue: controller.invoiceSearchQuery.value,
                onSearchChanged: (value) => controller.invoiceSearchQuery.value = value,
                hasActiveFilter: hasFilter,
                onFilterTap: () => showSideFilter(BucketFilterModal(clientId: widget.client.id)),
              );
            }),

            Expanded(
              child: invoices.isEmpty
                  ? Center(
                      child: Text(
                        controller.invoiceSearchQuery.value.isEmpty 
                            ? 'No pending invoices for this account.'
                            : 'No invoices match your search.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(BSizes.defaultSpace),
                      itemCount: invoices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: BSizes.spaceBtwItems),
                      itemBuilder: (context, index) {
                        final item = invoices[index];
                        return Obx(() => InvoiceItemCard(
                              item: item,
                              isSelected: localSelectedIds.contains(item.id),
                              onTap: () {
                                if (localSelectedIds.contains(item.id)) {
                                  localSelectedIds.remove(item.id);
                                } else {
                                  localSelectedIds.add(item.id);
                                }
                              },
                            ));
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}
