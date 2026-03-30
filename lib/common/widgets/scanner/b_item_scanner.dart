import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';

import 'scanned_item_tile.dart';
import 'scanner_actions.dart';

/// UI-only scanner widget. Delegates camera/file picking and analysis to a
/// controller. By default it resolves `StandardDeliveryController` via
/// `Get.find<StandardDeliveryController>()`.
///
/// The widget accepts an optional, named `controller` parameter so callers can
/// provide any controller instance that exposes the minimal API used by this
/// widget (duck-typed):
///  - `formState.scannedInventoryItems` -> RxList<InventoryItemModel>
///  - `RxBool isAnalyzingFile` (or similar) to show analyzing indicator
///  - `void clearScannedItems()` method
///
/// Example usages:
///   // Use default StandardDeliveryController (must be registered)
///   const BItemScanner();
///
///   // Provide an explicit controller instance (runtime)
///   BItemScanner(controller: stdDeliveryController)
class BItemScanner extends StatelessWidget {
  /// Optional controller instance. If omitted the widget will attempt to
  /// resolve `StandardDeliveryController` from GetX.
  ///
  /// Type is dynamic to allow duck-typing across different controllers that
  /// expose the minimal API required by this widget.
  final dynamic controller;

  const BItemScanner({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    // Resolve controller: prefer provided instance, otherwise fallback to the
    // app's StandardDeliveryController. The null-check + fallback placeholder
    // is intentional and mandatory to avoid runtime crashes when the expected
    // controller is not registered.
    dynamic ctl = controller;
    if (ctl == null) {
      try {
        ctl = Get.find<StandardDeliveryController>();
      } catch (e) {
        // Mandatory defensive UI: show placeholder instead of throwing.
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: BSizes.md),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.scan, size: 48, color: Colors.grey),
                const SizedBox(height: BSizes.sm),
                Text(
                  'Scanner not available',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: BSizes.xs),
                Text(
                  'Provide a controller via `controller:` or register StandardDeliveryController.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
    }

    final dark = BHelperFunctions.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // NOTE: ScannerActionRow is intentionally NOT rendered here when
        // BItemScanner is embedded inside a full-screen parent. Parent
        // widgets (e.g., ScannedItemsScreen) should place
        // `ScannerActionRow(controller: ctl)` above this widget so the
        // capture/attach actions are not duplicated.

        // Observed scanned items, loading and errors
        Obx(() {
          // Duck-typed access — controller must expose `formState.scannedInventoryItems`
          final List<InventoryItemModel> items =
              ctl.formState.scannedInventoryItems;
          final bool analyzing = ctl.isAnalyzingFile?.value ?? false;

          if (items.isEmpty && !analyzing) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loading indicator while analyzing file (if provided by controller)
              if (analyzing) const AnalyzingIndicator(),
              const SizedBox(height: BSizes.xs),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: BSizes.xs),
                itemBuilder: (ctx, index) {
                  final item = items[index];
                  return ScannedItemTile(
                    item: item,
                    index: index,
                    controller: ctl,
                    parentContext: ctx,
                    dark: dark,
                  );
                },
              ),
            ],
          );
        }),
      ],
    );
  }
}
