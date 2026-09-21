import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// Central status color & icon mapping for collection.
class CollectionStatusColors {
  CollectionStatusColors._();

  // Note: 'Pending' and 'On-going' have been removed from the visible status set.
  // Keep only outcome (user-selectable) statuses here.

  // ─── Outcome Statuses (User Selectable) ─────────────────────────────
  static const String statusCollected = 'Collected';
  static const String statusPartial = 'Partially Collected';
  static const String statusPreCollection = 'Pre-Collection';
  static const String statusFollowUp = 'Follow Up';
  static const String statusUnavailable = 'Customer Unavailable';
  static const String statusRefused = 'Refused to Pay';
  static const String statusOthers = 'Others';

  // ─── Global Process Statuses ────────────────────────────────────────
  static const String statusDeposit = 'Deposit';
  static const String statusCWTPickup = 'CWT Pick-up';
  static const String statusReconciliation = 'Reconciliation';

  static const List<String> allStatuses = [
    statusCollected,
    statusPartial,
    statusPreCollection,
    statusFollowUp,
    statusUnavailable,
    statusRefused,
    statusOthers,
    statusDeposit,
    statusCWTPickup,
    statusReconciliation,
  ];

  /// Statuses that a user can manually select in the update screen.
  static const List<String> updatableStatuses = [
    statusCollected,
    statusPartial,
    statusPreCollection,
    statusOthers,
  ];

  /// Returns a tuple of (background, foreground) colours for the given [status].
  static (Color bg, Color fg) colorsFor(String status,
      {bool darkMode = false}) {
    final s = status.trim();
    Color bg;
    Color fg = BCollectionColors.surface;

    switch (s) {
      case statusCollected:
        bg = BCollectionColors.success;
        break;
      case statusPartial:
        bg = BCollectionColors.warning;
        break;
      case statusPreCollection:
        bg = BCollectionColors.primary;
        break;
      case statusFollowUp:
        bg = BCollectionColors.info;
        break;
      case statusRefused:
        bg = BCollectionColors.danger;
        break;
      case statusUnavailable:
        bg = BCollectionColors.warning;
        break;
      case statusOthers:
        bg = BCollectionColors.neutral;
        break;
      case statusDeposit:
        bg = BCollectionColors.info;
        break;
      case statusCWTPickup:
        bg = BCollectionColors.warning;
        break;
      case statusReconciliation:
        bg = BCollectionColors.reconcile;
        break;
      default:
        bg = darkMode
            ? BCollectionColors.inkSecondary
            : BCollectionColors.surfaceMuted;
        fg = darkMode
            ? BCollectionColors.surfaceMuted
            : BCollectionColors.inkMuted;
    }

    return (bg, fg);
  }

  static (Color bg, Color fg) colorsForAuto(
      BuildContext context, String status) {
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
      case statusPreCollection:
        return Iconsax.calendar_tick;
      case statusFollowUp:
        return Iconsax.info_circle;
      case statusRefused:
        return Iconsax.warning_2;
      case statusUnavailable:
        return Iconsax.clock;
      case statusOthers:
        return Iconsax.edit;
      case statusDeposit:
        return Iconsax.bank;
      case statusCWTPickup:
        return Iconsax.document_text;
      case statusReconciliation:
        return Iconsax.status_up;
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
