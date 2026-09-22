import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

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
      amount: BFormatter.parseAmount(amountController.text),
      remarks: remarksController.text,
    );

    Get.back(); // Close form
    BLoaders.successSnackBar(
        title: 'Success', message: 'Advanced Payment recorded.');
  }

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;
    final accounts = controller.masterAccountList;

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
                DropdownButtonFormField<ClientModel>(
                  // The button sizes itself to the widest client name unless told
                  // to fill the row, and long pharmacy names overflowed by hundreds
                  // of pixels. Expanded, the name ellipsises inside the field.
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Account',
                    prefixIcon: Icon(Iconsax.user),
                  ),
                  value: selectedAccount,
                  items: accounts.map((a) {
                    return DropdownMenuItem(
                      value: a,
                      child: Text(a.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedAccount = v),
                  validator: (value) =>
                      value == null ? 'Account is required' : null,
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),
                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Amount Paid',
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
                const SizedBox(height: BSizes.spaceBtwInputFields),
                TextFormField(
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
