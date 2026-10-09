import 'package:flutter/material.dart';

class BElevatedButtonTheme {
  BElevatedButtonTheme._();

  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
    elevation: 0,
    foregroundColor: Colors.white,
    backgroundColor: Colors.blue,
    disabledForegroundColor: Colors.grey,
    disabledBackgroundColor: Colors.grey,
    // No border: a filled button's edge is its fill. A border fixed to blue
    // showed as a stray outline wherever a theme recolours the fill
    // (Collection's navy buttons).
    side: BorderSide.none,
    // Side padding so a button sized to its label does not run the label
    // into its edges; full-width buttons are unaffected.
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
    textStyle: const TextStyle(
        fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ));
  static final darkElevatedButtonTheme = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
    elevation: 0,
    foregroundColor: Colors.white,
    backgroundColor: Colors.blue,
    disabledForegroundColor: Colors.grey,
    disabledBackgroundColor: Colors.grey,
    // No border: a filled button's edge is its fill. A border fixed to blue
    // showed as a stray outline wherever a theme recolours the fill
    // (Collection's navy buttons).
    side: BorderSide.none,
    // Side padding so a button sized to its label does not run the label
    // into its edges; full-width buttons are unaffected.
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
    textStyle: const TextStyle(
        fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ));
}
