import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// Central status color & icon mapping for collection statuses.
///
/// Mirrors the [LogisticsStatusColors] pattern from
/// `features/logistics/helpers/status_color_mapper.dart` but scoped
/// to the Collection domain's own status values
/// (`Pending`, `Completed`, `Overdue`).
class CollectionStatusColors {
  CollectionStatusColors._();

  // ─── Status constants ───────────────────────────────────────────────
  static const String statusUnassigned = 'Unassigned';
  static const String statusPending = 'Pending';
  static const String statusCompleted = 'Completed';
  static const String statusOverdue = 'Overdue';

  // ─── Colour mapping ─────────────────────────────────────────────────

  /// Returns a tuple of (background, foreground) colours for the given
  /// collection [status]. Adjusts for [darkMode] when needed.
  static (Color bg, Color fg) colorsFor(String status,
      {bool darkMode = false}) {
    final s = status.trim();
    Color bg;
    Color fg;

    switch (s) {
      case statusCompleted:
        bg = BColors.success;
        fg = BColors.white;
        break;
      case statusOverdue:
        bg = BColors.error;
        fg = BColors.white;
        break;
      case statusPending:
        bg = Colors.orange;
        fg = BColors.white;
        break;
      default:
        bg = darkMode ? BColors.darkerGrey : BColors.light;
        fg = darkMode ? BColors.light : BColors.darkGrey;
    }

    return (bg, fg);
  }

  /// Convenience: derive dark/light from [context] automatically.
  static (Color bg, Color fg) colorsForAuto(
      BuildContext context, String status) {
    final dark = BHelperFunctions.isDarkMode(context);
    return colorsFor(status, darkMode: dark);
  }

  /// Returns a single representative colour for the given [status].
  ///
  /// Useful when only a flat colour is needed (e.g. icon tint, badge bg).
  static Color colorFor(String status) {
    switch (status.trim()) {
      case statusCompleted:
        return BColors.success;
      case statusOverdue:
        return BColors.error;
      case statusPending:
      default:
        return Colors.orange;
    }
  }

  // ─── Icon mapping ───────────────────────────────────────────────────

  /// Returns an appropriate icon for the given collection [status].
  static IconData iconFor(String status) {
    switch (status.trim()) {
      case statusCompleted:
        return Iconsax.tick_circle;
      case statusOverdue:
        return Iconsax.warning_2;
      case statusPending:
      default:
        return Iconsax.clock;
    }
  }

  // ─── Display text ───────────────────────────────────────────────────

  /// Keep full original status text; fallback to 'Unknown' if empty.
  static String display(String status) {
    final raw = status.trim();
    if (raw.isEmpty) return 'Unknown';
    return raw;
  }
}


