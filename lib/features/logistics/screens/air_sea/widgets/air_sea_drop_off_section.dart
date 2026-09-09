import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_text_form_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_hd_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart';

/// Widget for handling Drop Off status with 4 required fields:
/// 1. Proof Image (camera capture)
/// 2. ReceivedBy Name (text input)
/// 3. Receiver Signature (digital signature)
/// 4. DropOffAt Timestamp (auto-captured)
class AirSeaDropOffSection extends StatelessWidget {
  const AirSeaDropOffSection({super.key, required this.requestModel});

  final AirSeaModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;
    final iconColor = dark ? BColors.light : BColors.black;
    final controller = AirSeaControllers.forRequest(requestModel);
    final cameraController = Get.find<CameraHandlerController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BSizes.sm),
        const BTextDivider(text: 'Drop Off Confirmation'),
        const SizedBox(height: BSizes.sm),

        /// FIELD 1: Proof of Drop Off Image Capture
        Obx(
          () => Center(
            child: Column(
              children: [
                IconButton(
                  onPressed: () => Get.to(
                    () => BDropOffCapture(
                      title: 'Proof of Drop Off',
                      onCapture: (camera) async =>
                          camera.takePictureWithAnimation(requestModel.id),
                    ),
                  ),
                  icon: Icon(Iconsax.camera, size: 25, color: iconColor),
                ),
                BProductTitleText(
                  title: cameraController.imageProofPath.value.isEmpty
                      ? 'No image captured'
                      : cameraController.imageProofPath.value,
                  maxLines: 1,
                  smallSize: true,
                  fontColor: textColor,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: BSizes.spaceBtwItems),

        /// FIELD 2: Receiver Name Field
        BTextFormField(
          controller: controller.formState.receivedByController,
          label: 'Received By',
          prefixIcon: Iconsax.user,
          keyboardType: TextInputType.text,
        ),

        const SizedBox(height: BSizes.spaceBtwItems),

        /// FIELD 3: Signature Capture Button with Preview
        Center(
          child: Obx(() {
            final sig = controller.formState.receiverSignatureBytes.value;
            final hasSignature = sig != null && sig.isNotEmpty;

            return Column(
              children: [
                TextButton.icon(
                  onPressed: () =>
                      BFullScreenLoader.showSignatureDialogForAirSea(
                    context,
                    controller,
                  ),
                  icon: Icon(
                    hasSignature ? Iconsax.document_upload : Iconsax.edit,
                    color: textColor,
                  ),
                  label: Text(
                    hasSignature
                        ? 'Signature Captured (Tap to Redo)'
                        : 'Capture Signature',
                    style: TextStyle(color: textColor),
                  ),
                ),

                /// Signature Preview
                if (hasSignature) ...[
                  const SizedBox(height: BSizes.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: BSizes.defaultSpace),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Captured Signature:',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: BSizes.xs),
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: BColors.grey),
                            borderRadius: BorderRadius.circular(BSizes.xs),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(BSizes.xs),
                            child: Image.memory(
                              sig,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }),
        ),

        /// FIELD 4: DropOffAt Timestamp (Auto-captured, no UI needed)
        /// This is handled automatically by air_sea_data_manager.dart
      ],
    );
  }
}

