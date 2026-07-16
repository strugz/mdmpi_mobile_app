import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

class DepositFormScreen extends StatefulWidget {
  const DepositFormScreen({super.key});

  @override
  State<DepositFormScreen> createState() => _DepositFormScreenState();
}

class _DepositFormScreenState extends State<DepositFormScreen> {
  final bankNameController = TextEditingController();
  final amountController = TextEditingController();
  final checkNumberController = TextEditingController();
  final remarksController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  ClientModel? selectedClient;
  CollectionItemModel? selectedInvoice;

  @override
  void dispose() {
    bankNameController.dispose();
    amountController.dispose();
    checkNumberController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    if (selectedClient == null || selectedInvoice == null) {
      BLoaders.errorSnackBar(title: 'Required', message: 'Please select an Account and Invoice.');
      return;
    }

    final controller = CollectionActivityController.instance;
    controller.saveGlobalActivity(
      type: 'Deposit',
      accountName: selectedClient!.name,
      remarks: 'Deposit for Invoice #${selectedInvoice!.id}. ${remarksController.text}',
      totalCollected: double.tryParse(amountController.text) ?? 0,
      bankName: bankNameController.text,
      checkNumber: checkNumberController.text,
    );

    Get.back();
    BLoaders.successSnackBar(title: 'Success', message: 'Deposit activity recorded.');
  }

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;

    return Scaffold(
      appBar: const BAppBar(title: Text('Record Deposit'), showBackArrow: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                // Account Selection
                DropdownButtonFormField<ClientModel>(
                  value: selectedClient,
                  decoration: const InputDecoration(
                    labelText: 'Account',
                    prefixIcon: Icon(Iconsax.user),
                  ),
                  items: controller.masterAccountList.map((client) {
                    return DropdownMenuItem(
                      value: client,
                      child: Text(client.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedClient = val;
                      selectedInvoice = null;
                    });
                  },
                  validator: (value) => value == null ? 'Account is required' : null,
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),

                // Invoice Selection (Filtered by Client)
                if (selectedClient != null)
                  DropdownButtonFormField<CollectionItemModel>(
                    value: selectedInvoice,
                    decoration: const InputDecoration(
                      labelText: 'Invoice',
                      prefixIcon: Icon(Iconsax.document_text),
                    ),
                    items: controller.getInvoicesByAccount(selectedClient!.id).map((inv) {
                      return DropdownMenuItem(
                        value: inv,
                        child: Text('Invoice #${inv.id}'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedInvoice = val),
                    validator: (value) => value == null ? 'Invoice is required' : null,
                  ),
                const SizedBox(height: BSizes.spaceBtwInputFields),

                TextFormField(
                  controller: bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    prefixIcon: Icon(Iconsax.bank),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Bank name is required' : null,
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),
                
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Iconsax.money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Amount is required';
                    if (double.tryParse(value) == null) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),
                
                TextFormField(
                  controller: checkNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Check Number',
                    prefixIcon: Icon(Iconsax.card_edit),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Check number is required' : null,
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),
                
                TextFormField(
                  controller: remarksController,
                  maxLines: 3,
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
