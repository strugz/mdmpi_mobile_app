import 'dart:math' as math;

import 'package:flutter/gestures.dart';
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
/// The carousel loops: swiping past the last card brings the first one back,
/// and swiping back from the first shows the last. The PageView runs over an
/// unbounded virtual index that starts far from zero; the real card is
/// `virtual % pages.length`.
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
  /// Virtual start, far enough from zero that a user never reaches the
  /// front edge by swiping backwards. A multiple of the page count keeps the
  /// modulo lined up with the real index.
  late final int _origin = widget.pages.length * 10000 + widget.initialPage;

  late final PageController _controller = PageController(
    viewportFraction: CollectionSummaryCarousel.viewportFraction,
    initialPage: _origin,
  );

  /// Virtual page the PageView reports as current.
  late int _current = _origin;

  int get _pageCount => widget.pages.length;

  /// Real card index for a virtual page.
  int _real(int virtual) => virtual % _pageCount;

  CollectionSummaryPage _pageAt(int virtual) => widget.pages[_real(virtual)];

  /// A tap that begins while the page is still settling. Scrollable wraps
  /// its children in IgnorePointer for the whole ballistic settle, so the
  /// card underneath never sees the tap. This Listener sits outside the
  /// PageView, so it does; on a clean release it opens the current card.
  int? _settlingPointer;
  Offset? _settlingDown;

  /// The card mostly on screen when the tap began. [_current] lags until the
  /// scroll passes the halfway mark, so it cannot be used here.
  int? _settlingTarget;

  /// True when pointer-down interrupted a settle. The scrollable's own drag
  /// recogniser has already put the position on hold by the time this runs,
  /// and a hold does not count as scrolling, so the scroll flag is useless
  /// here. A finished settle always lands on a whole page; an interrupted one
  /// is frozen at a fraction.
  bool get _isSettling {
    if (!_controller.hasClients) return false;
    final page = _controller.page;
    return page != null && page != page.roundToDouble();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_settlingPointer != null || !_isSettling) return;
    _settlingPointer = event.pointer;
    _settlingDown = event.position;
    _settlingTarget = _controller.page!.round();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _settlingPointer) return;
    final moved = (event.position - _settlingDown!).distance;
    final target = _settlingTarget!;
    _settlingPointer = null;
    _settlingDown = null;
    _settlingTarget = null;
    if (moved <= kTouchSlop) _pageAt(target).onTap?.call();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _settlingPointer) return;
    _settlingPointer = null;
    _settlingDown = null;
    _settlingTarget = null;
  }

  /// The virtual page for real index [real] that is closest to the current
  /// one, so a dot tap turns the short way round the loop.
  int _nearestVirtual(int real) {
    final forward = (real - _real(_current)) % _pageCount;
    final backward = forward - _pageCount;
    return _current + (forward <= -backward ? forward : backward);
  }

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
        Listener(
          // The children ignore pointers while settling, so this must be hit
          // on its own rather than only through a hit child.
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onPointerDown,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _controller,
              physics: const _SnappyPagePhysics(),
              clipBehavior: Clip.none,
              // No itemCount: the index is unbounded so the loop never ends.
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, index) {
                final page = _pageAt(index);
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
        ),
        const SizedBox(height: BSizes.sm),
        _Dots(
          count: _pageCount,
          current: _real(_current),
          color: _pageAt(_current).color,
          onTap: (i) => _controller.animateToPage(
            _nearestVirtual(i),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }
}

/// Page physics that settle in well under 300ms. The stock PageScrollPhysics
/// spring trails off for close to a second, and for that whole time the
/// cards ignore taps.
class _SnappyPagePhysics extends PageScrollPhysics {
  const _SnappyPagePhysics({super.parent});

  @override
  _SnappyPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _SnappyPagePhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.5,
        stiffness: 1200,
        ratio: 1.0,
      );

  /// The default tolerance waits for a thousandth of a pixel; the tail of
  /// the settle is invisible long before that, so stop at half a pixel.
  @override
  Tolerance toleranceFor(ScrollMetrics metrics) => Tolerance(
        velocity: 10 / (0.050 * metrics.devicePixelRatio),
        distance: 0.5 / metrics.devicePixelRatio,
      );
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
