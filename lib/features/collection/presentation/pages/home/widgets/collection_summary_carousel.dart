import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/cards/collection_summary_card.dart';

/// One summary tile of the carousel. [value] is read on every build so a
/// reactive wrapper (Obx) around the carousel keeps the figure live.
class CollectionSummaryPage {
  const CollectionSummaryPage({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

/// Horizontal carousel of [CollectionSummaryCard]s with a mirror transition.
///
/// The card being swiped away turns on its vertical axis until it is edge-on,
/// and the next card turns in from the opposite side, like a panel flipping to
/// show its mirror face. The angle is driven by the scroll offset, so the
/// gesture can be reversed or interrupted at any point and the card simply
/// follows the finger. With system animations disabled the turn is replaced by
/// a plain crossfade so nothing swings.
class CollectionSummaryCarousel extends StatefulWidget {
  const CollectionSummaryCarousel({
    super.key,
    required this.pages,
    this.height = 104,
    this.initialPage = 0,
  });

  final List<CollectionSummaryPage> pages;

  /// PageView needs a bounded height inside the dashboard's scroll view.
  final double height;
  final int initialPage;

  /// Neighbours peek in slightly so the row still reads as swipeable.
  static const double viewportFraction = 0.92;

  /// A full quarter turn per page: at one page away the card is edge-on.
  static const double _maxTurn = math.pi / 2;

  /// Perspective entry (row 3, column 2) of the turn matrix: near faces grow,
  /// far faces shrink. Also what tells this transform apart from the
  /// press-scale one inside the card.
  static const double perspective = 0.0015;

  @override
  State<CollectionSummaryCarousel> createState() =>
      _CollectionSummaryCarouselState();
}

class _CollectionSummaryCarouselState extends State<CollectionSummaryCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: CollectionSummaryCarousel.viewportFraction,
    initialPage: widget.initialPage,
  );
  late int _current = widget.initialPage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Signed distance of [index] from the current scroll position, in pages.
  /// Falls back to the integer page before the first layout.
  double _delta(int index) {
    if (_controller.hasClients && _controller.position.haveDimensions) {
      return index - (_controller.page ?? _current.toDouble());
    }
    return (index - _current).toDouble();
  }

  Widget _mirror(BuildContext context, Widget child, int index) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delta = _delta(index).clamp(-1.0, 1.0);
        final progress = delta.abs();
        // Fade the edge-on card out so a hairline never shows through.
        final opacity = (1 - progress * 1.15).clamp(0.0, 1.0);

        if (reduceMotion) {
          return Opacity(opacity: opacity, child: child);
        }

        final shrink = 1 - progress * 0.06;
        final matrix = Matrix4.identity()
          ..setEntry(
              3,
              2,
              CollectionSummaryCarousel
                  .perspective) // near faces grow, far shrink
          ..rotateY(-delta * CollectionSummaryCarousel._maxTurn)
          ..scaleByDouble(shrink, shrink, 1, 1);

        return Transform(
          transform: matrix,
          alignment: Alignment.center,
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            physics: const PageScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: widget.pages.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final page = widget.pages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _mirror(
                  context,
                  CollectionSummaryCard(
                    title: page.title,
                    value: page.value,
                    icon: page.icon,
                    color: page.color,
                    onTap: page.onTap,
                  ),
                  index,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: BSizes.sm),
        _Dots(
          count: widget.pages.length,
          current: _current,
          color: widget.pages[_current].color,
          onTap: (i) => _controller.animateToPage(
            i,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.current,
    required this.color,
    required this.onTap,
  });

  final int count;
  final int current;
  final Color color;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? color : BColors.grey,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }
}
