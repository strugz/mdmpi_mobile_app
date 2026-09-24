import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/devices/device_utility.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/area_selection/widgets/filter_by_area_button.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/account_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/invoice_card.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({
    super.key,
    required this.title,
    required this.color,
  });

  final String title;
  final Color color;

  void _showAccountInvoices(BuildContext context, ClientModel client,
      List<CollectionItemModel> invoices) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BCollectionColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(BSizes.borderRadiusLg)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(BSizes.md),
              child: Text(
                'Invoices for ${client.name}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                // Last card clears the system navigation bar.
                padding: EdgeInsets.fromLTRB(
                    BSizes.defaultSpace,
                    BSizes.defaultSpace,
                    BSizes.defaultSpace,
                    BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom),
                itemCount: invoices.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: BSizes.spaceBtwItems),
                itemBuilder: (context, index) {
                  return InvoiceCard(
                    item: invoices[index],
                    // One account's invoices, under a title that names it.
                    // Repeating the name on every card put a line of noise
                    // between the invoice number and the amount.
                    showAccountName: false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;

    return Scaffold(
      // The theme's navy, like every other Collection bar. The category's
      // colour painted the whole bar once (orange for Advanced Payment), so
      // one pushed page looked like it belonged to another app; it now only
      // tints the category's own status pill.
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          const SizedBox(height: BSizes.spaceBtwItems),
          const BFilterByAreaButton(),
          const SizedBox(height: BSizes.spaceBtwItems),
          Expanded(
            child: Obx(() {
              if (title == 'Advanced Payment') {
                final unassigned =
                    controller.filteredUnassignedAdvancedPayments;
                final resolvedAccounts = controller.advancedPaymentAccounts;

                if (unassigned.isEmpty && resolvedAccounts.isEmpty) {
                  return const _NoAdvances();
                }

                final float = unassigned.fold<double>(
                    0, (s, p) => s + ((p['amount'] as num?)?.toDouble() ?? 0));

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                      BSizes.defaultSpace,
                      0,
                      BSizes.defaultSpace,
                      BSizes.defaultSpace +
                          MediaQuery.paddingOf(context).bottom),
                  children: [
                    if (unassigned.isNotEmpty) ...[
                      _AdvanceSectionHeader(
                          count: unassigned.length, float: float),
                      const SizedBox(height: BSizes.spaceBtwItemsLight),
                      for (final pay in unassigned) ...[
                        _AdvanceCard(
                          payment: pay,
                          accountName: controller.masterAccountList
                                  .firstWhereOrNull(
                                      (c) => c.id == pay['clientId'])
                                  ?.name ??
                              (pay['clientName'] as String? ?? ''),
                          accent: color,
                          onApply: () =>
                              _showPaymentDetailSheet(context, controller, pay),
                        ),
                        const SizedBox(height: BSizes.spaceBtwItemsLight),
                      ],
                    ],
                  ],
                );
              }

              List<ClientModel> accounts = [];

              switch (title) {
                case 'Settled':
                  accounts = controller.settledAccounts;
                  break;
                case 'Past Due':
                  accounts = controller.overdueAccounts;
                  break;
                case 'Reconciliation':
                  accounts = controller.reconciliationAccounts;
                  break;
                default:
                  accounts = [];
              }

              if (accounts.isEmpty) {
                return const Center(
                  child: Text('No accounts found for this category.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(BSizes.defaultSpace),
                itemCount: accounts.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: BSizes.spaceBtwItems),
                itemBuilder: (context, index) {
                  final client = accounts[index];
                  List<CollectionItemModel> invoices = [];
                  switch (title) {
                    case 'Settled':
                      invoices =
                          controller.getSettledInvoicesByAccount(client.id);
                      break;
                    case 'Past Due':
                      invoices =
                          controller.getOverdueInvoicesByAccount(client.id);
                      break;
                    case 'Reconciliation':
                      invoices = controller
                          .getReconciliationInvoicesByAccount(client.id);
                      break;
                  }

                  return AccountCard(
                    client: client,
                    invoiceCount: invoices.length,
                    totalAmount:
                        invoices.fold(0.0, (sum, i) => sum + i.toBeCollected),
                    totalCollected:
                        invoices.fold(0.0, (sum, i) => sum + i.totalCollected),
                    onTap: () =>
                        _showAccountInvoices(context, client, invoices),
                    onInfoTap: () {},
                    onClaimTap: title == 'Reconciliation'
                        ? () => controller.claimAccount(client.id)
                        : null,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetailSheet(BuildContext context,
      CollectionActivityController controller, Map<String, dynamic> payment) {
    Get.bottomSheet(
      _ApplyAdvanceSheet(
        payment: payment,
        accountName: controller.masterAccountList
                .firstWhereOrNull((c) => c.id == payment['clientId'])
                ?.name ??
            (payment['clientName'] as String? ?? ''),
        onApply: ({
          required String invoiceNumber,
          required double amountDue,
          required String dueDate,
          required DateTime collectionDate,
        }) =>
            controller.assignInvoiceToPayment(
          paymentId: payment['id'],
          invoiceNumber: invoiceNumber,
          amountDue: amountDue,
          dueDate: dueDate,
          collectionDate: collectionDate,
        ),
      ),
      // Scroll-controlled so five fields and the keyboard fit on a short
      // phone; the sheet sizes to its content up to the screen.
      isScrollControlled: true,
      backgroundColor: BCollectionColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(BSizes.borderRadiusLg)),
      ),
    );
  }
}

/// "Received Sep 24, 2026 07:19 AM" from a stored stamp; never the raw ISO.
String _receivedLabel(Object? stamp) {
  final s = stamp?.toString() ?? '';
  if (s.isEmpty) return 'Received date unknown';
  return 'Received ${BFormatter.formatDateWithAmPm(s)}';
}

/// What this list is and what it adds up to, in one line under the filter.
///
/// "Unassigned Payments" named a database state. The collector's question is
/// what is still waiting for an invoice, and how much float that is.
class _AdvanceSectionHeader extends StatelessWidget {
  const _AdvanceSectionHeader({required this.count, required this.float});

  final int count;
  final double float;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Awaiting an invoice',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: BSizes.xxs),
        Text(
          '$count payment${count == 1 ? '' : 's'} · '
          '${BFormatter.formatPesoCurrency(float)} float, not yet in '
          'Collected this Month',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: BCollectionColors.inkMuted),
        ),
      ],
    );
  }
}

/// One Advanced Payment still waiting for its invoice.
///
/// It was a name, a raw ISO stamp and a 32pt button whose label the theme's
/// 16pt vertical padding pushed out of view — a blue lozenge that said
/// nothing. Now: the account and the amount on one line, when it came in and
/// its remark under them, a pill saying what state it is in, and one
/// full-width action that says what it does. The whole card is the target
/// too, and presses like every other card in the module.
class _AdvanceCard extends StatelessWidget {
  const _AdvanceCard({
    required this.payment,
    required this.accountName,
    required this.accent,
    required this.onApply,
  });

  final Map<String, dynamic> payment;
  final String accountName;
  final Color accent;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
    final remarks = (payment['remarks'] as String? ?? '').trim();

    return BPressableScale(
      onTap: onApply,
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(BSizes.md),
        decoration: BoxDecoration(
          color: BCollectionColors.surface,
          borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
          border: Border.all(color: BCollectionColors.outline, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Wrap, not Row: a long hospital name drops the amount under it
            // at a large font instead of squeezing either one.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: BSizes.sm,
              runSpacing: BSizes.xxs,
              children: [
                Text(
                  accountName.isEmpty ? 'Unknown account' : accountName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  BFormatter.formatPesoCurrency(amount),
                  maxLines: 1,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: BCollectionColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BSizes.xs),
            Row(
              children: [
                const Icon(Iconsax.calendar_1,
                    size: 14, color: BCollectionColors.inkMuted),
                const SizedBox(width: BSizes.xs),
                Flexible(
                  child: Text(
                    _receivedLabel(payment['date']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: BCollectionColors.inkSecondary),
                  ),
                ),
              ],
            ),
            if (remarks.isNotEmpty) ...[
              const SizedBox(height: BSizes.xxs),
              Text(
                remarks,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: BCollectionColors.inkMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: BSizes.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: BSizes.sm, vertical: BSizes.xxs),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
                ),
                child: Text(
                  'Float · awaiting invoice',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: accent, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwItemsLight),
            // No fixed height and the theme's tall padding replaced, so the
            // label always has room and grows with the system font size.
            ElevatedButton.icon(
              onPressed: onApply,
              icon: const Icon(Iconsax.receipt_add, size: 18),
              label: const Text('Apply to invoice'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: BSizes.md, vertical: BSizes.sm + 2),
                minimumSize: const Size.fromHeight(0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// No advance is waiting: say so, and say what one is.
class _NoAdvances extends StatelessWidget {
  const _NoAdvances();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(BSizes.md),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BCollectionColors.primary.withValues(alpha: 0.06),
              ),
              child: Icon(Iconsax.wallet_money,
                  size: 32,
                  color: BCollectionColors.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: BSizes.spaceBtwItems),
            Text('No advanced payments waiting',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: BCollectionColors.inkSecondary)),
            const SizedBox(height: BSizes.xs),
            Text(
              'An advance stays here as float until you apply it to an '
              'invoice.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: BCollectionColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _ApplyAdvance = Future<void> Function({
  required String invoiceNumber,
  required double amountDue,
  required String dueDate,
  required DateTime collectionDate,
});

/// Apply an Advanced Payment to an invoice.
///
/// It sat its Cancel and Assign on the gesture bar: the padding was read from
/// the page's context, once, when the sheet opened — so it had neither the
/// navigation bar nor, later, the keyboard. Both now come from the sheet's own
/// context: `SafeArea(top: false)` at the outermost edge for the bar, the
/// keyboard inset once inside it. The amount due was prefilled as "750000.0";
/// it is money now, like every other amount field. The actions are one
/// full-width bar with the primary action wider, as on Field Engagement.
class _ApplyAdvanceSheet extends StatefulWidget {
  const _ApplyAdvanceSheet({
    required this.payment,
    required this.accountName,
    required this.onApply,
  });

  final Map<String, dynamic> payment;
  final String accountName;
  final _ApplyAdvance onApply;

  @override
  State<_ApplyAdvanceSheet> createState() => _ApplyAdvanceSheetState();
}

class _ApplyAdvanceSheetState extends State<_ApplyAdvanceSheet> {
  static final DateFormat _day = DateFormat('yyyy-MM-dd');
  static final DateFormat _shown = DateFormat('MMM d, yyyy');

  final _formKey = GlobalKey<FormState>();
  final _invoiceNumber = TextEditingController();
  late final TextEditingController _amountDue;
  final _dueDate = TextEditingController();
  late final TextEditingController _collectionDateText;

  DateTime? _due;
  late DateTime _collectionDate;
  late final DateTime _earliest;

  double get _amount => (widget.payment['amount'] as num?)?.toDouble() ?? 0;

  @override
  void initState() {
    super.initState();
    _amountDue = TextEditingController(
        text: _amount > 0
            ? BFormatter.formatPesoCurrency(_amount, includeSymbol: false)
                .trim()
            : '');

    // The advance is float until applied; this date decides which month's
    // Collected this Month it lands in. Today by default, never before the
    // day the money was received.
    final received = BFormatter.parseLocal(widget.payment['date']?.toString());
    _earliest = received == null
        ? DateTime(2000)
        : DateTime(received.year, received.month, received.day);
    final now = DateTime.now();
    _collectionDate = DateTime(now.year, now.month, now.day);
    if (_collectionDate.isBefore(_earliest)) _collectionDate = _earliest;
    _collectionDateText =
        TextEditingController(text: _shown.format(_collectionDate));
  }

  @override
  void dispose() {
    _invoiceNumber.dispose();
    _amountDue.dispose();
    _dueDate.dispose();
    _collectionDateText.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _due = picked;
      _dueDate.text = _shown.format(picked);
    });
  }

  Future<void> _pickCollection() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _collectionDate,
      firstDate: _earliest,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _collectionDate = picked;
      _collectionDateText.text = _shown.format(picked);
    });
  }

  Future<void> _apply() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final month = DateFormat('MMMM yyyy').format(_collectionDate);
    await widget.onApply(
      invoiceNumber: _invoiceNumber.text.trim(),
      amountDue: BFormatter.parseAmount(_amountDue.text),
      dueDate: _day.format(_due!),
      collectionDate: _collectionDate,
    );
    Get.back();
    BLoaders.successSnackBar(
      title: 'Applied to invoice',
      message: 'Counts in $month\'s Collected this Month.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final month = DateFormat('MMMM yyyy').format(_collectionDate);

    // Outermost: the navigation bar, once. Inside: the keyboard, once — the
    // system already drops the bar's padding while the keyboard is up.
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: BDevicesUtils.keyboardInset(context)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(BSizes.defaultSpace, BSizes.sm,
              BSizes.defaultSpace, BSizes.defaultSpace),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: BSizes.md),
                    decoration: BoxDecoration(
                      color: BCollectionColors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Apply to invoice',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (widget.accountName.isNotEmpty) ...[
                  const SizedBox(height: BSizes.xxs),
                  Text(widget.accountName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: BCollectionColors.inkSecondary)),
                ],
                const SizedBox(height: BSizes.spaceBtwItemsLight),
                // What is being applied, set apart from the fields that say
                // where it goes.
                Container(
                  padding: const EdgeInsets.all(BSizes.spaceBtwItemsLight),
                  decoration: BoxDecoration(
                    color: BCollectionColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Advance',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: BCollectionColors.inkMuted,
                              fontWeight: FontWeight.w600)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          BFormatter.formatPesoCurrency(_amount),
                          maxLines: 1,
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: BCollectionColors.ink),
                        ),
                      ),
                      Text(_receivedLabel(widget.payment['date']),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: BCollectionColors.inkMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: BSizes.spaceBtwItems),
                TextFormField(
                  key: const ValueKey('advance-invoice-number'),
                  controller: _invoiceNumber,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Invoice number',
                    prefixIcon: Icon(Iconsax.receipt_item, size: 20),
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Enter the invoice number'
                      : null,
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),
                TextFormField(
                  key: const ValueKey('advance-amount-due'),
                  controller: _amountDue,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Amount due on the invoice',
                    prefixText: '₱ ',
                    prefixIcon: Icon(Iconsax.money, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter the amount due';
                    }
                    if (BFormatter.parseAmount(v) <= 0) {
                      return 'Enter an amount greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),
                TextFormField(
                  key: const ValueKey('advance-due-date'),
                  controller: _dueDate,
                  readOnly: true,
                  onTap: _pickDue,
                  decoration: const InputDecoration(
                    labelText: 'Due date',
                    hintText: 'Choose a date',
                    prefixIcon: Icon(Iconsax.calendar_1, size: 20),
                  ),
                  validator: (_) => _due == null ? 'Choose the due date' : null,
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),
                TextFormField(
                  key: const ValueKey('advance-collection-date'),
                  controller: _collectionDateText,
                  readOnly: true,
                  onTap: _pickCollection,
                  decoration: InputDecoration(
                    labelText: 'Collection date',
                    prefixIcon: const Icon(Iconsax.calendar_tick, size: 20),
                    helperText: "Counts in $month's Collected this Month",
                    helperMaxLines: 2,
                  ),
                ),
                const SizedBox(height: BSizes.spaceBtwSections),
                // One bar, the primary action wider — the Done / Defer layout
                // Field Engagement uses. Heights come from padding, not a
                // fixed box, so the labels always fit.
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: Get.back,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: BSizes.sm + 4),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(BSizes.borderRadiusMd)),
                        ),
                        child: const Text('Cancel', maxLines: 1),
                      ),
                    ),
                    const SizedBox(width: BSizes.spaceBtwItemsLight),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _apply,
                        icon: const Icon(Iconsax.tick_circle, size: 18),
                        label: const Text('Apply', maxLines: 1),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: BSizes.sm + 4),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(BSizes.borderRadiusMd)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
