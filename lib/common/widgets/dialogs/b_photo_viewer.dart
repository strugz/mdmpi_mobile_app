import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';

/// Full-screen photo viewer for proof / delivery shots.
///
/// Replaces the Material dialog that showed the photo inside a tinted card
/// with a title bar, an X *and* a "Close" button, and no page indicator. A
/// photo wants a dark, edge-to-edge canvas: it is the content, the chrome is
/// secondary and can be tapped away. Swipe between photos, pinch to zoom,
/// one way out (X / system back), and a "1 of 3" counter so the reader knows
/// there is more to see.
class BPhotoViewer extends StatefulWidget {
  const BPhotoViewer({
    super.key,
    required this.localPaths,
    this.title = 'Photo',
    this.caption,
    this.semanticsLabel = 'Photo',
    this.initialIndex = 0,
  });

  final List<String> localPaths;
  final String title;

  /// Small line under the counter, e.g. `Request 01002`.
  final String? caption;
  final String semanticsLabel;
  final int initialIndex;

  /// Pushes the viewer as a translucent full-screen route: quick fade + scale
  /// in (ease-out, 180 ms), faster out — it is opened occasionally, so a
  /// short entrance is right; nothing appears from `scale(0)`.
  static Future<void> show(
    BuildContext context, {
    required List<String> localPaths,
    String title = 'Photo',
    String? caption,
    String semanticsLabel = 'Photo',
    int initialIndex = 0,
  }) {
    return Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (_, __, ___) => BPhotoViewer(
        localPaths: localPaths,
        title: title,
        caption: caption,
        semanticsLabel: semanticsLabel,
        initialIndex: initialIndex,
      ),
      transitionsBuilder: (_, animation, __, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    ));
  }

  @override
  State<BPhotoViewer> createState() => _BPhotoViewerState();
}

class _BPhotoViewerState extends State<BPhotoViewer> {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _chromeVisible = true;

  /// Quarter turns per photo (a rotated photo stays rotated while you swipe
  /// away and back; rotation never touches the file).
  final Map<int, int> _quarterTurns = {};

  int get _currentTurns => _quarterTurns[_index] ?? 0;

  void _rotate() =>
      setState(() => _quarterTurns[_index] = (_currentTurns + 1) % 4);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.localPaths.length;
    final onDark = Colors.white.withValues(alpha: 0.9);
    final muted = Colors.white.withValues(alpha: 0.6);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light icons on the dark canvas while the viewer is up.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Photos — full bleed, pinch to zoom, swipe to page.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _chromeVisible = !_chromeVisible),
              child: PageView.builder(
                controller: _pages,
                itemCount: count,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, index) => InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  clipBehavior: Clip.none,
                  // Rotation is on-screen movement, so ease-in-out; 200 ms is
                  // enough to read the turn without waiting on it.
                  child: AnimatedRotation(
                    turns: (_quarterTurns[index] ?? 0) / 4,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    child: Semantics(
                      label:
                          '${widget.semanticsLabel} (${index + 1} of $count)',
                      image: true,
                      child: Image.file(
                        File(widget.localPaths[index]),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text('Could not load this photo',
                              style: TextStyle(color: muted)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Chrome — fades out on tap so the photo can be inspected clean.
            IgnorePointer(
              ignoring: !_chromeVisible,
              child: AnimatedOpacity(
                opacity: _chromeVisible ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: Column(
                  children: [
                    // Top bar: title, one close control.
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xB3000000), Color(0x00000000)],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Close',
                              icon: Icon(Iconsax.close_circle, color: onDark),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            Expanded(
                              child: Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(color: onDark),
                              ),
                            ),
                            // Rotate the current photo a quarter turn; the
                            // box labels in proof shots are often sideways.
                            IconButton(
                              key: const Key('photo_viewer_rotate'),
                              tooltip: 'Rotate',
                              icon: Icon(Iconsax.rotate_right, color: onDark),
                              onPressed: _rotate,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Bottom: counter + dots + caption.
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xB3000000), Color(0x00000000)],
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              BSizes.md, BSizes.lg, BSizes.md, BSizes.md),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (count > 1) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var i = 0; i < count; i++)
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 160),
                                        curve: Curves.easeOut,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        width: i == _index ? 18 : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: i == _index ? onDark : muted,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: BSizes.sm),
                              ],
                              Text(
                                count > 1
                                    ? '${_index + 1} of $count'
                                    : (widget.caption ?? ''),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: onDark),
                              ),
                              if (count > 1 &&
                                  (widget.caption?.isNotEmpty ?? false))
                                Text(
                                  widget.caption!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: muted),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
