import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

/// A small copy glyph for a reference number (P.O., invoice, waybill).
///
/// Collectors paste these into chats and remittance replies all day, so the
/// feedback is where the finger is: the glyph turns into a tick for a moment,
/// with a light haptic, and a short snackbar names what was copied. The tick
/// comes back to a copy glyph on its own; there is nothing to dismiss.
///
/// The visible glyph is 16pt; the target is 32pt so it can be hit with a thumb
/// without making the line it sits on any taller.
class BCopyIconButton extends StatefulWidget {
  const BCopyIconButton({
    super.key,
    required this.value,
    required this.label,
    this.color,
    this.size = 16,
  });

  /// Text put on the clipboard.
  final String value;

  /// What it is, for the snackbar and screen readers: "P.O.", "Invoice".
  final String label;

  final Color? color;
  final double size;

  @override
  State<BCopyIconButton> createState() => _BCopyIconButtonState();
}

class _BCopyIconButtonState extends State<BCopyIconButton> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _copied = false);
    });
    // maybeOf: a card rendered outside a Scaffold (a test, a sheet) still copies.
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${widget.label} ${widget.value} copied'),
        duration: const Duration(milliseconds: 1600),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.outline;
    return Semantics(
      button: true,
      label: 'Copy ${widget.label} ${widget.value}',
      excludeSemantics: true,
      child: InkResponse(
        onTap: _copy,
        radius: 18,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            // Scale + fade from 0.6, never from 0: the tick grows out of the
            // glyph it replaces rather than appearing from nowhere.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.6, end: 1).animate(anim),
                  child: child,
                ),
              ),
              child: _copied
                  ? Icon(Iconsax.tick_circle5,
                      key: const ValueKey('done'),
                      size: widget.size,
                      color: Colors.green.shade600)
                  : Icon(Iconsax.copy,
                      key: const ValueKey('copy'),
                      size: widget.size,
                      color: color),
            ),
          ),
        ),
      ),
    );
  }
}
