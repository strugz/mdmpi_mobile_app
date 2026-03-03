import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';

/// A prominent button representing the collection bucket.
///
/// Displays a bucket icon with the current item count badge and a label.
/// Tap to navigate to the collection bucket screen.
class CollectionBucketButton extends StatelessWidget {
  final int itemCount;
  final VoidCallback onTap;
  final String label;

  const CollectionBucketButton({
    super.key,
    required this.itemCount,
    required this.onTap,
    this.label = 'Collection Bucket',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return GestureDetector(
      onTap: onTap,
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
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Bucket icon with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(BSizes.sm + 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                  ),
                  child: Icon(
                    Icons.shopping_basket_rounded,
                    color: primaryColor,
                    size: BSizes.iconLg,
                  ),
                ),
                if (itemCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          itemCount > 99 ? '99+' : '$itemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: BSizes.spaceBtwItems),

            // Label and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: BSizes.xxs),
                  Text(
                    itemCount == 0
                        ? 'No items in bucket'
                        : '$itemCount item${itemCount == 1 ? '' : 's'} to collect',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: primaryColor,
              size: BSizes.iconSm,
            ),
          ],
        ),
      ),
    );
  }
}



