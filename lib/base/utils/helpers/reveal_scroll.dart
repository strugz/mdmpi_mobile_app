import 'package:flutter/widgets.dart';

/// Scroll a section that has just unfolded into view.
///
/// A switch near the bottom of a form that reveals more fields leaves them
/// below the fold: the sheet grows, but the viewport stays where it was and
/// the collector has to scroll to find what they just asked for. This waits
/// for the unfold animation to finish (the scroll extent only exists once the
/// section has its full height) and then moves the least distance that puts
/// the section fully on screen, so a section already in view does not move.
class BRevealScroll {
  BRevealScroll._();

  static const Duration _scrollDuration = Duration(milliseconds: 240);

  /// Reveal the widget under [key] once [afterUnfold] has elapsed. No-op if
  /// the widget is gone by then or is not inside a scrollable.
  static Future<void> into(GlobalKey key,
      {required Duration afterUnfold}) async {
    await Future<void>.delayed(afterUnfold);
    // The unfold's last frame may not have laid out yet, and until it has
    // the scroll range still ends where the folded form did.
    await WidgetsBinding.instance.endOfFrame;
    final context = key.currentContext;
    if (context == null || !context.mounted) return;
    if (Scrollable.maybeOf(context) == null) return;
    await Scrollable.ensureVisible(
      context,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      duration: _scrollDuration,
      curve: Curves.easeOutCubic,
    );
  }
}
