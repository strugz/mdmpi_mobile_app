import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_text_form_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_view_delivered_item_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_captured_signature_image.dart';

import '../../../../../common/widgets/dialogs/request_image_dialog.dart';

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
                onPressed: () =>
                    BFullScreenLoader.showSignatureDialogForAirSea(
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
                    await camera.takePictureWithAnimation('${requestModel.id}_provincial_delivery');
                    formState.cameraDropOffPicture.value =
                        camera.imageProofPath.value;
                  },
                ),
              ),
              icon: const Icon(Iconsax.camera),
              label: const Text('Capture Delivery Proof'),
            ),
          ),
          Obx(
            () => _ProofPreview(
              localPath: formState.cameraDropOffPicture.value,
              emptyMessage: 'No delivery proof captured yet',
            ),
          ),
        ]
        else ...[
          if (requestModel.provincialReceiverName.isNotEmpty)
            BLabelValueText(
              label: 'Recipient Name',
              value: requestModel.provincialReceiverName,
              showLabel: true,
              icon: Iconsax.user,
              padding: EdgeInsets.zero,
              mainAlignment: MainAxisAlignment.start,
            ),
          if (requestModel.provincialDeliveredEndAt != null)
            BLabelValueText(
              label: 'Delivered At',
              value: BFormatter.formatDateWithAmPm(
                requestModel.provincialDeliveredEndAt!.toIso8601String(),
              ),
              showLabel: true,
              icon: Iconsax.calendar_1,
              padding: EdgeInsets.zero,
              mainAlignment: MainAxisAlignment.start,
            ),
          if (requestModel.provincialDeliveredLocation.isNotEmpty)
            BLabelValueText(
              label: 'Delivered Location',
              value: requestModel.provincialDeliveredLocation,
              showLabel: true,
              icon: Iconsax.location,
              padding: EdgeInsets.zero,
              mainAlignment: MainAxisAlignment.start,
            ),
          const SizedBox(height: BSizes.sm),
          Text(
            'Recipient Signature',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: BSizes.xs),
          CapturedSignatureImage(requestId: '${requestModel.id}_provincial_delivery'),
          const SizedBox(height: BSizes.sm),
          Obx(() {
            final localPath = formState.cameraDropOffPicture.value;
            if (localPath.isNotEmpty) {
              return _ProofPreview(
                localPath: localPath,
                emptyMessage: 'Delivery proof unavailable',
              );
            }

            return ViewDeliveredItemButton(
              textColor: Theme.of(context).textTheme.bodyLarge?.color ??
                  Theme.of(context).colorScheme.onSurface,
              labelTitle: 'View Delivery Proof',
              onPressed: () {
                showRequestImageDialog(
                  context,
                  requestId: requestModel.id,
                  fetchIfMissing: true,
                  semanticsLabel:
                      'Provincial delivery proof image for request ${'${requestModel.id}_provincial_delivery'}',
                  apiController: 'RequestAirSea',
                  title: 'Provincial Delivery Proof',
                );
              },
            );
          }),
        ],
      ],
    );
  }
}

class _ProofPreview extends StatelessWidget {
  const _ProofPreview({
    required this.localPath,
    required this.emptyMessage,
  });

  final String localPath;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (localPath.trim().isEmpty) {
      return Text(
        emptyMessage,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(BSizes.sm),
          child: Image.file(
            File(localPath),
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 100,
              width: double.infinity,
              alignment: Alignment.center,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Iconsax.gallery_slash),
            ),
          ),
        ),
        const SizedBox(height: BSizes.xs),
        Text(
          localPath,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

