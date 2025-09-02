import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';

class CameraPreview extends StatelessWidget {
  final CameraHandlerController cameraController;
  final Widget?
      overlayWidget; // Optional widget to display on top of the camera
  final Alignment previewAlignment;
  final double? previewWidth;
  final double? previewHeight;

  const CameraPreview({
    super.key,
    required this.cameraController,
    this.overlayWidget,
    this.previewAlignment = Alignment.topCenter,
    this.previewWidth,
    this.previewHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (cameraController.isCameraLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final previewWidget = cameraController.getCameraPreviewWidget();

      if (previewWidget == null) {
        return const Center(child: Text("Camera Preview Not Available"));
      }

      // Use Stack to allow overlaying widgets
      return Stack(
        children: [
          Align(
            alignment: previewAlignment,
            child: SizedBox(
              width: previewWidth ??
                  MediaQuery.of(context).size.width,
              height: previewHeight ??
                  MediaQuery.of(context).size.height,
              child: previewWidget,
            ),
          ),
          if (overlayWidget != null) overlayWidget!,
        ],
      );
    });
  }
}
