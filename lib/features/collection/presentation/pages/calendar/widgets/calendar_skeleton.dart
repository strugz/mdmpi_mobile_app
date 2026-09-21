import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:shimmer/shimmer.dart';

/// The calendar while its first load is still running.
///
/// Without it the screen shows a full month with no marked days, which is
/// indistinguishable from a collector who did no work — the exact wrong thing
/// to say while their work is still being read.
///
/// The bones sit where the real content will: month title, the day-of-week
/// strip, five rows of day discs, then the day heading and two engagement
/// cards. There is deliberately no bone for the account chips — most days do
/// not have that row, and a bone that resolves to nothing is a promise the
/// screen does not keep.
class CalendarSkeleton extends StatelessWidget {
  const CalendarSkeleton({super.key});

  /// The bone fill and the sweep across it, matching the home skeleton: the
  /// base has to be darker than the off-white body or the bones vanish into
  /// it, and the highlight is the body colour so the sweep reads as light
  /// passing over rather than as a second shape.
  @visibleForTesting
  static const Color boneBase = BCollectionColors.outline;
  static const Color _boneHighlight = BCollectionColors.background;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Loading your calendar',
      child: ExcludeSemantics(
        child: Shimmer.fromColors(
          baseColor: boneBase,
          highlightColor: _boneHighlight,
          period: const Duration(milliseconds: 1400),
          // The bones are drawn at the live geometry, which on a short screen
          // is a few points taller than the space they are given. Scrollable
          // so they clip rather than paint an overflow stripe over the first
          // thing the collector sees; not scrollABLE by the reader, because
          // there is nothing down there to read.
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: BSizes.md),
                const Center(child: _Bone(height: 20, width: 160)),
                const SizedBox(height: BSizes.md),
                const _DayRow(size: 12, radius: 6, width: 24),
                const SizedBox(height: BSizes.sm),
                for (var row = 0; row < 5; row++) ...[
                  const _DayRow(size: 32, radius: 16, width: 32),
                  const SizedBox(height: BSizes.spaceBtwItemsLight),
                ],
                const SizedBox(height: BSizes.xs),
                const _Bone(height: 1),
                const Padding(
                  padding: EdgeInsets.fromLTRB(BSizes.defaultSpace, BSizes.md,
                      BSizes.defaultSpace, BSizes.sm),
                  child: _Bone(height: 20, width: 180),
                ),
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
                  child: Column(
                    children: [
                      _Bone(height: 96),
                      SizedBox(height: BSizes.spaceBtwItemsLight),
                      _Bone(height: 96),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Seven evenly spaced bones, the geometry of one week of the grid.
class _DayRow extends StatelessWidget {
  const _DayRow(
      {required this.size, required this.radius, required this.width});

  final double size;
  final double radius;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (var i = 0; i < 7; i++)
          _Bone(height: size, width: width, radius: radius),
      ],
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.height, this.width, this.radius = 6});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: CalendarSkeleton.boneBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
