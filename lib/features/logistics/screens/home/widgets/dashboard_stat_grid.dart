import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/pressable/b_pressable.dart';
import 'package:shimmer/shimmer.dart';

/// Data for one tile of the [DashboardStatGrid].
class DashboardStat {
  const DashboardStat({
    required this.label,
    required this.count,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color accent;

  /// Present when the tile drills into something (e.g. a module).
  final VoidCallback? onTap;
}

/// A grid of stat tiles that fills whatever height it is given.
///
/// Built from rows of `Expanded` tiles rather than a `GridView`, for two
/// reasons: the rows stretch to share the available height (so Home fits one
/// screen), and the grid reports an intrinsic height (its minimum), which the
/// one-screen layout uses to decide when it must fall back to scrolling.
///
/// Three columns on phones, four from 600px. The grid swaps with a fade and
/// rise when [switchKey] changes; tiles stagger in 40ms apart. Stagger is
/// decorative and never blocks taps.
class DashboardStatGrid extends StatelessWidget {
  const DashboardStatGrid({
    super.key,
    required this.stats,
    required this.switchKey,
  });

  final List<DashboardStat> stats;

  /// Identifies the current data set (e.g. the selected module) so a filter
  /// change animates while a same-view count update does not.
  final Object switchKey;

  static int columnsFor(double width) => width >= 600 ? 4 : 3;

  static const double gap = BSizes.sm + BSizes.xs;

  @override
  Widget build(BuildContext context) {
    final columns = columnsFor(MediaQuery.sizeOf(context).width);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        fit: StackFit.passthrough,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: _TileRows(
        key: ValueKey<Object>(switchKey),
        columns: columns,
        children: [
          for (var i = 0; i < stats.length; i++)
            _Staggered(index: i, child: DashboardStatCard(stat: stats[i])),
        ],
      ),
    );
  }
}

/// Lays [children] out in equal-width, equal-height rows of [columns].
class _TileRows extends StatelessWidget {
  const _TileRows({super.key, required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final end = (start + columns).clamp(0, children.length);
      final slice = children.sublist(start, end);
      rows.add(Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < columns; i++) ...[
              if (i > 0) const SizedBox(width: DashboardStatGrid.gap),
              Expanded(
                child: i < slice.length ? slice[i] : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ));
    }

    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: DashboardStatGrid.gap),
          rows[r],
        ],
      ],
    );
  }
}

/// One stat tile: icon badge and count on the first line, label below, and a
/// thin accent stripe on the left. Grows with the row; content sits at the
/// bottom when there is spare height.
class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({super.key, required this.stat});

  final DashboardStat stat;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textTheme = Theme.of(context).textTheme;

    return BPressable(
      onTap: stat.onTap,
      semanticLabel: '${stat.label}: ${stat.count}',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: dark ? BColors.dark : BColors.white,
          borderRadius: BorderRadius.circular(BSizes.cardRadiusLg),
          border: Border.all(
            color: dark
                ? BColors.white.withValues(alpha: 0.08)
                : BColors.grey.withValues(alpha: 0.7),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: stat.accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BSizes.sm + BSizes.xs,
                BSizes.sm,
                BSizes.sm,
                BSizes.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              stat.accent.withValues(alpha: dark ? 0.22 : 0.12),
                          borderRadius:
                              BorderRadius.circular(BSizes.cardRadiusXs + 1),
                        ),
                        child: Icon(stat.icon, size: 14, color: stat.accent),
                      ),
                      const Spacer(),
                      Text(
                        '${stat.count}',
                        style: textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1,
                          letterSpacing: -0.5,
                          color: dark ? BColors.white : BColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BSizes.xs),
                  Text(
                    stat.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall!.copyWith(
                      height: 1.2,
                      color: dark ? BColors.darkGrey : BColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholders shaped like the hero card and the stat grid, so the
/// layout does not shift when the numbers arrive. Fills the height it is
/// given, like the real content.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key, this.rows = 3});

  final int rows;

  /// Matches the rendered hero card so the swap does not jump.
  static const double heroHeight = 124;

  /// The least a placeholder tile will shrink to, mirroring a real tile.
  static const double minTileHeight = 72;

  @override
  Widget build(BuildContext context) {
    final columns = DashboardStatGrid.columnsFor(MediaQuery.sizeOf(context).width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: heroHeight,
          child: _ShimmerBox(radius: BSizes.cardRadiusLg + 4),
        ),
        const SizedBox(height: BSizes.sm + BSizes.xs),
        Expanded(
          child: Column(
            children: [
              for (var r = 0; r < rows; r++) ...[
                if (r > 0) const SizedBox(height: DashboardStatGrid.gap),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var c = 0; c < columns; c++) ...[
                        if (c > 0) const SizedBox(width: DashboardStatGrid.gap),
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                minHeight: minTileHeight),
                            child: const _ShimmerBox(
                                radius: BSizes.cardRadiusLg),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return Shimmer.fromColors(
      baseColor: dark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: dark ? Colors.grey[700]! : Colors.grey[100]!,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dark ? BColors.darkerGrey : BColors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Fades and rises a child in, delayed by [index] × 40ms.
class _Staggered extends StatefulWidget {
  const _Staggered({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_Staggered> createState() => _StaggeredState();
}

class _StaggeredState extends State<_Staggered>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 40 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
