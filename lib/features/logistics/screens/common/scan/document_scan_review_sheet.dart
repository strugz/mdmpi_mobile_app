import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/widgets/scanner/scanned_items_screen.dart';
import 'package:mdmpi_mobile_app/data/controllers/client_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/delivery_document_scan_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/delivery_document_type.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/scan_form_target.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/delivery_document_scan_result.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/scan/client_match_picker.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/scan/document_scan_progress_sheet.dart';

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
                  const Text('None read.')
                else
                  Obx(() => Wrap(
                        spacing: BSizes.sm,
                        children: [
                          for (final ref in result.references)
                            FilterChip(
                              label: Text(ref),
                              selected: scan.selectedReferences.contains(ref),
                              onSelected: (_) => scan.toggleReference(ref),
                            ),
                        ],
                      )),
                const Divider(),

                /// Items
                Text('Items', style: theme.textTheme.titleSmall),
                if (items.items.isEmpty)
                  Text(items.headerFound
                      ? 'The item table was empty.'
                      : 'No item table found. Use Add Item.')
                else
                  Obx(() => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: scan.includeItems.value,
                        onChanged: (v) => scan.includeItems.value = v ?? false,
                        title: Text(
                            '${items.items.length} item${items.items.length == 1 ? '' : 's'} found'),
                        subtitle: Text(items.unsure.isEmpty
                            ? 'You can check and edit them after Apply.'
                            : '${items.unsure.length} to check (quantity or text unsure). '
                                'You can edit them after Apply.'),
                      )),
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
                result.items.items.isNotEmpty)
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
