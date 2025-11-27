import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/camera/camera_preview.dart';
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';

class BDropOffCapture extends StatefulWidget {
  const BDropOffCapture({
    super.key,
    this.title = 'Capture',
    required this.onCapture,
  });

  final String title;

  final Future<void> Function(CameraHandlerController camera) onCapture;

  @override
  State<BDropOffCapture> createState() => _BDropOffCaptureState();
}

class _BDropOffCaptureState extends State<BDropOffCapture> {
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
    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final bool isGestureNavigation = bottomPadding > 0.0;
    final dark = BHelperFunctions.isDarkMode(context);
    final iconColor = dark ? BColors.light : BColors.black;

    Widget buildCaptureOverlay() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: BSizes.defaultSpace),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: IconButton(
            onPressed: () => widget.onCapture(cameraController),
            icon: Icon(Icons.camera, size: 52, color: iconColor),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: SafeArea(
        bottom: !isGestureNavigation,
        child: Scaffold(
          appBar: BAppBar(
            title: Text(widget.title),
            showBackArrow: true,
          ),
          body: Obx(
            () => Stack(
              children: [
                CameraPreview(
                  cameraController: cameraController,
                  overlayWidget: buildCaptureOverlay(),
                ),
                if (cameraController.isFlashing.value)
                  FadeTransition(
                    opacity: cameraController.flashOpacity,
                    child: Container(color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
