import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';

/// A display bucket on the dashboard: one row aggregating one or more raw
/// request statuses for a given module.
class DashboardBucket {
  const DashboardBucket({
    required this.label,
    required this.icon,
    required this.accent,
    required this.statuses,
  });

  /// Row label shown on the dashboard (e.g. "For Delivery").
  final String label;

  final IconData icon;

  final Color accent;

  /// Raw status strings counted into this bucket, exactly as the API emits
  /// them. Matching is done case-insensitively (see [normalizeStatus]) to
  /// defuse casing drift such as "Getting supplies ready" vs
  /// "Getting Supplies Ready".
  final Set<String> statuses;

  /// True when [rawStatus] belongs to this bucket (case-insensitive).
  bool contains(String rawStatus) {
    final normalized = DashboardBucketConfig.normalizeStatus(rawStatus);
    return statuses
        .any((s) => DashboardBucketConfig.normalizeStatus(s) == normalized);
  }
}

/// Per-module dashboard configuration: status buckets, module accent colors,
/// and module icons. Pure lookup tables — no GetX — so invariants are
/// unit-testable.
class DashboardBucketConfig {
  DashboardBucketConfig._();

  /// Canonical status normalization used for all bucket matching.
  static String normalizeStatus(String status) => status.trim().toLowerCase();

  // Shared bucket accents (aligned with the request tile palette).
  static const Color _sky = Color(0xFF0EA5E9);
  static const Color _violet = Color(0xFF8B5CF6);
  static const Color _orange = Color(0xFFF57C00);
  static const Color _green = Color(0xFF2E9E6B);
  static const Color _rose = Color(0xFFE0507A);
  static const Color _indigo = Color(0xFF4B68FF);

  static const DashboardBucket _newRequest = DashboardBucket(
    label: BTexts.statusNewRequest,
    icon: Iconsax.receipt_text,
    accent: _sky,
    statuses: {BTexts.statusNewRequest},
  );

  static const DashboardBucket _cancelled = DashboardBucket(
    label: BTexts.statusCancelled,
    icon: Iconsax.close_circle,
    accent: BColors.error,
    statuses: {BTexts.statusCancelled},
  );

  /// Buckets shown when [module] is selected, in display order.
  static List<DashboardBucket> bucketsFor(FormCategoryType module) {
    switch (module) {
      case FormCategoryType.standardDelivery:
      case FormCategoryType.hotlineDirect:
        return const [
          _newRequest,
          DashboardBucket(
            label: 'Getting Supplies Ready',
            icon: Iconsax.box,
            accent: BColors.warning,
            statuses: {BTexts.statusGettingSuppliesReady},
          ),
          DashboardBucket(
            label: BTexts.statusItemPrepared,
            icon: Iconsax.box_tick,
            accent: _violet,
            statuses: {BTexts.statusItemPrepared},
          ),
          DashboardBucket(
            label: BTexts.statusForDelivery,
            icon: Iconsax.truck_fast,
            accent: BColors.info,
            statuses: {BTexts.statusForDelivery},
          ),
          DashboardBucket(
            label: BTexts.statusDoneDelivery,
            icon: Iconsax.tick_circle,
            accent: BColors.success,
            statuses: {BTexts.statusDoneDelivery},
          ),
          _cancelled,
        ];
      case FormCategoryType.pullOutReturn:
        return const [
          _newRequest,
          DashboardBucket(
            label: BTexts.statusForPullOut,
            icon: Iconsax.box_tick,
            accent: _violet,
            statuses: {BTexts.statusForPullOut},
          ),
          DashboardBucket(
            label: BTexts.statusInTransit,
            icon: Iconsax.truck_fast,
            accent: BColors.info,
            statuses: {BTexts.statusInTransit},
          ),
          DashboardBucket(
            label: BTexts.statusTakenOut,
            icon: Iconsax.box_remove,
            accent: _orange,
            statuses: {BTexts.statusTakenOut},
          ),
          _cancelled,
        ];
      case FormCategoryType.stockReceive:
        return const [
          _newRequest,
          DashboardBucket(
            label: BTexts.statusInTransit,
            icon: Iconsax.truck_fast,
            accent: BColors.info,
            statuses: {BTexts.statusInTransit},
          ),
          DashboardBucket(
            label: BTexts.statusTakenOut,
            icon: Iconsax.box_remove,
            accent: _orange,
            statuses: {BTexts.statusTakenOut},
          ),
          _cancelled,
        ];
      case FormCategoryType.pickUp:
        return const [
          _newRequest,
          DashboardBucket(
            label: 'Getting Supplies Ready',
            icon: Iconsax.box,
            accent: BColors.warning,
            statuses: {BTexts.statusGettingSuppliesReady},
          ),
          DashboardBucket(
            label: BTexts.statusItemPacked,
            icon: Iconsax.box_tick,
            accent: _violet,
            statuses: {BTexts.statusItemPacked},
          ),
          DashboardBucket(
            label: BTexts.statusReceived,
            icon: Iconsax.tick_circle,
            accent: BColors.success,
            statuses: {BTexts.statusReceived},
          ),
          _cancelled,
        ];
      case FormCategoryType.airSea:
        return const [
          _newRequest,
          DashboardBucket(
            label: 'Preparing',
            icon: Iconsax.box,
            accent: BColors.warning,
            statuses: {
              BTexts.statusGettingSuppliesReady,
              BTexts.statusItemPacked,
              BTexts.statusEndorsedToGuard,
              BTexts.statusForDispatch,
            },
          ),
          DashboardBucket(
            label: BTexts.statusInTransit,
            icon: Iconsax.truck_fast,
            accent: BColors.info,
            statuses: {
              BTexts.statusDispatch,
              BTexts.statusProvincialPickUp,
              BTexts.statusProvincialInTransit,
            },
          ),
          DashboardBucket(
            label: 'Completed',
            icon: Iconsax.tick_circle,
            accent: BColors.success,
            statuses: {
              BTexts.statusDropOff,
              BTexts.statusReceived,
              BTexts.statusProvincialDelivered,
            },
          ),
          _cancelled,
        ];
    }
  }

  /// Accent color per module — mirrors the request shortcut tile palette.
  static Color moduleAccent(FormCategoryType module) {
    switch (module) {
      case FormCategoryType.standardDelivery:
        return _indigo;
      case FormCategoryType.pullOutReturn:
        return _orange;
      case FormCategoryType.pickUp:
        return _green;
      case FormCategoryType.airSea:
        return _sky;
      case FormCategoryType.hotlineDirect:
        return _rose;
      case FormCategoryType.stockReceive:
        return _violet;
    }
  }

  /// Icon per module for the "All Requests" view rows.
  static IconData moduleIcon(FormCategoryType module) {
    switch (module) {
      case FormCategoryType.standardDelivery:
        return Iconsax.truck_fast;
      case FormCategoryType.pullOutReturn:
        return Iconsax.box_remove;
      case FormCategoryType.pickUp:
        return Iconsax.box_1;
      case FormCategoryType.airSea:
        return Iconsax.airplane;
      case FormCategoryType.hotlineDirect:
        return Iconsax.call;
      case FormCategoryType.stockReceive:
        return Iconsax.box_add;
    }
  }
}
