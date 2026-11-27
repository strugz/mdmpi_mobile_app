import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/camera/camera_preview.dart';
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';

import '../../../../../base/utils/constants/colors.dart';
import 'b_photo_review_screen.dart';

/// Proof photo capture. The photo is saved the moment the shutter is pressed,
/// before the review screen, so it survives the app being closed right after
/// (couriers often capture before an X-ray check and only drop off later).
class BDropOffCapture extends StatefulWidget {
  const BDropOffCapture({
    super.key,
    this.title = 'Capture',
    this.onCapture,
    this.onSavePhoto,
    this.onDiscardPhoto,
  }) : assert(onCapture != null || onSavePhoto != null,
            'Provide onCapture or onSavePhoto');

  final String title;

  /// Takes and saves the picture itself (single fixed file per request);
  /// returns the saved path, or null when nothing was saved. Retake keeps
  /// the file; the next shot overwrites it.
  final Future<String?> Function(CameraHandlerController camera)? onCapture;

  /// Saves the photo just taken at [imagePath] (a temporary camera file);
  /// returns the saved path, or null when nothing was saved.
  final Future<String?> Function(
      CameraHandlerController camera, String imagePath)? onSavePhoto;

  /// Removes a photo saved by [onSavePhoto] when the user taps Retake.
  final Future<void> Function(CameraHandlerController camera, String savedPath)?
      onDiscardPhoto;

  @override
  State<BDropOffCapture> createState() => _BDropOffCaptureState();
}

class _BDropOffCaptureState extends State<BDropOffCapture> {
  late final CameraHandlerController cameraController;
  final RxBool isReviewingPhoto = false.obs;
  final Rx<String?> capturedImagePath = Rx<String?>(null);
  bool _isSaving = false;

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

  /// Confirm: the photo is already saved, so just return to the request.
  void _confirmPhoto() {
    isReviewingPhoto.value = false;
    capturedImagePath.value = null;
    if (mounted) Get.back();
  }

  /// Retake: drop the saved photo (where the caller supports it) and go
  /// back to the camera preview.
  Future<void> _retakePhoto() async {
    final savedPath = capturedImagePath.value;
    isReviewingPhoto.value = false;
    capturedImagePath.value = null;
    if (savedPath != null && widget.onDiscardPhoto != null) {
      try {
        await widget.onDiscardPhoto!(cameraController, savedPath);
      } catch (e) {
        logDebug('Error discarding retaken photo: $e');
      }
    }
  }

  /// Shutter: take the photo, save it right away, then show the review.
  Future<void> _onCameraButtonTap() async {
    if (_isSaving) return;
    _isSaving = true;
    try {
      String? savedPath;
      if (widget.onSavePhoto != null) {
        final tempPath =
            await cameraController.takePictureForReviewWithAnimation();
        if (tempPath == null) return;
        savedPath = await widget.onSavePhoto!(cameraController, tempPath);
      } else {
        savedPath = await widget.onCapture!(cameraController);
      }

      if (savedPath == null || savedPath.isEmpty || !mounted) return;

      // A retake can overwrite the same file name; drop the cached image so
      // the review shows the new photo.
      await FileImage(File(savedPath)).evict();
      capturedImagePath.value = savedPath;
      isReviewingPhoto.value = true;
    } catch (e) {
      logDebug('Error capturing proof photo: $e');
    } finally {
      _isSaving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Camera preview stays full-bleed; only the capture button clears the
    // system navigation bar. (BPhotoReviewScreen has its own SafeArea.)
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    /// Build camera capture overlay with camera button
    Widget buildCaptureOverlay() {
      return Padding(
        padding: EdgeInsets.only(
            top: BSizes.defaultSpace,
            bottom: BSizes.defaultSpace + bottomInset),
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
        top: false,
        bottom: false,
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
