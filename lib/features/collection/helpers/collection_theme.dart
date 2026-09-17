import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';

/// Colour tokens for the Collection department.
///
/// One accent, warm neutrals, status colours kept where they already carry
/// meaning. The budget is one hue per card beyond ink and grey: the accent is
/// for the single primary action on a screen and for selection, the status
/// colours live on badges and stripes only, and everything else is ink on
/// off-white. Soft tints are the base colour at 12% over white, so
/// `color.withValues(alpha: 0.12)` reproduces them.
class BCollectionColors {
  BCollectionColors._();

  // Surfaces
  /// Scaffold body. Warm off-white so white cards float without a border.
  static const Color background = Color(0xFFF7F7F5);
  static const Color surface = Color(0xFFFFFFFF);

  /// Chips at rest, input fill, quick-fill pills.
  static const Color surfaceMuted = Color(0xFFF1F1EE);

  /// Hairlines only: dividers, bar edges, input borders.
  static const Color outline = Color(0xFFE6E6E2);

  // Ink
  static const Color ink = Color(0xFF1C1C1E);
  static const Color inkSecondary = Color(0xFF5C5C60);

  /// Placeholders, footnotes, disabled text, inactive icons.
  static const Color inkMuted = Color(0xFF8E8E93);

  // Accent
  static const Color primary = Color(0xFF3452C7);
  static const Color primaryPressed = Color(0xFF2A43A6);
  static const Color primarySoft = Color(0xFFEAEEFB);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF2E7D4F);
  static const Color warning = Color(0xFFC77700);
  static const Color danger = Color(0xFFB93838);
  static const Color info = Color(0xFF2F6FAE);
  static const Color reconcile = Color(0xFF6D4BB0);
  static const Color neutral = Color(0xFF6B6B70);

  // Header
  static const Color headerBackground = Color(0xFF1F2A5C);
  static const Color onHeader = Color(0xFFFFFFFF);
  static const Color onHeaderMuted = Color(0xFFB8C0E0);

  static const ColorScheme scheme = ColorScheme.light(
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primarySoft,
    onPrimaryContainer: primary,
    secondary: inkSecondary,
    onSecondary: onPrimary,
    surface: surface,
    onSurface: ink,
    onSurfaceVariant: inkSecondary,
    outline: inkMuted,
    outlineVariant: outline,
    error: danger,
    onError: onPrimary,
  );
}

/// The Collection theme: the app theme with the Collection tokens applied.
///
/// Applied for the whole session once the user is known to be in Collection
/// (see [BCollectionTheme.applyFor]). A Collection user sees only Collection
/// screens plus Settings, so a session-wide swap is simpler and safer than
/// wrapping every pushed route.
class BCollectionTheme {
  BCollectionTheme._();

  static ThemeData get light {
    final base = BAppTheme.lightTheme;
    return base.copyWith(
      colorScheme: BCollectionColors.scheme,
      primaryColor: BCollectionColors.primary,
      scaffoldBackgroundColor: BCollectionColors.background,
      dividerColor: BCollectionColors.outline,
      // Keep the app bar transparent, as the base theme has it. Flutter
      // derives the status bar icon colour from the app bar background, and
      // an off-white one turned the clock and icons dark on the navy header.
      appBarTheme: base.appBarTheme.copyWith(
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: BCollectionColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: BCollectionColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.copyWith(
          backgroundColor:
              const WidgetStatePropertyAll(BCollectionColors.primary),
          foregroundColor:
              const WidgetStatePropertyAll(BCollectionColors.onPrimary),
          overlayColor: WidgetStatePropertyAll(
              BCollectionColors.onPrimary.withValues(alpha: 0.08)),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
          foregroundColor:
              const WidgetStatePropertyAll(BCollectionColors.inkSecondary),
          side: const WidgetStatePropertyAll(
              BorderSide(color: BCollectionColors.outline)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: BCollectionColors.primary),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: BCollectionColors.surfaceMuted,
        filled: true,
        prefixIconColor: BCollectionColors.inkMuted,
        suffixIconColor: BCollectionColors.inkMuted,
        hintStyle: base.inputDecorationTheme.hintStyle
            ?.copyWith(color: BCollectionColors.inkMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BCollectionColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: BCollectionColors.primary, width: 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? BCollectionColors.onPrimary
                : BCollectionColors.surface),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? BCollectionColors.primary
                : BCollectionColors.outline),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: BCollectionColors.primary),
    );
  }

  /// Switch the session theme to match the department. Idempotent; call it
  /// whenever the department becomes known (cold start, login, refresh).
  ///
  /// Safe to call from a build method: the swap is deferred to after the
  /// current frame, because changing the theme marks GetMaterialApp dirty
  /// and Flutter forbids that while it is already building (AppRouter
  /// calls this from build, and the red screen at login was exactly that).
  static void applyFor(String department) {
    final isCollection = department.trim().toLowerCase() == 'collection';
    final wanted = isCollection ? light : BAppTheme.lightTheme;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context == null) return;
      if (Get.theme.scaffoldBackgroundColor == wanted.scaffoldBackgroundColor) {
        return;
      }
      Get.changeTheme(wanted);
    });
  }
}
