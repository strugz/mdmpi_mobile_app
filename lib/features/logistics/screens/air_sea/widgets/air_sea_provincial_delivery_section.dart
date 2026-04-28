import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_text_form_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_delivery_details_section.dart';
import 'package:mdmpi_mobile_app/common/widgets/popups/image_preview_dialog.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart';

import '../../../../../base/utils/constants/text_string.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';

/// Provincial delivery section for the Air/Sea staged provincial flow.
///
/// When [isEditable] is true, the section collects the recipient name,
/// signature, and proof image required before the modal action confirms the
/// Provincial Delivered transition. Otherwise it renders a readonly summary.
class AirSeaProvincialDeliverySection extends StatelessWidget {
  const AirSeaProvincialDeliverySection({
    super.key,
    required this.requestModel,
    required this.isEditable,
  });

  final AirSeaModel requestModel;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AirSeaController>();
    final formState = controller.formState;
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BSizes.spaceBtwItems),
        const BTextDivider(text: 'Provincial Delivered'),
        const SizedBox(height: BSizes.sm),
        if (isEditable) ...[
          BTextFormField(
            controller: formState.provincialDeliveredToController,
            label: 'Recipient Name',
            prefixIcon: Iconsax.user,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: BSizes.spaceBtwItems),
          Center(
            child: Obx(() {
              final sig = formState.receiverSignatureBytes.value;
              final hasSignature = sig != null && sig.isNotEmpty;

              return TextButton.icon(
                onPressed: () => BFullScreenLoader.showSignatureDialogForAirSea(
                  context,
                  controller,
                ),
                icon: Icon(
                  hasSignature ? Iconsax.document_upload : Iconsax.edit,
                ),
                label: Text(
                  hasSignature
                      ? 'Signature Captured (Tap to Redo)'
                      : 'Capture Recipient Signature',
                ),
              );
            }),
          ),
          Obx(() {
            final sig = formState.receiverSignatureBytes.value;
            if (sig == null || sig.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: BColors.grey),
                borderRadius: BorderRadius.circular(BSizes.sm),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(BSizes.sm),
                child: Image.memory(sig, fit: BoxFit.contain),
              ),
            );
          }),
          const SizedBox(height: BSizes.spaceBtwItems),
          Center(
            child: TextButton.icon(
              onPressed: () => Get.to(
                () => BDropOffCapture(
                  title: 'Provincial Delivery Proof',
                  onCapture: (camera) async {
                    await camera.takePictureWithAnimation(
                        '${requestModel.id}_provincial_delivery');
                    formState.cameraDropOffPicture.value =
                        camera.imageProofPath.value;
                  },
                ),
              ),
              icon: const Icon(Iconsax.camera),
              label: const Text('Capture Delivery Proof'),
            ),
          ),
          Obx(() {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: BProductTitleText(
                    title: formState.cameraDropOffPicture.value,
                    maxLines: 1,
                    smallSize: true,
                    fontColor: textColor,
                  ),
                ),
                if (formState.cameraDropOffPicture.value.isNotEmpty)
                  Listener(
                    onPointerDown: (_) {
                      if (formState.cameraDropOffPicture.value.isNotEmpty) {
                        ImagePreviewDialog.show(
                            context, formState.cameraDropOffPicture.value);
                      }
                    },
                    onPointerUp: (_) {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: Icon(Iconsax.eye, color: textColor, size: 20),
                  )
              ],
            );
          }),
        ] else ...[
          if (requestModel.provincialReceiverName.isNotEmpty)
            BLabelValueText(
              label: 'Recipient Name',
              value: requestModel.provincialReceiverName,
              showLabel: true,
              icon: Iconsax.user,
              padding: EdgeInsets.zero,
              mainAlignment: MainAxisAlignment.start,
            ),
          if (requestModel.provincialDeliveredEndAt.isNotEmpty)
            BLabelValueText(
              label: 'Delivered At',
              value: BFormatter.formatDateWithAmPm(
                requestModel.provincialDeliveredEndAt,
              ),
              showLabel: true,
              icon: Iconsax.calendar_1,
              padding: EdgeInsets.zero,
              mainAlignment: MainAxisAlignment.start,
            ),
          const SizedBox(height: BSizes.xs),
          BDeliveryDetailsSection(
            driver: requestModel.provincialPickUpBy,
            receivedBy: requestModel.provincialReceiverName,
            receivedByLabel: 'Recipient Name',
            completedAt: BFormatter.formatDateWithAmPm(
              requestModel.provincialDeliveredEndAt,
            ),
            completedAtLabel: 'Delivered At',
            requestId: requestModel.id,
            apiController: 'RequestAirSea',
            viewItemButtonLabel: 'View Delivery Proof',
            dialogTitle: 'Provincial Delivery Proof',
            showViewItemButton:
                requestModel.status == BTexts.statusProvincialDelivered,
            imageProofType: 'Provincial_Delivery_Proof',
            signatureType: 'Provincial_Signature',
            signatureHeight: 40,
            location: requestModel.provincialDeliveredLocation,
            locationLabel: 'Delivered Location',
          ),

        ],
      ],
    );
  }
}
