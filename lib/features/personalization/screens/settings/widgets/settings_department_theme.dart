import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Status colours for Settings, per department: Collection's muted tokens, or
/// the app's standard green/orange/red for Logistics.
@immutable
class SettingsStatusColors extends ThemeExtension<SettingsStatusColors> {
  const SettingsStatusColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.canvas,
  });

  final Color success;
  final Color warning;
  final Color danger;

  /// Page background behind white cards: Collection's warm off-white, or a
  /// cool tint of the Logistics blue.
  final Color canvas;

  static const collection = SettingsStatusColors(
    success: BCollectionColors.success,
    warning: BCollectionColors.warning,
    danger: BCollectionColors.danger,
    canvas: BCollectionColors.background,
  );

  static const logistics = SettingsStatusColors(
    success: BColors.success,
    warning: BColors.warning,
    danger: BColors.error,
    canvas: Color(0xFFF1F4FA),
  );

  /// The colours in scope, falling back to Logistics outside Settings.
  static SettingsStatusColors of(BuildContext context) =>
      Theme.of(context).extension<SettingsStatusColors>() ?? logistics;

  @override
  SettingsStatusColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? canvas,
  }) =>
      SettingsStatusColors(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        canvas: canvas ?? this.canvas,
      );

  @override
  SettingsStatusColors lerp(SettingsStatusColors? other, double t) {
    if (other == null) return this;
    return SettingsStatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
    );
  }
}

/// Settings is the one screen both departments share, so it wears the
/// signed-in user's: the Collection theme for Collection, the Logistics blue
/// for everyone else.
///
/// The app-wide Logistics theme sets no colour scheme, so Material's default
/// purple leaked into the switch and the Hard Reset card while the icons were
/// hard-coded blue. [logistics] seeds the scheme from [BColors.primary] so
/// every accent in Settings is the same blue.
class SettingsDepartmentTheme extends StatelessWidget {
  const SettingsDepartmentTheme({super.key, required this.child});

  final Widget child;

  static bool isCollection(String department) =>
      department.trim().toLowerCase() == 'collection';

  static final ThemeData collection = BCollectionTheme.light.copyWith(
    extensions: const [SettingsStatusColors.collection],
  );

  static final ThemeData logistics = BAppTheme.lightTheme.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: BColors.primary,
      primary: BColors.primary,
      onPrimary: Colors.white,
      surface: Colors.white,
    ),
    extensions: const [SettingsStatusColors.logistics],
  );

  static ThemeData forDepartment(String department) =>
      isCollection(department) ? collection : logistics;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UserController>()) {
      return Theme(data: logistics, child: child);
    }
    final user = Get.find<UserController>().user;
    return Obx(
      () => Theme(data: forDepartment(user.value.department), child: child),
    );
  }
}
