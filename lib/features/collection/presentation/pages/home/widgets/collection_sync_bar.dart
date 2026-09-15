import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/upload/collection_upload_outbox_screen.dart';

/// Home sync bar: download a fresh bucket and upload the day's collections.
///
/// The Download action is gated by the controller (blocked while un-uploaded
/// work remains); the Upload All chip appears only when there are queued
/// changes and opens the outbox for review/retry.
class CollectionSyncBar extends StatelessWidget {
  const CollectionSyncBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionActivityController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
      child: Obx(() {
        final pending = controller.pendingUploadCount;
        final busy = controller.isLoading.value;

        return Row(
          children: [
            // Download bucket (guarded)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : controller.downloadBucket,
                icon: const Icon(Iconsax.import_1, size: 18),
                label: const Text('Download Bucket'),
              ),
            ),
            const SizedBox(width: BSizes.spaceBtwItems),
            // Upload all: an actionable button when there is queued work, or a
            // clearly-labelled muted "all uploaded" state when the queue is empty.
            Expanded(
              child: pending == 0
                  ? OutlinedButton.icon(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        disabledForegroundColor: BColors.darkGrey,
                      ),
                      icon: const Icon(Iconsax.tick_circle, size: 18),
                      label: const Text('All uploaded'),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => Get.to(
                        () => const CollectionUploadOutboxScreen(),
                        transition: Transition.cupertino,
                        duration: const Duration(milliseconds: 300),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BColors.primary,
                        foregroundColor: BColors.white,
                      ),
                      icon: const Icon(Iconsax.cloud_plus, size: 18),
                      label: Text('Upload ($pending)'),
                    ),
            ),
          ],
        );
      }),
    );
  }
}
