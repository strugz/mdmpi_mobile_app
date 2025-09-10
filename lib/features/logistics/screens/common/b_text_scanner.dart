import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/camera/camera_preview.dart';
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';

class BTextScanner extends StatelessWidget {
  const BTextScanner({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final CameraHandlerController cameraController =
    Get.find<CameraHandlerController>();
    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final bool isGestureNavigation = bottomPadding > 0.0;

    // Define the overlay for this specific screen
    Widget buildScanTextOverlay() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: BSizes.defaultSpace),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ElevatedButton(
            onPressed: cameraController.isProcessing.value
                ? null
                : () {
              cameraController.scanText(controller);
            },
            child: Obx(() => Text(cameraController.isProcessing.value
                ? 'Processing...'
                : 'Scan Text')), // Obx for button text
          ),
        ),
      );
    }

    return SafeArea(
      bottom: !isGestureNavigation,
      child: Scaffold(
        appBar: BAppBar(
          title: const Text('Search Text'),
          showBackArrow: true,
        ),
        body: CameraPreview(
          cameraController: cameraController,
          previewWidth: 350, // Specific width for this screen
          previewHeight: 500, // Specific height for this screen
          overlayWidget: buildScanTextOverlay(), // Pass the specific overlay
        ),
      ),
    );
  }
}
