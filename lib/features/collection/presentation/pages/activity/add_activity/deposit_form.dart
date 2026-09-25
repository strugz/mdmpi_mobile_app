import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/client_picker_sheet.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/bank_field.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/widgets/engagement_invoice_picker.dart';

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
      BLoaders.errorSnackBar(
          title: 'Required',
          message: 'Please select an Account and at least one Invoice.');
      return;
    }

    final controller = CollectionActivityController.instance;
    controller.saveGlobalActivity(
      type: 'Deposit',
      clientId: selectedClient!.id,
      documentIds: selectedInvoiceIds,
      accountName: selectedClient!.name,
      remarks:
          'Deposit for Invoice(s) #${selectedInvoiceIds.join(', ')}. ${remarksController.text}',
      totalCollected: BFormatter.parseAmount(amountController.text),
      bankName: bankNameController.text,
      checkNumber: checkNumberController.text,
    );

    Get.back();
    BLoaders.successSnackBar(
        title: 'Success', message: 'Deposit activity recorded.');
  }

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;

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
                // Account: an existing client, searched in the registry.
                ClientPickerField(
                  key: const ValueKey('deposit-account'),
                  value: selectedClient,
                  search: controller.searchClientRegistry,
                  searchKnown: controller.searchKnownAccounts,
                  onChanged: (client) => setState(() {
                    selectedClient = client;
                    selectedInvoiceIds.clear();
                  }),
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),

                // The checklist unfolds under the account rather than
                // popping in, so the form grows instead of jumping.
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: selectedClient == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(
                              bottom: BSizes.spaceBtwInputFields),
                          child: EngagementInvoicePicker(
                            invoices: controller
                                .getInvoicesByAccount(selectedClient!.id),
                            selectedIds: selectedInvoiceIds,
                            onToggle: (id, selected) => setState(() {
                              selected
                                  ? selectedInvoiceIds.add(id)
                                  : selectedInvoiceIds.remove(id);
                            }),
                          ),
                        ),
                ),

                BBankField(
                  controller: bankNameController,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Bank is required'
                      : null,
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),

                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Iconsax.money),
                    prefixText: '₱ ',
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
                const SizedBox(height: BSizes.spaceBtwInputFields),

                TextFormField(
                  controller: checkNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Check Number',
                    prefixIcon: Icon(Iconsax.card_edit),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Check number is required'
                      : null,
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),

                TextFormField(
                  controller: remarksController,
                  maxLines: 3,
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
                  child: const Text('Record deposit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
