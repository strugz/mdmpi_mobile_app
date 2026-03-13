import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';

/// UI-only scanner widget. Delegates camera/file picking and analysis to
/// `StandardDeliveryController` (methods: pickAndAnalyzeFromCamera, pickAndAnalyzeFromFile).
class BItemScanner extends StatelessWidget {
  const BItemScanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StandardDeliveryController>();
    final dark = BHelperFunctions.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action row — controller handles picking + analysis
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => controller.pickAndAnalyzeFromCamera(),
                icon: const Icon(Iconsax.camera),
                label: const Text('Capture'),
              ),
            ),
            const SizedBox(width: BSizes.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => controller.pickAndAnalyzeFromFile(),
                icon: const Icon(Iconsax.document_upload),
                label: const Text('Attach File'),
              ),
            ),
          ],
        ),

        const SizedBox(height: BSizes.spaceBtwItems),

        // Loading
        Obx(() {
          if (controller.isAnalyzingFile.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: BSizes.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        }),

        // Error text
        Obx(() {
          final err = controller.analyzeError.value;
          if (err != null && err.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(bottom: BSizes.sm),
              child: Text(
                err,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.red),
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        // Scanned items
        Obx(() {
          final List<InventoryItemModel> items =
              controller.formState.scannedInventoryItems;
          if (items.isEmpty && !controller.isAnalyzingFile.value) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scanned Items (${items.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (items.isNotEmpty)
                    TextButton.icon(
                      onPressed: controller.clearScannedItems,
                      icon: const Icon(Iconsax.trash, size: 16),
                      label: const Text('Clear'),
                    ),
                ],
              ),
              const SizedBox(height: BSizes.xs),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: BSizes.xs),
                itemBuilder: (ctx, index) {
                  final item = items[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BSizes.sm,
                      vertical: BSizes.sm,
                    ),
                    decoration: BoxDecoration(
                      color: dark
                          ? BColors.darkerGrey.withOpacity(0.18)
                          : BColors.light,
                      borderRadius: BorderRadius.circular(BSizes.cardRadiusSm),
                      border: Border.all(
                        color: dark ? BColors.darkerGrey : BColors.grey,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemCode,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.description,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Qty: ${item.qty % 1 == 0 ? item.qty.toInt() : item.qty}  •  ${item.unit}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          dark ? BColors.light : BColors.darkGrey,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => controller.removeScannedItem(index),
                          icon: Icon(
                            Iconsax.close_circle,
                            size: 20,
                            color: dark ? BColors.light : BColors.darkGrey,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
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

