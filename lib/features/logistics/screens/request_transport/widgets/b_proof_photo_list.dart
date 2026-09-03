import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/popups/image_preview_dialog.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart';

/// Proof-of-delivery photo capture list (up to
/// [CameraHandlerController.maxProofPhotos] photos per request).
///
/// Shows a camera button with a photo counter and one row per captured
/// photo with preview and remove actions. Shared by the Standard Delivery
/// modal footer and the request transport details screen.
class BProofPhotoList extends StatefulWidget {
  const BProofPhotoList({
    super.key,
    required this.requestId,
    required this.iconColor,
    required this.textColor,
  });

  final String requestId;
  final Color iconColor;
  final Color textColor;

  @override
  State<BProofPhotoList> createState() => _BProofPhotoListState();
}

class _BProofPhotoListState extends State<BProofPhotoList> {
  late final CameraHandlerController cameraController;

  @override
  void initState() {
    super.initState();
    cameraController = Get.find<CameraHandlerController>();
    cameraController.syncProofPhotos(widget.requestId);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final photos = cameraController.imageProofPaths.toList();
      final atLimit = photos.length >= CameraHandlerController.maxProofPhotos;

      return Center(
        child: Column(
          children: [
            IconButton(
              onPressed: atLimit
                  ? null
                  : () => Get.to(
                        () => BDropOffCapture(
                          title: 'Proof Picture',
                          onConfirmPath: (camera, imagePath) async =>
                              camera.addProofPictureFromFile(
                            widget.requestId,
                            imagePath,
                          ),
                        ),
                      ),
              icon: Icon(Iconsax.camera, size: 25, color: widget.iconColor),
            ),
            Text(
              '${photos.length}/${CameraHandlerController.maxProofPhotos} photos',
              style: TextStyle(color: widget.textColor, fontSize: 12),
            ),
            const SizedBox(height: BSizes.xs),
            for (int i = 0; i < photos.length; i++)
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(photos[i]),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Iconsax.gallery_slash,
                          color: widget.iconColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: BSizes.xs),
                  Expanded(
                    child: Text(
                      photos[i].split(Platform.pathSeparator).last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: widget.textColor, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    onPressed: () => ImagePreviewDialog.show(
                      context,
                      photos[i],
                      barrierDismissible: true,
                    ),
                    icon:
                        Icon(Iconsax.eye, color: widget.iconColor, size: 20),
                  ),
                  IconButton(
                    onPressed: () => cameraController.removeProofPhoto(
                      widget.requestId,
                      i,
                    ),
                    icon:
                        Icon(Iconsax.trash, color: widget.iconColor, size: 20),
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }
}
