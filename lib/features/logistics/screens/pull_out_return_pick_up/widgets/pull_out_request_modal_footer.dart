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
        /// -- Proof of Pull out (for In Transit status) --
        if (requestModel.requestStatus == BTexts.statusInTransit) ...[
          const SizedBox(height: BSizes.md),
          const BTextDivider(text: 'Proof of Pull out'),
          const SizedBox(height: BSizes.sm),
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
                  if (cameraController.imageProofPath.value.isNotEmpty)
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
          const SizedBox(height: BSizes.spaceBtwItems),
          BTextFormField(
            controller: requestController.formState.releasedByController,
            label: 'Released By',
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: BSizes.sm),
          Center(
            child: TextButton.icon(
              onPressed: () => BFullScreenLoader.showSignatureDialogForPullOut(
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
                      height: 200,
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

        /// -- Delivery Details (when driver/helper/dates are available) --
        if (hasDriver || hasHelper || hasDeparted || hasPullOut) ...[
          const SizedBox(height: BSizes.md),
          const BTextDivider(text: 'Delivery Details'),
          const SizedBox(height: BSizes.sm),
          if (hasDriver || hasHelper)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (hasDriver)
                  Expanded(
                    child: BProductTitleText(
                      title: 'Driver: ${requestModel.driver}',
                      maxLines: 2,
                      smallSize: true,
                      fontColor: textColor,
                    ),
                  ),
                if (hasDriver && hasHelper) const SizedBox(width: BSizes.xs),
                if (hasHelper)
                  Expanded(
                    child: BProductTitleText(
                      title: 'Helper: ${requestModel.helper}',
                      maxLines: 2,
                      smallSize: true,
                      fontColor: textColor,
                    ),
                  ),
              ],
            ),
          if (hasDeparted) ...[
            const SizedBox(height: BSizes.sm),
            BProductTitleText(
              title: 'Departed At: ${BFormatter.formatDateTimeCustomizable(
                requestModel.pullOutDateStartAt,
                "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                "yyyy-MM-dd HH:mm",
              )}',
              maxLines: 1,
              smallSize: true,
              fontColor: textColor,
            ),
          ],
          if (hasPullOut) ...[
            const SizedBox(height: BSizes.sm),
            BProductTitleText(
              title: 'Pull Out At: ${BFormatter.formatDateTimeCustomizable(
                requestModel.pullOutDateEndAt,
                "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                "yyyy-MM-dd HH:mm",
              )}',
              maxLines: 1,
              smallSize: true,
              fontColor: textColor,
            ),
          ],
        ],
      ],
    );
  }
}
