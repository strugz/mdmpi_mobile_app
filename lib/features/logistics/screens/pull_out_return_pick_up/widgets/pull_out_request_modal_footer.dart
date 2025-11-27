import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_text_form_field.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart';

import '../../../../../../base/utils/constants/colors.dart';
import '../../../../../../base/utils/constants/sizes.dart';
import '../../../../../../common/widgets/texts/product_title_text.dart';
import '../../../../../base/utils/constants/text_string.dart';
import '../../../../../base/utils/popups/full_screen_loader.dart';
import '../../../../../common/controllers/camera_controller.dart';
import '../../../controllers/pull_out_controller.dart';
import '../../../models/pull_out_model.dart';

class PullOutRequestModalFooter extends StatelessWidget {
  const PullOutRequestModalFooter({super.key, required this.requestModel});

  final PullOutModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;
    final iconColor = dark ? BColors.light : BColors.black;

    final cameraController = Get.find<CameraHandlerController>();

    final PullOutController requestController = Get.find();

    final hasDriver = requestModel.driver.isNotEmpty;
    final hasHelper = requestModel.helper.isNotEmpty;
    final hasDeparted = requestModel.pullOutDateStartAt.isNotEmpty;
    final hasPullOut = requestModel.pullOutDateEndAt.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// -- For Out Transit --
        if (requestModel.requestStatus == BTexts.statusInTransit) ...[
          const BTextDivider(text: 'Proof of Pull out'),
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
          BTextFormField(
            controller: requestController.formState.releasedByController,
            label: 'Released By',
            keyboardType: TextInputType.text,
          ),
          Center(
            child: TextButton.icon(
              // Use Obx to rebuild if signature changes
              onPressed: () => BFullScreenLoader.showSignatureDialogForPullOut(
                  context, requestController),
              icon: Icon(
                requestController.formState.receiverSignatureBytes.value == null
                    ? Iconsax.edit // Or another icon for "add signature"
                    : Iconsax
                        .document_upload, // Or an icon for "view/change signature"
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
          if (requestController.formState.receiverSignatureBytes.value != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: BSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Captured Signature:",
                      style: TextStyle(
                          color: textColor, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: BSizes.xs),
                    Container(
                      height: 200, // Adjust as needed
                      decoration: BoxDecoration(
                        border: Border.all(color: BColors.grey),
                      ),
                      child: Image.memory(requestController
                          .formState.receiverSignatureBytes.value!),
                    ),
                  ],
                ),
              ),
            ),
        ],
        if (hasDriver || hasHelper) ...[
          BTextDivider(text: 'Delivery details'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasDriver)
                BProductTitleText(
                  title: 'Driver: ${requestModel.driver}',
                  maxLines: 2,
                  smallSize: true,
                  fontColor: dark ? BColors.light : BColors.black,
                ),
              if (hasHelper)
                BProductTitleText(
                  title: 'Helper: ${requestModel.helper}',
                  maxLines: 2,
                  smallSize: true,
                  fontColor: dark ? BColors.light : BColors.black,
                ),
            ],
          ),
          if (hasDeparted)
            BProductTitleText(
              title: 'Departed At: ${BFormatter.formatDateTimeCustomizable(
                requestModel.pullOutDateStartAt,
                "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                "yyyy-MM-dd HH:mm",
              )}',
              maxLines: 1,
              smallSize: true,
              fontColor: dark ? BColors.light : BColors.black,
            ),
          const SizedBox(height: BSizes.xs),
          if (hasPullOut)
            BProductTitleText(
              title: 'Pull Out At: ${BFormatter.formatDateTimeCustomizable(
                requestModel.pullOutDateEndAt,
                "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                "yyyy-MM-dd HH:mm",
              )}',
              maxLines: 1,
              smallSize: true,
              fontColor: dark ? BColors.light : BColors.black,
            ),
          const SizedBox(height: BSizes.xs),
        ],
      ],
    );
  }
}
