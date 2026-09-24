import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/devices/device_utility.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_filter_sheet.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_filter_bar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/acquiring_overlay.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/bucket_toolbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/account_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/po/account_po_invoices_screen.dart';
import 'collection_account_information_screen.dart';
import 'widgets/collection_search_filter_bar.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/activity_filter.dart';

/// The Collection Bucket: every account a collector could take on.
///
/// This is a catalogue you pick from, and it ran two interaction models at
/// once. A selection mode existed, but only behind a long press; meanwhile
/// every row carried its own full-width "Acquire Account" button, so the
/// screen was a column of identical blue buttons with accounts in between,
/// and taking five accounts meant five taps, five snackbars and five list
/// reflows.
///
/// One model now. Tapping a card ticks the account — the whole card, not
/// just the circle, because ticking is what this screen is for and a thumb
/// should not have to aim. A labelled "Details" control on each card is the
/// way into the account's page. Once anything is ticked, a bar slides in
/// with the count and the total value, and one tap acquires the lot. Taking
/// one account is two taps instead of one; taking a route is one tap per
/// account plus one, instead of one per account plus a snackbar per account.
///
/// The filters stay where they are while things are ticked. They used to
/// collapse the moment one row was selected — the search bar vanishing under
/// the collector's finger on the way to the second account.
///
/// A ticked account rides to the top of the list, newest tick first, so the
/// pick is always together and always countable. A catalogue of 261 accounts
/// scatters a pick over screens otherwise, and by the fifth one a collector
/// cannot see what they hold.
///
/// The card leaves upward, never downward: rows below the one just ticked hold
/// still, and that is where the next target is. The view itself never moves —
/// the app bar carries a "Jump to selected" control for going back up to the
/// pick, so working down the catalogue is not interrupted by a list that
/// scrolls itself.
class CollectionBucketScreen extends StatefulWidget {
  const CollectionBucketScreen({super.key});

  @override
  State<CollectionBucketScreen> createState() => _CollectionBucketScreenState();
}

class _CollectionBucketScreenState extends State<CollectionBucketScreen> {
  /// The one tempo for state changes on this screen: the acquire bar
  /// arriving, the list ↔ empty swap.
  static const Duration _stateDuration = Duration(milliseconds: 200);

  /// Owned here so the collector can ride back up to their pick from wherever
  /// they have scrolled to. The list moves rows on its own; the view does not,
  /// because a list that scrolls itself on every tick is a list you cannot
  /// work down.
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Carry the view to the head of the list, where the pick is.
  Future<void> _jumpToSelected() async {
    if (_scroll.hasClients && _scroll.offset > 0) {
      await _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Captured before the move, because the selection is cleared on the way
  /// into it and the snackbar still has to name what was taken.
  Future<void> _acquireSelected(CollectionActivityController controller) async {
    final summary = controller.selectionSummary;
    await controller.claimSelectedAccounts();
    BLoaders.successSnackBar(
      title: 'Accounts Acquired',
      message:
          '${summary.accounts} account${summary.accounts == 1 ? '' : 's'} · ${BFormatter.formatPesoCurrency(summary.due)} moved to Field Engagement.',
    );
  }

  void _openAccount(client) =>
      Get.to(() => CollectionAccountInformationScreen(client: client));

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionActivityController>();

    return Obx(() {
      final selecting = controller.isSelectionMode.value;
      final selected = controller.selectionSummary;

      return Scaffold(
        appBar: AppBar(
          leading: selecting
              ? IconButton(
                  tooltip: 'Clear selection',
                  icon: const Icon(Icons.close),
                  onPressed: controller.exitSelectionMode,
                )
              : null,
          // No style override: the app bar theme's 18pt is the size for a bar
          // title. headlineMedium is 24pt — a page heading, which on a 56pt
          // bar crowded the back arrow and the actions either side of it.
          title: Text(
            selecting ? '${selected.accounts} selected' : 'Collection Bucket',
          ),
          actions: [
            if (selecting)
              // The pick is always at the head of the list; this is the way
              // back to it after scrolling down for the next account.
              IconButton(
                tooltip: 'Jump to selected',
                icon: const Icon(Icons.vertical_align_top_rounded),
                onPressed: _jumpToSelected,
              ),
            if (selecting)
              // "Take the whole area": once the filters have narrowed the
              // list to today's route, this is the second and last tap.
              TextButton(
                // The theme's text buttons are accent blue, which on the
                // navy bar is barely there.
                style: TextButton.styleFrom(
                    foregroundColor: BCollectionColors.onHeader),
                onPressed: controller.selectAllVisibleAccounts,
                child: const Text('Select all'),
              )
            else
              IconButton(
                tooltip: 'Add to bucket',
                icon: const Icon(Iconsax.add_circle),
                onPressed: () => Get.toNamed(BRoutes.addToBucket),
              ),
          ],
        ),
        // Height animates rather than the bar popping in, so the list
        // underneath slides up to make room instead of jumping.
        bottomNavigationBar: AnimatedSize(
          duration: _stateDuration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: selecting
              ? _AcquireBar(
                  count: selected.accounts,
                  total: selected.due,
                  onAcquire: () => _acquireSelected(controller),
                )
              : const SizedBox(width: double.infinity),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Obx(() => CollectionSearchFilterBar(
                      searchHint: 'Search accounts',
                      initialValue: controller.bucketSearchQuery.value,
                      onSearchChanged: (value) =>
                          controller.bucketSearchQuery.value = value,
                      hasActiveFilter:
                          controller.bucketFilterSpec.value.isActive,
                      onFilterTap: () => _openFilter(context, controller),
                    )),
                // The same one-tap filters as the engagement list, minus area:
                // the toolbar below already owns that chip.
                Obx(() => QuickFilterBar(
                      filter: controller.bucketFilterSpec.value,
                      defaultSort: ActivitySort.name,
                      onChanged: (f) => controller.bucketFilterSpec.value = f,
                    )),
                const BucketToolbar(),
                Expanded(
                  child: Obx(() {
                    final accounts = controller.bucketAccounts;
                    // A line is only worth ruling when there is something on
                    // both sides of it.
                    final picked = controller.selectedVisibleCount;
                    final groupEnd =
                        picked > 0 && picked < accounts.length ? picked : 0;
                    final movedId = controller.lastMovedAccountId.value;
                    final generation = controller.selectionGeneration.value;

                    // Cross-fade between the list and the empty state so a
                    // filter that empties the list does not hard-cut to a
                    // different layout.
                    return AnimatedSwitcher(
                      duration: _stateDuration,
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: accounts.isEmpty
                          ? _BucketEmptyState(
                              key: const ValueKey('empty'),
                              filtered: controller.hasActiveBucketFilter,
                              onClearFilters: controller.clearBucketFilters,
                              onAddAccount: () =>
                                  Get.toNamed(BRoutes.addToBucket),
                            )
                          : ListView.separated(
                              key: const ValueKey('list'),
                              controller: _scroll,
                              padding: EdgeInsets.fromLTRB(
                                BSizes.defaultSpace,
                                BSizes.sm,
                                BSizes.defaultSpace,
                                // The last row clears the gesture bar when the
                                // acquire bar is not there to do it.
                                BSizes.defaultSpace +
                                    BDevicesUtils.systemBottomInset(context),
                              ),
                              itemCount: accounts.length,
                              separatorBuilder: (_, index) =>
                                  index == groupEnd - 1
                                      ? const _GatheredGroupDivider()
                                      : const SizedBox(height: BSizes.sm),
                              itemBuilder: (context, index) {
                                final client = accounts[index];
                                final card = Obx(() => AccountCard(
                                      client: client,
                                      invoiceCount: controller
                                          .getAccountInvoiceCount(client.id),
                                      poCount: controller
                                          .getAccountPoCount(client.id),
                                      onPoInvoicesTap: () =>
                                          Get.to(() => AccountPoInvoicesScreen(
                                                client: client,
                                                invoices: () => controller
                                                    .getBucketOpenInvoices(
                                                        client.id),
                                              )),
                                      totalAmount: controller
                                          .getAccountTotalDue(client.id),
                                      totalCollected: controller
                                          .getAccountTotalCollected(client.id),
                                      overdueCount: controller
                                          .getBucketAccountOverdueCount(
                                              client.id),
                                      isSelected: controller.selectedAccountIds
                                          .contains(client.id),
                                      // The whole card is the target for the
                                      // thing this screen is for. The circle is
                                      // the state, not the only place to tap.
                                      onTap: () => controller
                                          .toggleAccountSelection(client.id),
                                      onSelectTap: () => controller
                                          .toggleAccountSelection(client.id),
                                      // Kept as a shortcut for anyone used to it.
                                      onLongPress: () => controller
                                          .toggleAccountSelection(client.id),
                                      // The one way into the account's page, and
                                      // labelled as such.
                                      onInfoTap: () => _openAccount(client),
                                    ));

                                // The one row that just moved arrives rather
                                // than appears. Only that row: animating the
                                // whole group on every tick would make a
                                // five-account pick flash five times.
                                return index == 0 && client.id == movedId
                                    ? _GatheredEntry(
                                        key: ValueKey('moved-$generation'),
                                        child: card,
                                      )
                                    : card;
                              },
                            ),
                    );
                  }),
                ),
              ],
            ),
            // Covers the list while the acquire writes, so a long write reads
            // as work rather than as a list that stopped responding.
            Obx(() => AcquiringOverlay(
                  visible: controller.isAcquiring.value,
                  invoiceCount: controller.acquiringInvoices.value,
                  accountCount: controller.acquiringAccounts.value,
                )),
          ],
        ),
      );
    });
  }

  static Future<void> _openFilter(
      BuildContext context, CollectionActivityController controller) async {
    final chosen = await ActivityFilterSheet.show(
      context,
      initial: controller.bucketFilterSpec.value,
      count: controller.countBucketAccounts,
    );
    if (chosen != null) controller.bucketFilterSpec.value = chosen;
  }
}

/// The entrance for the row that has just moved to the top: a 160ms fade and
/// an 8px rise, so it reads as having arrived rather than having been swapped
/// in behind the collector's back.
///
/// Short on purpose. This plays on every tick, dozens of times a route, and an
/// animation seen that often is one to feel rather than wait for.
class _GatheredEntry extends StatelessWidget {
  const _GatheredEntry({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child:
            Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

/// The line under the ticked group.
///
/// Without it the top of the list is just some ticked cards that happen to be
/// first, and a collector scrolling back up cannot tell where their pick ends
/// and the catalogue resumes. The label carries that, so the line itself can
/// stay a hairline.
class _GatheredGroupDivider extends StatelessWidget {
  const _GatheredGroupDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BSizes.md),
      child: Row(
        children: [
          Text(
            'All accounts',
            style: theme.textTheme.labelSmall?.copyWith(
              color: BCollectionColors.inkMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: BSizes.sm),
          const Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: BCollectionColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// What is ticked and what it is worth, with the one button that acts on it.
class _AcquireBar extends StatelessWidget {
  const _AcquireBar({
    required this.count,
    required this.total,
    required this.onAcquire,
  });

  final int count;
  final double total;
  final VoidCallback onAcquire;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            BSizes.defaultSpace, BSizes.md, BSizes.defaultSpace, BSizes.md),
        decoration: const BoxDecoration(
          color: BCollectionColors.surface,
          border: Border(top: BorderSide(color: BCollectionColors.outline)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$count account${count == 1 ? '' : 's'} selected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: BCollectionColors.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // The basket total. A collector deciding how much to take on
                // today should not have to add the rows up.
                Text(
                  BFormatter.formatPesoCurrency(total),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: BCollectionColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BSizes.sm),
            ElevatedButton.icon(
              onPressed: count == 0 ? null : onAcquire,
              icon: const Icon(Iconsax.tick_circle, size: 18),
              label:
                  Text('Acquire ${count == 1 ? 'account' : '$count accounts'}'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty bucket / no-match state.
///
/// Copy and action depend on *why* it is empty: an empty bucket offers a way
/// to add an account; an over-filtered bucket offers to clear the filters.
/// Enters with a short fade + 8px rise (nothing appears from nowhere).
class _BucketEmptyState extends StatelessWidget {
  const _BucketEmptyState({
    super.key,
    required this.filtered,
    required this.onClearFilters,
    required this.onAddAccount,
  });

  final bool filtered;
  final VoidCallback onClearFilters;
  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child:
              Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BCollectionColors.primary.withValues(alpha: 0.06),
                ),
                alignment: Alignment.center,
                child: Icon(
                  filtered
                      ? Iconsax.search_status
                      : Icons.shopping_basket_rounded,
                  size: 40,
                  color: BCollectionColors.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text(
                filtered
                    ? 'No accounts match your filters'
                    : 'Your bucket is empty',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: BCollectionColors.inkSecondary,
                ),
              ),
              const SizedBox(height: BSizes.xs),
              Text(
                filtered
                    ? 'Try a different name, amount range, or area.'
                    : 'Download a bucket from Home, or add an account to get started.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: BCollectionColors.inkMuted),
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              if (filtered)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Iconsax.close_circle, size: 18),
                  label: const Text('Clear all filters'),
                )
              else
                OutlinedButton.icon(
                  onPressed: onAddAccount,
                  icon: const Icon(Iconsax.add_circle, size: 18),
                  label: const Text('Add an account'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
