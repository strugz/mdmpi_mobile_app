import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';

/// Provincial delivery section: captures client contact name and optional remarks.
/// Shown when status is "Provincial In Transit" and user has Provincial role.
class AirSeaProvincialDeliverySection extends StatelessWidget {
  const AirSeaProvincialDeliverySection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AirSeaController>();
    final formState = controller.formState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BSizes.spaceBtwItems),
        Text(
          'Provincial Delivery',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: BSizes.spaceBtwItems),
        TextFormField(
          controller: formState.provincialDeliveredToController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Iconsax.user),
            labelText: 'Delivered To (Client Contact)',
          ),
        ),
        const SizedBox(height: BSizes.spaceBtwItems),
        TextFormField(
          controller: formState.provincialRemarksController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Iconsax.note),
            labelText: 'Remarks (optional)',
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}

