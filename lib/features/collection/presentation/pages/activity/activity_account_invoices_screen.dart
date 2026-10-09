import 'package:mdmpi_mobile_app/data/services/collection_sms_service.dart';
import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/collection_search_filter_bar.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'activity_detail_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/invoice_card.dart';
import 'widgets/defer_reason_sheet.dart';
import 'widgets/invoice_filter_sheet.dart';
import 'widgets/invoice_details_modal.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/po_grouping.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/invoice_search.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/po_invoice_group_card.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/invoice_view_toggle.dart';
import 'invoice_cart_screen.dart';
import 'scanned_invoices_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/voucher_scan_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/models/scanned_invoice.dart';
import 'widgets/voucher_file_picker.dart';
import 'package:mdmpi_mobile_app/data/services/outbox/voucher_reread_service.dart';

/// One claimed account's invoices. Tapping opens an invoice's record;
/// a long-press starts the cart (meeting of 2026-10-07, item 1), where taps
/// add and remove. Scan reads a client's voucher or a Sales Invoice and
/// ticks its SIs right here (scrolled to, with a banner saying what was not
/// found); Details opens Scanned Invoices to fix misreads. The PO | SI
/// switch picks P.O. groups or a flat SI list.
class CollectionActivityAccountInvoicesScreen extends StatefulWidget {
  final ClientModel client;

  /// Tests pass a fake; the app asks for a photo, an image or a PDF.
  final VoucherPagesPick? pickVoucher;

  const CollectionActivityAccountInvoicesScreen(
      {super.key, required this.client, this.pickVoucher});

  @override
  State<CollectionActivityAccountInvoicesScreen> createState() =>
      _CollectionActivityAccountInvoicesScreenState();
}

class _CollectionActivityAccountInvoicesScreenState
    extends State<CollectionActivityAccountInvoicesScreen> {
  final controller = Get.find<CollectionActivityController>();

  /// Scrolls the list to a card the scan ticked.
  final _scroll = ScrollController();
  final Map<String, GlobalKey> _cardKeys = {};

  VoucherScanController? get _scan => Get.isRegistered<VoucherScanController>()
      ? VoucherScanController.instance
      : null;

  /// P.O. groups opened or closed by hand. The default mirrors the bucket
  /// side: closed across several P.O.s, open for a single one or under a
  /// search. Ticked invoices are not in them but in the Selected group at
  /// the top, so a closed P.O. never hides a tick.
  final Map<String, bool> _expandedOverrides = {};

  /// The Selected group at the top: open by default and after every scan.
  bool _selectedExpanded = true;

  bool _isExpanded(PoGrouping grouping, PoInvoiceGroup group) {
    final override = _expandedOverrides[group.key];
    if (override != null) return override;
    return grouping.groups.length == 1 ||
        controller.invoiceSearchQuery.value.isNotEmpty;
  }

  void _toggle(PoGrouping grouping, PoInvoiceGroup group) {
    setState(() {
      _expandedOverrides[group.key] = !_isExpanded(grouping, group);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    controller.invoiceSearchQuery.value = ''; // Reset search on leave
    controller.clearInvoiceFilters(); // ...and the filter with it
    controller.exitActivitySelectionMode(); // Exit selection on leave
    if (Get.isRegistered<VoucherScanController>()) {
      VoucherScanController.instance.reset(); // ...and the voucher list
    }
    super.dispose();
  }

  /// One invoice card with this screen's behaviour: tap opens the record
  /// screen or toggles the tick, long-press ticks, the info glyph opens the
  /// details sheet. Shared by the flat list and the P.O. groups.
  Widget _invoiceCard(BuildContext context, CollectionItemModel item,
      {bool showPoNumber = true}) {
    final isSelected = controller.selectedActivityInvoiceIds.contains(item.id);
    return KeyedSubtree(
        key: _cardKeys.putIfAbsent(item.id, GlobalKey.new),
        child: InvoiceCard(
          item: item,
          showPoNumber: showPoNumber,
          isSelected: isSelected,
          isSelectionMode: controller.isActivitySelectionMode.value,
          onTap: () {
            if (controller.isActivitySelectionMode.value) {
              controller.toggleActivityInvoiceSelection(item.id);
            } else {
              Get.to(() => ActivityDetailScreen(item: item));
            }
          },
          onLongPress: () => controller.toggleActivityInvoiceSelection(item.id),
          onInfoTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              showDragHandle: false,
              backgroundColor: Colors.transparent,
              builder: (sheetContext) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(sheetContext).bottom),
                child: InvoiceDetailsModal(item: item),
              ),
            );
          },
        ));
  }

  /// The account's list: every selected invoice in the collapsible Selected
  /// group at the top, then the rest, grouped by P.O. ([mode] PO) or flat.
  Widget _list(BuildContext context, List<CollectionItemModel> invoices,
      InvoiceViewMode mode) {
    final spec = controller.invoiceFilterSpec.value;
    final selected = controller.cartItems(widget.client.id)..sort(spec.compare);
    final selectedIds = {for (final i in selected) i.id};
    final rest = invoices.where((i) => !selectedIds.contains(i.id)).toList();
    final grouping = PoGrouping.of(rest);

    final rows = <Widget>[
      if (selected.isNotEmpty)
        _SelectedGroup(
          key: const ValueKey('cart-group'),
          count: selected.length,
          total: controller.cartTotal(widget.client.id),
          expanded: _selectedExpanded,
          onToggle: () =>
              setState(() => _selectedExpanded = !_selectedExpanded),
          children: [
            for (final item in selected)
              _invoiceCard(context, item, showPoNumber: mode.showsPo),
          ],
        ),
      if (grouping.hasGroups && mode.showsPo) ...[
        for (final g in grouping.groups)
          PoInvoiceGroupCard(
            key: ValueKey('po-${g.key}'),
            group: g,
            expanded: _isExpanded(grouping, g),
            onToggle: () => _toggle(grouping, g),
            itemBuilder: (item) =>
                _invoiceCard(context, item, showPoNumber: false),
          ),
        if (grouping.ungrouped.isNotEmpty) ...[
          const PoSectionLabel('No P.O.'),
          for (final inv in grouping.ungrouped) _invoiceCard(context, inv),
        ],
      ] else
        // SI mode, or no P.O. on any invoice: a flat list.
        for (final inv in rest)
          _invoiceCard(context, inv, showPoNumber: mode.showsPo),
    ];

    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.all(BSizes.defaultSpace),
      itemCount: rows.length,
      separatorBuilder: (_, index) =>
          rows[index] is PoSectionLabel || rows[index + 1] is PoSectionLabel
              ? const SizedBox.shrink()
              : const SizedBox(height: BSizes.spaceBtwItems),
      itemBuilder: (_, index) => rows[index],
    );
  }

  Future<void> _showUnclaimWithReasonDialog() async {
    final reason = await DeferReasonSheet.show(
      context,
      accountName: widget.client.name,
    );
    if (reason == null || !mounted) return;

    controller.unclaimWithReason(
        widget.client.id, reason.status, reason.remarks);

    Get.back(); // Return to Activity list

    if (!CollectionSmsService.smsFollows()) {
      BLoaders.successSnackBar(
        title: 'Account Released',
        message: '${widget.client.name} moved back to bucket.',
      );
    }
  }

  void _clearEngagement() {
    controller.unclaimAccount(widget.client.id);
    Get.back();
    if (!CollectionSmsService.smsFollows()) {
      BLoaders.successSnackBar(
        title: 'Engagement done',
        message: '${widget.client.name} is no longer assigned to you.',
      );
    }
  }

  /// Closing out the account: both actions release it, so neither is
  /// destructive and neither earns a saturated fill. They used to be two
  /// filled buttons (red and raw Material blue) sitting above the invoices,
  /// louder than the work itself and competing for primacy. Clearing is the
  /// common path, so it leads; deferring is the exception and sits quiet
  /// beside it. Hidden while selecting, where batch recording is the job.
  Widget? _bottomBar() {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
    );

    // The cart: what is in it, and the way to review it.
    final cart = controller.cartItems(widget.client.id);
    if (controller.isActivitySelectionMode.value && cart.isNotEmpty) {
      return SafeArea(
        top: false,
        child: Container(
          key: const ValueKey('cart-bar'),
          padding: const EdgeInsets.fromLTRB(
            BSizes.defaultSpace,
            BSizes.spaceBtwItemsLight,
            BSizes.defaultSpace,
            BSizes.spaceBtwItemsLight,
          ),
          decoration: const BoxDecoration(
            color: BCollectionColors.surface,
            border: Border(top: BorderSide(color: BCollectionColors.outline)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: _CartSummary(
                  count: cart.length,
                  total: controller.cartTotal(widget.client.id),
                ),
              ),
              const SizedBox(width: BSizes.spaceBtwItemsLight),
              // Its natural width when it fits; on a narrow phone at large
              // text it gives way rather than pushing past the edge.
              Flexible(
                flex: 6,
                child: _ReviewInvoiceButton(onPressed: _openCart),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      key: const ValueKey('account-bar'),
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace,
          BSizes.spaceBtwItemsLight,
          BSizes.defaultSpace,
          BSizes.spaceBtwItemsLight,
        ),
        decoration: const BoxDecoration(
          color: BCollectionColors.surface,
          border: Border(top: BorderSide(color: BCollectionColors.outline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _showUnclaimWithReasonDialog,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: shape,
                  foregroundColor: BCollectionColors.inkSecondary,
                  side: const BorderSide(color: BCollectionColors.outline),
                ),
                child: const Text('Defer', maxLines: 1),
              ),
            ),
            const SizedBox(width: BSizes.spaceBtwItemsLight),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _clearEngagement,
                icon: const Icon(Iconsax.tick_circle, size: 18),
                label: const Text('Done Engagement', maxLines: 1),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: shape,
                  elevation: 0,
                  backgroundColor: BCollectionColors.primary,
                  foregroundColor: BCollectionColors.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCart() => Get.to(() => InvoiceCartScreen(
        client: widget.client,
        onScan: () async =>
            Get.to(() => ScannedInvoicesScreen(client: widget.client)),
      ));

  /// Reads a client's voucher (or a Sales Invoice) and ticks its SIs in
  /// this list, scrolled to the first; the banner says what was not found.
  Future<void> _scanVoucher() async {
    final scan = _scan;
    if (scan == null) return;
    scan.openFor(widget.client.id);
    final pick = widget.pickVoucher ??
        () => BVoucherFilePicker.choose(camera: GetPlatform.isAndroid);
    final (:pages, :useAi) = await pick();
    if (pages.isEmpty || !mounted) return;
    final summary = await scan.scanAndSelect(pages, useAi: useAi);
    if (!mounted) return;
    if (summary == null) {
      BLoaders.errorSnackBar(
          title: 'Voucher not read', message: scan.error.value ?? '');
      return;
    }
    if (summary.selectedIds.isNotEmpty) _showSelected();
  }

  /// Opens the Selected group and brings the top of the list into view,
  /// where the invoices a scan just selected are.
  void _showSelected() {
    setState(() => _selectedExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic);
      }
    });
  }

  /// What an online re-read of this account's offline scans found that the
  /// phone's reading missed, with a way to select it.
  Widget _rereadBanner() {
    if (!Get.isRegistered<VoucherRereadService>()) {
      return const SizedBox.shrink();
    }
    final service = VoucherRereadService.instance;
    return Obx(() {
      final records = service.unseenFor(widget.client.id);
      // Only what is still open and not in the cart already.
      final open = {
        for (final i in controller.getActivityOpenInvoices(widget.client.id))
          i.id
      };
      final ids = {
        for (final r in records) ...r.foundIds,
      }
          .where((id) =>
              open.contains(id) &&
              !controller.selectedActivityInvoiceIds.contains(id))
          .toList();
      if (records.isEmpty) return const SizedBox.shrink();
      if (ids.isEmpty) {
        // All of it is selected or settled already: nothing to show.
        WidgetsBinding.instance
            .addPostFrameCallback((_) => service.markSeen(records));
        return const SizedBox.shrink();
      }
      return _RereadBanner(
        ids: ids,
        onSelect: () {
          controller.addFromVoucher(ids);
          service.markSeen(records);
          _showSelected();
        },
        onClose: () => service.markSeen(records),
      );
    });
  }

  void _openScanDetails() =>
      Get.to(() => ScannedInvoicesScreen(client: widget.client));

  /// What the last scan ticked and what it could not, above the list.
  Widget _scanBanner(BuildContext context) {
    final scan = _scan;
    if (scan == null) return const SizedBox.shrink();
    return Obx(() {
      final busy = scan.isAnalyzing.value;
      final last = scan.bannerFor(widget.client.id);
      if (busy) {
        return const Padding(
          padding: EdgeInsets.fromLTRB(
              BSizes.defaultSpace, BSizes.sm, BSizes.defaultSpace, 0),
          child: LinearProgressIndicator(key: ValueKey('voucher-reading')),
        );
      }
      if (last == null) return const SizedBox.shrink();
      return _ScanBanner(
        summary: last,
        onDetails: _openScanDetails,
        onClose: () => scan.lastScan.value = null,
      );
    });
  }

  /// Leaving with a scanned voucher in the cart loses it: ask first.
  Future<void> _confirmLeave() async {
    final leave = await Get.dialog<bool>(AlertDialog(
      title: const Text('Leave and empty the cart?'),
      content: const Text(
          'The invoices from the scanned voucher will be taken out of the '
          'cart.'),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Stay')),
        TextButton(
            key: const ValueKey('cart-leave'),
            onPressed: () => Get.back(result: true),
            child: const Text('Leave')),
      ],
    ));
    if (leave == true && mounted) {
      controller.exitActivitySelectionMode();
      Get.back();
    }
  }

  /// Why the list is empty, and — when it is a filter doing it — the way out.
  /// A filter that empties the list and leaves nothing but the sentence
  /// "No invoices match" makes the account look settled when it is not.
  Widget _emptyState() {
    final filtered = controller.hasActiveInvoiceFilter;
    final searched = controller.invoiceSearchQuery.value.isNotEmpty;

    if (!filtered && !searched) {
      return const Text('No claimed invoices for this account.');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          searched
              ? 'No invoices match your search.'
              : 'No invoices match the filter.',
          textAlign: TextAlign.center,
        ),
        if (filtered) ...[
          const SizedBox(height: BSizes.spaceBtwItemsLight),
          TextButton(
            onPressed: controller.clearInvoiceFilters,
            child: const Text('Clear filter'),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selecting = controller.isActivitySelectionMode.value;
      final scannedCart = controller.voucherInvoiceIds.isNotEmpty &&
          controller.cartItems(widget.client.id).isNotEmpty;
      return PopScope(
        canPop: !scannedCart,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmLeave();
        },
        child: Scaffold(
          appBar: AppBar(
            leading: selecting
                ? IconButton(
                    key: const ValueKey('cart-clear'),
                    tooltip: 'Empty the cart',
                    icon: const Icon(Icons.close),
                    onPressed: () => controller.exitActivitySelectionMode(),
                  )
                : null,
            title: Text(
              selecting
                  ? '${controller.cartItems(widget.client.id).length} in cart'
                  : widget.client.name,
            ),
            actions: [
              IconButton(
                key: const ValueKey('voucher-scan'),
                tooltip: 'Scan a voucher',
                icon:
                    const Icon(Iconsax.scan, color: BCollectionColors.onHeader),
                onPressed:
                    _scan?.isAnalyzing.value == true ? null : _scanVoucher,
              ),
              if (selecting)
                TextButton(
                  key: const ValueKey('cart-select-all'),
                  onPressed: () =>
                      controller.toggleSelectAllVisible(widget.client.id),
                  child: Text(
                    controller.isAllVisibleSelected(widget.client.id)
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(color: BCollectionColors.onHeader),
                  ),
                ),
            ],
          ),
          // One bottom bar holding the primary action for the current mode:
          // batch recording while selecting, closing the account out otherwise.
          // Starting or ending the cart swaps the bar: a short fade and a
          // small rise, so the change of mode reads as one motion.
          bottomNavigationBar: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            reverseDuration: const Duration(milliseconds: 120),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.12), end: Offset.zero)
                    .animate(animation),
                child: child,
              ),
            ),
            child: _bottomBar(),
          ),
          body: Obx(() {
            final invoices =
                controller.getActivityInvoicesByAccount(widget.client.id);
            final mode = controller.invoiceViewMode.value;
            // Nothing to switch when no invoice of the account has a P.O.
            final hasPo = controller
                .getActivityOpenInvoices(widget.client.id)
                .any((i) => i.hasPoNumber);

            return Column(
              children: [
                /// Search and Filter Bar
                // Invoices, not engagements: this filter asks how late, how
                // much and what has been recorded, and counts invoices. The
                // engagement sheet used to open here, offering an area every
                // invoice in the account already shares and a button that
                // promised to show accounts. It stays while carting: a long
                // list is searched to find what to add.
                Obx(() => CollectionSearchFilterBar(
                      searchHint: controller.invoiceViewMode.value.searchHint,
                      initialValue: controller.invoiceSearchQuery.value,
                      onSearchChanged: (value) =>
                          controller.invoiceSearchQuery.value = value,
                      hasActiveFilter: controller.hasActiveInvoiceFilter,
                      onFilterTap: () async {
                        final chosen = await InvoiceFilterSheet.show(
                          context,
                          initial: controller.invoiceFilterSpec.value,
                          count: (spec) => controller.countActivityInvoices(
                              widget.client.id, spec),
                        );
                        if (chosen != null) {
                          controller.invoiceFilterSpec.value = chosen;
                        }
                      },
                    )),
                Obx(() => ActiveInvoiceFilterChips(
                      filter: controller.invoiceFilterSpec.value,
                      onChanged: (f) => controller.invoiceFilterSpec.value = f,
                    )),
                if (hasPo)
                  InvoiceViewToggle(
                      mode: mode, onChanged: controller.setInvoiceViewMode),
                _scanBanner(context),
                _rereadBanner(),

                Expanded(
                  child: invoices.isEmpty &&
                          controller.cartItems(widget.client.id).isEmpty
                      ? Center(child: _emptyState())
                      : _list(context, invoices, mode),
                ),
              ],
            );
          }),
        ),
      );
    });
  }
}

/// "3 selected from scan · 1 not found: 700099999", with Details.
class _ScanBanner extends StatelessWidget {
  const _ScanBanner({
    required this.summary,
    required this.onDetails,
    required this.onClose,
  });

  final VoucherScanSummary summary;
  final VoidCallback onDetails;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = summary.selectedIds.length;
    final color = summary.needsChecking
        ? BCollectionColors.warning
        : BCollectionColors.success;
    return Container(
      key: const ValueKey('voucher-scan-banner'),
      margin: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace, BSizes.sm, BSizes.defaultSpace, 0),
      padding: const EdgeInsets.fromLTRB(BSizes.md, BSizes.xs, 0, BSizes.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
      ),
      child: Row(
        children: [
          Icon(summary.needsChecking ? Iconsax.warning_2 : Iconsax.tick_circle,
              size: 18, color: color),
          const SizedBox(width: BSizes.sm),
          Expanded(
            child: Text(
              [
                '$n selected from scan',
                if (summary.notFound.isNotEmpty)
                  '${summary.notFound.length} not found: '
                      '${summary.notFound.join(', ')}',
                if (summary.unsure > 0) '${summary.unsure} to check',
                if (summary.offline) 'read on the phone, check carefully',
              ].join(' · '),
              key: const ValueKey('voucher-scan-banner-text'),
              style: theme.textTheme.bodySmall,
            ),
          ),
          TextButton(
            key: const ValueKey('voucher-scan-details'),
            onPressed: onDetails,
            child: const Text('Details'),
          ),
          IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// "Online re-read found 2 more invoices: …", with Select.
class _RereadBanner extends StatelessWidget {
  const _RereadBanner({
    required this.ids,
    required this.onSelect,
    required this.onClose,
  });

  final List<String> ids;
  final VoidCallback onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final n = ids.length;
    return Container(
      key: const ValueKey('voucher-reread-banner'),
      margin: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace, BSizes.sm, BSizes.defaultSpace, 0),
      padding: const EdgeInsets.fromLTRB(BSizes.md, BSizes.xs, 0, BSizes.xs),
      decoration: BoxDecoration(
        color: BCollectionColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.magic_star,
              size: 18, color: BCollectionColors.primary),
          const SizedBox(width: BSizes.sm),
          Expanded(
            child: Text(
              'Online re-read found $n more invoice${n == 1 ? '' : 's'}: '
              '${ids.join(', ')}',
              key: const ValueKey('voucher-reread-text'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            key: const ValueKey('voucher-reread-select'),
            onPressed: onSelect,
            child: const Text('Select'),
          ),
          IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// Every selected invoice, gathered at the top of the account's list: a
/// header with the count and the total, opening to the invoice cards.
class _SelectedGroup extends StatelessWidget {
  const _SelectedGroup({
    super.key,
    required this.count,
    required this.total,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  final int count;
  final double total;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: BCollectionColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
        border: Border.all(
            color: BCollectionColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const ValueKey('cart-group-toggle'),
            onTap: onToggle,
            borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: BSizes.md, vertical: BSizes.spaceBtwItemsLight),
              child: Row(
                children: [
                  const Icon(Iconsax.tick_square,
                      size: 20, color: BCollectionColors.primary),
                  const SizedBox(width: BSizes.sm),
                  Expanded(
                    child: Text('Selected ($count)',
                        key: const ValueKey('cart-group-title'),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(BFormatter.formatPesoCurrency(total),
                          maxLines: 1,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: BCollectionColors.primary,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ])),
                    ),
                  ),
                  const SizedBox(width: BSizes.xs),
                  Icon(expanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                      size: 18, color: BCollectionColors.inkSecondary),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                        BSizes.sm, 0, BSizes.sm, BSizes.sm),
                    child: Column(
                      children: [
                        for (var i = 0; i < children.length; i++) ...[
                          if (i > 0)
                            const SizedBox(height: BSizes.spaceBtwItems),
                          children[i],
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// "10 selected" over the total, so the figure that matters reads first.
/// Tabular figures keep the total from shifting as invoices are ticked.
class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.count, required this.total});

  final int count;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('cart-bar-summary'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$count selected',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: BCollectionColors.inkSecondary)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(BFormatter.formatPesoCurrency(total),
              maxLines: 1,
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: BCollectionColors.ink,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ),
      ],
    );
  }
}

/// The cart's way forward. Drawn here rather than from the shared button
/// theme, whose zero side padding and leftover blue border made the label
/// run into the edges. Same height and corner as Done Engagement; presses
/// in slightly (0.97, 120ms) so the tap is felt.
class _ReviewInvoiceButton extends StatelessWidget {
  const _ReviewInvoiceButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Review Invoice',
      child: BPressableScale(
        key: const ValueKey('cart-review'),
        onTap: onPressed,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: BSizes.md + 4),
          decoration: BoxDecoration(
            color: BCollectionColors.primary,
            borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.receipt_item,
                  size: 18, color: BCollectionColors.onPrimary),
              const SizedBox(width: BSizes.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Review Invoice',
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: BCollectionColors.onPrimary,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
