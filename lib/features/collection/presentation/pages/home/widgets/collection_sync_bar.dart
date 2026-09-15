import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/upload/collection_upload_outbox_screen.dart';

/// Home sync row: download a fresh bucket and upload the day's collections.
///
/// Compact (40px) with one-word labels so it stays a single line at any
/// system text scale. The Download action is gated by the controller
/// (blocked while un-uploaded work remains); the Upload button appears only
/// when there are queued changes and opens the outbox for review/retry.
class CollectionSyncBar extends StatelessWidget {
  const CollectionSyncBar({super.key});

  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionActivityController>();

    final compactShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
    );
    const compactPadding = EdgeInsets.symmetric(horizontal: BSizes.spaceBtwItemsLight);

    return Obx(() {
      final pending = controller.pendingUploadCount;
      final busy = controller.isLoading.value;
      final downloading =
          controller.bucketDownloadPhase.value == BucketDownloadPhase.downloading;

      return SizedBox(
        height: _height,
        child: Row(
          children: [
            // Download bucket (guarded). While a download is in flight the
            // icon becomes a spinner; the full-screen transition is rendered
            // by the home screen.
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : controller.downloadBucket,
                style: OutlinedButton.styleFrom(
                  shape: compactShape,
                  padding: compactPadding,
                  minimumSize: const Size(0, _height),
                  visualDensity: VisualDensity.compact,
                ),
                icon: downloading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Iconsax.import_1, size: 16),
                label: Text(
                  downloading ? 'Downloading…' : 'Download',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: BSizes.spaceBtwItemsLight),
            // Upload: actionable when there is queued work, otherwise a muted
            // "Uploaded" confirmation.
            Expanded(
              child: pending == 0
                  ? OutlinedButton.icon(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        shape: compactShape,
                        padding: compactPadding,
                        minimumSize: const Size(0, _height),
                        visualDensity: VisualDensity.compact,
                        disabledForegroundColor: BColors.darkGrey,
                      ),
                      icon: const Icon(Iconsax.tick_circle, size: 16),
                      label: const Text('Uploaded', maxLines: 1, overflow: TextOverflow.ellipsis),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => Get.to(
                        () => const CollectionUploadOutboxScreen(),
                        transition: Transition.cupertino,
                        duration: const Duration(milliseconds: 300),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: compactShape,
                        padding: compactPadding,
                        minimumSize: const Size(0, _height),
                        visualDensity: VisualDensity.compact,
                        elevation: 0,
                        backgroundColor: BColors.primary,
                        foregroundColor: BColors.white,
                      ),
                      icon: const Icon(Iconsax.cloud_plus, size: 16),
                      label: Text('Upload ($pending)', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
            ),
          ],
        ),
      );
    });
  }
}
