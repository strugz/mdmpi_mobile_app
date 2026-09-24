import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/client_picker_sheet.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

class CWTPickupFormScreen extends StatefulWidget {
  const CWTPickupFormScreen({super.key});

  @override
  State<CWTPickupFormScreen> createState() => _CWTPickupFormScreenState();
}

class _CWTPickupFormScreenState extends State<CWTPickupFormScreen> {
  /// Shows the chosen client's name; the field itself is read-only.
  final accountNameController = TextEditingController();
  final remarksController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  /// The existing client picked from the registry. The account used to be
  /// typed freehand, and a name spelled differently from the registry saved
  /// with no client id.
  ClientModel? _client;

  Future<void> _pickClient() async {
    final controller = CollectionActivityController.instance;
    final picked = await ClientPickerSheet.show(
      context,
      search: controller.searchClientRegistry,
      searchKnown: controller.searchKnownAccounts,
      selected: _client,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _client = picked;
      accountNameController.text = picked.name;
    });
    formKey.currentState?.validate();
  }

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
      type: 'CWT Pick-up',
      clientId: _client!.id,
      accountName: _client!.name,
      remarks: remarksController.text,
    );

    Get.back(); // Close form first
    BLoaders.successSnackBar(
        title: 'Success', message: 'CWT Pick-up activity recorded.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          const BAppBar(title: Text('Record CWT Pick-up'), showBackArrow: true),
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
                // Tap to search the existing clients; nothing is typed here.
                TextFormField(
                  key: const ValueKey('cwt-account'),
                  controller: accountNameController,
                  readOnly: true,
                  onTap: _pickClient,
                  decoration: InputDecoration(
                    labelText: 'Account',
                    hintText: 'Choose an existing client',
                    prefixIcon: const Icon(Iconsax.user),
                    suffixIcon: const Icon(Iconsax.arrow_down_1, size: 18),
                    helperText: _client?.code,
                  ),
                  validator: (_) =>
                      _client == null ? 'Choose the account' : null,
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
                  child: const Text('Record CWT pick-up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
