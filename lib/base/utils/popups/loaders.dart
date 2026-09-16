import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/devices/device_utility.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// Every transient message in the app.
///
/// GetX defaults a snackbar to `margin: EdgeInsets.zero`, so it sits flush
/// against the bottom of the screen — which, on an edge-to-edge Android
/// build, is underneath the gesture pill or the three-button strip. The last
/// line of the message is covered by the system navigation bar. Nothing here
/// should be calling `Get.snackbar` directly; this is the only place that
/// knows how to clear that.
class BLoaders {
  BLoaders._();

  /// Fast enough to feel like a response. GetX ships a one-second entrance,
  /// which on something seen dozens of times a day reads as lag.
  static const Duration _motion = Duration(milliseconds: 260);

  static void hideSnackBar() {
    // In test mode there may be no valid context/overlay
    if (Get.testMode) return;
    ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
  }

  /// Insets for a bottom-anchored snackbar, clear of the system navigation
  /// bar by [systemInset].
  ///
  /// Kept separate so the one thing that actually goes wrong here — the
  /// bottom edge — can be checked without a screen.
  @visibleForTesting
  static EdgeInsets snackBarMargin(double systemInset) => EdgeInsets.fromLTRB(
        BSizes.md,
        0,
        BSizes.md,
        BSizes.md + systemInset,
      );

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

  /// The one call that puts a snackbar on screen.
  static void snackBar({
    required String title,
    String message = '',
    Color background = BColors.primary,
    IconData icon = Iconsax.info_circle,
    int duration = 3,
  }) {
    if (Get.testMode) return;
    final context = Get.context;
    if (context == null) return;

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: background,
      colorText: BColors.white,
      icon: Icon(icon, color: BColors.white),
      // A pulsing icon on a message that appears dozens of times a day is
      // movement with nothing to say.
      shouldIconPulse: false,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      borderRadius: BSizes.cardRadiusMd,
      margin: snackBarMargin(BDevicesUtils.systemBottomInset(context)),
      duration: Duration(seconds: duration),
      animationDuration: _motion,
      // Entering and leaving, so ease-out both ways: the movement the eye is
      // watching for happens immediately.
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeOutCubic,
      // Otherwise a message spans a tablet or a desktop window edge to edge.
      maxWidth: 520,
    );
  }

  static void successSnackBar(
          {required String title, String message = '', int duration = 3}) =>
      snackBar(
        title: title,
        message: message,
        // Purple, not green: the app's own colour is what confirms an
        // action here, and BColors.success stays for amounts and statuses
        // where green carries a meaning of its own.
        background: BColors.primary,
        icon: Iconsax.tick_circle,
        duration: duration,
      );

  static void warningSnackBar(
          {required String title, String message = '', int duration = 3}) =>
      snackBar(
        title: title,
        message: message,
        background: BColors.warning,
        icon: Iconsax.warning_2,
        duration: duration,
      );

  static void errorSnackBar(
          {required String title, String message = '', int duration = 4}) =>
      snackBar(
        title: title,
        message: message,
        background: BColors.error,
        icon: Iconsax.close_circle,
        // Something went wrong is worth a beat longer than something worked.
        duration: duration,
      );
}
