import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/signature/signature_pad.dart';

/// Reusable signature capture dialog.
///
/// Use this in any feature/controller to prompt the user for a handwritten
/// signature. Pass an [onSave] callback to receive the raw bytes (or null if
/// the pad was empty).
///
/// Design/Behavior:
/// * Dark/light adapts via [BHelperFunctions.isDarkMode].
/// * Fixed size by default (400x345) but can be overridden.
/// * No business logic inside; caller decides how to persist or handle bytes.
///
/// Example:
/// ```dart
/// BSignatureCaptureDialog.show(
///   context: context,
///   onSave: (bytes) => controller.setSignature(bytes),
/// );
/// ```
class BSignatureCaptureDialog {
  /// Show the signature capture dialog.
  ///
  /// Parameters:
  /// * [context] BuildContext to show the dialog.
  /// * [onSave] Callback invoked when user taps save inside the signature pad.
  /// * [width] Optional dialog width (default 400).
  /// * [height] Optional dialog height (default 345).
  static Future<void> show({
    required BuildContext context,
    required void Function(Uint8List? signatureBytes) onSave,
    double width = 400,
    double height = 345,
  }) async {
    final dark = BHelperFunctions.isDarkMode(context);
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: dark ? BColors.black : BColors.light,
          contentPadding: EdgeInsets.zero,
          titlePadding: EdgeInsets.zero,
          content: SizedBox(
            width: width,
            height: height,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SignaturePadWidget(
                    onSave: (Uint8List? bytes) {
                      // Delegate to caller for handling.
                      onSave(bytes);
                      Navigator.of(dialogContext).pop();
                      if (bytes != null) {
                        BHelperFunctions.showSnackBar("Signature saved!");
                      } else {
                        BHelperFunctions.showSnackBar("Signature pad was empty.");
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
