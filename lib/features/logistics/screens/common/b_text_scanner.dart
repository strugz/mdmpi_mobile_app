import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/camera/camera_preview.dart';
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';

class BTextScanner extends StatefulWidget {
  const BTextScanner({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<BTextScanner> createState() => _BTextScannerState();
}

class _BTextScannerState extends State<BTextScanner> {
  late final CameraHandlerController cameraController;

  @override
  void initState() {
    super.initState();
    cameraController = Get.find<CameraHandlerController>();
    // Ensure camera preview is active when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cameraController.resumePreview();
    });
  }

  @override
  void dispose() {
    // Stop any ongoing flash animations to prevent buffer issues
    cameraController.stopFlashAnimation();
    // Pause preview to release camera buffers before leaving
    cameraController.pausePreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Camera preview stays full-bleed; only the control over it clears the
    // system navigation bar.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Define the overlay for this specific screen
    Widget buildScanTextOverlay() {
      return Padding(
        padding: EdgeInsets.only(
            top: BSizes.defaultSpace,
            bottom: BSizes.defaultSpace + bottomInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ElevatedButton(
            onPressed: cameraController.isProcessing.value
                ? null
                : () {
              cameraController.scanText(widget.controller);
            },
            child: Obx(() => Text(cameraController.isProcessing.value
                ? 'Processing...'
                : 'Scan Text')), // Obx for button text
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      bottom: false,
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
