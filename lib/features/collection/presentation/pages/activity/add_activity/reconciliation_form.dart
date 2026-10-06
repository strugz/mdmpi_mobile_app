import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/client_picker_sheet.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/widgets/engagement_invoice_picker.dart';

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

    return Scaffold(
      appBar: const BAppBar(
          title: Text('Record Reconciliation'), showBackArrow: true),
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
                  key: const ValueKey('reconciliation-account'),
                  value: selectedAccount,
                  search: controller.searchClientRegistry,
                  searchKnown: controller.searchKnownAccounts,
                  onChanged: (client) => setState(() {
                    selectedAccount = client;
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
                  child: selectedAccount == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(
                              bottom: BSizes.spaceBtwInputFields),
                          child: EngagementInvoicePicker(
                            invoices: controller
                                .getInvoicesByAccount(selectedAccount!.id),
                            selectedIds: selectedInvoiceIds,
                            onToggle: (id, selected) => setState(() {
                              selected
                                  ? selectedInvoiceIds.add(id)
                                  : selectedInvoiceIds.remove(id);
                            }),
                          ),
                        ),
                ),
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
                  child: const Text('Record reconciliation'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
