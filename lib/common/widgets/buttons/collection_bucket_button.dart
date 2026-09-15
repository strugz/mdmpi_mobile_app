import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';

/// Navigation card for the collection bucket.
///
/// Tapping plays the bucket animation and opens the bucket screen. The
/// animation is the card's personality, so it stays, but it never blocks
/// navigation: playback starts, [navigateDelay] later the push begins, and the
/// animation keeps running on the outgoing page while it slides away.
///
/// Why it is cheap now. The source GIF is 640x640, 127 frames, 2.66s. It is
/// drawn at 64pt, but Flutter decoded every frame at full size, which is about
/// eleven times more pixels than the screen can use and enough main-thread
/// work to stutter the page transition. [decodePx] decodes at display size
/// instead, and the asset is precached so the first tap costs no bundle read.
class CollectionBucketButton extends StatefulWidget {
  final int itemCount;
  final VoidCallback onTap;
  final String label;
  final String imageAsset;
  final String animationAsset;

  /// How long the animation plays before the page push starts. Kept short: the
  /// animation continues during the transition, so this only needs to be long
  /// enough for the tap to register as a response. Set to [Duration.zero] to
  /// navigate instantly.
  final Duration navigateDelay;

  const CollectionBucketButton({
    super.key,
    required this.itemCount,
    required this.onTap,
    this.label = 'Collection Bucket',
    this.imageAsset = 'assets/images/bucket-list.png',
    this.animationAsset = 'assets/images/animations/bucket-list.gif',
    this.navigateDelay = const Duration(milliseconds: 240),
  });

  /// Illustration size on the card.
  static const double imageSize = 64;

  /// Decode target in physical pixels: [imageSize] at a 3x device. Bounded so
  /// a 640x640 frame never decodes at full resolution.
  static const int decodePx = 192;

  @override
  State<CollectionBucketButton> createState() => _CollectionBucketButtonState();
}

class _CollectionBucketButtonState extends State<CollectionBucketButton> {
  bool _playing = false;

  /// Changes on every tap so the GIF is rebuilt and restarts at frame 0.
  int _playToken = 0;

  Timer? _navigateTimer;
  Timer? _resetTimer;
  bool _precached = false;

  /// Long enough to cover the delay plus the page transition, after which the
  /// card is covered and can quietly go back to the still image.
  static const Duration _resetAfter = Duration(milliseconds: 1200);

  ImageProvider get _animationProvider => ResizeImage(
        AssetImage(widget.animationAsset),
        width: CollectionBucketButton.decodePx,
        height: CollectionBucketButton.decodePx,
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // Pull the 2MB asset into the image cache up front so the first tap is as
    // smooth as every later one. Failure here is not worth interrupting the
    // screen for: the tap just decodes on demand instead.
    precacheImage(_animationProvider, context).catchError((_) {});
  }

  @override
  void dispose() {
    _navigateTimer?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    // Ignore repeat taps while a push is already queued.
    if (_playing) return;

    setState(() {
      _playing = true;
      _playToken++;
    });

    if (widget.navigateDelay == Duration.zero) {
      widget.onTap();
    } else {
      _navigateTimer = Timer(widget.navigateDelay, () {
        if (mounted) widget.onTap();
      });
    }

    _resetTimer = Timer(_resetAfter, () {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return BPressableScale(
      onTap: _handleTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: BSizes.md,
          vertical: BSizes.spaceBtwItemsLight,
        ),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(BSizes.cardRadiusLg),
          border: Border.all(
              color: primaryColor.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Row(
          children: [
            SizedBox(
              width: CollectionBucketButton.imageSize,
              height: CollectionBucketButton.imageSize,
              child: _playing ? _animation() : _stillImage(),
            ),
            const SizedBox(width: BSizes.spaceBtwItems),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: BSizes.fontSizeLg,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: BSizes.xxs),
                  Text(
                    widget.itemCount == 0
                        ? 'No items in bucket'
                        : '${widget.itemCount} item${widget.itemCount == 1 ? '' : 's'} to collect',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: BColors.darkerGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BSizes.sm),
            Icon(Iconsax.arrow_right_3,
                size: 18, color: primaryColor.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _stillImage() => Image.asset(
        widget.imageAsset,
        key: const ValueKey('bucket-still'),
        width: CollectionBucketButton.imageSize,
        height: CollectionBucketButton.imageSize,
        fit: BoxFit.contain,
        cacheWidth: CollectionBucketButton.decodePx,
        cacheHeight: CollectionBucketButton.decodePx,
      );

  Widget _animation() => Image.asset(
        widget.animationAsset,
        // A new key each tap restarts the animation at its first frame.
        key: ValueKey('bucket-anim-$_playToken'),
        width: CollectionBucketButton.imageSize,
        height: CollectionBucketButton.imageSize,
        fit: BoxFit.contain,
        cacheWidth: CollectionBucketButton.decodePx,
        cacheHeight: CollectionBucketButton.decodePx,
        // Hold the last painted frame while the codec spins up, so the swap
        // from the still image never flashes empty.
        gaplessPlayback: true,
      );
}
