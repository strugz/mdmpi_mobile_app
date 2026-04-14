import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';

class ReceiptPhotoCard extends StatelessWidget {
  const ReceiptPhotoCard({super.key, this.onAddPhoto});

  final VoidCallback? onAddPhoto;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BSizes.cardRadiusLg)),
      child: Padding(
        padding: const EdgeInsets.all(BSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.receipt_2, color: BColors.primary, size: 20),
                const SizedBox(width: BSizes.sm),
                Text(
                  'Receipts & Documentation',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: BSizes.md),
            
            /// Horizontal list of photos (Placeholder)
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  /// Add Photo Button
                  GestureDetector(
                    onTap: onAddPhoto,
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: BColors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                        border: Border.all(color: BColors.grey, style: BorderStyle.solid),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.camera, color: BColors.darkGrey),
                          SizedBox(height: BSizes.xs),
                          Text('Add Photo', style: TextStyle(fontSize: 10, color: BColors.darkGrey)),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: BSizes.sm),
                  
                  /// Placeholder for captured photos
                  _buildPhotoPlaceholder(),
                ],
              ),
            ),
            const SizedBox(height: BSizes.sm),
            Text(
              'Attach photos of official receipts, deposit slips, or signed documents.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: BColors.darkGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: BColors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
      ),
      child: const Center(
        child: Icon(Iconsax.image, color: BColors.grey, size: 32),
      ),
    );
  }
}
