import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

class ReconciliationFormScreen extends StatefulWidget {
  const ReconciliationFormScreen({super.key});

  @override
  State<ReconciliationFormScreen> createState() => _ReconciliationFormScreenState();
}

class _ReconciliationFormScreenState extends State<ReconciliationFormScreen> {
  final accountNameController = TextEditingController();
  final remarksController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    accountNameController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;

    final controller = CollectionActivityController.instance;
    controller.saveGlobalActivity(
      type: 'Reconciliation',
      accountName: accountNameController.text,
      remarks: remarksController.text,
    );

    Get.back(); // Close form first
    BLoaders.successSnackBar(title: 'Success', message: 'Reconciliation activity recorded.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BAppBar(title: Text('Record Reconciliation'), showBackArrow: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: accountNameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    prefixIcon: Icon(Iconsax.user),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Account name is required' : null,
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
