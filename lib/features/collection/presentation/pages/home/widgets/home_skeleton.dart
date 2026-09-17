import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:shimmer/shimmer.dart';

/// The home dashboard while its first load is still running.
///
/// On the first login the bucket comes from the server and the screen used to
/// sit for a few seconds showing "₱0.00", "No items in bucket" and "No
/// engagement history yet", which reads as an empty account rather than a
/// loading one. This draws the dashboard's blocks as grey bones in their
/// real positions and sizes, under one shimmer so they breathe together, and
/// the real content crossfades in over the top when the data lands.
///
/// Same layout as the live dashboard: a padded column of blocks, then a
/// white panel that takes the remaining height.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({
    super.key,
    required this.margin,
    required this.gap,
    required this.sectionGap,
    required this.historyCardHeight,
  });

  final double margin;
  final double gap;
  final double sectionGap;
  final double historyCardHeight;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: BCollectionColors.surfaceMuted,
      highlightColor: BCollectionColors.surface,
      period: const Duration(milliseconds: 1400),
      // Same fit recipe as the live dashboard: the panel takes the rest of
      // the height, and a viewport shorter than the bones clips quietly
      // instead of overflowing.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: margin),
                    child: Column(
                      children: [
                        const _Bone(height: 100),
                        SizedBox(height: gap),
                        const _Bone(height: 90),
                        SizedBox(height: gap),
                        Row(
                          children: const [
                            Expanded(child: _Bone(height: 44)),
                            SizedBox(width: BSizes.spaceBtwItemsLight),
                            Expanded(child: _Bone(height: 44)),
                          ],
                        ),
                        SizedBox(height: sectionGap),
                        const _Bone(height: 104),
                        const SizedBox(height: BSizes.sm),
                        const _Bone(height: 6, width: 40, radius: 3),
                        SizedBox(height: sectionGap),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: BCollectionColors.surface,
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(BSizes.borderRadiusLg)),
                      ),
                      padding:
                          EdgeInsets.fromLTRB(margin, BSizes.md, margin, 0),
                      child: Column(
                        children: [
                          Row(
                            children: const [
                              _Bone(height: 20, width: 180, radius: 6),
                              Spacer(),
                              _Bone(height: 14, width: 60, radius: 6),
                            ],
                          ),
                          const SizedBox(height: BSizes.md),
                          _Bone(height: historyCardHeight),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.height,
    this.width = double.infinity,
    this.radius = BSizes.cardRadiusMd,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    // The colour is only a mask for the shimmer gradient; any opaque fill.
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: BCollectionColors.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
