import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

class ActivityHistoryList extends StatelessWidget {
  const ActivityHistoryList({
    super.key,
    required this.history,
    this.accountNames,
    this.invoiceIds,
    this.items,
    this.reconciledOn,
    this.invoiceCounts,
    this.accountFirst = false,
    this.timeOnly = false,
  });

  final List<CollectionHistoryModel> history;

  /// Optional: Map of history index to account name (for global lists)
  final Map<int, String>? accountNames;

  /// Optional: Map of history index to invoice ID (for global lists)
  final Map<int, String?>? invoiceIds;

  /// Optional: Map of history index to full invoice item
  final Map<int, CollectionItemModel?>? items;

  /// Optional: Map of history index to the date the invoice was put into
  /// reconciliation before this engagement. See
  /// [ActivityHistoryCard.reconciledOn].
  ///
  /// The list renders what it is given and never folds history itself. The
  /// controller's history getters (`getAccountHistory`, `allRecentHistory`,
  /// `activitiesByDate`) already fold finished reconciliations into their
  /// outcomes and carry the date here.
  final Map<int, String?>? reconciledOn;

  /// Optional: Map of history index to how many invoices an account-level
  /// entry covered. See [ActivityHistoryCard.invoiceCount].
  final Map<int, int?>? invoiceCounts;

  /// See [ActivityHistoryCard.accountFirst] and
  /// [ActivityHistoryCard.timeOnly]. Both default to the card's own
  /// behaviour, so the screens that already use this list are untouched.
  final bool accountFirst;
  final bool timeOnly;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: BSizes.lg),
          child: Text('No engagement history available.'),
        ),
      );
    }

    // The history is already sorted newest-first and folded by the controller.
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        return ActivityHistoryCard(
          history: history[index],
          accountName: accountNames?[index],
          invoiceId: invoiceIds?[index],
          item: items?[index],
          reconciledOn: reconciledOn?[index],
          invoiceCount: invoiceCounts?[index],
          accountFirst: accountFirst,
          timeOnly: timeOnly,
        );
      },
    );
  }
}

/// One engagement entry. Tapping opens the detail sheet; [showDetail] opens
/// the same sheet for callers that intercept the tap themselves (the home
/// carousel does, for a tap that lands mid-settle).
class ActivityHistoryCard extends StatelessWidget {
  const ActivityHistoryCard({
    super.key,
    required this.history,
    this.accountName,
    this.invoiceId,
    this.item,
    this.reconciledOn,
    this.invoiceCount,
    this.margin = const EdgeInsets.only(bottom: BSizes.sm),
    this.accountFirst = false,
    this.timeOnly = false,
  });

  final CollectionHistoryModel history;
  final String? accountName;
  final String? invoiceId;
  final CollectionItemModel? item;

  /// How many invoices an account-level entry (a deferral) covered.
  ///
  /// A deferral is one event for the whole account, so it has no single
  /// invoice, posting date or due date. The card used to print
  /// "Invoice Date: N/A" and "Due: N/A" for it; it now says "3 invoices".
  final int? invoiceCount;

  bool get _isAccountLevel =>
      item == null && (invoiceId == null || invoiceId!.isEmpty);

  /// The account's name, or null when the caller had none. An empty string
  /// is "none" too: the archive stores one for a row the server sent without
  /// a name, and a card that printed it had a blank headline.
  String? get _accountName {
    final name = accountName ?? item?.client.name;
    return name == null || name.isEmpty ? null : name;
  }

  /// What an account-level entry covered, in place of the one invoice it
  /// does not have: "3 invoices" when the row lists them, "Whole account"
  /// when it does not. Never "Invoice Date: N/A" — a deferral has no invoice
  /// date, and saying so twice told the reader nothing.
  String get _accountScopeLabel => invoiceCount != null
      ? '$invoiceCount invoice${invoiceCount == 1 ? '' : 's'}'
      : 'Whole account';

  /// When this invoice was put into reconciliation before this engagement,
  /// or null if it never was.
  ///
  /// A collection that came out of a reconciliation used to look exactly like
  /// any other collection: the Reconciliation entry was a separate row, and
  /// once the invoice settled and left the bucket there was nothing on the
  /// Collected card to say the balance had been disputed first. The two are
  /// now one entry: this card's badge reads "Reconciliation Collected" (or
  /// "Reconciliation Refused to Pay", whatever the outcome was) and the
  /// detail sheet names the date. Callers that have the archive (the
  /// calendar) pass the date in; everyone else gets it derived from [item]'s
  /// history.
  final String? reconciledOn;

  /// The badge text: the outcome, prefixed when it finished a reconciliation.
  String get _statusLabel => _reconciledOn == null
      ? history.status
      : '${CollectionStatusColors.statusReconciliation} ${history.status}';

  /// The reconciliation this engagement came out of, if any: the explicit
  /// [reconciledOn], else the latest Reconciliation entry in the invoice's
  /// history that is not later than this entry. A card whose own status is
  /// Reconciliation never carries the chip; the badge already says so.
  String? get _reconciledOn {
    if (history.status == CollectionStatusColors.statusReconciliation) {
      return null;
    }
    if (reconciledOn != null && reconciledOn!.isNotEmpty) return reconciledOn;
    final own = BFormatter.parseLocal(history.date);
    String? latest;
    DateTime? latestAt;
    for (final h in item?.history ?? const <CollectionHistoryModel>[]) {
      if (h.status != CollectionStatusColors.statusReconciliation) continue;
      final at = BFormatter.parseLocal(h.date);
      if (at == null) continue;
      if (own != null && at.isAfter(own)) continue;
      if (latestAt == null || at.isAfter(latestAt)) {
        latestAt = at;
        latest = h.date;
      }
    }
    return latest;
  }

  /// Lead with the account and demote the invoice number.
  ///
  /// On an account's own screen the invoice number is what tells two entries
  /// apart. In a day's list it is not: the reader is scanning who they
  /// visited, and an invoice number they never memorised is a poor headline
  /// for a visit.
  final bool accountFirst;

  /// Show the time and not the date.
  ///
  /// For a list already sitting under a heading that names the day, repeating
  /// the date on every card says nothing, and the time — which is the part
  /// that orders the day — is buried at the end of it.
  final bool timeOnly;

  /// Space around the card. The list stacks cards with a bottom gap; a
  /// carousel page wants none.
  final EdgeInsetsGeometry margin;

  /// The collector label as shown on the card: initials for the current user.
  ///
  /// Matched against every name this user's own work may be stored under
  /// rather than against one literal. Engagements have been written with the
  /// full name, with initials and with 'You' at different times, and the
  /// archive now writes the full name — a single-literal test recognised at
  /// most one of those and showed the other two in full.
  String get _collectorLabel {
    final name = history.collectorName.trim();
    if (name.isEmpty) return name;
    // Without a signed-in user there is nothing to compare against, so the
    // stored name stands. This is also what lets the card be pumped on its
    // own in a widget test.
    if (!Get.isRegistered<UserController>()) return name;
    final user = UserController.instance.user.value;
    final mine = {
      user.fullName,
      user.initials,
      user.username,
      'You',
    }.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty);
    if (mine.contains(name.toLowerCase())) return user.initials;
    return name;
  }

  void showDetail(BuildContext context) =>
      _showDetail(context, _collectorLabel);

  void _showDetail(BuildContext context, String collectorName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: BCollectionColors.surface,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(BSizes.borderRadiusLg)),
        ),
        padding: EdgeInsets.fromLTRB(
            BSizes.defaultSpace,
            BSizes.defaultSpace,
            BSizes.defaultSpace,
            BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: BSizes.md),
                decoration: BoxDecoration(
                  color: BCollectionColors.outline.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Engagement Details',
                    style: Theme.of(context).textTheme.headlineSmall),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: BSizes.sm),

            if (accountName != null || invoiceId != null || item != null) ...[
              Text(
                accountName ?? item?.client.name ?? 'Unknown Account',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: BCollectionColors.primary),
              ),
              if (invoiceId != null || item != null)
                Text('Invoice #${invoiceId ?? item?.id}',
                    style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: BSizes.md),
            ],

            if (item != null) ...[
              Wrap(
                spacing: BSizes.sm,
                runSpacing: BSizes.sm,
                children: [
                  _buildInfoTile(
                      context,
                      'Total Amount',
                      BFormatter.formatPesoCurrency(
                          item!.toBeCollected + item!.totalCollected),
                      Iconsax.money),
                  _buildInfoTile(
                      context,
                      'Current Balance',
                      BFormatter.formatPesoCurrency(item!.toBeCollected),
                      Iconsax.wallet_money,
                      valueColor: BCollectionColors.primary),
                  _buildInfoTile(
                      context, 'Due Date', item!.dueDate, Iconsax.calendar,
                      valueColor:
                          item!.isOverdue ? BCollectionColors.danger : null),
                  if (item!.documentReferences.isNotEmpty)
                    _buildInfoTile(
                        context,
                        'References',
                        item!.documentReferences.join(', '),
                        Iconsax.document_text),
                ],
              ),
              const Divider(height: BSizes.lg),
            ],

            Wrap(
              spacing: BSizes.sm,
              runSpacing: BSizes.sm,
              children: [
                _buildInfoTile(
                    context,
                    'Date',
                    BFormatter.formatDateWithAmPm(history.date),
                    Iconsax.calendar),
                _buildInfoTile(
                    context, 'Collector', collectorName, Iconsax.user),
                _buildInfoTile(
                  context,
                  'Status',
                  _statusLabel,
                  Iconsax.activity,
                  isBadge: true,
                  badgeStatus: history.status,
                ),
                if (_reconciledOn != null)
                  _buildInfoTile(
                      context,
                      'Reconciled on',
                      BFormatter.formatDateWithAmPm(_reconciledOn!),
                      Iconsax.status_up,
                      valueColor: BCollectionColors.reconcile),
                if (history.totalCollected > 0)
                  _buildInfoTile(
                      context,
                      'Amount Collected',
                      BFormatter.formatPesoCurrency(history.totalCollected),
                      Iconsax.wallet_money,
                      valueColor: BCollectionColors.success),
                if (history.bankName != null && history.bankName!.isNotEmpty)
                  _buildInfoTile(
                      context, 'Bank', history.bankName!, Iconsax.bank),
                if (history.checkNumber != null &&
                    history.checkNumber!.isNotEmpty)
                  _buildInfoTile(context, 'Check Number', history.checkNumber!,
                      Iconsax.card_edit),
                if (history.checkDate != null && history.checkDate!.isNotEmpty)
                  _buildInfoTile(context, 'Check Date', history.checkDate!,
                      Iconsax.calendar_1),
              ],
            ),

            const SizedBox(height: BSizes.md),
            Text('Remarks', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: BSizes.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(BSizes.md),
              decoration: BoxDecoration(
                color: BCollectionColors.background,
                borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
              ),
              child: Text(
                history.remarks.isEmpty || history.remarks == 'No remarks'
                    ? 'No additional remarks provided.'
                    : history.remarks,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
      BuildContext context, String label, String value, IconData icon,
      {bool isBadge = false, Color? valueColor, String? badgeStatus}) {
    final width = (MediaQuery.of(context).size.width -
            (BSizes.defaultSpace * 2) -
            BSizes.sm) /
        2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(BSizes.sm),
      decoration: BoxDecoration(
        color: BCollectionColors.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
        border:
            Border.all(color: BCollectionColors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: BCollectionColors.primary),
          const SizedBox(width: BSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                if (isBadge)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: ActivityStatusBadge(
                        status: badgeStatus ?? value, label: value),
                  )
                else
                  Text(
                    value,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: valueColor,
                          fontSize: 12,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayCollectorName = _collectorLabel;

    final isOverdue = item?.isOverdue ?? false;
    final daysPast = item?.daysPastDue ?? 0;

    return Card(
      margin: margin,
      child: InkWell(
        onTap: () => _showDetail(context, displayCollectorName),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
        child: Padding(
          padding: const EdgeInsets.all(BSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header: Invoice ID and Account Name + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          accountFirst
                              ? (_accountName ?? 'Account Engagement')
                              : (invoiceId != null || item != null
                                  ? 'Invoice #${invoiceId ?? item?.id}'
                                  : (_accountName ?? 'Account Engagement')),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (accountFirst && (invoiceId ?? item?.id) != null)
                          Text(
                            'Invoice #${invoiceId ?? item?.id}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: BCollectionColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else if (!accountFirst && item != null)
                          Text(
                            item!.client.name,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: BCollectionColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  ActivityStatusBadge(
                      status: history.status, label: _statusLabel),
                ],
              ),
              const SizedBox(height: BSizes.sm),

              /// Body Row 1: Posted Date + Amount Collected
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Iconsax.calendar,
                            size: 14, color: BCollectionColors.inkMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _isAccountLevel
                                ? _accountScopeLabel
                                : 'Invoice Date: ${item?.postingDate ?? 'N/A'}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: BCollectionColors.inkMuted,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (history.totalCollected > 0)
                    Text(
                      BFormatter.formatPesoCurrency(history.totalCollected),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: BCollectionColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: BSizes.xs),

              /// Body Row 2: Due Date + Overdue Tag + Collector Name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // An account-level row with no invoice list already says
                  // "Whole account" above; there is no due date to add and
                  // nothing else worth a second line, so the collector's
                  // name stands alone on the right.
                  if (_isAccountLevel && invoiceCount == null)
                    const Spacer()
                  else
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Iconsax.timer,
                              size: 14,
                              color: isOverdue
                                  ? BCollectionColors.danger
                                  : BCollectionColors.inkMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _isAccountLevel
                                  ? 'Whole account'
                                  : 'Due: ${item?.dueDate ?? 'N/A'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: isOverdue
                                        ? BCollectionColors.danger
                                        : BCollectionColors.inkMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: BSizes.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: BCollectionColors.danger,
                                borderRadius: BorderRadius.circular(
                                    BSizes.borderRadiusSm),
                              ),
                              child: Text(
                                BFormatter.formatDaysOverdue(daysPast),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: BCollectionColors.surface,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  Text(
                    displayCollectorName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BCollectionColors.inkMuted, fontSize: 10),
                  ),
                ],
              ),
              const Divider(height: BSizes.md),

              /// Footer: Timestamp and Remarks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    // Stored as ISO (2026-09-17T11:45:12.579265); shown as a
                    // date a person reads, not a stamp with a T in it. Under a
                    // heading that already names the day, only the time is new.
                    timeOnly
                        ? BFormatter.formatTimeAmPm(history.date)
                        : BFormatter.formatDateWithAmPm(history.date),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontSize: 10),
                  ),
                  if (history.remarks.isNotEmpty &&
                      history.remarks != 'No remarks')
                    Expanded(
                      child: Text(
                        '  |  ${history.remarks}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              fontSize: 10,
                              color: BCollectionColors.inkSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The engagement status badge, shared by the history card, its detail sheet
/// and the calendar's visit card. [status] picks the colour; [label] is what
/// it says, which differs from the status when an outcome finished a
/// reconciliation ("Reconciliation Collected" in the Collected green).
class ActivityStatusBadge extends StatelessWidget {
  const ActivityStatusBadge(
      {super.key, required this.status, String? label})
      : label = label ?? status;

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) return const SizedBox.shrink();
    final (bg, _) = CollectionStatusColors.colorsForAuto(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: BSizes.sm, vertical: BSizes.xxs),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(color: bg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
