import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/scanner/simple_text_scanner.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';

/// Full-screen editor for document references.
///
/// Mirrors the ScannedItemsScreen pattern: request forms show a compact
/// "Add Document Reference (n)" button and this screen hosts the actual
/// field list (add, edit, scan, remove).
class DocumentReferenceScreen extends StatelessWidget {
  const DocumentReferenceScreen({super.key, this.isRequired = true});

  /// Whether at least a value per field is mandatory. Stock Receive submits
  /// without document references; every other form keeps them required.
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<StandardDeliveryController>();
    final dark = BHelperFunctions.isDarkMode(context);
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: BAppBar(
        title: Obx(() {
          final count = requestController
              .formState.documentReferenceControllers
              .where((c) => c.text.trim().isNotEmpty)
              .length;
          return Text(
            'Document References ($count)',
            style: Theme.of(context).textTheme.bodyLarge,
          );
        }),
        showBackArrow: true,
        leadingOnPressed: () => Get.back(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BSizes.md),
        child: Form(
          key: formKey,
          child: Obx(
            () => Column(
              children: <Widget>[
                Column(
                  children: requestController
                      .formState.documentReferenceControllers
                      .map((controller) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: BSizes.sm),
                      child: TextFormField(
                        onTap: () async {
                          // Only start scanner if current field is empty
                          if (controller.text.isEmpty) {
                            final result = await Get.to<List<String>?>(
                                () => const SimpleTextScanner());
                            // result == null -> user cancelled
                            if (result == null) {
                              // nothing to do
                              return;
                            }
                            if (result.isEmpty) {
                              // No matches found
                              Get.snackbar(
                                'No Text Found',
                                'Could not detect any document references. Please try again.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }

                            // Populate the tapped controller with the first non-duplicate match
                            final stdController = requestController;
                            for (int i = 0; i < result.length; i++) {
                              final String match = result[i].trim();
                              if (match.isEmpty) continue;

                              final bool alreadyExists = stdController
                                  .formState.documentReferenceControllers
                                  .any((c) => c.text.trim() == match);

                              if (alreadyExists) {
                                // skip duplicates
                                continue;
                              }

                              if (i == 0) {
                                // Put first match in the tapped controller
                                controller.text = match;
                              } else {
                                // Add new field(s) for subsequent matches
                                stdController.addDocumentReferenceField();
                                stdController.formState
                                    .documentReferenceControllers
                                    .last.text = match;
                              }
                            }
                          }
                        },
                        controller: controller,
                        decoration: InputDecoration(
                            prefixIcon: Icon(Iconsax.document_code),
                            labelText: isRequired
                                ? 'Document Reference'
                                : 'Document Reference (optional)',
                            labelStyle: TextStyle(
                                color:
                                    dark ? BColors.light : BColors.darkerGrey),
                            suffixIcon: IconButton(
                                onPressed: () {
                                  requestController
                                      .removeDocumentReferenceField(controller);
                                },
                                icon: Icon(Iconsax.close_circle))),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return isRequired
                                ? 'Document Reference is required'
                                : null;
                          }
                          final all = requestController
                              .formState.documentReferenceControllers
                              .map((c) => c.text.trim())
                              .where((s) => s.isNotEmpty)
                              .toList();
                          final count = all.where((s) => s == text).length;
                          if (count > 1) return 'Duplicate document reference';
                          return null;
                        },
                      ),
                    );
                  }).toList(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: requestController.addDocumentReferenceField,
                    icon: const Icon(Iconsax.add, size: BSizes.md),
                    label: const Text('Add Document Reference'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BSizes.sm),
          child: ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Get.back();
              }
            },
            child: const Text('Done'),
          ),
        ),
      ),
    );
  }
}
