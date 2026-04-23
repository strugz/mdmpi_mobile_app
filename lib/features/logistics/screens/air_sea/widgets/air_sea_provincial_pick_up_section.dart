import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_view_delivered_item_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart';

import '../../../../../common/widgets/dialogs/request_image_dialog.dart';

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
    final formState = controller.formState;

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
          Obx(
            () => _ProofPreview(
              localPath: formState.cameraPickUpPicture.value,
              emptyMessage: 'No pick-up proof captured yet',
            ),
          ),
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
          if (requestModel.provincialPickUpAt != null)
            BLabelValueText(
              label: 'Picked Up At',
              value: BFormatter.formatDateWithAmPm(
                requestModel.provincialPickUpAt!.toIso8601String(),
              ),
              showLabel: true,
              icon: Iconsax.calendar_1,
              padding: EdgeInsets.zero,
              mainAlignment: MainAxisAlignment.start,
            ),
          const SizedBox(height: BSizes.xs),
          Obx(() {
            final localPath = formState.cameraPickUpPicture.value;
            if (localPath.isNotEmpty) {
              return _ProofPreview(
                localPath: localPath,
                emptyMessage: 'Pick-up proof unavailable',
              );
            }

            return ViewDeliveredItemButton(
              textColor: Theme.of(context).textTheme.bodyLarge?.color ??
                  Theme.of(context).colorScheme.onSurface,
              labelTitle: 'View Pick Up Proof',
              onPressed: () {
                showRequestImageDialog(
                  context,
                  requestId: '${requestModel.id}_provincial_pick_up',
                  fetchIfMissing: true,
                  semanticsLabel:
                      'Provincial pick up proof image for request ${requestModel.id}',
                  apiController: 'RequestAirSea',
                  title: 'Provincial Pick Up Proof',
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
