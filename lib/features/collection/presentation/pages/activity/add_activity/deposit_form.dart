import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';

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
  List<String> selectedInvoiceIds = [];

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
    if (selectedClient == null || selectedInvoiceIds.isEmpty) {
      BLoaders.errorSnackBar(title: 'Required', message: 'Please select an Account and at least one Invoice.');
      return;
    }

    final controller = CollectionActivityController.instance;
    controller.saveGlobalActivity(
      type: 'Deposit',
      accountName: selectedClient!.name,
      remarks: 'Deposit for Invoice(s) #${selectedInvoiceIds.join(', ')}. ${remarksController.text}',
      totalCollected: double.tryParse(amountController.text.replaceAll(',', '')) ?? 0,
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
                      selectedInvoiceIds.clear();
                    });
                  },
                  validator: (value) => value == null ? 'Account is required' : null,
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),

                // Invoice Selection (Filtered by Client) - multi-select checklist (matches Reconciliation)
                if (selectedClient != null) ...[
                  Text('Select Invoices', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: BSizes.sm),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                    ),
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView(
                      shrinkWrap: true,
                      children: controller.getInvoicesByAccount(selectedClient!.id).map((inv) {
                        return CheckboxListTile(
                          title: Text(inv.id),
                          subtitle: Text('Posted: ${inv.postingDate} | Due: ${inv.dueDate}\nAmount: ${BFormatter.formatPesoCurrency(inv.toBeCollected, includeSymbol: true)}'),
                          value: selectedInvoiceIds.contains(inv.id),
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                selectedInvoiceIds.add(inv.id);
                              } else {
                                selectedInvoiceIds.remove(inv.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: BSizes.spaceBtwInputFields),
                ],

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
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Iconsax.money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Amount is required';
                    final normalized = value.replaceAll(',', '');
                    if (double.tryParse(normalized) == null) return 'Enter a valid amount';
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
