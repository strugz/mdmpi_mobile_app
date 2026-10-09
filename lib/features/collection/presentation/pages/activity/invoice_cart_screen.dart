import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

import 'activity_detail_screen.dart';
import 'batch_activity_detail_screen.dart';

/// The cart for one account (meeting of 2026-10-07, item 1): the invoices
/// picked by hand or added from Scanned Invoices, checked over before one
/// record; those from a voucher are marked. Check out opens the batch record (one
/// invoice: its own record); the cart empties once the batch is saved.
class InvoiceCartScreen extends StatefulWidget {
  const InvoiceCartScreen({super.key, required this.client, this.onScan});

  final ClientModel client;

  /// Scans another voucher; null where there is no camera.
  final Future<void> Function()? onScan;

  @override
  State<InvoiceCartScreen> createState() => _InvoiceCartScreenState();
}

class _InvoiceCartScreenState extends State<InvoiceCartScreen> {
  final controller = Get.find<CollectionActivityController>();
  Worker? _emptied;

  @override
  void initState() {
    super.initState();
    // Nothing left to review: back to the list.
    _emptied = ever(controller.selectedActivityInvoiceIds, (_) {
      if (mounted && controller.cartItems(widget.client.id).isEmpty) {
        Get.back();
      }
    });
  }

  @override
  void dispose() {
    _emptied?.dispose();
    super.dispose();
  }

  Future<void> _checkOut(List<CollectionItemModel> items) async {
    // Replaces this screen, so the record's own back lands on the list.
    if (items.length == 1) {
      // The single record does not end carting the way a batch save does;
      // its screen closing does.
      await Get.off(() => ActivityDetailScreen(item: items.single));
      controller.exitActivitySelectionMode();
    } else {
      Get.off(() => BatchActivityDetailScreen(items: items));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Invoice'),
        actions: [
          if (widget.onScan != null)
            IconButton(
              key: const ValueKey('cart-scan-again'),
              tooltip: 'Scan another voucher',
              icon: const Icon(Iconsax.scan),
              onPressed: widget.onScan,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
              BSizes.defaultSpace,
              BSizes.spaceBtwItemsLight,
              BSizes.defaultSpace,
              BSizes.spaceBtwItemsLight),
          decoration: const BoxDecoration(
            color: BCollectionColors.surface,
            border: Border(top: BorderSide(color: BCollectionColors.outline)),
          ),
          child: Obx(() {
            final items = controller.cartItems(widget.client.id);
            return ElevatedButton.icon(
              key: const ValueKey('cart-checkout'),
              onPressed: items.isEmpty ? null : () => _checkOut(items),
              icon: const Icon(Iconsax.layer, size: 18),
              label: Text(items.length == 1
                  ? 'Record 1 invoice'
                  : 'Record ${items.length} invoices'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: BCollectionColors.primary,
                foregroundColor: BCollectionColors.surface,
              ),
            );
          }),
        ),
      ),
      body: Obx(() {
        final items = controller.cartItems(widget.client.id);
        final total = controller.cartTotal(widget.client.id);
        final fromVoucher = controller.voucherInvoiceIds;
        return ListView(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          children: [
            Text(widget.client.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(
                '${items.length} invoice${items.length == 1 ? '' : 's'} · '
                '${BFormatter.formatPesoCurrency(total)} to collect',
                key: const ValueKey('cart-summary'),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: BCollectionColors.inkSecondary)),
            const SizedBox(height: BSizes.spaceBtwItems),
            for (final item in items)
              Card(
                margin: const EdgeInsets.only(bottom: BSizes.sm),
                child: ListTile(
                  key: ValueKey('cart-item-${item.id}'),
                  title: Text(item.id),
                  subtitle: Text([
                    if (item.dueDate.trim().isNotEmpty &&
                        item.dueDate.trim() != 'N/A')
                      'Due ${BFormatter.formatDate3(item.dueDate)}',
                    if (fromVoucher.contains(item.id)) 'from voucher',
                  ].join(' · ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(BFormatter.formatPesoCurrency(item.toBeCollected),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      IconButton(
                        key: ValueKey('cart-remove-${item.id}'),
                        tooltip: 'Remove from cart',
                        icon: const Icon(Iconsax.close_circle, size: 20),
                        onPressed: () => controller.removeFromCart(item.id),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
