import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/list_tiles/settings_menu_tile.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_heading.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_storage_controller.dart';

/// Settings → Storage (Collection TODO item 15).
class CollectionStorageScreen extends StatelessWidget {
  const CollectionStorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CollectionStorageController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const BAppBar(title: Text('Storage'), showBackArrow: true),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(() {
          final s = controller.snapshot.value;
          final err = controller.error.value;
          return ListView(
            padding: EdgeInsets.fromLTRB(
                BSizes.defaultSpace,
                BSizes.defaultSpace,
                BSizes.defaultSpace,
                BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom),
            children: [
              _SizeCard(
                  bytes: s?.databaseBytes,
                  rows: s?.collectionRows,
                  pending: s?.pendingUploads,
                  loading: controller.isLoading.value && s == null,
                  error: err),
              if (s != null && s.tables.isNotEmpty) ...[
                const SizedBox(height: BSizes.spaceBtwSections),
                const BSectionHeading(
                    title: 'What is on this phone', showActionButton: false),
                const SizedBox(height: BSizes.sm),
                for (final t in s.tables)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      key: ValueKey('storage-table-${t.table}'),
                      children: [
                        Expanded(
                            child: Text(t.label, style: theme.textTheme.bodyMedium)),
                        Text('${t.rows}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: BCollectionColors.inkSecondary)),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: BSizes.spaceBtwSections),
              const BSectionHeading(title: 'Actions', showActionButton: false),
              const SizedBox(height: BSizes.spaceBtwItems),
              BSettingsMenuTile(
                icon: Iconsax.cloud_change,
                title: 'Re-download the bucket',
                subTitle: (s?.pendingUploads ?? 0) > 0
                    ? '${s!.pendingUploads} un-uploaded change'
                        '${s.pendingUploads == 1 ? '' : 's'} · upload first'
                    : 'Replace the local copy with the server\'s',
                trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                onTap: controller.isWorking.value
                    ? null
                    : () => _confirm(
                          context,
                          key: 'storage-confirm-redownload',
                          title: 'Re-download the bucket?',
                          message: 'The local copy is replaced with what the '
                              'server has. Un-uploaded work is checked first.',
                          confirm: 'Download',
                          action: controller.redownloadBucket,
                          done: 'Bucket downloaded',
                        ),
              ),
              BSettingsMenuTile(
                icon: Iconsax.gallery_remove,
                title: 'Clear cached pictures',
                subTitle: 'Profile photos and other downloaded images',
                trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                onTap: controller.isWorking.value
                    ? null
                    : () => _confirm(
                          context,
                          key: 'storage-confirm-images',
                          title: 'Clear cached pictures?',
                          message: 'They are downloaded again when shown. '
                              'Nothing you recorded is touched.',
                          confirm: 'Clear',
                          action: controller.clearImageCache,
                          done: 'Cached pictures cleared',
                        ),
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text(
                'Your collections, engagements and the upload queue are never '
                'cleared here. Use Upload Data to send them.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: BCollectionColors.inkMuted),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String key,
    required String title,
    required String message,
    required String confirm,
    required Future<dynamic> Function() action,
    required String done,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              key: ValueKey(key),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirm)),
        ],
      ),
    );
    if (ok != true) return;
    final result = await action();
    if (result.isSuccess) {
      BLoaders.successSnackBar(title: done);
    } else {
      BLoaders.errorSnackBar(title: 'Not done', message: result.error);
    }
  }
}

class _SizeCard extends StatelessWidget {
  const _SizeCard(
      {required this.bytes,
      required this.rows,
      required this.pending,
      required this.loading,
      required this.error});

  final int? bytes;
  final int? rows;
  final int? pending;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('storage-size-card'),
      child: Padding(
        padding: const EdgeInsets.all(BSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Local data', style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            if (loading)
              const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else if (error != null)
              Text(error!,
                  key: const ValueKey('storage-error'),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: BCollectionColors.danger))
            else
              Text(CollectionStorageController.formatBytes(bytes ?? 0),
                  key: const ValueKey('storage-size'),
                  style: theme.textTheme.headlineSmall),
            if (rows != null)
              Text(
                '$rows Collection row${rows == 1 ? '' : 's'}'
                '${(pending ?? 0) > 0 ? ' · $pending waiting to upload' : ''}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: BCollectionColors.inkMuted),
              ),
          ],
        ),
      ),
    );
  }
}
