import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_upload_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// Review and upload the offline collection queue (end-of-day "Upload All").
class CollectionUploadOutboxScreen extends StatelessWidget {
  const CollectionUploadOutboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CollectionUploadController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Collections'),
        actions: [
          Obx(() => (controller.pending.isEmpty || controller.isUploading.value)
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'Discard all',
                  icon: const Icon(Iconsax.trash),
                  onPressed: () => _confirmDiscardAll(controller),
                )),
        ],
      ),
      body: Obx(() {
        final busy = controller.isUploading.value;

        final Widget content;
        if (controller.isLoading.value && !busy) {
          content = const Center(
            key: ValueKey('loading'),
            child: CircularProgressIndicator(),
          );
        } else if (controller.pending.isEmpty) {
          content = const _EmptyState(key: ValueKey('empty'));
        } else {
          content = _PendingList(
            key: const ValueKey('list'),
            controller: controller,
            busy: busy,
          );
        }

        return Column(
          children: [
            // Indeterminate bar under the app bar. The whole queue goes up in
            // one request, so there is no per-row progress to show.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: busy
                  ? const LinearProgressIndicator(
                      key: ValueKey('bar'),
                      minHeight: 2,
                    )
                  : const SizedBox(key: ValueKey('nobar'), height: 2),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: content,
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          child: Obx(() => _UploadAllButton(
                count: controller.pending.length,
                busy: controller.isUploading.value,
                onPressed: controller.uploadAll,
              )),
        ),
      ),
    );
  }

  void _confirmDiscardAll(CollectionUploadController controller) {
    Get.defaultDialog(
      title: 'Discard all?',
      middleText:
          'This permanently removes all queued collections without uploading them.',
      textConfirm: 'Discard',
      textCancel: 'Cancel',
      confirmTextColor: BCollectionColors.surface,
      buttonColor: BCollectionColors.danger,
      onConfirm: () {
        Get.back();
        controller.discardAll();
      },
    );
  }
}

/// The queued rows. Dimmed and non-interactive while the upload is in flight,
/// so a row cannot be discarded halfway through being sent.
class _PendingList extends StatelessWidget {
  const _PendingList({super.key, required this.controller, required this.busy});

  final CollectionUploadController controller;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: busy,
      child: AnimatedOpacity(
        opacity: busy ? 0.55 : 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(BSizes.defaultSpace),
            itemCount: controller.pending.length,
            separatorBuilder: (_, __) => const SizedBox(height: BSizes.sm),
            itemBuilder: (context, index) {
              final change = controller.pending[index];
              final rejected = change.retryCount > 0;
              return Card(
                child: ListTile(
                  leading: Icon(
                    rejected ? Iconsax.warning_2 : Iconsax.document_upload,
                    color: rejected
                        ? BCollectionColors.danger
                        : BCollectionColors.primary,
                  ),
                  title: Text(_operationLabel(change.operation)),
                  subtitle: Text(
                    'Invoice: ${change.itemId ?? '—'}'
                    '${rejected ? '\nRejected — attempts: ${change.retryCount}' : ''}',
                  ),
                  isThreeLine: rejected,
                  trailing: IconButton(
                    tooltip: 'Discard',
                    icon: const Icon(Iconsax.close_circle,
                        color: BCollectionColors.danger),
                    onPressed: change.id == null
                        ? null
                        : () => controller.discard(change.id!),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Upload All.
///
/// Stays primary-coloured while busy: the theme paints a disabled button
/// grey-on-grey, which reads as "dead" rather than "working". Taps are absorbed
/// instead. The content crossfades (fade + slight scale, ease-out, 180 ms) so
/// the change of state is visible the instant the button is pressed.
class _UploadAllButton extends StatelessWidget {
  const _UploadAllButton({
    required this.count,
    required this.busy,
    required this.onPressed,
  });

  final int count;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Widget child = busy
        ? Row(
            key: const ValueKey('busy'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: BCollectionColors.surface,
                ),
              ),
              const SizedBox(width: BSizes.sm),
              Text('Uploading $count…'),
            ],
          )
        : Row(
            key: ValueKey('idle-$count'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.cloud_plus),
              const SizedBox(width: BSizes.sm),
              Text(count == 0 ? 'Nothing to upload' : 'Upload All ($count)'),
            ],
          );

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: count == 0 ? null : (busy ? () {} : onPressed),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.tick_circle,
              size: 56, color: BCollectionColors.success),
          const SizedBox(height: BSizes.sm),
          Text(
            'All collections uploaded',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: BSizes.xs),
          Text(
            'Nothing waiting to sync.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: BCollectionColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

String _operationLabel(String operation) {
  switch (operation.toUpperCase()) {
    case 'CLAIM':
      return 'Acquire account';
    case 'SAVE_ACTIVITY':
      return 'Collection recorded';
    case 'BATCH_ACTIVITY':
      return 'Batch collection';
    case 'OFFICE_ACTIVITY':
      return 'Office activity';
    case 'DEPOSIT':
      return 'Deposit';
    case 'CWT_PICKUP':
      return 'CWT Pick-up';
    case 'RECONCILIATION':
      return 'Reconciliation';
    case 'ADVANCED_PAYMENT':
      return 'Advanced payment';
    case 'ASSIGN_ADVANCE':
      return 'Advance assigned to invoice';
    case 'SET_TARGET':
      return 'Monthly target';
    case 'DEFER':
      return 'Deferred engagement';
    case 'CLEAR':
      return 'Cleared engagement';
    default:
      return operation;
  }
}
