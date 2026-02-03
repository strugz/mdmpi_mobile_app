import 'dart:io';

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
import '../../../../../base/utils/local_storage/text_storage_service.dart';
import '../../../../../common/controllers/camera_controller.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';
import '../../../../personalization/controller/user_controller.dart';
import '../../../controllers/standard_delivery_controller.dart';
import '../../../controllers/request_transport_controller.dart';

class BRequestDetails extends StatelessWidget {
  const BRequestDetails({
    super.key,
    required this.requestController,
    required this.requestTransportController,
    required this.userController,
  });

  final StandardDeliveryController requestController;
  final RequestTransportController requestTransportController;
  final UserController userController;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;
    final iconColor = dark ? BColors.light : BColors.black;
    final cameraController = Get.find<CameraHandlerController>();
    final textStorage = TextStorageService();

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
            fontColor: textColor,
          ),
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
                    Center(
                      child: Column(
                        children: [
                          IconButton(
                            onPressed: () => Get.to(
                              () => BDropOffCapture(
                                title: 'Proof Picture',
                                onCapture: (camera) async =>
                                    camera.takePictureWithAnimation(
                                  requestController
                                      .currentSelectedRequest.value!.id,
                                ),
                              ),
                            ),
                            icon: Icon(Iconsax.camera,
                                size: 25, color: iconColor),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: BProductTitleText(
                                  title: textStorage
                                          .getText('proofImagePath') ??
                                      cameraController.imageProofPath.value ??
                                      'No image captured',
                                  maxLines: 1,
                                  smallSize: true,
                                  fontColor: textColor,
                                ),
                              ),
                              if ((textStorage.getText('proofImagePath') ??
                                          cameraController.imageProofPath.value)
                                      .isNotEmpty ??
                                  false)
                                Listener(
                                  onPointerDown: (_) {
                                    final imagePath = textStorage
                                            .getText('proofImagePath') ??
                                        cameraController.imageProofPath.value;
                                    if (imagePath != null &&
                                        imagePath.isNotEmpty) {
                                      _showImagePreview(context, imagePath);
                                    }
                                  },
                                  onPointerUp: (_) {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Icon(Iconsax.eye,
                                      color: iconColor, size: 24),
                                ),
                            ],
                          ),
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
                      onPressed: () =>
                          BFullScreenLoader.showRequestTransportSignatureDialog(
                        context,
                        requestController,
                      ),
                      icon: Icon(
                        requestController
                                    .formState.receiverSignatureBytes.value ==
                                null
                            ? Iconsax.edit
                            : Iconsax.document_upload,
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
                    if (requestController
                            .formState.receiverSignatureBytes.value !=
                        null)
                      Padding(
                        padding: const EdgeInsets.only(top: BSizes.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Captured Signature:',
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: BSizes.xs),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: BColors.grey),
                              ),
                              child: Image.memory(
                                requestController
                                    .formState.receiverSignatureBytes.value!,
                              ),
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

  /// Show image preview overlay for the captured proof image
  /// Displays while holding and closes when you release your finger
  void _showImagePreview(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: Listener(
            onPointerUp: (_) {
              Navigator.pop(dialogContext);
            },
            child: Dialog(
              insetPadding: const EdgeInsets.all(0),
              backgroundColor: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  AppBar(
                    automaticallyImplyLeading: false,
                    centerTitle: true,
                  ),
                  Expanded(
                    child: InteractiveViewer(
                      panEnabled: true,
                      boundaryMargin: const EdgeInsets.all(20.0),
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported,
                                    size: 50, color: BColors.grey),
                                const SizedBox(height: BSizes.sm),
                                const Text('Failed to load image'),
                                const SizedBox(height: BSizes.xs),
                                Text(
                                  imagePath,
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
