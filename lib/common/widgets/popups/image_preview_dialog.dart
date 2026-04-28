import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

class ImagePreviewDialog {
  /// Show a full-screen image preview for [imagePath].
  ///
  /// The dialog will be dismissed when the user releases the pointer
  /// (onPointerUp). This replicates the "hold-to-preview" behaviour used in
  /// the codebase. If [barrierDismissible] is true the user may also dismiss
  /// by tapping outside (not recommended for hold-to-preview flows).
  static Future<void> show(BuildContext context, String imagePath,
      {bool barrierDismissible = false}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) {
        return Listener(
          // Close when the pointer is released (matches existing behavior)
          onPointerUp: (_) {
            if (Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
          },
          child: Dialog(
            insetPadding: const EdgeInsets.all(0),
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                AppBar(
                  automaticallyImplyLeading: false,
                  centerTitle: true,
                  backgroundColor: BHelperFunctions.isDarkMode(context)
                      ? BColors.dark
                      : BColors.primary,
                ),
                Expanded(
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20.0),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: _buildImage(context, imagePath),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildImage(BuildContext context, String imagePath) {
    if (imagePath.isEmpty) {
      return Center(
        child: Text(
          'No image',
          style: TextStyle(
              color: BHelperFunctions.isDarkMode(context)
                  ? BColors.light
                  : BColors.black),
        ),
      );
    }

    return Image.file(
      File(imagePath),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 50, color: BColors.grey),
              const SizedBox(height: BSizes.sm),
              const Text('Failed to load image'),
              const SizedBox(height: BSizes.xs),
              Text(
                imagePath,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
