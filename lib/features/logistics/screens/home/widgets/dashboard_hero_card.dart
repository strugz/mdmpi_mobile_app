import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/pressable/b_pressable.dart';

/// One coloured slice of the [DashboardShareBar].
class ShareSegment {
  const ShareSegment({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

/// The focal card of the Home dashboard: the grand total in large type, a
/// tappable scope pill that opens the date filter, and a proportional bar of
/// the parts. When a module is selected, a back chip leads to All requests.
///
/// Pure widget, and free of `LayoutBuilder` so it reports an intrinsic height
/// (the one-screen Home layout measures it). The number crossfades with a
/// light blur when it changes; the bar animates its segment widths.
class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({
    super.key,
    required this.title,
    required this.total,
    required this.scopeLabel,
    required this.segments,
    this.accent = BColors.primary,
    this.icon,
    this.onScopeTap,
    this.onBack,
  });

  /// e.g. "All Requests" or the selected module's name.
  final String title;
  final int total;

  /// e.g. "All Time", "2026", "Sep 2026".
  final String scopeLabel;
  final List<ShareSegment> segments;
  final Color accent;
  final IconData? icon;

  /// Opens the date filter. The pill is inert when null.
  final VoidCallback? onScopeTap;

  /// Present when a module is selected; renders the back chip.
  final VoidCallback? onBack;

  static const String backLabel = 'All';

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textTheme = Theme.of(context).textTheme;
    final muted = dark ? BColors.darkGrey : BColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BSizes.md),
      decoration: BoxDecoration(
        color: dark ? BColors.dark : BColors.white,
        borderRadius: BorderRadius.circular(BSizes.cardRadiusLg + 4),
        border: Border.all(
          color: dark
              ? BColors.white.withValues(alpha: 0.08)
              : BColors.grey.withValues(alpha: 0.7),
        ),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: BColors.primary.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (onBack != null)
                _BackChip(accent: accent, dark: dark, onTap: onBack!)
              else if (icon != null)
                Container(
                  padding: const EdgeInsets.all(BSizes.sm - BSizes.xxs),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: dark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(BSizes.cardRadiusSm),
                  ),
                  child: Icon(icon, size: 16, color: accent),
                ),
              if (onBack != null || icon != null)
                const SizedBox(width: BSizes.sm),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge!.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: BSizes.sm),
              DateScopePill(label: scopeLabel, onTap: onScopeTap),
            ],
          ),
          const SizedBox(height: BSizes.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              _AnimatedCount(
                value: total,
                style: textTheme.displaySmall!.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1.05,
                  color: dark ? BColors.white : BColors.textPrimary,
                ),
              ),
              const SizedBox(width: BSizes.sm - BSizes.xxs),
              Text(
                total == 1 ? 'request' : 'requests',
                style: textTheme.bodySmall!.copyWith(color: muted),
              ),
            ],
          ),
          const SizedBox(height: BSizes.sm + BSizes.xs),
          DashboardShareBar(segments: segments),
        ],
      ),
    );
  }
}

class _BackChip extends StatelessWidget {
  const _BackChip({
    required this.accent,
    required this.dark,
    required this.onTap,
  });

  final Color accent;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BPressable(
      onTap: onTap,
      semanticLabel: 'Back to all requests',
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          BSizes.xs + BSizes.xxs,
          BSizes.xs + BSizes.xxs,
          BSizes.sm + BSizes.xxs,
          BSizes.xs + BSizes.xxs,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: dark ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(BSizes.cardRadiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.arrow_left_2, size: 14, color: accent),
            const SizedBox(width: BSizes.xxs),
            Text(
              DashboardHeroCard.backLabel,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The scope pill in the hero card header. Tapping it opens the date filter.
class DateScopePill extends StatelessWidget {
  const DateScopePill({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final fg = dark ? BColors.darkGrey : BColors.textSecondary;

    return BPressable(
      onTap: onTap,
      semanticLabel: 'Date filter: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BSizes.sm + BSizes.xxs,
          vertical: BSizes.xs + BSizes.xxs,
        ),
        decoration: BoxDecoration(
          color: dark ? BColors.white.withValues(alpha: 0.08) : BColors.softGrey,
          borderRadius: BorderRadius.circular(BSizes.cardRadiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.calendar_1, size: 13, color: fg),
            const SizedBox(width: BSizes.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: BSizes.xxs),
              Icon(Iconsax.arrow_down_1, size: 11, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}

/// Crossfades between integer values with a 2px blur to hide the overlap.
class _AnimatedCount extends StatelessWidget {
  const _AnimatedCount({required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.bottomLeft,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) {
        final blur = Tween<double>(begin: 2, end: 0).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: blur,
            builder: (_, child) => ImageFiltered(
              enabled: blur.value > 0.05,
              imageFilter: ImageFilter.blur(
                sigmaX: blur.value,
                sigmaY: blur.value,
              ),
              child: child,
            ),
            child: child,
          ),
        );
      },
      child: Text(
        '$value',
        key: ValueKey<int>(value),
        style: style,
      ),
    );
  }
}

/// A single-row proportional bar painted on a canvas. Segment widths animate
/// toward their new shares in 250ms; a zero total paints one muted track so
/// the card keeps its shape. No `LayoutBuilder`, so intrinsics stay valid.
class DashboardShareBar extends StatelessWidget {
  const DashboardShareBar({
    super.key,
    required this.segments,
    this.height = 8,
  });

  final List<ShareSegment> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final total = segments.fold<int>(0, (sum, s) => sum + s.count);
    final shares = [
      for (final s in segments) total == 0 ? 0.0 : s.count / total,
    ];
    final colors = [for (final s in segments) s.color];
    final track =
        dark ? BColors.white.withValues(alpha: 0.08) : BColors.softGrey;

    return TweenAnimationBuilder<List<double>>(
      tween: _SharesTween(end: shares),
      duration: const Duration(milliseconds: 250),
      curve: const Cubic(0.23, 1, 0.32, 1),
      builder: (_, animated, __) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _ShareBarPainter(
            shares: animated,
            colors: colors,
            track: track,
            radius: height / 2,
          ),
        ),
      ),
    );
  }
}

/// Lerps share lists element-wise; a missing element counts as zero.
class _SharesTween extends Tween<List<double>> {
  _SharesTween({super.end});

  @override
  List<double> lerp(double t) {
    final a = begin ?? const <double>[];
    final b = end ?? const <double>[];
    final length = a.length > b.length ? a.length : b.length;
    return List<double>.generate(length, (i) {
      final from = i < a.length ? a[i] : 0.0;
      final to = i < b.length ? b[i] : 0.0;
      return from + (to - from) * t;
    });
  }
}

class _ShareBarPainter extends CustomPainter {
  const _ShareBarPainter({
    required this.shares,
    required this.colors,
    required this.track,
    required this.radius,
  });

  final List<double> shares;
  final List<Color> colors;
  final Color track;
  final double radius;

  static const double _gap = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.clipRRect(rrect);

    final paint = Paint()..style = PaintingStyle.fill;
    final visible = shares.where((s) => s > 0.0005).length;
    if (visible == 0) {
      canvas.drawRect(Offset.zero & size, paint..color = track);
      return;
    }

    final usable = (size.width - _gap * (visible - 1)).clamp(0.0, size.width);
    var x = 0.0;
    var drawn = 0;
    for (var i = 0; i < shares.length && i < colors.length; i++) {
      final share = shares[i];
      if (share <= 0.0005) continue;
      final w = usable * share;
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint..color = colors[i]);
      x += w;
      drawn++;
      if (drawn < visible) x += _gap;
    }
  }

  @override
  bool shouldRepaint(_ShareBarPainter old) =>
      old.track != track ||
      old.radius != radius ||
      !_listEquals(old.shares, shares) ||
      !_listEquals(old.colors, colors);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
