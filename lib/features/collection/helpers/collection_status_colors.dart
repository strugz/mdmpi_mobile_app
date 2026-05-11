import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// Central status color & icon mapping for collection.
class CollectionStatusColors {
  CollectionStatusColors._();

  // Note: 'Pending' and 'On-going' have been removed from the visible status set.
  // Keep only outcome (user-selectable) statuses here.

  // ─── Outcome Statuses (User Selectable) ─────────────────────────────
  static const String statusCollected = 'Collected';
  static const String statusPartial = 'Partially Collected';
  static const String statusFollowUp = 'Follow Up';
  static const String statusUnavailable = 'Customer Unavailable';
  static const String statusRefused = 'Refused to Pay';

  static const List<String> allStatuses = [
    statusCollected,
    statusPartial,
    statusFollowUp,
    statusUnavailable,
    statusRefused,
  ];

  /// Statuses that a user can manually select in the update screen.
  static const List<String> updatableStatuses = [
    statusCollected,
    statusPartial,
    statusFollowUp,
    statusUnavailable,
    statusRefused,
  ];

  /// Returns a tuple of (background, foreground) colours for the given [status].
  static (Color bg, Color fg) colorsFor(String status, {bool darkMode = false}) {
    final s = status.trim();
    Color bg;
    Color fg = BColors.white;

    switch (s) {
      case statusCollected:
        bg = BColors.success;
        break;
      case statusPartial:
        bg = Colors.lightGreen;
        break;
      case statusFollowUp:
        bg = BColors.info;
        break;
      case statusRefused:
        bg = BColors.error;
        break;
      case statusUnavailable:
        bg = Colors.amber;
        break;
      default:
        bg = darkMode ? BColors.darkerGrey : BColors.light;
        fg = darkMode ? BColors.light : BColors.darkGrey;
    }

    return (bg, fg);
  }

  static (Color bg, Color fg) colorsForAuto(BuildContext context, String status) {
    final dark = BHelperFunctions.isDarkMode(context);
    return colorsFor(status, darkMode: dark);
  }

  static Color colorFor(String status) {
    return colorsFor(status).$1;
  }

  // ─── Icon mapping ───────────────────────────────────────────────────

  static IconData iconFor(String status) {
    switch (status.trim()) {
      case statusCollected:
      case statusPartial:
        return Iconsax.tick_circle;
      case statusFollowUp:
        return Iconsax.info_circle;
      case statusRefused:
        return Iconsax.warning_2;
      case statusUnavailable:
        return Iconsax.clock;
      default:
        return Iconsax.info_circle;
    }
  }

  // ─── Display text ───────────────────────────────────────────────────

  static String display(String status) {
    final raw = status.trim();
    if (raw.isEmpty) return 'Unknown';
    return raw;
  }
}
