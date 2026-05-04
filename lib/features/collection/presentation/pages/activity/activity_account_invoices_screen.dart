import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/collection_search_filter_bar.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'activity_detail_screen.dart';
import 'widgets/activity_filter_modal.dart';
import 'widgets/activity_list_tile.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client.name),
      ),
      body: Obx(() {
        final invoices = controller.getActivityInvoicesByAccount(widget.client.id);

        return Column(
          children: [
            /// Search and Filter Bar
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
                onFilterTap: () => Get.bottomSheet(
                  const ActivityFilterModal(),
                  backgroundColor: BColors.white,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(BSizes.borderRadiusLg)),
                  ),
                ),
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
                        return ActivityListTile(
                          item: item,
                          onTap: () => Get.to(() => ActivityDetailScreen(item: item)),
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
