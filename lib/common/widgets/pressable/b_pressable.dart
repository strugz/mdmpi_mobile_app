import 'package:flutter/material.dart';

/// A tappable wrapper that scales its child down slightly while pressed.
///
/// The scale is subtle (0.97) and fast (120ms, ease-out) so it reads as the
/// interface acknowledging the touch rather than as an animation. Release
/// snaps back at the same speed. Semantics are preserved through the
/// underlying [GestureDetector]; a null [onTap] renders the child unchanged.
class BPressable extends StatefulWidget {
  const BPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.borderRadius,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Scale applied while the pointer is down. Keep between 0.95 and 0.98.
  final double pressedScale;

  /// Clip radius so the ink response and the scaled child share a shape.
  final BorderRadius? borderRadius;

  final String? semanticLabel;

  @override
  State<BPressable> createState() => _BPressableState();
}

class _BPressableState extends State<BPressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed == value || widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final child = AnimatedScale(
      scale: _pressed ? widget.pressedScale : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: widget.child,
    );

    if (widget.onTap == null && widget.onLongPress == null) return child;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: MouseRegion(
          cursor: widget.onTap == null
              ? MouseCursor.defer
              : SystemMouseCursors.click,
          child: child,
        ),
      ),
    );
  }
}
