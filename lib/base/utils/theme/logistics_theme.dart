import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';

/// The colour themes a Logistics user can pick in Settings → Theme: the same
/// five as Collection, in Logistics' own shades.
///
/// Logistics wears one colour, on the header and the main actions, so each
/// theme is that colour ([primary]) and a soft tint of it ([soft]) for tiles
/// and selected chips. None is green, amber, red or purple: those are the
/// priority and status colours (low, medium, high, rush; delivered, pending,
/// cancelled), and an accent in one of them would read as a status.
/// [ocean] is the original Logistics blue, and stays the default.
enum BLogisticsAccent {
  ocean('Ocean', primary: Color(0xFF4B68FF), soft: Color(0xFFF3F5FF)),
  teal('Teal', primary: Color(0xFF0F7C80), soft: Color(0xFFE2F2F2)),
  rose('Rose', primary: Color(0xFFB0306A), soft: Color(0xFFF8E6EE)),
  cocoa('Cocoa', primary: Color(0xFF8A5A3C), soft: Color(0xFFF3EBE5)),
  graphite('Graphite', primary: Color(0xFF3F4A5A), soft: Color(0xFFEAECEF));

  const BLogisticsAccent(this.label,
      {required this.primary, required this.soft});

  final String label;
  final Color primary;
  final Color soft;

  static BLogisticsAccent? fromName(Object? name) {
    for (final a in values) {
      if (a.name == name) return a;
    }
    return null;
  }
}

/// The Logistics choices in use: light or dark ([themeMode]) and the colour
/// theme ([accent]). [BColors.primary] reads [accent], so every Logistics
/// screen that uses the brand blue follows the pick.
///
/// Read at build time, so they cannot be `const`. A change rebuilds the
/// whole app (see [BLogisticsTheme.setAccent]).
class BLogisticsColors {
  BLogisticsColors._();

  /// Light, dark, or (until the user picks one) the phone's setting.
  /// Set through [BLogisticsTheme.setMode], which also saves and applies it.
  static ThemeMode themeMode = ThemeMode.system;

  /// The colour theme. Set through [BLogisticsTheme.setAccent].
  static BLogisticsAccent accent = BLogisticsAccent.ocean;

  /// Tests set this to pin a mode; null follows [themeMode].
  @visibleForTesting
  static Brightness? debugBrightness;

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

  static Color get primary => accent.primary;
  static Color get soft => accent.soft;
}

/// The Logistics theme: the app theme with the picked colour on the bars,
/// buttons and the Material accents (switches, progress, focused fields).
///
/// Applied for the session by [BCollectionTheme.applyFor] when the user is
/// not in Collection, which owns the root theme swap for both departments.
class BLogisticsTheme {
  BLogisticsTheme._();

  static ThemeData get light => themeFor(Brightness.light);
  static ThemeData get dark => themeFor(Brightness.dark);

  /// The app theme for [brightness] in [accent] (default: the one picked).
  static ThemeData themeFor(Brightness brightness, [BLogisticsAccent? accent]) {
    final a = accent ?? BLogisticsColors.accent;
    final base = brightness == Brightness.dark
        ? BAppTheme.darkTheme
        : BAppTheme.lightTheme;
    return base.copyWith(
      primaryColor: a.primary,
      colorScheme: base.colorScheme.copyWith(
        primary: a.primary,
        onPrimary: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? Colors.grey : a.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: a.primary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: a.primary),
    );
  }

  /// Where the mode is kept: 'light', 'dark' or 'system'. Absent until the
  /// user first picks one, and the phone's setting rules till then.
  static const String themeModeKey = 'logistics.themeMode';

  /// Where the colour theme is kept: an accent's name.
  static const String accentKey = 'logistics.accent';

  /// The saved mode, or [ThemeMode.system] when there is none (or the
  /// storage cannot be read, as in some tests).
  static ThemeMode readSavedMode([Object? Function(String key)? read]) {
    try {
      return switch ((read ?? GetStorage().read)(themeModeKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      return ThemeMode.system;
    }
  }

  /// The saved colour theme, or [BLogisticsAccent.ocean].
  static BLogisticsAccent readSavedAccent(
      [Object? Function(String key)? read]) {
    try {
      return BLogisticsAccent.fromName((read ?? GetStorage().read)(accentKey)) ??
          BLogisticsAccent.ocean;
    } catch (_) {
      return BLogisticsAccent.ocean;
    }
  }

  /// Settings → Theme: use [mode] now and remember it on this phone.
  static void setMode(ThemeMode mode,
      {void Function(String key, Object value)? write}) {
    BLogisticsColors.themeMode = mode;
    try {
      (write ?? GetStorage().write)(themeModeKey, mode.name);
    } catch (e) {
      logDebug('BLogisticsTheme: theme choice not saved: $e');
    }
    if (Get.context == null) return;
    Get.rootController
      ..themeMode = mode
      ..update();
    rebuildAll();
  }

  /// Settings → Theme: use [accent] now and remember it on this phone. Both
  /// themes are rebuilt in its colour, then the whole app, because
  /// [BColors.primary] is read, not inherited.
  static void setAccent(BLogisticsAccent accent,
      {void Function(String key, Object value)? write}) {
    BLogisticsColors.accent = accent;
    try {
      (write ?? GetStorage().write)(accentKey, accent.name);
    } catch (e) {
      logDebug('BLogisticsTheme: colour theme not saved: $e');
    }
    if (Get.context == null) return;
    Get.rootController
      ..theme = light
      ..darkTheme = dark
      ..update();
    rebuildAll();
  }

  /// Marks every widget in the app for rebuilding, so each reads the colours
  /// again. Not Get.forceAppUpdate: that also empties the image cache.
  static void rebuildAll() {
    void mark(Element element) {
      element.markNeedsBuild();
      element.visitChildren(mark);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(mark);
  }
}
