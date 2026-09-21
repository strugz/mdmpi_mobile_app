import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

class ReconciliationFormScreen extends StatefulWidget {
  const ReconciliationFormScreen({super.key});

  @override
  State<ReconciliationFormScreen> createState() =>
      _ReconciliationFormScreenState();
}

class _ReconciliationFormScreenState extends State<ReconciliationFormScreen> {
  ClientModel? selectedAccount;
  final List<String> selectedInvoiceIds = [];
  final remarksController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
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
    if (selectedInvoiceIds.isEmpty) {
      BLoaders.errorSnackBar(
          title: 'Error', message: 'Please select at least one invoice');
      return;
    }

    final controller = CollectionActivityController.instance;
    controller.markInvoicesForReconciliation(
      selectedAccount!.id,
      selectedInvoiceIds,
      remarksController.text,
    );

    Get.back(); // Close form
    BLoaders.successSnackBar(
        title: 'Success', message: 'Reconciliation activity recorded.');
  }

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;
    final accounts = controller.masterAccountList;

    return Scaffold(
      appBar: const BAppBar(
          title: Text('Record Reconciliation'), showBackArrow: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  onChanged: (v) {
                    setState(() {
                      selectedAccount = v;
                      selectedInvoiceIds.clear();
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Account is required' : null,
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),
                if (selectedAccount != null) ...[
                  Text('Select Invoices',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: BSizes.sm),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius:
                          BorderRadius.circular(BSizes.borderRadiusMd),
                    ),
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView(
                      shrinkWrap: true,
                      children: controller
                          .getInvoicesByAccount(selectedAccount!.id)
                          .map((inv) {
                        return CheckboxListTile(
                          title: Text(inv.id),
                          subtitle: Text(
                              'Posted: ${inv.postingDate} | Due: ${inv.dueDate}\nAmount: ${inv.toBeCollected}'),
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
