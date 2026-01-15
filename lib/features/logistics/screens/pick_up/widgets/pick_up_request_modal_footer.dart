import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_text_form_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';

import '../../../../../base/utils/formatters/formatters.dart';

class PickUpRequestModalFooter extends StatelessWidget {
  const PickUpRequestModalFooter({super.key, required this.requestModel});

  final PickUpModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;
    final iconColor = dark ? BColors.light : BColors.black;

    final cameraController = Get.find<CameraHandlerController>();
    final PickUpController requestController = Get.find();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// -- For Item Packed status (capture proof of packing) --
        if (requestModel.status == BTexts.statusItemPacked) ...[
          const BTextDivider(text: 'Proof of Picked Up'),
          Obx(
            () => Center(
              child: Column(
                children: [
                  IconButton(
                    onPressed: () => Get.to(
                      () => BDropOffCapture(
                        title: 'Proof Picture',
                        onCapture: (camera) async =>
                            camera.takePictureWithAnimation(
                          requestModel.id,
                        ),
                      ),
                    ),
                    icon: Icon(Iconsax.camera, size: 25, color: iconColor),
                  ),
                  BProductTitleText(
                    title: cameraController.imageProofPath.value,
                    maxLines: 1,
                    smallSize: true,
                    fontColor: textColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BSizes.sm),
          BTextFormField(
            controller: requestController.formState.receivedByController,
            label: 'Received By',
            keyboardType: TextInputType.text,
          ),
          Center(
            child: TextButton.icon(
              onPressed: () => BFullScreenLoader.showSignatureDialogForPickUp(
                  context, requestController),
              icon: Icon(
                requestController.formState.receiverSignatureBytes.value == null
                    ? Iconsax.edit
                    : Iconsax.document_upload,
                color: textColor,
              ),
              label: Text(
                requestController.formState.receiverSignatureBytes.value == null
                    ? 'Capture Signature'
                    : 'Signature Captured (Tap to Redo)',
                style: TextStyle(color: textColor),
              ),
            ),
          ),
        ],
        /// -- Remarks --
        if (requestModel.remarks.isNotEmpty) ...[
          const SizedBox(height: BSizes.sm),
          const BTextDivider(text: 'Remarks'),
          BProductTitleText(
            title: requestModel.remarks,
            maxLines: 3,
            smallSize: true,
            fontColor: textColor,
          ),
        ],
      ],
    );
  }
}
