import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/data/services/collection_sms_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/client_picker_sheet.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// Routing of Documents: the collector took documents to or from an account
/// (update checklist item 7). For tracking the activity only: an account
/// and what was routed, no amount and no invoices. It is the collector's
/// activity, like a CWT Pick-up, and adds nothing to a money total.
class RoutingDocumentsFormScreen extends StatefulWidget {
  const RoutingDocumentsFormScreen({super.key});

  @override
  State<RoutingDocumentsFormScreen> createState() =>
      _RoutingDocumentsFormScreenState();
}

class _RoutingDocumentsFormScreenState
    extends State<RoutingDocumentsFormScreen> {
  final remarksController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  ClientModel? _client;

  @override
  void dispose() {
    remarksController.dispose();
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    final client = _client;
    if (client == null) {
      BLoaders.errorSnackBar(
          title: 'Account needed', message: 'Pick the account first.');
      return;
    }

    CollectionActivityController.instance.saveGlobalActivity(
      type: CollectionStatusColors.statusRoutingDocuments,
      clientId: client.id,
      accountName: client.name,
      remarks: remarksController.text.trim(),
    );

    Get.back();
    if (!CollectionSmsService.smsFollows()) {
      BLoaders.successSnackBar(
          title: 'Recorded', message: 'Routing of Documents saved.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;
    return Scaffold(
      appBar: const BAppBar(
          title: Text('Record Routing of Documents'), showBackArrow: true),
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
                ClientPickerField(
                  key: const ValueKey('routing-account'),
                  value: _client,
                  search: controller.searchClientRegistry,
                  searchKnown: controller.searchKnownAccounts,
                  onChanged: (client) => setState(() => _client = client),
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),
                // Required: the remarks are the record of what was routed.
                TextFormField(
                  key: const ValueKey('routing-remarks'),
                  controller: remarksController,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    hintText: 'Which documents, and to or from whom',
                    prefixIcon: Icon(Iconsax.edit),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Remarks are required'
                      : null,
                ),
                const SizedBox(height: BSizes.spaceBtwSections),
                ElevatedButton(
                  key: const ValueKey('routing-save'),
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48)),
                  child: const Text('Record routing of documents'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
