import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_text_form_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/scanner/b_single_field_scanner.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_hd_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';

/// Widget for handling waybill input when status is "Endorsed to Guard".
///
/// Displays a text input field for entering the waybill/tracking number
/// with OCR scanning capability.
class AirSeaWaybillInputSection extends StatelessWidget {
  const AirSeaWaybillInputSection({super.key, required this.requestModel});

  final AirSeaModel requestModel;

  @override
  Widget build(BuildContext context) {
    final controller = AirSeaControllers.forRequest(requestModel);
    final dark = BHelperFunctions.isDarkMode(context);

    // Initialize waybill field with existing value if available
    if (requestModel.waybillNumber.isNotEmpty &&
        controller.formState.waybillNumberController.text.isEmpty) {
      controller.formState.waybillNumberController.text =
          requestModel.waybillNumber;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BSizes.sm),
        const BTextDivider(text: 'Waybill Information'),
        const SizedBox(height: BSizes.sm),

        /// Waybill Number Field with Scanner Button
        Row(
          children: [
            // Text field - allows both manual typing and scanning
            Expanded(
              child: BTextFormField(
                controller: controller.formState.waybillNumberController,
                label: 'Waybill/Tracking Number',
                prefixIcon: Iconsax.clipboard_text,
              ),
            ),
            const SizedBox(width: BSizes.sm),

            // Scan/Clear button
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller.formState.waybillNumberController,
              builder: (context, value, child) {
                final hasValue = value.text.isNotEmpty;

                return IconButton(
                  onPressed: () {
                    if (hasValue) {
                      // Clear the field
                      controller.formState.waybillNumberController.clear();
                    } else {
                      // Open scanner
                      Get.to(() => BSingleFieldScanner(
                            controller: controller.formState.waybillNumberController,
                            title: 'Scan Waybill Number',
                          ));
                    }
                  },
                  icon: Icon(
                    hasValue ? Iconsax.close_circle : Iconsax.scan_barcode,
                    color: dark ? BColors.light : BColors.primary,
                  ),
                  tooltip: hasValue ? 'Clear' : 'Scan',
                );
              },
            ),
          ],
        ),
        const SizedBox(height: BSizes.spaceBtwItems),
      ],
    );
  }
}

