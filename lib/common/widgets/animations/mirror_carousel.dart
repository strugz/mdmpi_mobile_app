import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// Horizontal, looping carousel with a mirror transition between items.
///
/// The item being swiped away turns on its vertical axis until it is edge-on,
/// and the next one turns in from the opposite side, like a panel flipping to
/// show its mirror face. The angle is driven by the scroll offset, so the
/// gesture can be reversed or interrupted at any point and the item simply
/// follows the finger. With system animations disabled the turn is replaced by
/// a plain crossfade so nothing swings.
///
/// With two or more items the carousel loops: swiping past the last brings the
/// first back, and swiping back from the first shows the last. The PageView
/// runs over an unbounded virtual index that starts far from zero; the real
/// item is `virtual % itemCount`.
class BMirrorCarousel extends StatefulWidget {
  const BMirrorCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.height,
    this.initialPage = 0,
    this.onSettleTap,
    this.dotColor,
  });

  final int itemCount;

  /// Builds the item for a real index in `0 ..< itemCount`.
  final IndexedWidgetBuilder itemBuilder;

  /// PageView needs a bounded height inside a scroll view.
  final double height;
  final int initialPage;

  /// Called with the real index when a tap lands while the page is still
  /// settling after a swipe. Scrollable ignores pointers on its children for
  /// the whole settle, so the item itself never sees that tap; wire this to
  /// the same action as the item's own tap.
  final ValueChanged<int>? onSettleTap;

  /// Colour of the active dot for a real index. Defaults to the primary
  /// colour.
  final Color Function(int index)? dotColor;

  /// Neighbours peek in slightly so the row still reads as swipeable.
  static const double viewportFraction = 0.92;

  /// A full quarter turn per page: at one page away the item is edge-on.
  static const double _maxTurn = math.pi / 2;

  /// Perspective entry (row 3, column 2) of the turn matrix: near faces grow,
  /// far faces shrink. Also what tells this transform apart from any
  /// press-scale transform inside the item.
  static const double perspective = 0.0015;

  @override
  State<BMirrorCarousel> createState() => _BMirrorCarouselState();
}

class _BMirrorCarouselState extends State<BMirrorCarousel> {
  /// One item cannot loop; the PageView is then bounded to that single page.
  bool get _loops => widget.itemCount > 1;

  /// Virtual start, far enough from zero that a user never reaches the
  /// front edge by swiping backwards. A multiple of the item count keeps the
  /// modulo lined up with the real index.
  late final int _origin =
      (_loops ? widget.itemCount * 10000 : 0) + widget.initialPage;

  late final PageController _controller = PageController(
    viewportFraction: BMirrorCarousel.viewportFraction,
    initialPage: _origin,
  );

  /// Virtual page the PageView reports as current.
  late int _current = _origin;

  /// Real item index for a virtual page.
  int _real(int virtual) => virtual % widget.itemCount;

  /// A tap that begins while the page is still settling. Scrollable wraps
  /// its children in IgnorePointer for the whole ballistic settle, so the
  /// item underneath never sees the tap. This Listener sits outside the
  /// PageView, so it does; on a clean release it reports the current item.
  int? _settlingPointer;
  Offset? _settlingDown;

  /// The item mostly on screen when the tap began. [_current] lags until the
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
    if (moved <= kTouchSlop) widget.onSettleTap?.call(_real(target));
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
    if (!_loops) return real;
    final count = widget.itemCount;
    final forward = (real - _real(_current)) % count;
    final backward = forward - count;
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
        // Fade the edge-on item out so a hairline never shows through.
        final opacity = (1 - progress * 1.15).clamp(0.0, 1.0);

        if (reduceMotion) {
          return Opacity(opacity: opacity, child: child);
        }

        final shrink = 1 - progress * 0.06;
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, BMirrorCarousel.perspective)
          ..rotateY(-delta * BMirrorCarousel._maxTurn)
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
    final real = _real(_current);
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
              // No count while looping: the index is unbounded.
              itemCount: _loops ? null : widget.itemCount,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _mirror(
                  context,
                  widget.itemBuilder(context, _real(index)),
                  index,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: BSizes.sm),
        _Dots(
          count: widget.itemCount,
          current: real,
          color: widget.dotColor?.call(real) ?? BCollectionColors.primary,
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
/// items ignore taps.
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
                color: active ? color : BCollectionColors.outline,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }
}
