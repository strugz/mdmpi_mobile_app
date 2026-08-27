import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

class BLoaders {
  static void hideSnackBar() {
    // In test mode there may be no valid context/overlay
    if (Get.testMode) return;
    ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
  }

  static void customToast({required String message}) {
    if (Get.testMode) return;
    ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
      elevation: 0,
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.transparent,
      content: Container(
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: !BHelperFunctions.isDarkMode(Get.context!)
              ? BColors.grey.withValues(alpha: 0.9)
              : BColors.darkerGrey.withValues(alpha: 0.9),
        ),
        child: Center(
            child: Text(message,
                style: Theme.of(Get.context!).textTheme.labelLarge)),
      ),
    ));
  }

  static void successSnackBar({required String title, String message = '', duration = 3}) {
    if (Get.testMode) return;
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: Colors.white,
      backgroundColor: BColors.primary,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(10),
      icon: const Icon(Iconsax.check, color: BColors.white),
    );
  }

  static void warningSnackBar({required String title, String message = '', duration = 3}) {
    if (Get.testMode) return;
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: Colors.white,
      backgroundColor: BColors.primary,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: 3),
      margin: const EdgeInsets.all(20),
      icon: const Icon(Iconsax.warning_2, color: BColors.white),
    );
  }

  static void errorSnackBar({required String title, String message = '', duration = 3}) {
    if (Get.testMode) return;
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: Colors.white,
      backgroundColor: Colors.red.shade600,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: 3),
      margin: const EdgeInsets.all(20),
      icon: const Icon(Iconsax.warning_2, color: BColors.white),
    );
  }
}
