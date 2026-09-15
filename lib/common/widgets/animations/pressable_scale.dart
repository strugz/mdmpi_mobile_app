import 'package:flutter/material.dart';

/// Press feedback for any tappable surface: scales the child down slightly
/// while the pointer is down and springs back on release or cancel.
///
/// Gives cards and custom buttons the "the UI heard me" feel that Material's
/// ink ripple provides for its own buttons. Scale stays subtle (0.97) and the
/// transition short (120ms, ease-out) so it reads as feedback, not animation.
class BPressableScale extends StatefulWidget {
  const BPressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.duration = const Duration(milliseconds: 120),
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration duration;

  /// When false the child renders without gesture handling or feedback.
  final bool enabled;

  @override
  State<BPressableScale> createState() => _BPressableScaleState();
}

class _BPressableScaleState extends State<BPressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              _setPressed(false);
              widget.onLongPress!();
            },
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
