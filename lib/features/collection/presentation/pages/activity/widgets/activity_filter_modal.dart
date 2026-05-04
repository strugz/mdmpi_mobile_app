import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

class ActivityFilterModal extends StatelessWidget {
  const ActivityFilterModal({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionActivityController>();
    
    final minAmountController = TextEditingController(
      text: controller.activityMinAmount.value > 0 ? controller.activityMinAmount.value.toStringAsFixed(0) : '',
    );
    final maxAmountController = TextEditingController(
      text: controller.activityMaxAmount.value > 0 ? controller.activityMaxAmount.value.toStringAsFixed(0) : '',
    );
    final minInvoiceController = TextEditingController(
      text: controller.activityMinInvoices.value > 0 ? controller.activityMinInvoices.value.toString() : '',
    );
    final maxInvoiceController = TextEditingController(
      text: controller.activityMaxInvoices.value > 0 ? controller.activityMaxInvoices.value.toString() : '',
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: BSizes.defaultSpace,
        right: BSizes.defaultSpace,
        top: BSizes.defaultSpace,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Activity',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: BSizes.spaceBtwSections),
            
            Text('Total Amount Due Range', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: BSizes.xs),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Min',
                      prefixText: '₱ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('-'),
                ),
                Expanded(
                  child: TextField(
                    controller: maxAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Max',
                      prefixText: '₱ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BSizes.spaceBtwItems),
            
            Text('Number of Invoices Range', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: BSizes.xs),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minInvoiceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Min',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('-'),
                ),
                Expanded(
                  child: TextField(
                    controller: maxInvoiceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Max',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BSizes.spaceBtwSections),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.activityMinAmount.value = 0.0;
                      controller.activityMaxAmount.value = 0.0;
                      controller.activityMinInvoices.value = 0;
                      controller.activityMaxInvoices.value = 0;
                      Get.back();
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: BSizes.spaceBtwItems),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      controller.activityMinAmount.value = double.tryParse(minAmountController.text) ?? 0.0;
                      controller.activityMaxAmount.value = double.tryParse(maxAmountController.text) ?? 0.0;
                      controller.activityMinInvoices.value = int.tryParse(minInvoiceController.text) ?? 0;
                      controller.activityMaxInvoices.value = int.tryParse(maxInvoiceController.text) ?? 0;
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: BColors.primary),
                    child: const Text('Apply Filter'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BSizes.defaultSpace),
          ],
        ),
      ),
    );
  }
}
