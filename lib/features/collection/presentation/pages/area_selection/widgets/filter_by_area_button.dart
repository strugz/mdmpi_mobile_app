import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/area_selection/area_selection_screen.dart';

class BFilterByAreaButton extends StatelessWidget {
  const BFilterByAreaButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
      child: Obx(() {
        final area = controller.selectedArea.value;
        final hasFilter = area.isNotEmpty;

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Get.to(
              () => AreaSelectionScreen(
                title: 'Filter',
                isFilterMode: true,
              ),
              transition: Transition.cupertino,
            ),
            icon: Icon(
              Iconsax.map,
              size: 18,
              color: hasFilter ? BColors.primary : BColors.darkGrey,
            ),
            label: Text(
              hasFilter ? 'Filter by Area: $area' : 'Filter by Area',
              style: TextStyle(
                color: hasFilter ? BColors.primary : BColors.darkGrey,
                fontWeight: hasFilter ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: BSizes.md),
              side: BorderSide(
                color: hasFilter ? BColors.primary : BColors.grey,
                width: hasFilter ? 1.5 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
              ),
            ),
          ),
        );
      }),
    );
  }
}
