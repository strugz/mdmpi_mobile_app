import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// Central status color & icon mapping for collection role categories and sub-roles.
class CollectionStatusColors {
  CollectionStatusColors._();

  // ─── Role Categories ───────────────────────────────────────────────
  static const String categoryCoreFlow = 'Core Flow';
  static const String categoryDelays = 'Delays';
  static const String categoryOutcomes = 'Outcomes';
  static const String categoryAdministrative = 'Administrative';

  static const List<String> categories = [
    categoryCoreFlow,
    categoryDelays,
    categoryOutcomes,
    categoryAdministrative,
  ];

  // ─── Sub-roles: Core Flow ──────────────────────────────────────────
  static const String statusUnassigned = 'Unassigned';
  static const String statusAssigned = 'Assigned';
  static const String statusOngoing = 'On-going';

  // ─── Sub-roles: Delays ─────────────────────────────────────────────
  static const String statusBehindSchedule = 'Behind Schedule';
  static const String statusRescheduled = 'Rescheduled';

  // ─── Sub-roles: Outcomes ───────────────────────────────────────────
  static const String statusFullyCollected = 'Fully Collected';
  static const String statusPartiallyCollected = 'Partially Collected';
  static const String statusFailedCollection = 'Failed Collection';
  static const String statusCustomerUnavailable = 'Customer Unavailable';
  static const String statusRefusedToPay = 'Refused to Pay';

  // ─── Sub-roles: Administrative ─────────────────────────────────────
  static const String statusCancelled = 'Cancelled';
  static const String statusOnHold = 'On Hold';
  static const String statusForVerification = 'For Verification';

  /// Returns the list of sub-roles for a given category.
  static List<String> subRolesFor(String category) {
    switch (category) {
      case categoryCoreFlow:
        return [statusUnassigned, statusAssigned, statusOngoing];
      case categoryDelays:
        return [statusBehindSchedule, statusRescheduled];
      case categoryOutcomes:
        return [
          statusFullyCollected,
          statusPartiallyCollected,
          statusFailedCollection,
          statusCustomerUnavailable,
          statusRefusedToPay,
        ];
      case categoryAdministrative:
        return [statusCancelled, statusOnHold, statusForVerification];
      default:
        return [];
    }
  }

  // ─── Colour mapping ─────────────────────────────────────────────────

  /// Returns a tuple of (background, foreground) colours for the given [status].
  static (Color bg, Color fg) colorsFor(String status, {bool darkMode = false}) {
    final s = status.trim();
    Color bg;
    Color fg = BColors.white;

    switch (s) {
    // Core Flow
      case statusUnassigned:
        bg = BColors.darkerGrey;
        break;
      case statusAssigned:
        bg = BColors.primary;
        break;
      case statusOngoing:
        bg = Colors.orange;
        break;

    // Delays
      case statusBehindSchedule:
        bg = BColors.error;
        break;
      case statusRescheduled:
        bg = Colors.purple;
        break;

    // Outcomes
      case statusFullyCollected:
        bg = BColors.success;
        break;
      case statusPartiallyCollected:
        bg = Colors.lightGreen;
        break;
      case statusFailedCollection:
      case statusRefusedToPay:
        bg = BColors.error;
        break;
      case statusCustomerUnavailable:
        bg = Colors.amber;
        break;

    // Administrative
      case statusCancelled:
        bg = Colors.grey;
        break;
      case statusOnHold:
        bg = Colors.blueGrey;
        break;
      case statusForVerification:
        bg = Colors.cyan;
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
      case statusFullyCollected:
      case statusOngoing:
        return Iconsax.tick_circle;
      case statusBehindSchedule:
      case statusFailedCollection:
        return Iconsax.warning_2;
      case statusUnassigned:
      case statusOnHold:
        return Iconsax.clock;
      case statusAssigned:
        return Iconsax.user_tick;
      case statusRescheduled:
        return Iconsax.calendar_tick;
      case statusForVerification:
        return Iconsax.document_filter;
      case statusCancelled:
        return Iconsax.close_circle;
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