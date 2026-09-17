import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_outcome.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_fill_chip.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/reveal_scroll.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/bank_field.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// Record one payment against several invoices at once.
///
/// This screen exists because a single check often settles a stack of
/// invoices, and its whole job is splitting that one figure across them. It
/// used to ask the collector to do the split by hand, one amount at a time,
/// with the running arithmetic left to them: the Save button simply stayed
/// grey until the numbers happened to agree.
///
/// So the split is now a tap. Enter what was received, press Distribute, and
/// the amount pours over the invoices in order, settling each in turn until
/// it runs out. Everything after that is correction rather than entry:
///
///  - The total is a chip when the payment covers every invoice selected.
///  - Each row settles in full with one tap, and says what it leaves behind.
///  - Outcomes follow each row's amount, and stop the moment one is set by
///    hand.
///  - The three check fields are not rendered unless the payment is marked
///    as a check.
///  - What is left to allocate is always on screen, next to Save, rather
///    than in a banner that scrolls away.
class BatchActivityDetailScreen extends StatefulWidget {
  const BatchActivityDetailScreen({super.key, required this.items});

  final List<CollectionItemModel> items;

  @override
  State<BatchActivityDetailScreen> createState() =>
      _BatchActivityDetailScreenState();
}

class _BatchActivityDetailScreenState extends State<BatchActivityDetailScreen> {
  late final TextEditingController totalAmountController;
  late final TextEditingController bankNameController;
  late final TextEditingController checkNumberController;
  late final TextEditingController checkDateController;

  final Map<String, TextEditingController> itemAmountControllers = {};
  final Map<String, TextEditingController> itemRemarkControllers = {};

  final Map<String, String> itemStatuses = {};
  final Map<String, String> itemOthersRemarks = {};

  /// Rows whose outcome was chosen by hand. Those stop following the amount.
  final Set<String> _statusSetByHand = {};

  /// Rows showing their remark field. Remarks are the exception on a batch,
  /// so the fields are not there until asked for.
  final Set<String> _remarksShown = {};

  /// Whether this payment carries check details.
  ///
  /// Not a payment type: nothing in the record says "cash" or "check". The
  /// only thing stored is the bank name, check number and check date, so this
  /// is the switch that decides whether there are any — it reveals the three
  /// fields, and off it sends them as null rather than carrying over whatever
  /// was prefilled from a previous visit.
  late bool _payingByCheck;
  late final List<String> _bankSuggestions;

  /// Currency rounding: anything under half a centavo is agreement.
  static const double _tolerance = 0.005;

  double get _totalDue =>
      widget.items.fold(0, (sum, item) => sum + item.toBeCollected);

  double get _allocatedTotal {
    double total = 0;
    for (final controller in itemAmountControllers.values) {
      total += BFormatter.parseAmount(controller.text);
    }
    return total;
  }

  double get _targetTotal => BFormatter.parseAmount(totalAmountController.text);

  double get _unallocated => _targetTotal - _allocatedTotal;

  bool get _isBalanced => _targetTotal > 0 && _unallocated.abs() < _tolerance;

  /// Rows that took no money and have had no outcome chosen for them. The
  /// collector selected these invoices, so what happened to them is a
  /// question worth one tap rather than a guess worth recording.
  List<CollectionItemModel> get _undecided => [
        for (final item in widget.items)
          if ((itemStatuses[item.id] ?? '').isEmpty) item,
      ];

  bool get _canSave => _isBalanced && _undecided.isEmpty;

  double _amountFor(String id) =>
      BFormatter.parseAmount(itemAmountControllers[id]!.text);

  /// Whether what is still unallocated could be added to this row without
  /// taking it past what the invoice owes.
  bool _canTakeRest(CollectionItemModel item) {
    if (_unallocated <= _tolerance) return false;
    return _amountFor(item.id) + _unallocated <=
        item.toBeCollected + _tolerance;
  }

  @override
  void initState() {
    super.initState();
    totalAmountController = TextEditingController();

    // The bank details most recently used across the selection: a batch is
    // usually one instrument, so the last one seen is the best guess.
    CollectionHistoryModel? latestBankInfo;
    DateTime? latestDate;

    for (final item in widget.items) {
      CollectionHistoryModel? lastInfo;
      for (final h in item.history.reversed) {
        if (h.bankName != null && h.bankName!.isNotEmpty) {
          lastInfo = h;
          break;
        }
      }

      if (lastInfo != null) {
        try {
          final entryDate =
              DateTime.parse(lastInfo.date.replaceFirst(' ', 'T'));
          if (latestDate == null || entryDate.isAfter(latestDate)) {
            latestDate = entryDate;
            latestBankInfo = lastInfo;
          }
        } catch (_) {
          // Undated history is still better than no suggestion at all.
          latestBankInfo ??= lastInfo;
        }
      }
    }

    bankNameController =
        TextEditingController(text: latestBankInfo?.bankName ?? '');
    checkNumberController =
        TextEditingController(text: latestBankInfo?.checkNumber ?? '');
    checkDateController =
        TextEditingController(text: latestBankInfo?.checkDate ?? '');

    // Same rule as the single-invoice form: on if this account was last paid
    // by check, otherwise off, which is the state with nothing to fill in.
    _payingByCheck = latestBankInfo != null;

    _bankSuggestions = Get.isRegistered<CollectionActivityController>()
        ? CollectionActivityController.instance.recentBankNames()
        : const <String>[];

    for (final item in widget.items) {
      itemAmountControllers[item.id] = TextEditingController()
        ..addListener(() => _onRowAmountChanged(item));
      itemRemarkControllers[item.id] = TextEditingController();
      // Deliberately unset. Every row used to open pre-marked "Collected",
      // which meant a row left at zero was still recorded as collected in
      // full. Nothing has happened to these invoices yet, so they say so.
      itemStatuses[item.id] = '';
    }

    totalAmountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    totalAmountController.dispose();
    bankNameController.dispose();
    checkNumberController.dispose();
    checkDateController.dispose();
    for (final controller in itemAmountControllers.values) {
      controller.dispose();
    }
    for (final controller in itemRemarkControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onRowAmountChanged(CollectionItemModel item) {
    if (_statusSetByHand.contains(item.id)) return;
    final implied =
        CollectionOutcome.forAmount(_amountFor(item.id), item.toBeCollected);
    // Clearing the amount takes the outcome back with it, so a row never
    // keeps an outcome that its figures no longer support.
    setState(() => itemStatuses[item.id] = implied ?? '');
  }

  /// Write [amount] into a field the way the input formatter would, since a
  /// value set in code does not pass through it.
  void _setAmount(TextEditingController controller, double amount) {
    final text = amount <= 0
        ? ''
        : BFormatter.formatPesoCurrency(amount, includeSymbol: false).trim();
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Pour the amount received over the invoices in the order shown, settling
  /// each in turn until it runs out. This is how a payment is actually
  /// applied, and it is the reason this screen exists.
  void _distribute() {
    var left = _targetTotal;
    for (final item in widget.items) {
      final share = left <= 0
          ? 0.0
          : (left < item.toBeCollected ? left : item.toBeCollected);
      _setAmount(itemAmountControllers[item.id]!, share);
      left -= share;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {});
  }

  void _clearAllocation() {
    for (final controller in itemAmountControllers.values) {
      _setAmount(controller, 0);
    }
    setState(() {});
  }

  void _saveBatch() {
    if (!_canSave) return;

    final controller = CollectionActivityController.instance;

    final finalStatuses = Map<String, String>.from(itemStatuses);
    final finalAmounts = <String, double>{};
    final finalRemarks = <String, String>{};

    for (final item in widget.items) {
      finalAmounts[item.id] = _amountFor(item.id);

      var remark = itemRemarkControllers[item.id]!.text.trim();
      if (itemStatuses[item.id] == CollectionStatusColors.statusOthers) {
        finalStatuses[item.id] = itemOthersRemarks[item.id]?.isNotEmpty == true
            ? itemOthersRemarks[item.id]!
            : 'Others';
        final statusValue = finalStatuses[item.id]!;
        remark = remark.isEmpty ? statusValue : '$remark ($statusValue)';
      }
      finalRemarks[item.id] = remark.isEmpty ? 'Batch Recording' : remark;
    }

    final isCheck = _payingByCheck;
    String? trimmedOrNull(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    controller.saveBatchActivity(
      ids: widget.items.map((e) => e.id).toList(),
      statuses: finalStatuses,
      remarks: finalRemarks,
      amounts: finalAmounts,
      totalAmountReceived: _targetTotal,
      bankName: isCheck ? trimmedOrNull(bankNameController) : null,
      checkNumber: isCheck ? trimmedOrNull(checkNumberController) : null,
      checkDate: isCheck ? trimmedOrNull(checkDateController) : null,
      purposeOfVisit: 'Collection',
    );

    Get.back();
    BLoaders.successSnackBar(
      title: 'Saved',
      message:
          'Recorded ${BFormatter.formatPesoCurrency(_targetTotal)} across ${widget.items.length} invoices.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Record ${widget.items.length} invoices')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace,
          BSizes.defaultSpace,
          BSizes.defaultSpace,
          BSizes.spaceBtwSections,
        ),
        children: [
          _amountReceived(context),
          const SizedBox(height: BSizes.spaceBtwSections),
          _allocationHeader(context),
          const SizedBox(height: BSizes.spaceBtwItems),
          for (final item in widget.items) ...[
            _invoiceRow(context, item),
            const SizedBox(height: BSizes.spaceBtwItems),
          ],
          const SizedBox(height: BSizes.sm),
          _methodSection(context),
        ],
      ),
      bottomNavigationBar: _bottomBar(context),
    );
  }

  /// What was handed over. First, because it is the one figure the collector
  /// already knows when they open this screen.
  Widget _amountReceived(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Amount received', style: theme.textTheme.titleMedium),
        Text(
          '${widget.items.length} invoices · ${BFormatter.formatPesoCurrency(_totalDue)} due',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: BCollectionColors.inkMuted),
        ),
        const SizedBox(height: BSizes.spaceBtwItems),
        TextField(
          key: const ValueKey('batch-total'),
          controller: totalAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
            hintText: '0.00',
            // An icon rather than prefixText, which only paints once the
            // field has focus or content — so it would vanish while empty.
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: BSizes.md, right: BSizes.sm),
              child: Text(
                '₱',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: BCollectionColors.inkMuted,
                ),
              ),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
        const SizedBox(height: BSizes.spaceBtwItems),
        BQuickFillChip(
          label: 'Settles all · ${BFormatter.formatPesoCurrency(_totalDue)}',
          icon: Iconsax.money_tick,
          onTap: () {
            _setAmount(totalAmountController, _totalDue);
            _distribute();
          },
        ),
      ],
    );
  }

  Widget _allocationHeader(BuildContext context) {
    final theme = Theme.of(context);
    final hasTarget = _targetTotal > 0;
    final hasAllocation = _allocatedTotal > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Split across invoices', style: theme.textTheme.titleMedium),
        Text(
          'Oldest first, each settled in turn',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: BCollectionColors.inkMuted),
        ),
        const SizedBox(height: BSizes.spaceBtwItems),
        // Nothing to pour out until an amount is entered, and a chip that
        // does nothing when tapped is worse than no chip.
        if (hasTarget)
          Wrap(
            spacing: BSizes.sm,
            runSpacing: BSizes.sm,
            children: [
              BQuickFillChip(
                label: 'Distribute',
                icon: Iconsax.arrow_down,
                onTap: _distribute,
              ),
              if (hasAllocation)
                BQuickFillChip(
                  label: 'Clear',
                  icon: Iconsax.close_circle,
                  onTap: _clearAllocation,
                ),
            ],
          ),
      ],
    );
  }

  Widget _invoiceRow(BuildContext context, CollectionItemModel item) {
    final theme = Theme.of(context);
    final allocated = _amountFor(item.id);
    final remaining = item.toBeCollected - allocated;
    final status = itemStatuses[item.id] ?? '';
    final showRemark = _remarksShown.contains(item.id);

    return Container(
      padding: const EdgeInsets.all(BSizes.md),
      decoration: BoxDecoration(
        color: BCollectionColors.surface,
        border: Border.all(
          color: allocated > 0
              ? BCollectionColors.primary
              : BCollectionColors.outline,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${item.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: BCollectionColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${BFormatter.formatPesoCurrency(item.toBeCollected)} due',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showStatusPicker(item.id),
                child: _statusBadge(context, status),
              ),
            ],
          ),
          const SizedBox(height: BSizes.spaceBtwItemsLight),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: ValueKey('batch-amount-${item.id}'),
                  controller: itemAmountControllers[item.id],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Applied',
                    prefixText: '₱ ',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: BSizes.sm),
              BQuickFillChip(
                label: 'Full',
                onTap: () {
                  _setAmount(
                      itemAmountControllers[item.id]!, item.toBeCollected);
                  FocusManager.instance.primaryFocus?.unfocus();
                },
              ),
            ],
          ),
          // The leftover is almost always centavos, and typing centavos means
          // finding a decimal point on a numeric keypad — which not every
          // Android keyboard offers. One tap moves it onto this row instead.
          if (_canTakeRest(item)) ...[
            const SizedBox(height: BSizes.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: BQuickFillChip(
                label:
                    'Add the remaining ${BFormatter.formatPesoCurrency(_unallocated)}',
                icon: Iconsax.add_circle,
                onTap: () {
                  _setAmount(itemAmountControllers[item.id]!,
                      allocated + _unallocated);
                  FocusManager.instance.primaryFocus?.unfocus();
                },
              ),
            ),
          ],
          if (allocated > 0) ...[
            const SizedBox(height: BSizes.xs),
            Text(
              remaining.abs() < _tolerance
                  ? 'Settles this invoice'
                  : remaining > 0
                      ? '${BFormatter.formatPesoCurrency(remaining)} will remain'
                      : '${BFormatter.formatPesoCurrency(remaining.abs())} more than this invoice',
              style: theme.textTheme.bodySmall?.copyWith(
                color: remaining < -_tolerance
                    ? BCollectionColors.warning
                    : BCollectionColors.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          // Remarks are the exception on a batch, so the field is not there
          // until it is wanted.
          if (showRemark) ...[
            const SizedBox(height: BSizes.spaceBtwItemsLight),
            TextField(
              key: ValueKey('batch-remark-${item.id}'),
              controller: itemRemarkControllers[item.id],
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Remark',
                isDense: true,
              ),
            ),
          ] else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _remarksShown.add(item.id)),
                icon: const Icon(Iconsax.edit, size: 14),
                label: const Text('Add remark'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Anchors the check fields so switching them on can scroll them into view.
  final _checkFieldsKey = GlobalKey();

  static const _unfoldDuration = Duration(milliseconds: 180);

  void _setPayingByCheck(bool value) {
    setState(() => _payingByCheck = value);
    if (value) {
      BRevealScroll.into(_checkFieldsKey, afterUnfold: _unfoldDuration);
    }
  }

  /// Named for what it does, not for a payment type the record does not
  /// hold: switching it on is what puts check details on this batch.
  Widget _methodSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          value: _payingByCheck,
          onChanged: _setPayingByCheck,
          title: const Text('Paid by check'),
          secondary: const Icon(Iconsax.card),
          contentPadding: EdgeInsets.zero,
        ),
        // Three fields most batches never need, so most batches never see
        // them.
        AnimatedSize(
          duration: _unfoldDuration,
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _payingByCheck
              ? KeyedSubtree(key: _checkFieldsKey, child: _checkFields(context))
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _checkFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BSizes.spaceBtwInputFields),
        BBankField(controller: bankNameController),
        if (_bankSuggestions.isNotEmpty) ...[
          const SizedBox(height: BSizes.sm),
          Wrap(
            spacing: BSizes.sm,
            runSpacing: BSizes.sm,
            children: [
              for (final bank in _bankSuggestions)
                BQuickFillChip(
                  label: bank,
                  selected: bankNameController.text.trim() == bank,
                  onTap: () => setState(() => bankNameController.text = bank),
                ),
            ],
          ),
        ],
        const SizedBox(height: BSizes.spaceBtwInputFields),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: checkNumberController,
                decoration: const InputDecoration(
                  labelText: 'Check number',
                  prefixIcon: Icon(Iconsax.card_edit),
                ),
              ),
            ),
            const SizedBox(width: BSizes.sm),
            Expanded(
              child: TextField(
                controller: checkDateController,
                readOnly: true,
                onTap: _pickCheckDate,
                decoration: const InputDecoration(
                  labelText: 'Check date',
                  prefixIcon: Icon(Iconsax.calendar_1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: BSizes.sm),
        BQuickFillChip(
          label: 'Today',
          icon: Iconsax.calendar_1,
          onTap: () => setState(() =>
              checkDateController.text = BFormatter.formatDate(DateTime.now())),
        ),
      ],
    );
  }

  Future<void> _pickCheckDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      // Checks are often post-dated, so the future stays open.
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => checkDateController.text = BFormatter.formatDate(date));
    }
  }

  /// Where the split stands, pinned next to Save.
  ///
  /// This used to be a banner above a long list of rows, so the moment the
  /// collector scrolled down to fix a row they could no longer see what was
  /// left — and the disabled Save button at the bottom gave no reason.
  Widget _bottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final balanced = _isBalanced;
    final over = _unallocated < -_tolerance;
    final noTarget = _targetTotal <= 0;
    final undecided = _undecided.length;

    final (Color color, IconData icon, String message) = noTarget
        ? (
            BCollectionColors.inkMuted,
            Iconsax.info_circle,
            'Enter the amount received'
          )
        : balanced
            ? (undecided > 0
                ? (
                    BCollectionColors.warning,
                    Iconsax.info_circle,
                    undecided == 1
                        ? 'Set the outcome on 1 invoice'
                        : 'Set the outcome on $undecided invoices'
                  )
                : (
                    BCollectionColors.success,
                    Iconsax.tick_circle,
                    'Fully allocated'
                  ))
            : over
                ? (
                    BCollectionColors.danger,
                    Iconsax.warning_2,
                    '${BFormatter.formatPesoCurrency(_unallocated.abs())} over'
                  )
                : (
                    BCollectionColors.warning,
                    Iconsax.warning_2,
                    '${BFormatter.formatPesoCurrency(_unallocated)} left to allocate'
                  );

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace,
          BSizes.md,
          BSizes.defaultSpace,
          BSizes.md,
        ),
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
                Icon(icon, size: 16, color: color),
                const SizedBox(width: BSizes.xs),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            // On its own line. Beside the message, two six-figure amounts and
            // a sentence do not fit a phone: the row overflowed, and before
            // that the message wrapped into a ragged block.
            if (!noTarget) ...[
              const SizedBox(height: BSizes.xs),
              Text(
                '${BFormatter.formatPesoCurrency(_allocatedTotal)} of ${BFormatter.formatPesoCurrency(_targetTotal)} allocated',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: BCollectionColors.inkMuted),
              ),
            ],
            const SizedBox(height: BSizes.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSave ? _saveBatch : null,
                child: Text('Record ${widget.items.length} invoices'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker(String itemId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: BSizes.defaultSpace,
            left: BSizes.defaultSpace,
            right: BSizes.defaultSpace,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.paddingOf(context).bottom +
                BSizes.defaultSpace,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Outcome for #$itemId',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: BSizes.spaceBtwItems),
              ...CollectionStatusColors.updatableStatuses.map(
                (status) => ListTile(
                  title: Text(status),
                  leading: Icon(CollectionStatusColors.iconFor(status),
                      color: CollectionStatusColors.colorFor(status)),
                  trailing: itemStatuses[itemId] == status
                      ? const Icon(Iconsax.tick_circle,
                          color: BCollectionColors.primary)
                      : null,
                  onTap: () {
                    setModalState(() => itemStatuses[itemId] = status);
                    setState(() {
                      itemStatuses[itemId] = status;
                      // Chosen by hand, so the amount stops overriding it.
                      _statusSetByHand.add(itemId);
                    });
                    if (status != CollectionStatusColors.statusOthers) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              if (itemStatuses[itemId] ==
                  CollectionStatusColors.statusOthers) ...[
                const SizedBox(height: BSizes.sm),
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'What happened?',
                    prefixIcon: Icon(Iconsax.edit),
                  ),
                  onChanged: (val) => itemOthersRemarks[itemId] = val,
                  onSubmitted: (_) => Navigator.pop(context),
                ),
                const SizedBox(height: BSizes.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String status) {
    final unset = status.isEmpty;
    final (bg, _) = unset
        ? (BCollectionColors.inkMuted, BCollectionColors.surface)
        : CollectionStatusColors.colorsForAuto(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: BSizes.sm, vertical: BSizes.xxs),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            unset ? 'Set outcome' : status,
            style:
                TextStyle(color: bg, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Icon(Iconsax.edit, size: 10, color: bg),
        ],
      ),
    );
  }
}
