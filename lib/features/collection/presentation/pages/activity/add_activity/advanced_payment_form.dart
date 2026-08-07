import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

class AdvancedPaymentFormScreen extends StatefulWidget {
  const AdvancedPaymentFormScreen({super.key});

  @override
  State<AdvancedPaymentFormScreen> createState() => _AdvancedPaymentFormScreenState();
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
      BLoaders.errorSnackBar(title: 'Error', message: 'Please select an account');
      return;
    }

    final controller = CollectionActivityController.instance;
    controller.saveAdvancedPayment(
      clientId: selectedAccount!.id,
      amount: double.tryParse(amountController.text) ?? 0.0,
      remarks: remarksController.text,
    );

    Get.back(); // Close form
    BLoaders.successSnackBar(title: 'Success', message: 'Advanced Payment recorded.');
  }

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;
    final accounts = controller.masterAccountList;

    return Scaffold(
      appBar: const BAppBar(title: Text('Record Advanced Payment'), showBackArrow: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                DropdownButtonFormField<ClientModel>(
                  decoration: const InputDecoration(
                    labelText: 'Select Account',
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
                  validator: (value) => value == null ? 'Account is required' : null,
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),

                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount Paid',
                    prefixIcon: Icon(Iconsax.money_send),
                    prefixText: '₱ ',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Amount is required' : null,
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),
                
                TextFormField(
                  controller: remarksController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    prefixIcon: Icon(Iconsax.edit),
                  ),
                ),
                const SizedBox(height: BSizes.spaceBtwSections),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save Activity'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
