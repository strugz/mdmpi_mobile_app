import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/invoice_card.dart';
import 'widgets/collection_search_filter_bar.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_filter_sheet.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_filter_bar.dart';
import 'package:mdmpi_mobile_app/features/collection/models/activity_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/po_grouping.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/po_invoice_group_card.dart';

class CollectionAccountInvoicesScreen extends StatefulWidget {
  final ClientModel client;

  const CollectionAccountInvoicesScreen({super.key, required this.client});

  @override
  State<CollectionAccountInvoicesScreen> createState() =>
      _CollectionAccountInvoicesScreenState();
}

class _CollectionAccountInvoicesScreenState
    extends State<CollectionAccountInvoicesScreen> {
  final controller = Get.find<CollectionActivityController>();

  /// P.O. groups the collector has opened or closed by hand, by group key.
  /// Anything not here follows the default: closed when the account spans
  /// several P.O.s, open when there is only one or a search is narrowing the
  /// list (a match hidden inside a closed group is a match nobody sees).
  final Map<String, bool> _expandedOverrides = {};

  bool _isExpanded(PoGrouping grouping, PoInvoiceGroup group) {
    final override = _expandedOverrides[group.key];
    if (override != null) return override;
    return grouping.groups.length == 1 ||
        controller.invoiceSearchQuery.value.isNotEmpty;
  }

  void _toggle(PoGrouping grouping, PoInvoiceGroup group) {
    setState(() {
      _expandedOverrides[group.key] = !_isExpanded(grouping, group);
    });
  }

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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                controller.claimAccount(widget.client.id);
                Get.back();
                BLoaders.successSnackBar(
                  title: 'Account Claimed',
                  message:
                      'All invoices for ${widget.client.name} have been moved to Activity.',
                );
              },
              icon: const Icon(Iconsax.tick_circle),
              label: const Text('Claim Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BCollectionColors.primary,
                foregroundColor: BCollectionColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        final invoices = controller.getInvoicesByAccount(widget.client.id);
        final grouping = PoGrouping.of(invoices);

        return Column(
          children: [
            /// Search and Filter Bar
            Obx(() => CollectionSearchFilterBar(
                  searchHint: 'Search invoice or bank',
                  initialValue: controller.invoiceSearchQuery.value,
                  onSearchChanged: (value) =>
                      controller.invoiceSearchQuery.value = value,
                  hasActiveFilter: controller.bucketFilterSpec.value.isActive,
                  onFilterTap: () async {
                    final chosen = await ActivityFilterSheet.show(
                      context,
                      initial: controller.bucketFilterSpec.value,
                      count: controller.countBucketAccounts,
                    );
                    if (chosen != null) {
                      controller.bucketFilterSpec.value = chosen;
                    }
                  },
                )),
            Obx(() => QuickFilterBar(
                  filter: controller.bucketFilterSpec.value,
                  defaultSort: ActivitySort.name,
                  onChanged: (f) => controller.bucketFilterSpec.value = f,
                )),

            Expanded(
              child: invoices.isEmpty
                  ? Center(
                      child: Text(
                        controller.invoiceSearchQuery.value.isEmpty
                            ? 'No invoices for this account.'
                            : 'No invoices match your search.',
                      ),
                    )
                  : grouping.hasGroups
                      ? _groupedList(grouping)
                      // No P.O. on any invoice: the flat list, unchanged.
                      : ListView.separated(
                          padding: const EdgeInsets.all(BSizes.defaultSpace),
                          itemCount: invoices.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: BSizes.spaceBtwItems),
                          itemBuilder: (context, index) =>
                              InvoiceCard(item: invoices[index]),
                        ),
            ),
          ],
        );
      }),
    );
  }

  /// One collapsible row per P.O., then the invoices that carry none under a
  /// "No P.O." rule. Built as a flat list of rows so the ListView still
  /// recycles; a group's open invoices live inside its row.
  Widget _groupedList(PoGrouping grouping) {
    final rows = <Widget>[
      for (final g in grouping.groups)
        PoInvoiceGroupCard(
          key: ValueKey('po-${g.key}'),
          group: g,
          expanded: _isExpanded(grouping, g),
          onToggle: () => _toggle(grouping, g),
        ),
      if (grouping.ungrouped.isNotEmpty) ...[
        const PoSectionLabel('No P.O.'),
        for (final inv in grouping.ungrouped) InvoiceCard(item: inv),
      ],
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(BSizes.defaultSpace),
      itemCount: rows.length,
      separatorBuilder: (_, index) =>
          // The label carries its own spacing above and below.
          rows[index] is PoSectionLabel || rows[index + 1] is PoSectionLabel
              ? const SizedBox.shrink()
              : const SizedBox(height: BSizes.spaceBtwItems),
      itemBuilder: (_, index) => rows[index],
    );
  }
}
