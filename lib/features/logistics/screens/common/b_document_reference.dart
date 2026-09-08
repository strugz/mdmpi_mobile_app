import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/scanner/simple_text_scanner.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';

import '../../../../../base/utils/constants/colors.dart';

class BDocumentReference extends StatelessWidget {
  const BDocumentReference({super.key, this.isRequired = true});

  /// Whether at least a value per field is mandatory. Stock Receive submits
  /// without document references; every other form keeps them required.
  /// The duplicate-value check stays active either way.
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<StandardDeliveryController>();
    final dark = BHelperFunctions.isDarkMode(context);
    return Center(
      child: Obx(
        () => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              children: requestController.formState.documentReferenceControllers
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
                            stdController.formState.documentReferenceControllers
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
                            color: dark ? BColors.light : BColors.darkerGrey),
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
    );
  }
}
