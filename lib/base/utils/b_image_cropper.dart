import 'dart:io';

import 'package:flutter/material.dart' show Color;
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

/// A Crop & rotate screen for one photo (uCrop, Android): free-form corners,
/// rotate, pinch to zoom. Used right after Scan Document so the page is
/// trimmed to the paper before it is read.
class BImageCropper {
  BImageCropper._();

  /// The cropped copy of [file], or null when the user backed out or the
  /// cropper cannot run here (not Android). The caller then keeps [file].
  static Future<File?> crop(File file, {String title = 'Crop & rotate'}) async {
    if (!GetPlatform.isAndroid) return null;
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        compressQuality: 95,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: BColors.primary,
            toolbarWidgetColor: const Color(0xFFFFFFFF),
            activeControlsWidgetColor: BColors.primary,
            statusBarLight: false,
            freeStyleCropEnabled: true,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
        ],
      );
      return cropped == null ? null : File(cropped.path);
    } catch (e) {
      logDebug('BImageCropper: failed: $e');
      return null;
    }
  }
}
