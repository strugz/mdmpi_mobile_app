import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/utils/role_resolver.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_text_form_field.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_captured_signature_image.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/details/b_label_value.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_view_delivered_item_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/dialogs/request_image_dialog.dart';

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
    final UserController userController = Get.find();
    final roles = RoleResolver.parseRoles(userController.user.value.role);
    // Release role is the only one with action capability for Pick Up
    final hasReleaseRole = RoleResolver.hasRole(roles, BTexts.roleRelease);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// -- For Item Packed status (capture proof of packing) - Release role only --
        if (requestModel.status == BTexts.statusItemPacked &&
            hasReleaseRole) ...[
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

        /// -- Release Details (only show when receivedBy is filled) --
        if (requestModel.receivedBy.isNotEmpty) ...[
          const SizedBox(height: BSizes.md),
          const BTextDivider(text: 'Release Details'),
          const SizedBox(height: BSizes.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BLabelValue(
                      label: 'Received By',
                      value: requestModel.receivedBy,
                      signature: CapturedSignatureImage(requestId: requestModel.id),
                      signatureWidth: 120,
                      signatureHeight: 60,
                    ),
                  ],
                ),
              ),
              if (requestModel.itemPreparedEndAt.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BLabelValue(
                        label: 'Picked Up At',
                        value: BFormatter.formatDateWithAmPm(requestModel.itemPreparedEndAt),
                        valueTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // View Proof button (same behavior as BDeliveryDetailsSection)
          const SizedBox(height: BSizes.sm),
          ViewDeliveredItemButton(
            textColor: textColor,
            labelTitle: 'View Proof',
            onPressed: () {
              showRequestImageDialog(
                context,
                requestId: requestModel.id,
                fetchIfMissing: true,
                semanticsLabel: 'Pick Up item image for request ${requestModel.id}',
                apiController: 'RequestPickUp',
                title: 'Proof of Pick Up',
              );
            },
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
