import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Provincial pick-up section: shows logged-in user as receiver.
/// The proof image is handled by the existing image upload flow in the data manager.
/// Shown when status is "Received" or "Drop Off" and user has Provincial role.
class AirSeaProvincialPickUpSection extends StatelessWidget {
  const AirSeaProvincialPickUpSection({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    final userName = userController.user.value.initial;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BSizes.spaceBtwItems),
        Text(
          'Provincial Pick Up',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: BSizes.spaceBtwItems),
        BLabelValueText(
          label: 'Receiver',
          value: userName,
          showLabel: true,
          icon: Iconsax.user,
          padding: EdgeInsets.zero,
          mainAlignment: MainAxisAlignment.start,
        ),
        const SizedBox(height: BSizes.sm),
        Text(
          'A proof image will be captured upon confirmation.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
      ],
    );
  }
}
