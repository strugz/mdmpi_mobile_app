import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/inputs/range_selector.dart';

class BucketFilterModal extends StatelessWidget {
  const BucketFilterModal({super.key, this.clientId});

  final String? clientId; // when provided, compute slider max from this account's invoices

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionActivityController>();
    
    // Fixed slider limit to allow consistent customization across the app
    const double sliderMax = 1000000.0; // ₱1,000,000 hard cap

    // Fixed snapping step requested: ₱5,000
    const double step = 5000.0;
    final divisions = (sliderMax / step).round();

    RangeValues initialRange = RangeValues(
      controller.bucketMinAmount.value > 0 ? controller.bucketMinAmount.value : 0.0,
      controller.bucketMaxAmount.value > 0 ? controller.bucketMaxAmount.value : sliderMax,
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
                  'Filter Bucket',
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

            StatefulBuilder(builder: (context, setState) {
              RangeValues localRange = initialRange;

              void openPreciseDialog() {
                final minCtrl = TextEditingController(text: localRange.start.round().toString());
                final maxCtrl = TextEditingController(text: localRange.end.round().toString());
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Enter exact amounts'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(prefixText: '₱ ', labelText: 'Min'),
                        ),
                        const SizedBox(height: BSizes.sm),
                        TextField(
                          controller: maxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(prefixText: '₱ ', labelText: 'Max'),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () {
                          final newMin = double.tryParse(minCtrl.text) ?? localRange.start;
                          final newMax = double.tryParse(maxCtrl.text) ?? localRange.end;
                          final clampedMin = newMin.clamp(0.0, sliderMax);
                          final clampedMax = newMax.clamp(0.0, sliderMax);
                          setState(() => localRange = RangeValues(clampedMin, clampedMax));
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RangeSelector(
                    min: 0.0,
                    max: sliderMax,
                    values: localRange,
                    divisions: divisions > 0 ? divisions : null,
                    onChanged: (v) {
                      setState(() => localRange = v);
                    },
                    onChangeEnd: (v) {
                      controller.bucketMinAmount.value = v.start;
                      controller.bucketMaxAmount.value = v.end;
                    },
                  ),
                  const SizedBox(height: BSizes.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: openPreciseDialog,
                        icon: const Icon(Icons.edit),
                        tooltip: 'Enter exact amounts',
                      ),
                    ],
                  ),
                  const SizedBox(height: BSizes.spaceBtwItems),
                ],
              );
            }),

            const SizedBox(height: BSizes.spaceBtwSections),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.bucketMinAmount.value = 0.0;
                      controller.bucketMaxAmount.value = 0.0;
                      controller.bucketMinInvoices.value = 0;
                      controller.bucketMaxInvoices.value = 0;
                      Get.back();
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: BSizes.spaceBtwItems),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Values already written in onChangeEnd; just close
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
