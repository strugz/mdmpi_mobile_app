import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/tap_to_animate_navigate.dart' as tap_anim;

/// A prominent card representing the collection bucket.
///
/// Shows a large centered image (which plays an animation when tapped), with
/// the label and a subtitle placed below the image. The whole card is
/// tappable but the animation is handled by the image widget so it plays and
/// then navigation is triggered after the animation completes.
class CollectionBucketButton extends StatefulWidget {
  final int itemCount;
  final VoidCallback onTap;
  final String label;
  final String imageAsset;
  final String animationAsset;
  final bool isLottie;
  final Duration gifDuration;
  /// Fade duration used by the internal animation transition when the image
  /// switches to the animation. Forwarded to [TapToAnimateNavigate].
  final Duration fadeDuration;
  /// Scale applied to the animation relative to the static image size.
  /// Values > 1.0 make the animation larger than the static image.
  final double animationScale;

  const CollectionBucketButton({
    super.key,
    required this.itemCount,
    required this.onTap,
    this.label = 'COLLECTION BUCKET',
    this.imageAsset = 'assets/images/bucket-list.png',
    this.animationAsset = 'assets/images/animations/bucket-list.gif',
    this.isLottie = false,
    this.gifDuration = const Duration(seconds: 1),
    this.fadeDuration = const Duration(milliseconds: 300),
    this.animationScale = 1,
  });

  @override
  State<CollectionBucketButton> createState() => _CollectionBucketButtonState();
}

class _CollectionBucketButtonState extends State<CollectionBucketButton> {
  final ValueNotifier<int> _trigger = ValueNotifier<int>(0);

  @override
  void dispose() {
    _trigger.dispose();
    super.dispose();
  }

  void _onCardTap() {
    // trigger the animation; TapToAnimateNavigate listens for changes
    _trigger.value = _trigger.value + 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    // Make the image larger to be the main attraction; match animationScale
    final double imageSize = BSizes.productImageSize * widget.animationScale;

    return GestureDetector(
      onTap: _onCardTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: BSizes.md,
          vertical: BSizes.md,
        ),
        decoration: BoxDecoration(
          color: primaryColor.withAlpha((0.08 * 255).round()),
          borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
          border: Border.all(
            color: primaryColor.withAlpha((0.25 * 255).round()),
            width: 5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: imageSize,
              height: imageSize,
              child: tap_anim.TapToAnimateNavigate(
                imageAsset: widget.imageAsset,
                animationAsset: widget.animationAsset,
                isLottie: widget.isLottie,
                gifDuration: widget.gifDuration,
                fadeDuration: widget.fadeDuration,
                animationScale: widget.animationScale,
                onNavigate: widget.onTap,
                fit: BoxFit.contain,
                externalTrigger: _trigger,
                width: imageSize,
                height: imageSize,
              ),
            ),

            const SizedBox(width: BSizes.spaceBtwItems),

            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: BSizes.fontSizeLg * 1.2,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: BSizes.xxs),
                  Text(
                    widget.itemCount == 0
                        ? 'No items in bucket'
                        : '${widget.itemCount} item${widget.itemCount == 1 ? '' : 's'} to collect',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: BSizes.fontSizeMd * 1.05,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



