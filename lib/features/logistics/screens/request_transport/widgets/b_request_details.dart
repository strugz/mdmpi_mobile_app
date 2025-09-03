import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_document_reference.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../common/controllers/camera_controller.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';
import '../../../../personalization/controller/user_controller.dart';
import '../../../controllers/request_controller.dart';
import '../../../controllers/request_transport_controller.dart';

class BRequestDetails extends StatelessWidget {
  const BRequestDetails(
      {super.key,
      required this.requestController,
      required this.requestTransportController,
      required this.userController});

  final RequestController requestController;
  final RequestTransportController requestTransportController;
  final UserController userController;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;
    final iconColor = dark ? BColors.light : BColors.black;
    final cameraController = Get.find<CameraHandlerController>();
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BProductTitleText(
            title: requestController.currentSelectedRequest.value!.client.name,
            maxLines: 1,
            fontColor: textColor,
            bold: true,
          ),
          const SizedBox(height: BSizes.xs),
          BProductTitleText(
            title:
                requestController.currentSelectedRequest.value!.client.address,
            maxLines: 1,
            smallSize: true,
            fontColor: textColor,
          ),
          const SizedBox(height: BSizes.xs),
          BProductTitleText(
              title: "ETA: ${requestTransportController.eta}",
              maxLines: 2,
              smallSize: true,
              fontColor: textColor),
          const SizedBox(height: BSizes.xs),
          BDocumentReference(
              request: requestController.currentSelectedRequest.value!),
          const SizedBox(height: BSizes.md),
          if (requestController.currentSelectedRequest.value!.status ==
              BTexts.statusForDelivery)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: BSizes.xs),
              child: Obx(
                () => Column(
                  children: [
                    /// Drop Off Camera
                    Center(
                      child: Column(
                        children: [
                          IconButton(
                            onPressed: () => Get.to(
                              () => BDropOffCapture(
                                  request: requestController
                                      .currentSelectedRequest.value!,
                                  requestController: requestController),
                            ),
                            icon: Icon(Iconsax.camera,
                                size: 25, color: iconColor),
                          ),
                          BProductTitleText(
                              title: cameraController.imageProofPath.value,
                              maxLines: 1,
                              smallSize: true,
                              fontColor: textColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: BSizes.xs),
                    const Divider(),
                    const SizedBox(height: BSizes.xs),
                    TextFormField(
                      controller: requestController.formState.receiver,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.user_tick),
                        labelText: 'Receiver',
                      ),
                    ),
                    const SizedBox(height: BSizes.xs),
                    TextButton.icon(
                      // Use Obx to rebuild if signature changes
                      onPressed: () =>
                          BFullScreenLoader.showRequestTransportSignatureDialog(
                              context, requestController),
                      icon: Icon(
                        requestController
                                    .formState.receiverSignatureBytes.value ==
                                null
                            ? Iconsax
                                .edit // Or another icon for "add signature"
                            : Iconsax
                                .document_upload, // Or an icon for "view/change signature"
                        color: textColor,
                      ),
                      label: Text(
                        requestController
                                    .formState.receiverSignatureBytes.value ==
                                null
                            ? 'Capture Signature'
                            : 'Signature Captured (Tap to Redo)',
                        style: TextStyle(color: textColor),
                      ),
                    ),

                    // Optionally display the signature image if captured
                    if (requestController
                            .formState.receiverSignatureBytes.value !=
                        null)
                      Padding(
                        padding: const EdgeInsets.only(top: BSizes.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Captured Signature:",
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold),
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
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
