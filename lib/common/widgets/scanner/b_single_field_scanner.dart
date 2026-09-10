import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/camera/camera_preview.dart';
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';

/// Simplified scanner for single text field scenarios.
///
/// Opens a camera view to scan text via OCR and populates a single
/// TextEditingController with the first matched pattern found.
/// Useful for waybill numbers, tracking codes, invoice numbers, etc.
class BSingleFieldScanner extends StatefulWidget {
  const BSingleFieldScanner({
    super.key,
    required this.controller,
    this.title = 'Scan Text',
  });

  final TextEditingController controller;
  final String title;

  @override
  State<BSingleFieldScanner> createState() => _BSingleFieldScannerState();
}

class _BSingleFieldScannerState extends State<BSingleFieldScanner> {
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
                    _scanAndPopulateSingleField();
                  },
            child: Obx(() => Text(cameraController.isProcessing.value
                ? 'Processing...'
                : 'Scan Text')),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        appBar: BAppBar(
          title: Text(widget.title),
          showBackArrow: true,
        ),
        body: CameraPreview(
          cameraController: cameraController,
          previewWidth: 350,
          previewHeight: 500,
          overlayWidget: buildScanTextOverlay(),
        ),
      ),
    );
  }

  /// Scans text and populates the single field with the first match found.
  Future<void> _scanAndPopulateSingleField() async {
    await cameraController.scanSingleField(widget.controller);
  }
}

