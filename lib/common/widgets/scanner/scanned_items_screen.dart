import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/scanner/b_item_scanner.dart';
import 'package:mdmpi_mobile_app/common/widgets/scanner/scanner_actions.dart';

/// Full-screen view of scanned items.
///
/// - Defaults to `StandardDeliveryController` if no controller is provided.
/// - You can pass an explicit controller instance to reuse this screen with
///   other controllers: `Get.to(() => ScannedItemsScreen(controller: myCtl));`
class ScannedItemsScreen extends StatelessWidget {
  final dynamic controller;

  const ScannedItemsScreen({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    dynamic ctl;
    bool hasController = true;
    try {
      ctl = controller ?? Get.find<StandardDeliveryController>();
    } catch (e) {
      hasController = false;
      ctl = null;
    }

    if (!hasController) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scanned Items')),
        body: Padding(
          padding: const EdgeInsets.all(BSizes.md),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 56, color: Colors.grey),
                const SizedBox(height: BSizes.sm),
                Text(
                  'Scanner controller not available',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: BSizes.xs),
                Text(
                  'Provide a controller via the constructor or register StandardDeliveryController in bindings.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: BSizes.md),
                ElevatedButton(
                    onPressed: () => Get.back(), child: const Text('Back')),
              ],
            ),
          ),
        ),
      );
    }

    // dark mode is handled by child widgets when needed

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final RxList<InventoryItemModel> itemsRx =
              (ctl.formState?.scannedInventoryItems ??
                  <InventoryItemModel>[].obs) as RxList<InventoryItemModel>;
          return Text('Scanned Items (${itemsRx.length})');
        }),
        actions: [
          IconButton(
            tooltip: 'Clear items',
            onPressed: () {
              if (ctl.clearScannedItems is Function) {
                ctl.clearScannedItems();
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BSizes.md),
        child: Column(
          children: [
            // Top quick actions row (capture / attach)
            ScannerActionRow(controller: ctl),
            const SizedBox(height: BSizes.sm),

            // Embedded scanner widget (includes capture/attach actions / list)
            BItemScanner(controller: ctl),
          ],
        ),
      ),
    );
  }
}

