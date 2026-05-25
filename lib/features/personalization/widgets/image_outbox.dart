import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/image_outbox_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/image_outbox_item.dart';

/// Developer-facing widget that lists pending proof image upload outbox rows.
class ImageOutbox extends StatelessWidget {
  const ImageOutbox({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ImageOutboxController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return RefreshIndicator(
        onRefresh: controller.loadItems,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(BSizes.defaultSpace),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SummaryCard(controller: controller),
                  const SizedBox(height: BSizes.spaceBtwItems),
                  _BulkActions(controller: controller),
                  const SizedBox(height: BSizes.spaceBtwSections),
                  Text(
                    'Pending proof images',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: BSizes.xs),
                  Text(
                    'Retry failed proof uploads, inspect stored images, or clear developer outbox entries.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: BSizes.spaceBtwItems),
                ]),
              ),
            ),
            if (controller.items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  BSizes.defaultSpace,
                  0,
                  BSizes.defaultSpace,
                  BSizes.defaultSpace,
                ),
                sliver: SliverList.separated(
                  itemCount: controller.items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: BSizes.spaceBtwItems),
                  itemBuilder: (_, index) {
                    final item = controller.items[index];
                    return _ImageOutboxCard(
                      item: item,
                      isBusy: controller.isBusy(item),
                      onRetry: () => controller.retryItem(item),
                      onView: () => _showPreviewDialog(context, item),
                      onIgnore: () => _confirmIgnore(context, controller, item),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    });
  }

  Future<void> _confirmIgnore(
    BuildContext context,
    ImageOutboxController controller,
    ImageOutboxItem item,
  ) async {
    final shouldIgnore = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Mark as Ignored'),
          content: Text(
            'Remove ${item.imageType} image outbox entry for request ${item.requestId}? This action is intended for developer cleanup only.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldIgnore == true) {
      await controller.ignoreItem(item);
    }
  }

  void _showPreviewDialog(BuildContext context, ImageOutboxItem item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(BSizes.defaultSpace),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image Preview',
                  style: Theme.of(dialogContext).textTheme.titleLarge,
                ),
                const SizedBox(height: BSizes.xs),
                Text(
                  'Request ${item.requestId} - ${item.imageType}',
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: BSizes.spaceBtwItems),
                Flexible(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: BRoundedContainer(
                        radius: BSizes.cardRadiusMd,
                        backgroundColor: BColors.lightGrey,
                        child: Padding(
                          padding: const EdgeInsets.all(BSizes.sm),
                          child: InteractiveViewer(
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(BSizes.cardRadiusSm),
                              child: _ImagePreview(
                                imageBase64: item.imageBase64,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: BSizes.spaceBtwItems),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.controller});

  final ImageOutboxController controller;

  @override
  Widget build(BuildContext context) {
    return BRoundedContainer(
      radius: BSizes.cardRadiusMd,
      backgroundColor: BColors.primaryBackground,
      padding: const EdgeInsets.all(BSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Image Outbox Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: BSizes.xs),
          Text(
            'Rows remain here until upload succeeds or a developer removes them.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: BSizes.spaceBtwItems),
          Wrap(
            spacing: BSizes.sm,
            runSpacing: BSizes.sm,
            children: [
              _SummaryBadge(
                label: 'Total',
                value: controller.items.length.toString(),
                color: BColors.primary,
              ),
              _SummaryBadge(
                label: 'Failed',
                value: controller.failedCount.toString(),
                color: BColors.error,
              ),
              _SummaryBadge(
                label: 'Pending',
                value: controller.pendingCount.toString(),
                color: BColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BulkActions extends StatelessWidget {
  const _BulkActions({required this.controller});

  final ImageOutboxController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: BSizes.sm,
      runSpacing: BSizes.sm,
      children: [
        FilledButton.icon(
          onPressed: controller.items.isEmpty || controller.isRetryingAll.value
              ? null
              : () => _confirmRetryAll(context, controller),
          icon: controller.isRetryingAll.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Iconsax.refresh),
          label: const Text('Retry All'),
        ),
        OutlinedButton.icon(
          onPressed: controller.isLoading.value ? null : controller.loadItems,
          icon: const Icon(Iconsax.refresh_2),
          label: const Text('Refresh'),
        ),
        OutlinedButton.icon(
          onPressed: controller.items.isEmpty || controller.isClearingAll.value
              ? null
              : () => _confirmClearAll(context, controller),
          icon: controller.isClearingAll.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Iconsax.trash),
          label: const Text('Clear All'),
        ),
      ],
    );
  }

  Future<void> _confirmRetryAll(
    BuildContext context,
    ImageOutboxController controller,
  ) async {
    final shouldRetry = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Retry All Uploads'),
          content: const Text(
            'Retry every pending image upload in the outbox?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Retry All'),
            ),
          ],
        );
      },
    );

    if (shouldRetry == true) {
      await controller.retryAll();
    }
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    ImageOutboxController controller,
  ) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Image Outbox'),
          content: const Text(
            'Remove all pending image outbox entries? This developer action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      await controller.clearAll();
    }
  }
}

class _ImageOutboxCard extends StatelessWidget {
  const _ImageOutboxCard({
    required this.item,
    required this.isBusy,
    required this.onRetry,
    required this.onView,
    required this.onIgnore,
  });

  final ImageOutboxItem item;
  final bool isBusy;
  final VoidCallback onRetry;
  final VoidCallback onView;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(BSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(BSizes.cardRadiusSm),
                  child: SizedBox(
                    width: 112,
                    height: 84,
                    child: _ImagePreview(imageBase64: item.imageBase64),
                  ),
                ),
                const SizedBox(width: BSizes.spaceBtwItems),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request ${item.requestId}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: BSizes.xs),
                      _DetailRow(label: 'Type', valueText: item.imageType),
                      const SizedBox(height: BSizes.xs),
                      _DetailRow(
                        label: 'Status',
                        valueWidget: _StatusBadge(status: item.apiStatus),
                      ),
                      const SizedBox(height: BSizes.xs),
                      _DetailRow(
                        label: 'Captured',
                        valueText: item.capturedAt != null
                            ? DateFormat('MMM d, yyyy h:mm a')
                                .format(item.capturedAt!.toLocal())
                            : 'Not available',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: BSizes.spaceBtwItems),
            Wrap(
              spacing: BSizes.sm,
              runSpacing: BSizes.sm,
              children: [
                FilledButton.tonalIcon(
                  onPressed: isBusy ? null : onRetry,
                  icon: isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.refresh),
                  label: const Text('Retry'),
                ),
                OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Iconsax.eye),
                  label: const Text('View'),
                ),
                TextButton.icon(
                  onPressed: isBusy ? null : onIgnore,
                  icon: const Icon(Iconsax.trash, color: BColors.error),
                  label: const Text(
                    'Mark as Ignored',
                    style: TextStyle(color: BColors.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    this.valueText,
    this.valueWidget,
  });

  final String label;
  final String? valueText;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: BColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(width: BSizes.xs),
        Expanded(
          child: valueWidget ??
              Text(
                valueText ?? '-',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final lowerStatus = status.toLowerCase();
    final color = switch (lowerStatus) {
      'failed' => BColors.error,
      'pending' => BColors.warning,
      'synced' => BColors.success,
      _ => BColors.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BSizes.sm,
        vertical: BSizes.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BSizes.md,
        vertical: BSizes.sm,
      ),
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(BSizes.cardRadiusSm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.imageBase64,
    this.fit = BoxFit.cover,
  });

  final String imageBase64;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeBase64(imageBase64);
    if (bytes == null || bytes.isEmpty) {
      return Container(
        color: BColors.lightGrey,
        alignment: Alignment.center,
        child: const Icon(Iconsax.image, color: BColors.darkGrey),
      );
    }

    return Container(
      color: BColors.white,
      child: Image.memory(bytes, fit: fit),
    );
  }

  Uint8List? _decodeBase64(String value) {
    try {
      final payload = value.contains(',') ? value.split(',').last : value;
      if (payload.trim().isEmpty) {
        return null;
      }
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Iconsax.tick_circle,
              size: 56,
              color: BColors.success,
            ),
            const SizedBox(height: BSizes.spaceBtwItems),
            Text(
              'No pending image uploads',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BSizes.xs),
            Text(
              'Proof images are either synced already or there are no outbox rows to review.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
