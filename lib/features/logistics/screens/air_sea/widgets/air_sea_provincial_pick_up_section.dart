import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/popups/image_preview_dialog.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_view_delivered_item_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';
import '../../../../../common/widgets/dialogs/request_image_dialog.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';

/// Provincial pick-up section for the Air/Sea staged provincial flow.
///
/// When [isEditable] is true, this renders the required pick-up proof capture
/// inputs. Otherwise it shows a compact readonly summary of the completed stage.
class AirSeaProvincialPickUpSection extends StatelessWidget {
  const AirSeaProvincialPickUpSection({
    super.key,
    required this.requestModel,
    required this.isEditable,
  });

  final AirSeaModel requestModel;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AirSeaController>();
    final dark = BHelperFunctions.isDarkMode(context);
    final formState = controller.formState;
    final textColor = dark ? BColors.light : BColors.black;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BTextDivider(text: 'Provincial Pick Up'),
        if (isEditable) ...[
          Center(
            child: TextButton.icon(
              onPressed: () => Get.to(
                () => BDropOffCapture(
                  title: 'Provincial Pick Up Proof',
                  onCapture: (camera) async {
                    await camera.takePictureWithAnimation(
                        '${requestModel.id}_provincial_pick_up');
                    formState.cameraPickUpPicture.value =
                        camera.imageProofPath.value;
                  },
                ),
              ),
              icon: const Icon(Iconsax.camera),
              label: const Text('Capture Pick Up Proof'),
            ),
          ),
          Obx(() {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: BProductTitleText(
                    title: formState.cameraPickUpPicture.value,
                    maxLines: 1,
                    smallSize: true,
                    fontColor: textColor,
                  ),
                ),
                if (formState.cameraPickUpPicture.value.isNotEmpty)
                  Listener(
                    onPointerDown: (_) {
                      if (formState.cameraPickUpPicture.value.isNotEmpty) {
                        ImagePreviewDialog.show(
                            context, formState.cameraPickUpPicture.value);
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
          if (requestModel.provincialPickUpBy.isNotEmpty)
            BLabelValueText(
              label: 'Picked Up By',
              value: requestModel.provincialPickUpBy,
              showLabel: true,
              icon: Iconsax.user,
              padding: EdgeInsets.zero,
              mainAlignment: MainAxisAlignment.start,
            ),
          if (requestModel.provincialPickUpAt.isNotEmpty)
            BLabelValueText(
              label: 'Picked Up At',
              value: BFormatter.formatDateWithAmPm(
                requestModel.provincialPickUpAt,
              ),
              showLabel: true,
              icon: Iconsax.calendar_1,
              padding: EdgeInsets.zero,
              mainAlignment: MainAxisAlignment.start,
            ),
          const SizedBox(height: BSizes.xs),
          ViewDeliveredItemButton(
            textColor: Theme.of(context).textTheme.bodyLarge?.color ??
                Theme.of(context).colorScheme.onSurface,
            labelTitle: 'View Pick Up Proof',
            onPressed: () {
              showRequestImageDialog(context,
                  requestId: requestModel.id,
                  semanticsLabel:
                  'Provincial pick up proof image for request ${requestModel.id}',
                  apiController: 'RequestAirSea',
                  title: 'Provincial Pick Up Proof',
                  type: 'Provincial_PickUp_Proof');
            },
          ),
        ],
      ],
    );
  }
}

