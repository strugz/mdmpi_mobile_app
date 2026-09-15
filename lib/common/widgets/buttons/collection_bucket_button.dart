import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/tap_to_animate_navigate.dart' as tap_anim;

/// Navigation card for the collection bucket.
///
/// The bucket illustration plays its animation on tap and then navigates.
/// Sized as a card, not a billboard: the item count is the information, so
/// it leads; the label is a plain title beneath it.
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
  final double animationScale;

  const CollectionBucketButton({
    super.key,
    required this.itemCount,
    required this.onTap,
    this.label = 'Collection Bucket',
    this.imageAsset = 'assets/images/bucket-list.png',
    this.animationAsset = 'assets/images/animations/bucket-list.gif',
    this.isLottie = false,
    this.gifDuration = const Duration(seconds: 1),
    this.fadeDuration = const Duration(milliseconds: 300),
    this.animationScale = 1,
  });

  /// Static image size on the card. Was 100; 64 keeps the illustration as
  /// the card's personality without dominating the screen.
  static const double imageSize = 64;

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
    final size = CollectionBucketButton.imageSize * widget.animationScale;
    final count = widget.itemCount;

    return GestureDetector(
      onTap: _onCardTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: BSizes.md,
          vertical: BSizes.spaceBtwItemsLight,
        ),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(BSizes.cardRadiusLg),
          border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Row(
          children: [
            SizedBox(
              width: size,
              height: size,
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
                width: size,
                height: size,
              ),
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
                    count == 0
                        ? 'No items in bucket'
                        : '$count item${count == 1 ? '' : 's'} to collect',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: BColors.darkerGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BSizes.sm),
            Icon(Iconsax.arrow_right_3, size: 18, color: primaryColor.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}
