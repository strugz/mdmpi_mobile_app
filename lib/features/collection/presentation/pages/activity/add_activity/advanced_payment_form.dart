import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/client_picker_sheet.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_amount_blur_pad.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_fill_chip.dart';

/// What an advance is usually for. A chip adds its label to the remarks, or
/// takes it back out; anything else is still typed.
const advancedPaymentRemarkChips = ['Machine', 'Reagents', 'Hold accounts'];

/// [remarks] with [label] added (or removed when already there), the parts
/// kept as a comma-separated list.
String toggleRemarkChip(String remarks, String label) {
  final parts = remarks
      .split(',')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
  final at = parts.indexWhere((p) => p.toLowerCase() == label.toLowerCase());
  at >= 0 ? parts.removeAt(at) : parts.add(label);
  return parts.join(', ');
}

bool _hasRemarkChip(String remarks, String label) => remarks
    .split(',')
    .any((p) => p.trim().toLowerCase() == label.toLowerCase());

class AdvancedPaymentFormScreen extends StatefulWidget {
  const AdvancedPaymentFormScreen({super.key});

  @override
  State<AdvancedPaymentFormScreen> createState() =>
      _AdvancedPaymentFormScreenState();
}

class _AdvancedPaymentFormScreenState extends State<AdvancedPaymentFormScreen> {
  ClientModel? selectedAccount;
  final amountController = TextEditingController();
  final remarksController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    amountController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    if (selectedAccount == null) {
      BLoaders.errorSnackBar(
          title: 'Error', message: 'Please select an account');
      return;
    }

    final controller = CollectionActivityController.instance;
    controller.saveAdvancedPayment(
      clientId: selectedAccount!.id,
      clientName: selectedAccount!.name,
      amount: BFormatter.parseAmount(amountController.text),
      remarks: remarksController.text.trim(),
    );

    Get.back(); // Close form
    BLoaders.successSnackBar(
        title: 'Success', message: 'Advanced Payment recorded.');
  }

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;

    return Scaffold(
      appBar: const BAppBar(
          title: Text('Record Advanced Payment'), showBackArrow: true),
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
                // Account: an existing client, searched in the registry. An
                // advance often comes before any invoice exists, so the
                // bucket's accounts were never the whole list.
                ClientPickerField(
                  key: const ValueKey('advance-account'),
                  value: selectedAccount,
                  search: controller.searchClientRegistry,
                  searchKnown: controller.searchKnownAccounts,
                  onChanged: (client) =>
                      setState(() => selectedAccount = client),
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),
                BAmountBlurPad(
                  controller: amountController,
                  child: TextFormField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Amount Paid',
                      hintText: '0.00',
                      prefixIcon: Icon(Iconsax.money_send),
                      prefixText: '₱ ',
                    ),
                    // "Not empty" was the whole check, so a zero or an
                    // unparseable amount sailed through and was recorded as
                    // ₱0.00 against the account.
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
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: remarksController,
                  builder: (context, value, _) => Wrap(
                    spacing: BSizes.sm,
                    runSpacing: BSizes.sm,
                    children: [
                      for (final label in advancedPaymentRemarkChips)
                        BQuickFillChip(
                          key: ValueKey('advance-remark-$label'),
                          label: label,
                          selected: _hasRemarkChip(value.text, label),
                          onTap: () {
                            final text =
                                toggleRemarkChip(remarksController.text, label);
                            remarksController.value = TextEditingValue(
                              text: text,
                              selection:
                                  TextSelection.collapsed(offset: text.length),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),
                TextFormField(
                  key: const ValueKey('advance-remarks'),
                  controller: remarksController,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Remarks (optional)',
                    prefixIcon: Icon(Iconsax.edit),
                  ),
                ),
                const SizedBox(height: BSizes.spaceBtwSections),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48)),
                  child: const Text('Record advanced payment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
