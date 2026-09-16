import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_outcome.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_fill_chip.dart';

/// How the money came in. Drives whether the check fields exist at all.
enum PaymentMethod { cash, check }

/// Record a collection against one invoice.
///
/// Built around typing as little as possible, because this is filled in the
/// field, one-handed, many times a day. Everything the app already knows is
/// offered as a tap:
///
///  - Cash is the default method, so the three check fields are not rendered
///    at all unless Check is chosen. That is the single biggest reduction.
///  - The balance is a chip, so a full payment is one tap instead of typing
///    eight digits. It is also the common case.
///  - The outcome follows the amount (full pays Collected, part pays
///    Partially Collected) and stops following the moment it is set by hand.
///  - Bank names already used are chips; the check date defaults to today.
class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({super.key, required this.item});

  final CollectionItemModel item;

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late String selectedStatus;
  late PaymentMethod _method;

  late final TextEditingController totalCollectedController;
  late final TextEditingController bankNameController;
  late final TextEditingController checkNumberController;
  late final TextEditingController checkDateController;
  late final TextEditingController othersRemarkController;

  /// Once the outcome is chosen by hand, the amount stops overriding it.
  /// Changing a field under the user is worse than making them tap once.
  bool _statusSetByHand = false;

  late final List<String> _bankSuggestions;

  double get _balance => widget.item.toBeCollected;

  double get _enteredAmount =>
      BFormatter.parseAmount(totalCollectedController.text);

  @override
  void initState() {
    super.initState();

    if (widget.item.status.trim().isEmpty ||
        !CollectionStatusColors.updatableStatuses
            .contains(widget.item.status)) {
      selectedStatus = CollectionStatusColors.statusCollected;
    } else {
      selectedStatus = widget.item.status;
    }

    totalCollectedController = TextEditingController();
    totalCollectedController.addListener(_onAmountChanged);

    // Carry over the bank details last used on this invoice.
    CollectionHistoryModel? lastBankInfo;
    for (final h in widget.item.history.reversed) {
      if (h.bankName != null && h.bankName!.isNotEmpty) {
        lastBankInfo = h;
        break;
      }
    }

    bankNameController =
        TextEditingController(text: lastBankInfo?.bankName ?? '');
    checkNumberController =
        TextEditingController(text: lastBankInfo?.checkNumber ?? '');
    checkDateController =
        TextEditingController(text: lastBankInfo?.checkDate ?? '');
    othersRemarkController = TextEditingController();

    // If this invoice was last paid by check, start there; otherwise cash,
    // which is both the common case and the one with nothing to fill in.
    _method = lastBankInfo != null ? PaymentMethod.check : PaymentMethod.cash;

    // Suggestions are a convenience, never a requirement: if the controller
    // is not around the form still works, it just offers no bank chips.
    _bankSuggestions = Get.isRegistered<CollectionActivityController>()
        ? CollectionActivityController.instance.recentBankNames()
        : const <String>[];
  }

  @override
  void dispose() {
    totalCollectedController.removeListener(_onAmountChanged);
    totalCollectedController.dispose();
    bankNameController.dispose();
    checkNumberController.dispose();
    checkDateController.dispose();
    othersRemarkController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final implied = CollectionOutcome.forAmount(_enteredAmount, _balance);
    setState(() {
      if (!_statusSetByHand && implied != null) selectedStatus = implied;
    });
  }

  void _fillFullAmount() {
    // Grouped, because a value set in code bypasses the input formatters and
    // an ungrouped 37759.82 would not match what typing the same figure
    // produces.
    final text =
        BFormatter.formatPesoCurrency(_balance, includeSymbol: false).trim();
    totalCollectedController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    FocusManager.instance.primaryFocus?.unfocus();
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

  void _saveActivity() {
    final controller = CollectionActivityController.instance;
    final isOthers = selectedStatus == CollectionStatusColors.statusOthers;
    final customRemark = othersRemarkController.text.trim();

    if (isOthers && customRemark.isEmpty) {
      Get.snackbar('Required', 'Please enter a remark for "Others"',
          backgroundColor: BColors.warning);
      return;
    }

    final finalStatus = isOthers ? customRemark : selectedStatus;
    final usingCheck = _method == PaymentMethod.check;

    controller.saveActivity(
      id: widget.item.id,
      status: finalStatus.isEmpty ? 'Others' : finalStatus,
      remarks: finalStatus.isEmpty ? 'Others' : finalStatus,
      totalCollected: _enteredAmount,
      // Cash records no check details, the same as leaving them blank before.
      bankName: usingCheck && bankNameController.text.trim().isNotEmpty
          ? bankNameController.text.trim()
          : null,
      checkNumber: usingCheck && checkNumberController.text.trim().isNotEmpty
          ? checkNumberController.text.trim()
          : null,
      checkDate: usingCheck && checkDateController.text.trim().isNotEmpty
          ? checkDateController.text.trim()
          : null,
      purposeOfVisit:
          selectedStatus == CollectionStatusColors.statusPreCollection
              ? 'Pre-Collection'
              : 'Collection',
    );

    Get.back();
    Get.snackbar(
      'Saved',
      'Engagement updated',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: BColors.success.withValues(alpha: 0.9),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = _enteredAmount;
    final remaining = (_balance - amount).clamp(0, double.infinity).toDouble();
    final overpaid = amount > _balance;

    return Scaffold(
      appBar: AppBar(title: const Text('Engagement Details')),
      // Save stays reachable without scrolling back down.
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            BSizes.defaultSpace,
            BSizes.spaceBtwItemsLight,
            BSizes.defaultSpace,
            BSizes.spaceBtwItemsLight,
          ),
          decoration: const BoxDecoration(
            color: BColors.white,
            border: Border(top: BorderSide(color: BColors.grey)),
          ),
          child: ElevatedButton.icon(
            onPressed: _saveActivity,
            icon: const Icon(Iconsax.tick_circle, size: 18),
            label: const Text('Save engagement'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              elevation: 0,
              backgroundColor: BColors.primary,
              foregroundColor: BColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace,
          BSizes.spaceBtwItemsLight,
          BSizes.defaultSpace,
          BSizes.spaceBtwSections,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summary(context),
            const SizedBox(height: BSizes.spaceBtwSections),

            _sectionLabel(context, 'Amount collected'),
            const SizedBox(height: BSizes.sm),
            _amountField(),
            const SizedBox(height: BSizes.sm),
            _amountHelpers(context, amount, remaining, overpaid),

            const SizedBox(height: BSizes.spaceBtwSections),
            _sectionLabel(context, 'Outcome'),
            const SizedBox(height: BSizes.sm),
            _statusChips(),
            if (selectedStatus == CollectionStatusColors.statusOthers) ...[
              const SizedBox(height: BSizes.spaceBtwItemsLight),
              TextField(
                controller: othersRemarkController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'What happened?',
                  prefixIcon: Icon(Iconsax.edit),
                ),
                maxLines: 2,
              ),
            ],

            const SizedBox(height: BSizes.spaceBtwSections),
            _sectionLabel(context, 'Payment method'),
            const SizedBox(height: BSizes.sm),
            _methodChips(),

            // Only exists for checks. Cash collections never see these three
            // fields, which is the whole point.
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _method == PaymentMethod.check
                  ? _checkFields(context)
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      );

  /// Invoice, balance and the two dates that matter, in one block.
  ///
  /// Replaces four boxed tiles that between them pushed the form below the
  /// fold and included an often-empty Status tile and the account name, which
  /// the collector just came from.
  Widget _summary(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = widget.item.isOverdue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BSizes.spaceBtwItemsLight),
      decoration: BoxDecoration(
        color: BColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
        border: Border.all(color: BColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '#${widget.item.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: BColors.darkerGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                widget.item.client.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: BColors.darkGrey),
              ),
            ],
          ),
          const SizedBox(height: BSizes.xs),
          Text(
            BFormatter.formatPesoCurrency(_balance),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: BColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: BSizes.xxs),
          Text(
            'Balance due · ${_dueLabel()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: overdue ? BColors.error : BColors.darkGrey,
              fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _dueLabel() {
    final due = widget.item.dueDate.trim();
    if (due.isEmpty || due == 'N/A') return 'no due date';
    final date = BFormatter.formatDate3(due);
    if (!widget.item.isOverdue) return 'due $date';
    return '${BFormatter.formatDaysOverdue(widget.item.daysPastDue).toLowerCase()} ($date)';
  }

  Widget _amountField() => TextField(
        controller: totalCollectedController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        // The same typing rules as every other money field in Collection:
        // digits, one decimal point, grouped as you go so a five-figure
        // balance stays readable.
        inputFormatters: [ThousandsSeparatorInputFormatter()],
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        decoration: const InputDecoration(
          hintText: '0.00',
          // prefixIcon rather than prefixText: a prefix only paints once the
          // field has focus or content, so the peso sign would vanish exactly
          // when the field is empty and the label matters most.
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: BSizes.md, right: BSizes.sm),
            child: Text(
              '₱',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BColors.darkGrey,
              ),
            ),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      );

  /// One tap for the whole balance, plus a running total so the collector
  /// never has to do the subtraction in their head.
  Widget _amountHelpers(
      BuildContext context, double amount, double remaining, bool overpaid) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: BSizes.sm,
          runSpacing: BSizes.sm,
          children: [
            BQuickFillChip(
              label: 'Full ${BFormatter.formatPesoCurrency(_balance)}',
              icon: Iconsax.wallet_check,
              selected: amount > 0 && amount >= _balance,
              onTap: _fillFullAmount,
            ),
            if (totalCollectedController.text.isNotEmpty)
              BQuickFillChip(
                label: 'Clear',
                icon: Iconsax.close_circle,
                onTap: () {
                  totalCollectedController.clear();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
              ),
          ],
        ),
        if (amount > 0) ...[
          const SizedBox(height: BSizes.sm),
          Text(
            overpaid
                ? 'That is ${BFormatter.formatPesoCurrency(amount - _balance)} more than the balance'
                : remaining == 0
                    ? 'Settles this invoice in full'
                    : '${BFormatter.formatPesoCurrency(remaining)} will remain',
            style: theme.textTheme.bodySmall?.copyWith(
              color: overpaid ? BColors.warning : BColors.darkGrey,
              fontWeight: overpaid ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  /// Chips rather than a dropdown: one tap instead of open-then-choose, and
  /// the whole set is readable without opening anything.
  Widget _statusChips() => Wrap(
        spacing: BSizes.sm,
        runSpacing: BSizes.sm,
        children: [
          for (final status in CollectionStatusColors.updatableStatuses)
            BQuickFillChip(
              label: status,
              selected: selectedStatus == status,
              onTap: () => setState(() {
                selectedStatus = status;
                _statusSetByHand = true;
              }),
            ),
        ],
      );

  Widget _methodChips() => Wrap(
        spacing: BSizes.sm,
        runSpacing: BSizes.sm,
        children: [
          BQuickFillChip(
            label: 'Cash',
            icon: Iconsax.money,
            selected: _method == PaymentMethod.cash,
            onTap: () => setState(() => _method = PaymentMethod.cash),
          ),
          BQuickFillChip(
            label: 'Check',
            icon: Iconsax.card,
            selected: _method == PaymentMethod.check,
            onTap: () => setState(() => _method = PaymentMethod.check),
          ),
        ],
      );

  Widget _checkFields(BuildContext context) {
    final today = BFormatter.formatDate(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BSizes.spaceBtwItems),
        TextField(
          controller: bankNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Bank name',
            prefixIcon: Icon(Iconsax.bank),
          ),
        ),
        // Banks this collector already uses, so the name is picked not typed.
        if (_bankSuggestions.isNotEmpty) ...[
          const SizedBox(height: BSizes.sm),
          Wrap(
            spacing: BSizes.sm,
            runSpacing: BSizes.sm,
            children: [
              for (final bank in _bankSuggestions)
                BQuickFillChip(
                  label: bank,
                  selected: bankNameController.text.trim().toLowerCase() ==
                      bank.toLowerCase(),
                  onTap: () => setState(() => bankNameController.text = bank),
                ),
            ],
          ),
        ],
        const SizedBox(height: BSizes.spaceBtwInputFields),
        TextField(
          controller: checkNumberController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Check number',
            prefixIcon: Icon(Iconsax.card_edit),
          ),
        ),
        const SizedBox(height: BSizes.spaceBtwInputFields),
        TextField(
          controller: checkDateController,
          readOnly: true,
          onTap: _pickCheckDate,
          decoration: InputDecoration(
            hintText: 'Check date',
            prefixIcon: const Icon(Iconsax.calendar_1),
            suffixIcon: IconButton(
              tooltip: 'Pick a date',
              icon: const Icon(Iconsax.arrow_down_1, size: 18),
              onPressed: _pickCheckDate,
            ),
          ),
        ),
        const SizedBox(height: BSizes.sm),
        // Most checks handed over are dated today.
        BQuickFillChip(
          label: 'Today',
          icon: Iconsax.calendar_tick,
          selected: checkDateController.text == today,
          onTap: () => setState(() => checkDateController.text = today),
        ),
      ],
    );
  }
}
