import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/document_reference_screen.dart';

/// Compact entry point for document references on request forms.
///
/// Renders an "Add Document Reference (n)" button (same pattern as the
/// "Add Item (n)" button) that opens [DocumentReferenceScreen], where the
/// actual fields live. A hidden FormField keeps the required/duplicate
/// validation inside the host form's validate() pass.
class BDocumentReference extends StatelessWidget {
  const BDocumentReference({super.key, this.isRequired = true});

  /// Whether at least a value per field is mandatory. Stock Receive submits
  /// without document references; every other form keeps them required.
  /// The duplicate-value check stays active either way.
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<StandardDeliveryController>();

    List<String> nonEmptyRefs() => requestController
        .formState.documentReferenceControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Obx(() {
            final count = nonEmptyRefs().length;
            return TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: BSizes.sm),
              ),
              onPressed: () async {
                // Open the editor with one ready-to-fill field. Done here
                // (not in the screen's build) so the list isn't mutated
                // while widgets are still building.
                if (requestController
                    .formState.documentReferenceControllers.isEmpty) {
                  requestController.addDocumentReferenceField();
                }
                await Get.to(
                    () => DocumentReferenceScreen(isRequired: isRequired));
                // Typing into existing controllers doesn't notify the RxList;
                // refresh on return so the count label updates.
                requestController.formState.documentReferenceControllers
                    .refresh();
              },
              icon: const Icon(Iconsax.add, size: 16),
              label: Text(count > 0
                  ? 'Add Document Reference ($count)'
                  : 'Add Document Reference'),
            );
          }),
        ),

        /// Hidden validator so Create Request still guards references
        /// even though the fields live on a separate screen.
        FormField<String>(
          validator: (_) {
            final refs = nonEmptyRefs();
            if (isRequired && refs.isEmpty) {
              return 'At least one document reference is required';
            }
            if (refs.toSet().length != refs.length) {
              return 'Duplicate document reference';
            }
            return null;
          },
          builder: (FormFieldState<String> formFieldState) {
            return formFieldState.hasError
                ? Padding(
                    padding: const EdgeInsets.only(right: BSizes.sm),
                    child: Text(
                      formFieldState.errorText ?? '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
