import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/camera/camera_preview.dart';
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';

/// Generic reusable camera capture screen.
///
/// Responsibilities:
/// - Displays a full-screen [CameraPreview].
/// - Shows a capture button overlay that triggers the provided [onCapture] callback.
/// - Handles a flash overlay animation driven by [CameraHandlerController].
///
/// Usage:
///   Get.to(() => BDropOffCapture(
///     title: 'Proof Picture',
///     onCapture: (camera) => camera.takePictureWithAnimation(requestId),
///   ));
///
/// The widget expects a registered [CameraHandlerController] via GetX DI:
///   Get.lazyPut(() => CameraHandlerController(), fenix: true);
class BDropOffCapture extends StatelessWidget {
  const BDropOffCapture({
    super.key,
    this.title = 'Capture',
    required this.onCapture,
  });

  /// App bar title.
  final String title;

  /// Callback invoked when the capture button is pressed. Receives the active
  /// [CameraHandlerController]. Return a Future if you need async handling.
  final Future<void> Function(CameraHandlerController camera) onCapture;

  @override
  Widget build(BuildContext context) {
    final cameraController = Get.find<CameraHandlerController>();
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
            onPressed: () => onCapture(cameraController),
            icon: Icon(Icons.camera, size: 52, color: iconColor),
          ),
        ),
      );
    }

    return SafeArea(
      bottom: !isGestureNavigation,
      child: Scaffold(
        appBar: BAppBar(
          title: Text(title),
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
    );
  }
}
