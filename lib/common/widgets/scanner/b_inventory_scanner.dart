import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../base/utils/popups/loaders.dart';
import '../../../base/utils/logger.dart';
import '../../../base/utils/constants/colors.dart';
import '../../../base/utils/constants/sizes.dart';
import '../../../base/utils/helpers/helper_functions.dart';
import '../../../data/models/inventory_item_model.dart';
import '../../../features/logistics/controllers/standard_delivery_controller.dart';

/// Widget that lets the user capture a picture or attach a file, sends it to
/// the Gemini OCR endpoint via [StandardDeliveryController.analyzeFileForInventory],
/// and displays the parsed [InventoryItemModel] items in a scrollable list.
class BInventoryScanner extends StatelessWidget {
  const BInventoryScanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StandardDeliveryController>();
    final dark = BHelperFunctions.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Action buttons: Camera & File ──────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(controller, ImageSource.camera),
                icon: const Icon(Iconsax.camera),
                label: const Text('Capture'),
              ),
            ),
            const SizedBox(width: BSizes.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickFile(controller),
                icon: const Icon(Iconsax.document_upload),
                label: const Text('Attach File'),
              ),
            ),
          ],
        ),

        const SizedBox(height: BSizes.spaceBtwItems),

        // ── Loading indicator ──────────────────────────────────────────
        Obx(() {
          if (controller.isAnalyzingFile.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: BSizes.md),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: BSizes.sm),
                    Text('Analyzing file…'),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        // ── Error message ──────────────────────────────────────────────
        Obx(() {
          final error = controller.analyzeError.value;
          if (error != null && error.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(bottom: BSizes.sm),
              child: Text(
                error,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.red),
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        // ── Scanned items list ─────────────────────────────────────────
        Obx(() {
          final items = controller.formState.scannedInventoryItems;
          if (items.isEmpty && !controller.isAnalyzingFile.value) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scanned Items (${items.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (items.isNotEmpty)
                    TextButton.icon(
                      onPressed: controller.clearScannedItems,
                      icon: const Icon(Iconsax.trash, size: 16),
                      label: const Text('Clear'),
                    ),
                ],
              ),
              const SizedBox(height: BSizes.xs),

              // Item cards
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: BSizes.xs),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _InventoryItemTile(
                    item: item,
                    dark: dark,
                    onDelete: () => controller.removeScannedItem(index),
                  );
                },
              ),
            ],
          );
        }),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Opens the camera via [ImagePicker], then delegates to
  /// [StandardDeliveryController.analyzeFileForInventory].
  Future<void> _pickImage(
    StandardDeliveryController controller,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (picked == null) return; // user cancelled

    final file = File(picked.path);
    await controller.analyzeFileForInventory(file);
  }

  /// Opens the system file picker filtered to images and PDFs, then delegates
  /// to [StandardDeliveryController.analyzeFileForInventory].
  Future<void> _pickFile(StandardDeliveryController controller) async {
    try {
      final BuildContext context = Get.context ?? Get.rootDelegate.navigatorKey.currentContext!;

      final choice = await showModalBottomSheet<String?>(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Iconsax.image),
                  title: const Text('Pick image from gallery'),
                  onTap: () => Navigator.of(ctx).pop('gallery'),
                ),
                ListTile(
                  leading: const Icon(Iconsax.folder_2),
                  title: const Text('Pick any file'),
                  onTap: () => Navigator.of(ctx).pop('file'),
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.of(ctx).pop(null),
                ),
              ],
            ),
          );
        },
      );

      if (choice == null) return; // cancelled

      if (choice == 'gallery') {
        final picker = ImagePicker();
        final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (picked == null) return;
        final file = File(picked.path);
        await controller.analyzeFileForInventory(file);
        return;
      }

      if (choice == 'file') {
        // Allow common image types and PDFs
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowMultiple: false,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
          withData: true, // ensures bytes are available on web/limited platforms
        );

        if (result == null || result.files.isEmpty) return; // user cancelled

        final picked = result.files.single;

        String? path = picked.path;

        if (path == null && picked.bytes != null) {
          // Platform (web, some desktop) returns bytes only — write to temp file
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/${picked.name}');
          await tempFile.writeAsBytes(picked.bytes!);
          path = tempFile.path;
        }

        if (path == null) {
          BLoaders.errorSnackBar(title: 'File Error', message: 'Unable to resolve selected file path.');
          return;
        }

        final file = File(path);
        if (!await file.exists()) {
          BLoaders.errorSnackBar(title: 'File not found', message: 'Selected file does not exist.');
          return;
        }

        await controller.analyzeFileForInventory(file);
        return;
      }
    } catch (e, st) {
      BLoaders.errorSnackBar(title: 'File Error', message: e.toString());
      try {
        // optional debug log if available in project
        // ignore: avoid_catches_without_on_clauses
        logDebug('File picker error: $e\n$st');
      } catch (_) {}
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private tile widget – kept small and const-friendly
// ─────────────────────────────────────────────────────────────────────────────

class _InventoryItemTile extends StatelessWidget {
  const _InventoryItemTile({
    required this.item,
    required this.dark,
    required this.onDelete,
  });

  final InventoryItemModel item;
  final bool dark;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BSizes.sm,
        vertical: BSizes.sm,
      ),
      decoration: BoxDecoration(
        color: dark
            ? BColors.darkerGrey.withValues(alpha: 0.3)
            : BColors.light,
        borderRadius: BorderRadius.circular(BSizes.cardRadiusSm),
        border: Border.all(
          color: dark ? BColors.darkerGrey : BColors.grey,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item code
                Text(
                  item.itemCode,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                // Description
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Qty & Unit
                Text(
                  'Qty: ${item.qty % 1 == 0 ? item.qty.toInt() : item.qty}  •  ${item.unit}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: dark ? BColors.light : BColors.darkGrey,
                      ),
                ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Iconsax.close_circle,
              size: 20,
              color: dark ? BColors.light : BColors.darkGrey,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
