import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/devices/device_utility.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/side_filter_drawer.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/bucket_filter_modal.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/bucket_toolbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/account_card.dart';
import 'collection_account_information_screen.dart';
import 'widgets/collection_search_filter_bar.dart';

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
class CollectionBucketScreen extends StatelessWidget {
  const CollectionBucketScreen({super.key});

  /// The one tempo for state changes on this screen: the acquire bar
  /// arriving, the list ↔ empty swap.
  static const Duration _stateDuration = Duration(milliseconds: 200);

  void _acquireSelected(CollectionActivityController controller) {
    final summary = controller.selectionSummary;
    controller.claimSelectedAccounts();
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
          title: Text(
            selecting ? '${selected.accounts} selected' : 'Collection Bucket',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          actions: [
            if (selecting)
              // "Take the whole area": once the filters have narrowed the
              // list to today's route, this is the second and last tap.
              TextButton(
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
        body: Column(
          children: [
            Obx(() {
              final hasFilter = controller.bucketMinAmount.value > 0 ||
                  controller.bucketMaxAmount.value > 0 ||
                  controller.bucketMinInvoices.value > 0 ||
                  controller.bucketMaxInvoices.value > 0;

              return CollectionSearchFilterBar(
                searchHint: 'Search by account name…',
                initialValue: controller.bucketSearchQuery.value,
                onSearchChanged: (value) =>
                    controller.bucketSearchQuery.value = value,
                hasActiveFilter: hasFilter,
                onFilterTap: () => showSideFilter(BucketFilterModal()),
              );
            }),
            const BucketToolbar(),
            Expanded(
              child: Obx(() {
                final accounts = controller.bucketAccounts;

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
                          onAddAccount: () => Get.toNamed(BRoutes.addToBucket),
                        )
                      : ListView.separated(
                          key: const ValueKey('list'),
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
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: BSizes.sm),
                          itemBuilder: (context, index) {
                            final client = accounts[index];
                            return Obx(() => AccountCard(
                                  client: client,
                                  invoiceCount: controller
                                      .getAccountInvoiceCount(client.id),
                                  totalAmount:
                                      controller.getAccountTotalDue(client.id),
                                  totalCollected: controller
                                      .getAccountTotalCollected(client.id),
                                  overdueCount: controller
                                      .getBucketAccountOverdueCount(client.id),
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
                          },
                        ),
                );
              }),
            ),
          ],
        ),
      );
    });
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
          color: BColors.white,
          border: Border(top: BorderSide(color: BColors.grey)),
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
                      color: BColors.darkGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // The basket total. A collector deciding how much to take on
                // today should not have to add the rows up.
                Text(
                  BFormatter.formatPesoCurrency(total),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: BColors.primary,
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
                  color: BColors.primary.withValues(alpha: 0.06),
                ),
                alignment: Alignment.center,
                child: Icon(
                  filtered
                      ? Iconsax.search_status
                      : Icons.shopping_basket_rounded,
                  size: 40,
                  color: BColors.primary.withValues(alpha: 0.7),
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
                  color: BColors.darkerGrey,
                ),
              ),
              const SizedBox(height: BSizes.xs),
              Text(
                filtered
                    ? 'Try a different name, amount range, or area.'
                    : 'Download a bucket from Home, or add an account to get started.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: BColors.darkGrey),
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
