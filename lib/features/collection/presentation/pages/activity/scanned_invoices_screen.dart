import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/scanner/scanner_actions.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/scanned_invoice.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/voucher_scan_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

import 'widgets/voucher_file_picker.dart';

/// Scanned Invoices (meeting of 2026-10-07, item 2), laid out like the
/// Logistics Scanned Items screen: every number the scans read off the
/// client's voucher or Sales Invoice, each checked against this account. The
/// collector corrects or removes any, scans more pages (Capture / Attach
/// File), then selects the account's open invoices in its list.
class ScannedInvoicesScreen extends StatefulWidget {
  const ScannedInvoicesScreen({
    super.key,
    required this.client,
    this.takePhoto,
    this.attach,
    this.cameraAvailable,
  });

  final ClientModel client;

  /// Tests pass fakes; the app uses [BVoucherFilePicker].
  final VoucherFilePick? takePhoto;
  final VoucherFilePick? attach;

  /// Null: the camera only on Android.
  final bool? cameraAvailable;

  @override
  State<ScannedInvoicesScreen> createState() => _ScannedInvoicesScreenState();
}

class _ScannedInvoicesScreenState extends State<ScannedInvoicesScreen> {
  final controller = VoucherScanController.instance;

  @override
  void initState() {
    super.initState();
    controller.openFor(widget.client.id);
  }

  bool get _camera => widget.cameraAvailable ?? GetPlatform.isAndroid;

  Future<void> _read(VoucherFilePick pick) async {
    for (final page in await pick()) {
      if (!mounted) return;
      await controller.analyze(page);
    }
  }

  /// Ticks the account's open invoices on the list and goes back (to the
  /// account's list, or to the cart when opened from it).
  void _select() {
    controller.addToCart();
    Get.back();
  }

  Future<void> _edit(int index, ScannedInvoice tile) async {
    final typed =
        await Get.dialog<String>(_EditNumberDialog(initial: tile.read));
    if (typed != null) controller.edit(index, typed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text('Scanned Invoices (${controller.tiles.length})')),
        actions: [
          IconButton(
            key: const ValueKey('scanned-clear'),
            tooltip: 'Clear the list',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              controller.tiles.clear();
              controller.error.value = null;
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
              BSizes.defaultSpace,
              BSizes.spaceBtwItemsLight,
              BSizes.defaultSpace,
              BSizes.spaceBtwItemsLight),
          decoration: const BoxDecoration(
            color: BCollectionColors.surface,
            border: Border(top: BorderSide(color: BCollectionColors.outline)),
          ),
          child: Obx(() {
            final n = controller.addableIds.length;
            return ElevatedButton.icon(
              key: const ValueKey('scanned-add-to-cart'),
              onPressed:
                  n == 0 || controller.isAnalyzing.value ? null : _select,
              icon: const Icon(Iconsax.shopping_cart, size: 18),
              label: Text(n == 1 ? 'Select 1 invoice' : 'Select $n invoices'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: BCollectionColors.primary,
                foregroundColor: BCollectionColors.surface,
              ),
            );
          }),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        children: [
          Text(widget.client.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(
              'Capture or attach the client\'s voucher. The SI, Invoice and '
              'Sales Invoice numbers on it are listed and checked against '
              'this account. Scan more pages to add to the list.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: BCollectionColors.inkSecondary)),
          const SizedBox(height: BSizes.spaceBtwItems),
          Obx(() {
            final busy = controller.isAnalyzing.value;
            return ScannerActionRow(
              onCapture: busy || !_camera
                  ? null
                  : () =>
                      _read(widget.takePhoto ?? BVoucherFilePicker.takePhoto),
              onAttach: busy
                  ? null
                  : () => _read(widget.attach ?? BVoucherFilePicker.attach),
            );
          }),
          Obx(() {
            final error = controller.error.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (controller.isAnalyzing.value) const AnalyzingIndicator(),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: BSizes.sm),
                    child: Text(error,
                        key: const ValueKey('scanned-error'),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: BCollectionColors.danger)),
                  ),
                if (controller.anyOffline)
                  Container(
                    key: const ValueKey('scanned-offline'),
                    margin: const EdgeInsets.only(top: BSizes.sm),
                    padding: const EdgeInsets.all(BSizes.sm),
                    decoration: BoxDecoration(
                      color: BCollectionColors.warning.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(BSizes.borderRadiusMd),
                    ),
                    child: Text(
                        'Read on the phone, without the AI: check each number '
                        'carefully against the voucher.',
                        style: theme.textTheme.bodySmall),
                  ),
                const SizedBox(height: BSizes.sm),
                for (var i = 0; i < controller.tiles.length; i++)
                  _Tile(
                    tile: controller.tiles[i],
                    index: i,
                    onEdit: () => _edit(i, controller.tiles[i]),
                    onRemove: () => controller.remove(i),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.tile,
    required this.index,
    required this.onEdit,
    required this.onRemove,
  });

  final ScannedInvoice tile;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  static (IconData, Color) _look(ScannedInvoiceStatus s) => switch (s) {
        ScannedInvoiceStatus.matched => (
            Iconsax.tick_circle,
            BCollectionColors.success
          ),
        ScannedInvoiceStatus.likely => (
            Iconsax.tick_circle,
            BCollectionColors.warning
          ),
        ScannedInvoiceStatus.elsewhere => (
            Iconsax.warning_2,
            BCollectionColors.warning
          ),
        ScannedInvoiceStatus.ambiguous => (
            Iconsax.warning_2,
            BCollectionColors.warning
          ),
        ScannedInvoiceStatus.notFound => (
            Iconsax.close_circle,
            BCollectionColors.danger
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _look(tile.status);
    final subtitle = [
      if (tile.label.isNotEmpty) tile.label,
      tile.status.label,
      if (tile.invoiceId != null && tile.invoiceId != tile.read)
        'as ${tile.invoiceId}',
      if (tile.amount != null)
        'voucher ${BFormatter.formatPesoCurrency(tile.amount!)}',
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: BSizes.sm),
      child: ListTile(
        key: ValueKey('scanned-tile-$index'),
        leading: Icon(icon, color: color),
        title: Text(tile.read),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: ValueKey('scanned-edit-$index'),
              tooltip: 'Correct the number',
              icon: const Icon(Iconsax.edit_2, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              key: ValueKey('scanned-remove-$index'),
              tooltip: 'Remove',
              icon: const Icon(Iconsax.trash, size: 20),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

/// Correct one scanned number; owns its text field so it outlives the
/// dialog's closing animation.
class _EditNumberDialog extends StatefulWidget {
  const _EditNumberDialog({required this.initial});

  final String initial;

  @override
  State<_EditNumberDialog> createState() => _EditNumberDialogState();
}

class _EditNumberDialogState extends State<_EditNumberDialog> {
  late final _field = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Correct the number'),
        content: TextField(
          key: const ValueKey('scanned-edit-field'),
          controller: _field,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'SI / Invoice no.'),
          onSubmitted: (v) => Get.back(result: v),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
              key: const ValueKey('scanned-edit-save'),
              onPressed: () => Get.back(result: _field.text),
              child: const Text('Save')),
        ],
      );
}
