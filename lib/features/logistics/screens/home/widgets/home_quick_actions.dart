import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/pressable/b_pressable.dart';
import 'package:mdmpi_mobile_app/data/controllers/navigation_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_bucket_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/request_form_navigator.dart';

/// "New request" shortcuts as a fixed grid of white tiles that sits inside the
/// Home header, so it is the first thing on the screen.
///
/// Four columns on phones (two rows), one row of eight from 600px. The eighth
/// tile, "All forms", opens the Request tab and fills the grid.
///
/// Type sizing: the label size is measured against the real tile width and the
/// viewer's text scale, then the largest size that fits every label in two
/// lines is used for all tiles at once. One size across the grid keeps the row
/// even; measuring keeps long labels like "Standard Delivery" from clipping on
/// a device with enlarged system text.
///
/// Built from plain rows, not a `GridView`, and with no `LayoutBuilder`, so the
/// header reports an intrinsic height: `SliverFillRemaining(hasScrollBody:
/// false)` calls `getMaxIntrinsicHeight` on the Home column, and a
/// `LayoutBuilder` there would throw. Widths therefore come from
/// `MediaQuery`, mirroring the padding the header applies.
///
/// Navigation is deliberately not animated: this is the action a courier
/// repeats most.
class HomeQuickActionGrid extends StatelessWidget {
  const HomeQuickActionGrid({
    super.key,
    required this.labels,
    required this.pages,
    required this.iconPaths,
    this.onOpen,
    this.onOpenAll,
    this.horizontalPadding = BSizes.defaultSpace * 2,
  });

  final List<String> labels;
  final List<Widget> pages;
  final List<String> iconPaths;

  /// Test seam; defaults to [RequestFormNavigator.open].
  final void Function(int index)? onOpen;

  /// Test seam; defaults to switching the nav shell to the Request tab.
  final VoidCallback? onOpenAll;

  /// Total horizontal padding the grid sits inside, used to derive tile width
  /// without a `LayoutBuilder`. Must match the header's own padding.
  final double horizontalPadding;

  static const String allFormsLabel = 'All forms';

  /// Index of the Request tab in the logistics nav shell.
  static const int _requestTabIndex = 1;

  static const double gap = BSizes.sm;

  static const int labelMaxLines = 2;
  static const double labelLineHeight = 1.2;
  static const double minLabelFontSize = 7.5;

  /// Used when the theme leaves `labelSmall.fontSize` unset, as this app's
  /// Poppins text theme does. The resolved size is always written back onto
  /// the style, so a tile never falls through to the ambient default size.
  static const double defaultLabelFontSize = 11;

  /// The grid is dense chrome, so very large system text is clamped here. The
  /// measured label size below still shrinks to fit within that ceiling.
  static const double maxTextScale = 1.3;

  static int columnsFor(double width) => width >= 600 ? 8 : 4;

  /// Width available to a tile's label, derived the same way the rows lay out.
  static double labelWidthFor(
    double screenWidth,
    int columns, {
    double horizontalPadding = BSizes.defaultSpace * 2,
  }) {
    final available = screenWidth - horizontalPadding - gap * (columns - 1);
    final tile = available / columns;
    return math.max(24.0, tile - QuickActionTile.horizontalPadding * 2);
  }

  /// Picks one type size and one box height for the whole grid.
  ///
  /// The size is the largest at or below [style]'s own size that renders every
  /// label within [maxWidth] in [labelMaxLines] lines at [textScaler]. The box
  /// height is then *measured* at that size rather than computed from
  /// `fontSize * lineHeight * lines`: a font's own ascent and descent can make
  /// a line taller than that formula predicts, which is what clipped the
  /// second line of "Standard Delivery" on a phone set to 1.25x text.
  static QuickActionLabelLayout resolveLabelLayout({
    required List<String> labels,
    required double maxWidth,
    required TextStyle style,
    required TextScaler textScaler,
  }) {
    final base = style.fontSize ?? defaultLabelFontSize;

    var fontSize = minLabelFontSize;
    for (var size = base; size > minLabelFontSize; size -= 0.5) {
      final candidate = style.copyWith(fontSize: size);
      final fits = labels.every(
        (label) => !_measure(label, maxWidth, candidate, textScaler).overflows,
      );
      if (fits) {
        fontSize = size;
        break;
      }
    }

    final resolved = style.copyWith(fontSize: fontSize);
    var boxHeight = 0.0;
    for (final label in labels) {
      boxHeight = math.max(
        boxHeight,
        _measure(label, maxWidth, resolved, textScaler).height,
      );
    }

    return QuickActionLabelLayout(
      style: resolved,
      boxHeight: boxHeight.ceilToDouble(),
    );
  }

  static ({bool overflows, double height}) _measure(
    String text,
    double maxWidth,
    TextStyle style,
    TextScaler textScaler,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: labelMaxLines,
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);
    final result = (
      overflows: painter.didExceedMaxLines || painter.width > maxWidth + 0.5,
      height: painter.height,
    );
    painter.dispose();
    return result;
  }

  Color _accentFor(int index) {
    final type = FormCategoryConstants.fromIndex(index);
    return type == null
        ? BColors.primary
        : DashboardBucketConfig.moduleAccent(type);
  }

  void _open(int index) {
    if (onOpen != null) {
      onOpen!(index);
      return;
    }
    RequestFormNavigator.open(index, pages);
  }

  void _openAll() {
    if (onOpenAll != null) {
      onOpenAll!();
      return;
    }
    if (Get.isRegistered<NavigationController>()) {
      Get.find<NavigationController>().changeScreen(_requestTabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final columns = columnsFor(media.size.width);
    final textScaler = media.textScaler.clamp(maxScaleFactor: maxTextScale);

    final baseStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
          fontWeight: FontWeight.w600,
          height: labelLineHeight,
          color: BColors.textPrimary,
        );
    final layout = resolveLabelLayout(
      labels: [...labels, allFormsLabel],
      maxWidth: labelWidthFor(
        media.size.width,
        columns,
        horizontalPadding: horizontalPadding,
      ),
      style: baseStyle,
      textScaler: textScaler,
    );

    final tiles = <Widget>[
      for (var i = 0; i < labels.length; i++)
        QuickActionTile(
          label: labels[i],
          accent: _accentFor(i),
          image: AssetImage(iconPaths[i]),
          labelStyle: layout.style,
          labelBoxHeight: layout.boxHeight,
          onTap: () => _open(i),
        ),
      QuickActionTile(
        label: allFormsLabel,
        accent: BColors.primary,
        icon: Iconsax.category,
        labelStyle: layout.style,
        labelBoxHeight: layout.boxHeight,
        onTap: _openAll,
      ),
    ];

    final rows = <Widget>[];
    for (var start = 0; start < tiles.length; start += columns) {
      final end = math.min(start + columns, tiles.length);
      final slice = tiles.sublist(start, end);
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < columns; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            Expanded(
              child: i < slice.length ? slice[i] : const SizedBox.shrink(),
            ),
          ],
        ],
      ));
    }

    // The measured size already accounts for the clamp; clamping the subtree
    // keeps any Text inside from re-applying the device's larger scale.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxTextScale,
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: gap),
            rows[r],
          ],
        ],
      ),
    );
  }
}

/// One shortcut tile: tinted icon badge above a label of at most two lines.
///
/// [labelStyle] and [labelBoxHeight] are resolved once by
/// [HomeQuickActionGrid] and shared by every tile, so the whole row uses one
/// type size and one height without the row needing to stretch (which would
/// need a bounded height the header does not have).
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.label,
    required this.accent,
    required this.onTap,
    this.image,
    this.icon,
    this.labelStyle,
    this.labelBoxHeight,
  }) : assert(image != null || icon != null, 'Provide an image or an icon');

  final String label;
  final Color accent;
  final VoidCallback onTap;
  final ImageProvider? image;
  final IconData? icon;

  /// Pre-resolved label style, sized to the tile by the grid.
  final TextStyle? labelStyle;

  /// Pre-resolved height of the label box, shared across the row.
  final double? labelBoxHeight;

  static const double horizontalPadding = BSizes.xs;
  static const double badgeSize = 32;

  /// Identifies the label box, so a test can assert the text is not clipped.
  static const Key labelBoxKey = Key('quick-action-label-box');

  @override
  Widget build(BuildContext context) {
    final fallback = HomeQuickActionGrid.resolveLabelLayout(
      labels: [label],
      maxWidth: HomeQuickActionGrid.labelWidthFor(
        MediaQuery.sizeOf(context).width,
        HomeQuickActionGrid.columnsFor(MediaQuery.sizeOf(context).width),
      ),
      style: Theme.of(context).textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.w600,
            height: HomeQuickActionGrid.labelLineHeight,
            color: BColors.textPrimary,
          ),
      textScaler: MediaQuery.textScalerOf(context)
          .clamp(maxScaleFactor: HomeQuickActionGrid.maxTextScale),
    );
    final style = labelStyle ?? fallback.style;
    final resolvedBoxHeight = labelBoxHeight ?? fallback.boxHeight;

    return BPressable(
      onTap: onTap,
      semanticLabel: 'New $label request',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: BSizes.sm,
        ),
        decoration: BoxDecoration(
          color: BColors.white,
          borderRadius: BorderRadius.circular(BSizes.cardRadiusMd + 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: badgeSize,
              height: badgeSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(BSizes.cardRadiusSm),
              ),
              child: image != null
                  ? Image(image: image!, width: 18, height: 18, color: accent)
                  : Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(height: BSizes.xs + BSizes.xxs),
            SizedBox(
              key: labelBoxKey,
              height: resolvedBoxHeight,
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: HomeQuickActionGrid.labelMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One resolved label style and box height, shared by every tile in a grid.
class QuickActionLabelLayout {
  const QuickActionLabelLayout({required this.style, required this.boxHeight});

  /// The label style with an explicit, fitted `fontSize`.
  final TextStyle style;

  /// Height that holds [HomeQuickActionGrid.labelMaxLines] rendered lines.
  final double boxHeight;
}
