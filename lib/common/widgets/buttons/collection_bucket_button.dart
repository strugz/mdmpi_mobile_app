import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';

/// Navigation card for the collection bucket.
///
/// Sized as a card, not a billboard: the item count is the information, so it
/// leads; the label is a plain title above it.
///
/// Navigation is immediate. This card is opened many times a day, and it
/// previously played a one-second GIF before calling [onTap], so every trip
/// into the bucket cost a second of dead time before the page transition even
/// started. Decoding that GIF also competed with the next screen's first
/// frame, which made the transition itself stutter. Press feedback now comes
/// from the scale-down every other pressable surface in the app uses.
class CollectionBucketButton extends StatelessWidget {
  final int itemCount;
  final VoidCallback onTap;
  final String label;
  final String imageAsset;

  const CollectionBucketButton({
    super.key,
    required this.itemCount,
    required this.onTap,
    this.label = 'Collection Bucket',
    this.imageAsset = 'assets/images/bucket-list.png',
  });

  /// Illustration size on the card.
  static const double imageSize = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return BPressableScale(
      onTap: onTap,
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
            Image.asset(
              imageAsset,
              width: imageSize,
              height: imageSize,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: BSizes.spaceBtwItems),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
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
                    itemCount == 0
                        ? 'No items in bucket'
                        : '$itemCount item${itemCount == 1 ? '' : 's'} to collect',
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
}
