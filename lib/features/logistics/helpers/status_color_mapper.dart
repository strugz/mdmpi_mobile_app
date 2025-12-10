import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// Central status color mapping for logistics request statuses.
/// Ensures sufficient contrast for light & dark modes.
class LogisticsStatusColors {
  LogisticsStatusColors._();

  /// Returns a tuple of (background, foreground) colors for a given status.
  static (Color bg, Color fg) colorsFor(String status, {bool darkMode = false}) {
    final s = status.trim();
    Color bg;
    Color fg;
    switch (s) {
      case BTexts.statusCancelled:
        bg = BColors.cancelledBackground; fg = BColors.black; break;
      case BTexts.statusNewRequest:
        bg = BColors.accent; fg = BColors.black; break;
      case BTexts.statusGettingSuppliesReady:
        bg = _adjustAlpha(BColors.warning, darkMode, baseAlpha: 0.2); fg = BColors.warning; break;
      case BTexts.statusItemPrepared:
        bg = _adjustAlpha(BColors.info, darkMode, baseAlpha: 0.15); fg = BColors.info; break;
      case BTexts.statusForDelivery:
        bg = darkMode ? BColors.primary.withValues(alpha: 0.25) : BColors.primaryBackground; fg = BColors.primary; break;
      case BTexts.statusInTransit:
        bg = _adjustAlpha(BColors.secondary, darkMode, baseAlpha: 0.3); fg = BColors.white; break;
      case BTexts.statusTakenOut:
        bg = _adjustAlpha(BColors.success, darkMode, baseAlpha: 0.25); fg = BColors.success; break;
      case BTexts.statusItemPacked:
        bg = _adjustAlpha(BColors.info, darkMode, baseAlpha: 0.2); fg = darkMode ? BColors.white : BColors.info; break;
      case BTexts.statusDoneDelivery:
        bg = _adjustAlpha(BColors.success, darkMode, baseAlpha: 0.3); fg = darkMode ? BColors.white : BColors.success; break;
      case BTexts.statusReceived:
        bg = BColors.success; fg = BColors.white; break;

      default:
        bg = darkMode ? BColors.darkerGrey : BColors.light; fg = darkMode ? BColors.light : BColors.darkGrey;
    }
    fg = _ensureReadableForeground(bg, fg, darkMode);
    return (bg, fg);
  }

  /// Convenience: derive dark/light from context directly.
  static (Color bg, Color fg) colorsForAuto(BuildContext context, String status) {
    final dark = BHelperFunctions.isDarkMode(context);
    return colorsFor(status, darkMode: dark);
  }

  /// Keep full original status text; fallback to 'Unknown' if empty.
  static String display(String status) {
    final raw = status.trim();
    if (raw.isEmpty) return 'Unknown';
    return raw; // show complete original status text
  }

  /// Increase alpha for translucent backgrounds in dark mode to avoid blending.
  static Color _adjustAlpha(Color base, bool darkMode, {double baseAlpha = 0.25}) {
    if (!darkMode) return base.withValues(alpha: baseAlpha);
    // In dark mode boost alpha for better separation.
    final boosted = (baseAlpha < 0.35) ? 0.45 : baseAlpha;
    return base.withValues(alpha: boosted);
  }

  /// Ensure foreground contrast against background (simple luminance heuristic).
  static Color _ensureReadableForeground(Color bg, Color desired, bool darkMode) {
    final lumBg = bg.computeLuminance();
    final lumFg = desired.computeLuminance();
    // If contrast insufficient, pick black or white based on background luminance.
    final contrast = (lumBg > lumFg) ? lumBg - lumFg : lumFg - lumBg;
    if (contrast < 0.35) {
      return lumBg > 0.5 ? BColors.black : BColors.white;
    }
    // Additional safeguard: very bright background in light mode -> dark text.
    if (!darkMode && lumBg > 0.85) return BColors.black;
    // Very dark background in dark mode -> white text.
    if (darkMode && lumBg < 0.2) return BColors.white;
    return desired;
  }
}
