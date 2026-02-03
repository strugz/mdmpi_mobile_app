import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/camera/camera_preview.dart';
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';

import '../../../../../base/utils/constants/colors.dart';
import 'b_photo_review_screen.dart';

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
  final RxBool isReviewingPhoto = false.obs;
  final Rx<String?> capturedImagePath = Rx<String?>(null);

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

  /// Handle confirm button in photo review screen
  Future<void> _confirmPhoto() async {
    logDebug('✅ Photo confirmed, saving...');
    try {
      // Call the onCapture callback to save the photo
      await widget.onCapture(cameraController);

      // Reset state
      isReviewingPhoto.value = false;
      capturedImagePath.value = null;

      logDebug('✅ Photo saved successfully');

      // Automatically navigate back to request_transport
      if (mounted) {
        logDebug('🔙 Navigating back to request transport...');
        Get.back();
      }
    } catch (e) {
      logDebug('❌ Error saving photo: $e');
    }
  }

  /// Handle retake button - go back to camera
  void _retakePhoto() {
    logDebug('🔄 Retaking photo...');
    isReviewingPhoto.value = false;
    capturedImagePath.value = null;
    // Camera preview remains active
  }

  /// Handle camera button tap - take photo and show review
  Future<void> _onCameraButtonTap() async {
    logDebug('📸 Camera button tapped');

    // Take picture with animation
    final imagePath =
        await cameraController.takePictureForReviewWithAnimation();

    if (imagePath != null && mounted) {
      logDebug('✅ Photo captured, showing review: $imagePath');
      capturedImagePath.value = imagePath;
      isReviewingPhoto.value = true;
    } else {
      logDebug('❌ Failed to capture photo');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final bool isGestureNavigation = bottomPadding > 0.0;

    /// Build camera capture overlay with camera button
    Widget buildCaptureOverlay() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: BSizes.defaultSpace),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: IconButton(
            onPressed: _onCameraButtonTap,
            icon: Icon(Icons.camera, size: 52, color: BColors.light),
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
          body: Obx(() {
            /// Show photo review screen if reviewing photo
            if (isReviewingPhoto.value && capturedImagePath.value != null) {
              return BPhotoReviewScreen(
                imagePath: capturedImagePath.value!,
                onConfirm: _confirmPhoto,
                onRetake: _retakePhoto,
                title: '${widget.title} Review',
              );
            }

            /// Show camera preview if not reviewing
            return Stack(
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
            );
          }),
        ),
      ),
    );
  }
}
