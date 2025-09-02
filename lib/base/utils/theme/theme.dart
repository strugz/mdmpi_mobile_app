import 'package:flutter/material.dart';

import 'custom_themes/appbar_theme.dart';
import 'custom_themes/bottom_sheet_theme.dart';
import 'custom_themes/checkbox_theme.dart';
import 'custom_themes/chip_theme.dart';
import 'custom_themes/elevated_button_theme.dart';
import 'custom_themes/outlined_botton_theme.dart';
import 'custom_themes/text_field_theme.dart';
import 'custom_themes/text_theme.dart';

class BAppTheme {
  BAppTheme._();
  static ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: Brightness.light,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      textTheme: BTextTheme.lightTextTheme,
      elevatedButtonTheme: BElevatedButtonTheme.lightElevatedButtonTheme,
      appBarTheme: BAppBarTheme.lightAppBarTheme,
      bottomSheetTheme: BBottomSheetTheme.lightBottomSheetTheme,
      checkboxTheme: BCheckBoxTheme.lightCheckBoxTheme,
      chipTheme: BChipTheme.lightChipTheme,
      outlinedButtonTheme: BOutLinedButtonTheme.lightOutLinedButtonTheme,
      inputDecorationTheme: BTextFormFieldTheme.lightInputDecorationTheme);
  static ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: Brightness.dark,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.black,
      textTheme: BTextTheme.darkTextTheme,
      elevatedButtonTheme: BElevatedButtonTheme.darkElevatedButtonTheme,
      appBarTheme: BAppBarTheme.darkAppBarTheme,
      bottomSheetTheme: BBottomSheetTheme.darkBottomSheetTheme,
      checkboxTheme: BCheckBoxTheme.darkCheckBoxTheme,
      chipTheme: BChipTheme.darkChipTheme,
      outlinedButtonTheme: BOutLinedButtonTheme.darkOutLinedButtonTheme,
      inputDecorationTheme: BTextFormFieldTheme.darkInputDecorationTheme);
}
