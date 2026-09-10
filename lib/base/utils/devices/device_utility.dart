import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BDevicesUtils {
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  // ── System insets ─────────────────────────────────────────────────────────
  //
  // The app runs edge-to-edge on Android (main.dart), so the navigation bar
  // (3-button strip or gesture pill) overlaps the bottom of every screen.
  // Rule for bottom-anchored widgets:
  //   * navigation bar  → `SafeArea(top: false)` (or [systemBottomInset]) once,
  //     at the OUTERMOST bottom widget — never around a whole Scaffold, which
  //     shortens full-bleed content such as maps and camera previews;
  //   * keyboard        → [keyboardInset] once — Scaffold already applies it to
  //     `bottomNavigationBar`, sheet presenters add it themselves;
  //   * never add the two together, and never use the keyboard height to
  //     decide whether the navigation bar exists (that was the old bug).

  /// Height of the system navigation bar / gesture area under this context.
  static double systemBottomInset(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom;

  /// Height of the on-screen keyboard under this context (0 when closed).
  static double keyboardInset(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom;

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getPixelRatio() {
    return MediaQuery.of(Get.context!).devicePixelRatio;
  }

  static double getAppBarHeight() {
    return kToolbarHeight;
  }
  // (getBottomNavigationBarHeight was removed: it returned Flutter's 56 dp
  // Material constant and was being mistaken for the system inset.)

  static Future<bool> isPhysicalDevice() async {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static void vibrate(Duration duration) {
    HapticFeedback.vibrate();
    Future.delayed(duration, () => HapticFeedback.vibrate());
  }

  static Future<void> setPreferredOrientations(
      List<DeviceOrientation> orientation) async {
    await SystemChrome.setPreferredOrientations(orientation);
  }

  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('mdmpi.com.ph');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static bool isIOS() {
    return Platform.isIOS;
  }

  static bool isAndroid() {
    return Platform.isAndroid;
  }

  static Future<void> launchUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
