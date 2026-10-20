import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';

/// One set of Collection colour tokens: [light] or [dark].
///
/// One accent, warm neutrals, status colours kept where they already carry
/// meaning. The budget is one hue per card beyond ink and grey: the accent is
/// for the single primary action on a screen and for selection, the status
/// colours live on badges and stripes only, and everything else is ink on
/// the background. Soft tints are the base colour at 12% over the surface,
/// so `color.withValues(alpha: 0.12)` reproduces them in either set.
@immutable
class BCollectionPalette {
  const BCollectionPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.outline,
    required this.ink,
    required this.inkSecondary,
    required this.inkMuted,
    required this.primary,
    required this.primaryPressed,
    required this.primarySoft,
    required this.onPrimary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.reconcile,
    required this.neutral,
    required this.headerBackground,
    required this.onHeader,
    required this.onHeaderMuted,
  });

  final Brightness brightness;

  // Surfaces
  /// Scaffold body: a step off the surface, so cards float without a border.
  final Color background;
  final Color surface;

  /// Chips at rest, input fill, quick-fill pills.
  final Color surfaceMuted;

  /// Hairlines only: dividers, bar edges, input borders.
  final Color outline;

  // Ink
  final Color ink;
  final Color inkSecondary;

  /// Placeholders, footnotes, disabled text, inactive icons.
  final Color inkMuted;

  // Accent
  final Color primary;
  final Color primaryPressed;
  final Color primarySoft;
  final Color onPrimary;

  // Status
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color reconcile;
  final Color neutral;

  // Header
  final Color headerBackground;
  final Color onHeader;
  final Color onHeaderMuted;

  static const light = BCollectionPalette(
    brightness: Brightness.light,
    background: Color(0xFFF7F7F5),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1F1EE),
    outline: Color(0xFFE6E6E2),
    ink: Color(0xFF1C1C1E),
    inkSecondary: Color(0xFF5C5C60),
    inkMuted: Color(0xFF8E8E93),
    primary: Color(0xFF3452C7),
    primaryPressed: Color(0xFF2A43A6),
    primarySoft: Color(0xFFEAEEFB),
    onPrimary: Color(0xFFFFFFFF),
    success: Color(0xFF2E7D4F),
    warning: Color(0xFFC77700),
    danger: Color(0xFFB93838),
    info: Color(0xFF2F6FAE),
    reconcile: Color(0xFF6D4BB0),
    neutral: Color(0xFF6B6B70),
    headerBackground: Color(0xFF1F2A5C),
    onHeader: Color(0xFFFFFFFF),
    onHeaderMuted: Color(0xFFB8C0E0),
  );

  /// The same roles on a phone in dark mode: near-black surfaces a step
  /// apart, light ink, and the accent and status hues lifted so they read on
  /// dark. Where a status colour fills a badge, its text is the surface
  /// colour, which reads on the lifted hues as white did on the deep ones.
  static const dark = BCollectionPalette(
    brightness: Brightness.dark,
    background: Color(0xFF111113),
    surface: Color(0xFF1C1C1F),
    surfaceMuted: Color(0xFF26262A),
    outline: Color(0xFF34343A),
    ink: Color(0xFFF2F2F4),
    inkSecondary: Color(0xFFB9B9BF),
    inkMuted: Color(0xFF8C8C93),
    primary: Color(0xFF8EA2F2),
    primaryPressed: Color(0xFF7389E6),
    primarySoft: Color(0xFF252B45),
    onPrimary: Color(0xFF0F1530),
    success: Color(0xFF62BE88),
    warning: Color(0xFFE6A23C),
    danger: Color(0xFFE57373),
    info: Color(0xFF72A9E0),
    reconcile: Color(0xFFAB90E6),
    neutral: Color(0xFF9C9CA2),
    headerBackground: Color(0xFF161C3A),
    onHeader: Color(0xFFFFFFFF),
    onHeaderMuted: Color(0xFFAAB2D4),
  );

  ColorScheme get scheme => ColorScheme(
        brightness: brightness,
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

/// Colour tokens for the Collection department, from the palette in use:
/// the collector's choice from the Home toggle ([themeMode]), or the phone's
/// light/dark setting until they make one.
///
/// Read at build time, so they cannot be `const`. When the phone switches
/// mode the whole app is rebuilt (see [BCollectionTheme.applyFor]), so every
/// widget picks up the new set, whether it looks the theme up or not.
class BCollectionColors {
  BCollectionColors._();

  /// Tests set this to pin a palette; null follows the phone.
  @visibleForTesting
  static Brightness? debugBrightness;

  /// Light, dark, or (until the collector picks one) the phone's setting.
  /// Set through [BCollectionTheme.setMode], which also saves and applies it.
  static ThemeMode themeMode = ThemeMode.system;

  static bool get isDark {
    final pinned = debugBrightness;
    if (pinned != null) return pinned == Brightness.dark;
    return switch (themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        PlatformDispatcher.instance.platformBrightness == Brightness.dark,
    };
  }

  static BCollectionPalette get current =>
      isDark ? BCollectionPalette.dark : BCollectionPalette.light;

  // Surfaces
  static Color get background => current.background;
  static Color get surface => current.surface;
  static Color get surfaceMuted => current.surfaceMuted;
  static Color get outline => current.outline;

  // Ink
  static Color get ink => current.ink;
  static Color get inkSecondary => current.inkSecondary;
  static Color get inkMuted => current.inkMuted;

  // Accent
  static Color get primary => current.primary;
  static Color get primaryPressed => current.primaryPressed;
  static Color get primarySoft => current.primarySoft;
  static Color get onPrimary => current.onPrimary;

  // Status
  static Color get success => current.success;
  static Color get warning => current.warning;
  static Color get danger => current.danger;
  static Color get info => current.info;
  static Color get reconcile => current.reconcile;
  static Color get neutral => current.neutral;

  // Header
  static Color get headerBackground => current.headerBackground;
  static Color get onHeader => current.onHeader;
  static Color get onHeaderMuted => current.onHeaderMuted;

  static ColorScheme get scheme => current.scheme;
}

/// The Collection theme: the app theme with the Collection tokens applied.
///
/// Applied for the whole session once the user is known to be in Collection
/// (see [BCollectionTheme.applyFor]). A Collection user sees only Collection
/// screens plus Settings, so a session-wide swap is simpler and safer than
/// wrapping every pushed route.
class BCollectionTheme {
  BCollectionTheme._();

  static ThemeData get light =>
      _build(BAppTheme.lightTheme, BCollectionPalette.light);

  /// The Collection theme on a phone in dark mode. Without it, a dark phone
  /// got the app's plain black theme under Collection's light colours: white
  /// cards and fields on black, with the dark theme's white text on them.
  static ThemeData get dark =>
      _build(BAppTheme.darkTheme, BCollectionPalette.dark);

  static ThemeData _build(ThemeData base, BCollectionPalette c) {
    return base.copyWith(
      colorScheme: c.scheme,
      primaryColor: c.primary,
      scaffoldBackgroundColor: c.background,
      dividerColor: c.outline,
      textTheme: _textTheme(base.textTheme),
      // Every bar is the header navy, so a pushed page reads as part of the
      // same module as the tab it came from instead of dropping to a bare
      // grey page. The status bar is pinned light: Flutter would derive it
      // from the background anyway, but an off-white bar once turned the
      // clock and icons dark on the navy header, so it is stated outright.
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: c.headerBackground,
        foregroundColor: c.onHeader,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: c.onHeader, size: 24),
        actionsIconTheme: IconThemeData(color: c.onHeader, size: 24),
        titleTextStyle:
            base.appBarTheme.titleTextStyle?.copyWith(color: c.onHeader),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: c.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStatePropertyAll(c.primary),
          foregroundColor: WidgetStatePropertyAll(c.onPrimary),
          overlayColor:
              WidgetStatePropertyAll(c.onPrimary.withValues(alpha: 0.08)),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
          foregroundColor: WidgetStatePropertyAll(c.inkSecondary),
          side: WidgetStatePropertyAll(BorderSide(color: c.outline)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.primary),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: c.surfaceMuted,
        filled: true,
        prefixIconColor: c.inkMuted,
        suffixIconColor: c.inkMuted,
        hintStyle:
            base.inputDecorationTheme.hintStyle?.copyWith(color: c.inkMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? c.onPrimary : c.surface),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? c.primary : c.outline),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
    );
  }

  /// Collection's type ramp — the one place its text sizes are decided.
  ///
  /// The base scale is flat (every title 16, every body 14), so screens kept
  /// hand-tuning `fontSize` per widget, and each tweak fought the last. Here
  /// each role is a real step below the one above it; widgets pick a role
  /// and never a number, so the system font size scales all of it together.
  /// Body text stays at 14 — shrinking it made every list feel cramped.
  /// Only sizes change; weights and colours stay the base theme's.
  static TextTheme _textTheme(TextTheme base) => base.copyWith(
        titleLarge: base.titleLarge?.copyWith(fontSize: 18),
        titleMedium: base.titleMedium?.copyWith(fontSize: 16),
        titleSmall: base.titleSmall?.copyWith(fontSize: 14),
        bodySmall: base.bodySmall?.copyWith(fontSize: 12),
        labelSmall: base.labelSmall?.copyWith(fontSize: 11),
      );

  /// Switch the session theme to match the department. Idempotent; call it
  /// whenever the department becomes known (cold start, login, refresh).
  ///
  /// Both themes are set: the app follows the phone's light/dark setting and
  /// GetX keeps one theme for each. Only the light one used to be set, so a
  /// phone in dark mode never got the Collection theme at all.
  ///
  /// Safe to call from a build method: the swap is deferred to after the
  /// current frame, because changing the theme marks GetMaterialApp dirty
  /// and Flutter forbids that while it is already building (AppRouter
  /// calls this from build, and the red screen at login was exactly that).
  static void applyFor(String department) {
    final isCollection = department.trim().toLowerCase() == 'collection';
    _watchBrightness();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context == null) return;
      if (_appliedCollection == isCollection) return;
      _appliedCollection = isCollection;
      // Both set on the root controller, not through Get.changeTheme: that
      // files a theme under dark only once a dark theme is already set, so
      // the first call after start-up would put the dark theme in the light
      // slot and a light phone would turn dark.
      // The Home toggle is Collection's; everyone else follows the phone.
      BCollectionColors.themeMode =
          isCollection ? readSavedMode() : ThemeMode.system;
      Get.rootController
        ..theme = isCollection ? light : BAppTheme.lightTheme
        ..darkTheme = isCollection ? dark : BAppTheme.darkTheme
        ..themeMode = BCollectionColors.themeMode
        ..update();
    });
    // The callback waits for a frame; ask for one, or a call made while
    // nothing is redrawing (after login, say) would wait for the next tap.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  static bool? _appliedCollection;
  static _BrightnessWatcher? _watcher;

  /// Where the Home toggle's choice is kept: 'light' or 'dark'. Absent until
  /// the collector first taps it, and the phone's setting rules till then.
  static const String themeModeKey = 'collection.themeMode';

  /// The saved choice, or [ThemeMode.system] when there is none (or the
  /// storage cannot be read, as in some tests).
  static ThemeMode readSavedMode([Object? Function(String key)? read]) {
    try {
      final saved = (read ?? GetStorage().read)(themeModeKey);
      return switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      return ThemeMode.system;
    }
  }

  /// The Home toggle: use [mode] now and remember it on this phone.
  ///
  /// The whole app is rebuilt, because the Collection tokens are read, not
  /// inherited: a widget that never looks the theme up would otherwise keep
  /// the old colours.
  static void setMode(ThemeMode mode,
      {void Function(String key, Object value)? write}) {
    BCollectionColors.themeMode = mode;
    try {
      (write ?? GetStorage().write)(themeModeKey, mode.name);
    } catch (e) {
      logDebug('BCollectionTheme: theme choice not saved: $e');
    }
    if (Get.context == null) return;
    Get.rootController
      ..themeMode = mode
      ..update();
    rebuildAll();
  }

  /// Marks every widget in the app for rebuilding, so each reads the
  /// Collection tokens again (they are read, not inherited). Not
  /// Get.forceAppUpdate: that runs the hot-reload path, which also empties
  /// the image cache.
  static void rebuildAll() {
    void mark(Element element) {
      element.markNeedsBuild();
      element.visitChildren(mark);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(mark);
  }

  /// Forget the last [applyFor], so a test can apply again.
  @visibleForTesting
  static void debugReset() => _appliedCollection = null;

  /// The Collection tokens are read, not inherited, so a widget that never
  /// looks the theme up would keep the old colours when the phone switches
  /// mode. Rebuild the whole app then; it happens once per switch.
  static void _watchBrightness() {
    if (_watcher != null) return;
    _watcher = _BrightnessWatcher();
    WidgetsBinding.instance.addObserver(_watcher!);
  }
}

class _BrightnessWatcher with WidgetsBindingObserver {
  @override
  void didChangePlatformBrightness() {
    // Only the phone's setting changed; a pinned choice does not follow it.
    if (BCollectionColors.themeMode != ThemeMode.system) return;
    BCollectionTheme.rebuildAll();
  }
}
