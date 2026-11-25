import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/widgets/scanner/scanned_items_screen.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/controllers/client_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/delivery_document_scan_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/delivery_document_type.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/scan_form_target.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/delivery_document_scan_result.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/scan/client_match_picker.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/scan/document_scan_progress_sheet.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/scan/scan_source_sheet.dart';

/// Review of one scan before anything reaches the form (plan §3): confirm
/// the client (never pre-selected), untick references, and apply. Items go
/// to the existing items screen right after Apply so they are always checked.
/// Scanning from the Request screen, the sheet also asks which request the
/// document is for, and [onApplied] opens that form.
class DocumentScanReviewSheet extends StatelessWidget {
  const DocumentScanReviewSheet(
      {super.key, required this.scanning, this.onApplied});

  /// The scan in flight; the sheet shows progress until it completes.
  final Future<bool> scanning;

  /// Called after Apply, once the sheet is closed. Null: the form is already
  /// open, so only the items screen follows.
  final void Function(OneScanApplied applied)? onApplied;

  static Future<void> show(BuildContext context,
      {required Future<bool> scanning,
      void Function(OneScanApplied applied)? onApplied}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (_) =>
          DocumentScanReviewSheet(scanning: scanning, onApplied: onApplied),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scan = Get.find<DeliveryDocumentScanController>();
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: FutureBuilder<bool>(
          future: scanning,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const DocumentScanProgress();
            }
            final result = scan.result.value;
            if (snapshot.data != true || result == null) {
              return _Failed(message: scan.error.value);
            }
            return _Review(scan: scan, result: result, onApplied: onApplied);
          },
        ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BSizes.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message ?? 'Could not read the document.'),
          const SizedBox(height: BSizes.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({required this.scan, required this.result, this.onApplied});

  final DeliveryDocumentScanController scan;
  final DeliveryDocumentScanResult result;
  final void Function(OneScanApplied applied)? onApplied;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = result.items;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Check the scan', style: theme.textTheme.titleMedium),
                if (result.documentType != DeliveryDocumentType.unknown)
                  Text('Document: ${result.documentType.label}',
                      style: theme.textTheme.bodySmall),
                Obx(() {
                  final warning = scan.documentWarning;
                  if (warning == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: BSizes.sm),
                    child: Row(
                      key: const Key('scanDocumentWarning'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Iconsax.warning_2,
                            size: BSizes.iconSm,
                            color: theme.colorScheme.error),
                        const SizedBox(width: BSizes.sm),
                        Expanded(child: Text(warning)),
                      ],
                    ),
                  );
                }),
                _TargetSection(scan: scan, result: result),
                for (final w in result.warnings)
                  Padding(
                    padding: const EdgeInsets.only(top: BSizes.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Iconsax.info_circle,
                            size: BSizes.iconSm,
                            color: theme.colorScheme.error),
                        const SizedBox(width: BSizes.sm),
                        Expanded(child: Text(w)),
                      ],
                    ),
                  ),
                const SizedBox(height: BSizes.md),

                /// Client
                Text('Client', style: theme.textTheme.titleSmall),
                if (result.header.hasName)
                  Text('Read: ${result.header.name}',
                      style: theme.textTheme.bodySmall),
                _ClientSection(scan: scan, result: result),
                const Divider(),

                /// References
                Text('References', style: theme.textTheme.titleSmall),
                if (result.references.isEmpty)
                  const Text('None read.'),
                Obx(() => Wrap(
                      spacing: BSizes.sm,
                      children: [
                        for (final ref in scan.allReferences)
                          FilterChip(
                            label: Text(ref),
                            selected: scan.selectedReferences.contains(ref),
                            onSelected: (_) => scan.toggleReference(ref),
                          ),
                        ActionChip(
                          key: const Key('scanAddReference'),
                          avatar: const Icon(Iconsax.add, size: BSizes.iconSm),
                          label: const Text('Add reference'),
                          onPressed: () => _addReference(context),
                        ),
                        ActionChip(
                          key: const Key('scanReferencesAgain'),
                          avatar: scan.isScanningReferences.value
                              ? const SizedBox.square(
                                  dimension: BSizes.iconSm,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Iconsax.scan, size: BSizes.iconSm),
                          label: Text(scan.isScanningReferences.value
                              ? 'Reading…'
                              : 'Scan references'),
                          onPressed: scan.isScanningReferences.value
                              ? null
                              : () => _scanReferences(context),
                        ),
                      ],
                    )),
                const Divider(),

                /// Items
                Text('Items', style: theme.textTheme.titleSmall),
                Obx(() {
                  final rows = scan.reviewItems.toList();
                  if (rows.isEmpty) {
                    return Text(items.headerFound
                        ? 'The item table was empty. Use Add item below.'
                        : 'No item table found. Use Add item below.');
                  }
                  final include = scan.includeItems.value;
                  final toCheck = rows.where((r) => r.unsure).length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CheckboxListTile(
                        key: const Key('scanIncludeItems'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: include,
                        onChanged: (v) => scan.includeItems.value = v ?? false,
                        title: Text(
                            'Add ${rows.length} item${rows.length == 1 ? '' : 's'}'),
                        subtitle: Text(toCheck == 0
                            ? 'Tap an item to change it.'
                            : '$toCheck marked to check. Tap an item to fix it.'),
                      ),
                      // Unticked: the list stays readable but clearly out.
                      AnimatedOpacity(
                        opacity: include ? 1 : 0.4,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        child: Column(
                          children: [
                            for (var i = 0; i < rows.length; i++)
                              _ItemRow(
                                key: Key('scanItem-$i'),
                                row: rows[i],
                                onTap: () => _editItem(context, i),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
                Wrap(
                  spacing: BSizes.sm,
                  children: [
                    ActionChip(
                      key: const Key('scanAddItem'),
                      avatar: const Icon(Iconsax.add, size: BSizes.iconSm),
                      label: const Text('Add item'),
                      onPressed: () => _addItem(context),
                    ),
                    Obx(() {
                      final busy = scan.isScanningItems.value;
                      return ActionChip(
                        key: const Key('scanItemsAgain'),
                        avatar: busy
                            ? const SizedBox.square(
                                dimension: BSizes.iconSm,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Iconsax.scan, size: BSizes.iconSm),
                        label: Text(busy ? 'Reading…' : 'Scan items'),
                        onPressed: busy ? null : () => _scanItems(context),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(BSizes.md, 0, BSizes.md, BSizes.sm),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    scan.discard();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: BSizes.md),
              Expanded(
                // The app theme greys out a disabled button's text completely,
                // so this one keeps a readable label that says what is missing.
                child: Obx(() => ElevatedButton(
                      key: const Key('applyScan'),
                      style: ElevatedButton.styleFrom(
                        disabledForegroundColor: Colors.white,
                      ),
                      onPressed:
                          scan.canApply ? () => _apply(context) : null,
                      child: Text(
                          scan.canApply
                              ? 'Apply'
                              : scan.target.value == null
                                  ? 'Pick a request first'
                                  : 'Pick a client first',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addReference(BuildContext context) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => const _AddReferenceDialog(),
    );
    if (value == null || value.trim().isEmpty) return;
    if (!scan.addReference(value)) {
      BLoaders.warningSnackBar(
          title: 'Already listed', message: '${value.trim()} is already a reference.');
    }
  }

  Future<void> _scanReferences(BuildContext context) async {
    final source = await ScanSourceSheet.show(context,
        title: 'Scan for references',
        subtitle: 'Only the references on this page are added. The client '
            'and items you already have stay as they are.');
    if (source == null) return;
    final file = await ScanSourceSheet.pickFile(scan, source);
    if (file == null) return;
    final added = await scan.scanReferences(file);
    if (added == null) {
      BLoaders.errorSnackBar(
          title: 'Scan references',
          message: scan.error.value ?? 'Could not read the page.');
    } else if (added == 0) {
      BLoaders.warningSnackBar(
          title: 'No new references',
          message: 'Nothing on that page that is not already listed.');
    } else {
      BLoaders.successSnackBar(
          title: 'References added',
          message: 'Added $added reference${added == 1 ? '' : 's'}.');
    }
  }

  Future<void> _editItem(BuildContext context, int index) async {
    final current = scan.reviewItems[index].item;
    final edit = await showDialog<_ItemEdit>(
      context: context,
      builder: (_) => _EditItemDialog(item: current),
    );
    if (edit == null) return;
    if (edit.remove) {
      scan.removeItem(index);
    } else {
      scan.updateItem(index, edit.item!);
    }
  }

  Future<void> _addItem(BuildContext context) async {
    final edit = await showDialog<_ItemEdit>(
      context: context,
      builder: (_) => const _EditItemDialog(),
    );
    final item = edit?.item;
    if (item != null) scan.addItem(item);
  }

  Future<void> _scanItems(BuildContext context) async {
    final source = await ScanSourceSheet.show(context,
        title: 'Scan for items',
        subtitle: 'Only the items on this page are added, e.g. page 2 of the '
            'invoice. The client and references stay as they are.');
    if (source == null) return;
    final file = await ScanSourceSheet.pickFile(scan, source);
    if (file == null) return;
    final added = await scan.scanItems(file);
    if (added == null) {
      BLoaders.errorSnackBar(
          title: 'Scan items',
          message: scan.error.value ?? 'Could not read the page.');
    } else if (added == 0) {
      BLoaders.warningSnackBar(
          title: 'No new items',
          message: 'No item rows on that page that are not already listed.');
    } else {
      BLoaders.successSnackBar(
          title: 'Items added',
          message: 'Added $added item${added == 1 ? '' : 's'}.');
    }
  }

  Future<void> _apply(BuildContext context) async {
    final form = Get.find<StandardDeliveryController>();
    if (scan.replacesClientOn(form)) {
      final current = form.formState.clientInformation.value!.name;
      final next = scan.confirmedClient.value!.name;
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace client?'),
          content: Text('Replace client $current with $next?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Keep current')),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Replace')),
          ],
        ),
      );
      if (replace != true) scan.chooseSkipClient();
    }

    final applied = scan.applyToForm(form);
    scan.discard();
    if (!context.mounted) return;
    Navigator.of(context).pop();

    final parts = [
      if (applied.target != null && onApplied != null) applied.target!.label,
      if (applied.clientSet) 'client',
      if (applied.referencesAdded > 0)
        '${applied.referencesAdded} reference${applied.referencesAdded == 1 ? '' : 's'}',
      if (applied.itemsAdded > 0)
        '${applied.itemsAdded} item${applied.itemsAdded == 1 ? '' : 's'}',
    ];
    BLoaders.successSnackBar(
      title: 'Scan applied',
      message: [
        parts.isEmpty ? 'Nothing new to add.' : 'Added ${parts.join(', ')}.',
        if (applied.itemsSkipped) 'Items left out: this form has no items.',
      ].join(' '),
    );
    final opened = onApplied;
    if (opened != null) {
      opened(applied);
      return;
    }
    if (applied.itemsAdded > 0) {
      Get.to(() => ScannedItemsScreen(controller: form));
    }
  }
}

class _ClientSection extends StatelessWidget {
  const _ClientSection({required this.scan, required this.result});

  final DeliveryDocumentScanController scan;
  final DeliveryDocumentScanResult result;

  Future<void> _search(BuildContext context) async {
    final clients = Get.find<ClientController>();
    final seed = scan.searchSeed;
    // The search sheet's list is not reactive (plan §10 F1), so load the
    // matches first and open it with them already there.
    await clients.filterClientFromDb(seed);
    if (!context.mounted) return;
    BFullScreenLoader.showSearchSheet(
      context,
      clients,
      Get.find<StandardDeliveryController>(),
      initialQuery: seed,
      onClientSelected: scan.confirmClient,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final chosen = scan.confirmedClient.value;
      if (chosen != null) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Iconsax.tick_circle),
          title: Text(chosen.name),
          subtitle: Text(scan.addressFromScan.value
              ? '${chosen.address}\nAddress from scanned document'
              : chosen.address),
          isThreeLine: scan.addressFromScan.value,
          trailing: TextButton(
            onPressed: () => scan.confirmedClient.value = null,
            child: const Text('Change'),
          ),
        );
      }
      if (scan.skipClient.value) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Client skipped: the form keeps its client.'),
          trailing: TextButton(
            onPressed: () => scan.skipClient.value = false,
            child: const Text('Undo'),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.match.showList) ...[
            Text('Tap the right client:', style: theme.textTheme.bodySmall),
            ClientMatchPicker(
              match: result.match,
              onPick: (c) => scan.confirmClient(c.client),
            ),
          ],
          Wrap(
            spacing: BSizes.sm,
            children: [
              TextButton.icon(
                key: const Key('scanSearchClient'),
                onPressed: () => _search(context),
                icon: const Icon(Iconsax.search_normal, size: BSizes.iconSm),
                label: Text(result.match.showList ? 'Search instead' : 'Search'),
              ),
              TextButton(
                key: const Key('scanSkipClient'),
                onPressed: scan.chooseSkipClient,
                child: const Text('Skip client'),
              ),
            ],
          ),
        ],
      );
    });
  }
}

String _qtyText(double qty) =>
    qty % 1 == 0 ? qty.toInt().toString() : qty.toString();

/// One scanned item: code and quantity first (what gets checked against the
/// paper), description under it. A row to check carries a warning mark.
class _ItemRow extends StatelessWidget {
  const _ItemRow({super.key, required this.row, required this.onTap});

  final ReviewItem row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = row.item;
    // The code the edit dialog changes, so an edit shows up right away.
    final code = item.itemCode.isNotEmpty
        ? item.itemCode
        : (item.partNo.isNotEmpty ? item.partNo : '(no code)');
    final qty = '× ${_qtyText(item.qty)}${item.unit.isEmpty ? '' : ' ${item.unit}'}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BSizes.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BSizes.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: row.unsure
                  ? Icon(Iconsax.warning_2,
                      size: BSizes.iconSm, color: theme.colorScheme.error)
                  : Icon(Iconsax.box,
                      size: BSizes.iconSm,
                      color: theme.colorScheme.onSurfaceVariant),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: BSizes.sm),
                      Text(qty,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (item.description.isNotEmpty)
                    Text(item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall),
                  if (item.serialNo.isNotEmpty)
                    Text('S/N ${item.serialNo}',
                        style: theme.textTheme.bodySmall),
                  if (row.unsure)
                    Text('Check code, quantity or text',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error)),
                ],
              ),
            ),
            const SizedBox(width: BSizes.sm),
            Icon(Iconsax.edit_2,
                size: BSizes.iconSm,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// What the item dialog decided: an edited item, or remove the row.
class _ItemEdit {
  const _ItemEdit.save(InventoryItemModel this.item) : remove = false;
  const _ItemEdit.remove()
      : item = null,
        remove = true;

  final InventoryItemModel? item;
  final bool remove;
}

/// Edits one scanned item before Apply: code, description, quantity, unit
/// and serial. Batches and the other fields are kept as read. Without
/// [item] it adds a new one (quantity 1, no Remove).
class _EditItemDialog extends StatefulWidget {
  const _EditItemDialog({this.item});

  final InventoryItemModel? item;

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  final _form = GlobalKey<FormState>();
  late final InventoryItemModel _base = widget.item ??
      InventoryItemModel(itemCode: '', description: '', qty: 1, unit: '');
  late final _code = TextEditingController(text: _base.itemCode);
  late final _description = TextEditingController(text: _base.description);
  late final _qty = TextEditingController(text: _qtyText(_base.qty));
  late final _unit = TextEditingController(text: _base.unit);
  late final _serial = TextEditingController(text: _base.serialNo);
  bool get _isNew => widget.item == null;

  @override
  void dispose() {
    for (final c in [_code, _description, _qty, _unit, _serial]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_ItemEdit.save(_base.copyWith(
      itemCode: _code.text.trim(),
      description: _description.text.trim(),
      qty: double.parse(_qty.text.trim()),
      unit: _unit.text.trim(),
      serialNo: _serial.text.trim(),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      title: Text(_isNew ? 'Add item' : 'Edit item'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('scanItemCode'),
                controller: _code,
                autofocus: _isNew,
                decoration: const InputDecoration(labelText: 'Item code'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: BSizes.sm),
              TextFormField(
                key: const Key('scanItemDescription'),
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 1,
                maxLines: 3,
                validator: (v) => (v ?? '').trim().isEmpty &&
                        _code.text.trim().isEmpty
                    ? 'Enter a code or a description'
                    : null,
              ),
              const SizedBox(height: BSizes.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('scanItemQty'),
                      controller: _qty,
                      decoration: const InputDecoration(labelText: 'Qty'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        return n == null || n <= 0 ? 'More than 0' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: BSizes.sm),
                  Expanded(
                    child: TextFormField(
                      key: const Key('scanItemUnit'),
                      controller: _unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BSizes.sm),
              TextFormField(
                key: const Key('scanItemSerial'),
                controller: _serial,
                decoration: const InputDecoration(labelText: 'Serial no.'),
                onFieldSubmitted: (_) => _save(),
              ),
            ],
          ),
        ),
      ),
      actionsAlignment:
          _isNew ? MainAxisAlignment.end : MainAxisAlignment.spaceBetween,
      actions: [
        if (!_isNew)
          TextButton(
            key: const Key('scanItemRemove'),
            onPressed: () =>
                Navigator.of(context).pop(const _ItemEdit.remove()),
            child: Text('Remove', style: TextStyle(color: error)),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            TextButton(
                key: const Key('scanItemSave'),
                onPressed: _save,
                child: Text(_isNew ? 'Add' : 'Save')),
          ],
        ),
      ],
    );
  }
}

/// Asks for one reference the scan missed; pops the typed text.
class _AddReferenceDialog extends StatefulWidget {
  const _AddReferenceDialog();

  @override
  State<_AddReferenceDialog> createState() => _AddReferenceDialogState();
}

class _AddReferenceDialogState extends State<_AddReferenceDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_text.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add reference'),
      content: TextField(
        key: const Key('scanAddReferenceField'),
        controller: _text,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(hintText: 'e.g. PONo.:100108292'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        TextButton(
            key: const Key('scanAddReferenceOk'),
            onPressed: _submit,
            child: const Text('Add')),
      ],
    );
  }
}

/// Scan first: which request the document is for. Only the forms the
/// document belongs to and the user may create are offered; with one, it is
/// already chosen.
class _TargetSection extends StatelessWidget {
  const _TargetSection({required this.scan, required this.result});

  final DeliveryDocumentScanController scan;
  final DeliveryDocumentScanResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (!scan.choosesTarget.value) return const SizedBox.shrink();
      final choices = scan.targetChoices.toList();
      final chosen = scan.target.value;
      return Padding(
        padding: const EdgeInsets.only(top: BSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request', style: theme.textTheme.titleSmall),
            if (choices.isEmpty)
              Text(
                  'You cannot create a request for '
                  '${result.documentType == DeliveryDocumentType.unknown ? 'this document' : 'a ${result.documentType.label}'}.',
                  style: TextStyle(color: theme.colorScheme.error))
            else
              Wrap(
                spacing: BSizes.sm,
                children: [
                  for (final form in choices)
                    ChoiceChip(
                      key: Key('scanTarget-${form.name}'),
                      label: Text(form.label),
                      selected: chosen == form,
                      onSelected: (_) => scan.chooseTarget(form),
                    ),
                ],
              ),
            if (chosen != null &&
                !ScanFormTarget.takesItems(chosen) &&
                scan.allItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: BSizes.xs),
                child: Text('${chosen.label} has no items; they are left out.',
                    style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      );
    });
  }
}
