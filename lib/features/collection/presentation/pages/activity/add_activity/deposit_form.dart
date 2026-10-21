import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/deposit_remarks.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/bank_field.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/client_picker_sheet.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_amount_blur_pad.dart';

/// For Deposit: the collector's activity, nothing more.
///
/// A deposit counts toward neither Actual Collection nor Collected this Month
/// (revisions list item 9) and settles no invoice. The form is what the
/// deposit slip says — bank, amount, an optional check number (a cash
/// deposit has none) — and which accounts it covers (update checklist items
/// 12 and 13): each picked by search, with its share of the amount. The
/// remarks are written from those lines, "Account - Amount" one per line,
/// with an optional note last (see [BDepositRemarks]).
class DepositFormScreen extends StatefulWidget {
  const DepositFormScreen({super.key});

  @override
  State<DepositFormScreen> createState() => _DepositFormScreenState();
}

class _AccountLine {
  _AccountLine(this.client);

  final ClientModel client;
  final amount = TextEditingController();

  double get value => BFormatter.parseAmount(amount.text);
}

class _DepositFormScreenState extends State<DepositFormScreen> {
  final bankNameController = TextEditingController();
  final amountController = TextEditingController();
  final checkNumberController = TextEditingController();
  final noteController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final List<_AccountLine> _lines = [];

  /// The Amount follows the lines' total until the collector types it.
  bool _amountByHand = false;
  bool _settingAmount = false;
  String? _linesError;

  @override
  void initState() {
    super.initState();
    amountController.addListener(() {
      if (!_settingAmount) _amountByHand = true;
      // Refreshes the "accounts add up to" hint under the Amount.
      if (mounted) setState(() {});
    });
    noteController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    bankNameController.dispose();
    amountController.dispose();
    checkNumberController.dispose();
    noteController.dispose();
    for (final l in _lines) {
      l.amount.dispose();
    }
    super.dispose();
  }

  double get _linesTotal => _lines.fold(0.0, (sum, l) => sum + l.value);

  List<BDepositLine> get _depositLines => [
        for (final l in _lines)
          BDepositLine(account: l.client.name, amount: l.value),
      ];

  String get _remarks =>
      BDepositRemarks.compose(_depositLines, note: noteController.text);

  void _linesChanged() {
    setState(() => _linesError = null);
    if (_amountByHand) return;
    final total = _linesTotal;
    final text = total > 0
        ? BFormatter.formatPesoCurrency(total, includeSymbol: false).trim()
        : '';
    _settingAmount = true;
    amountController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _settingAmount = false;
  }

  Future<void> _addAccount() async {
    final controller = CollectionActivityController.instance;
    final client = await ClientPickerSheet.show(
      context,
      search: controller.searchClientRegistry,
      searchKnown: controller.searchKnownAccounts,
    );
    if (client == null || !mounted) return;
    // The same account twice would read as two deposits; keep one line.
    if (_lines.any((l) => l.client.id == client.id)) {
      BLoaders.warningSnackBar(
          title: 'Already added', message: '${client.name} is on the list.');
      return;
    }
    final line = _AccountLine(client);
    line.amount.addListener(_linesChanged);
    setState(() => _lines.add(line));
    _linesChanged();
  }

  void _removeAccount(_AccountLine line) {
    setState(() => _lines.remove(line));
    line.amount.dispose();
    _linesChanged();
  }

  /// Why the lines cannot be saved, or null.
  String? _checkLines() {
    if (_lines.isEmpty) return 'Add at least one account';
    if (_lines.any((l) => l.value <= 0)) {
      return 'Enter the amount for every account';
    }
    if (_remarks.length > BDepositRemarks.maxLength) {
      return 'Too many accounts for one deposit: the remarks hold '
          '${BDepositRemarks.maxLength} characters. Shorten the note or '
          'record a second deposit.';
    }
    return null;
  }

  void _save() {
    final linesError = _checkLines();
    setState(() => _linesError = linesError);
    final fieldsOk = formKey.currentState!.validate();
    if (!fieldsOk || linesError != null) return;

    CollectionActivityController.instance.saveGlobalActivity(
      type: 'Deposit',
      // Not recorded against an account: the accounts are in the remarks.
      clientId: '',
      accountName: '',
      remarks: _remarks,
      totalCollected: BFormatter.parseAmount(amountController.text),
      bankName: bankNameController.text.trim(),
      checkNumber: checkNumberController.text.trim(),
    );

    Get.back();
    BLoaders.successSnackBar(
        title: 'Deposit recorded',
        message: 'Saved as your activity. It does not count toward Actual '
            'Collection or Collected this Month.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _linesTotal;
    final amount = BFormatter.parseAmount(amountController.text);
    final differs =
        _lines.isNotEmpty && total > 0 && (amount - total).abs() >= 0.005;

    return Scaffold(
      appBar: const BAppBar(title: Text('Record Deposit'), showBackArrow: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            BSizes.defaultSpace,
            BSizes.defaultSpace,
            BSizes.defaultSpace,
            BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BBankField(
                  controller: bankNameController,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Bank is required'
                      : null,
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),

                TextFormField(
                  key: const ValueKey('deposit-check-number'),
                  controller: checkNumberController,
                  keyboardType: BCheckNumberInput.keyboardType,
                  inputFormatters: BCheckNumberInput.formatters,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Check Number (optional)',
                    prefixIcon: Icon(Iconsax.card_edit),
                  ),
                ),
                const SizedBox(height: BSizes.spaceBtwSections),

                // The accounts the deposit covers, each found by search.
                Text('Accounts', style: theme.textTheme.titleSmall),
                const SizedBox(height: BSizes.sm),
                for (final line in _lines) ...[
                  _lineRow(context, line),
                  const SizedBox(height: BSizes.sm),
                ],
                OutlinedButton.icon(
                  key: const ValueKey('deposit-add-account'),
                  onPressed: _addAccount,
                  icon: const Icon(Iconsax.search_normal_1, size: 18),
                  label: Text(
                      _lines.isEmpty ? 'Add account' : 'Add another account'),
                ),
                if (_linesError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: BSizes.xs),
                    child: Text(
                      _linesError!,
                      key: const ValueKey('deposit-lines-error'),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: BCollectionColors.danger),
                    ),
                  ),
                const SizedBox(height: BSizes.spaceBtwSections),

                BAmountBlurPad(
                  controller: amountController,
                  child: TextFormField(
                    key: const ValueKey('deposit-amount'),
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      prefixIcon: const Icon(Iconsax.money),
                      prefixText: '₱ ',
                      helperText: differs
                          ? 'The accounts add up to '
                              '${BFormatter.formatPesoCurrency(total)}'
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Amount is required';
                      }
                      if (BFormatter.parseAmount(value) <= 0) {
                        return 'Enter an amount greater than zero';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),

                TextFormField(
                  key: const ValueKey('deposit-note'),
                  controller: noteController,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: Icon(Iconsax.edit),
                  ),
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),

                // What the office will read, as it will be saved.
                if (_remarks.isNotEmpty) ...[
                  Text('Remarks', style: theme.textTheme.titleSmall),
                  const SizedBox(height: BSizes.xs),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(BSizes.md),
                    decoration: BoxDecoration(
                      color: BCollectionColors.surfaceMuted,
                      borderRadius:
                          BorderRadius.circular(BSizes.borderRadiusLg),
                    ),
                    child: Text(
                      _remarks,
                      key: const ValueKey('deposit-remarks-preview'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: BSizes.spaceBtwSections),
                ],

                ElevatedButton(
                  key: const ValueKey('deposit-save'),
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48)),
                  child: const Text('Record deposit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _lineRow(BuildContext context, _AccountLine line) {
    final theme = Theme.of(context);
    return Row(
      key: ValueKey('deposit-line-${line.client.id}'),
      children: [
        Expanded(
          flex: 3,
          child: Text(
            line.client.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: BSizes.sm),
        Expanded(
          flex: 2,
          child: BAmountBlurPad(
            controller: line.amount,
            child: TextField(
              key: ValueKey('deposit-line-amount-${line.client.id}'),
              controller: line.amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixText: '₱ ',
                isDense: true,
              ),
            ),
          ),
        ),
        IconButton(
          key: ValueKey('deposit-line-remove-${line.client.id}'),
          tooltip: 'Remove',
          onPressed: () => _removeAccount(line),
          icon: Icon(Iconsax.close_circle, color: BCollectionColors.inkMuted),
        ),
      ],
    );
  }
}
