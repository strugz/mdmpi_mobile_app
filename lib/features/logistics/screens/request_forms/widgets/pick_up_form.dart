import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/multi_select_drop_down.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_client_validation_field.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_client_information.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_document_reference.dart';

import '../../../../../base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/read_only_date_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/b_submit_button.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

class PickUpForm extends StatelessWidget {
  const PickUpForm({super.key});

  @override
  Widget build(BuildContext context) {
    final PickUpController controller = Get.find();
    final StandardDeliveryController stdController = Get.find();
    final RequestController requestController = Get.find();

    final stdFormRefs = stdController.formState.documentReferenceControllers;
    if (stdFormRefs.isEmpty) {
      stdController.addDocumentReferenceField();
    }

    // Initialize Pick-Up Date to today when form opens
    if (controller.formState.datePickUpController.text.isEmpty) {
      controller.formState.initializeDefaultDate();
    }

    Future<void> onSave() async {
      // Validate Client Information
      if (stdController.formState.clientInformation.value == null ||
          stdController.formState.clientInformation.value!.id.isEmpty) {
        BLoaders.errorSnackBar(
          title: 'Validation Error',
          message: 'Please select a client',
        );
        return;
      }

      // Validate Document Reference
      final hasDocumentReference = stdFormRefs.any((controller) =>
        controller.text.trim().isNotEmpty
      );
      if (!hasDocumentReference) {
        BLoaders.errorSnackBar(
          title: 'Validation Error',
          message: 'Please add at least one document reference',
        );
        return;
      }

      // Validate Item Categories (multi-select)
      if (controller.formState.selectedItemCategoryIds.isEmpty) {
        BLoaders.errorSnackBar(
          title: 'Validation Error',
          message: 'Please select at least one item category',
        );
        return;
      }

      await controller.submitFromForm();

      if ((controller.errorMessage.value ?? '').isEmpty) {
        controller.formState.preparedByController.clear();
        controller.formState.itemPreparedAtController.clear();
        controller.formState.itemPreparedEndAtController.clear();
        // Keep datePickUpController to retain the last selected date
        controller.formState.remarksController.clear();
        controller.formState.releasedByController.clear();
        controller.formState.receivedByController.clear();

        // Reload categories to re-apply defaults (Item Category)
        controller.formState.selectedItemCategoryIds.clear();
        controller.formState.itemCategoryController.clear();
        await controller.loadCategories();

        // Reset shared Standard Delivery form state used by common widgets
        stdController.formState.reset();
        stdController.addDocumentReferenceField(); // ensure a fresh field

        BLoaders.successSnackBar(title: 'Success', message: 'Request created');
      } else {
        BLoaders.errorSnackBar(
            title: 'Error',
            message: controller.errorMessage.value ?? 'Failed to add request');
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: BAppBar(
          title: Text(
            BTexts.getRequestFormTitle(
              requestController.currentSelectedCategory.value?.name,
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          showBackArrow: true,
          leadingOnPressed: () => Get.back(),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: controller.formState.formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: BSizes.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Search Client
                          const BClientInformation(),

                          /// Hidden validator for client selection
                          BClientValidationField(
                            clientInformation: stdController.formState.clientInformation,
                          ),

                          const Divider(),
                          const SizedBox(height: BSizes.sm),

                          /// Document Reference
                          const BDocumentReference(),
                          const SizedBox(height: BSizes.sm),
                        ],
                      ),

                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// Item Categories (multi-select; first = primary)
                      Obx(() => BMultiSelectDropDown(
                            label: 'Item Categories',
                            icon: Iconsax.box,
                            items: controller.formState.itemCategories
                                .map((e) => e.toJson())
                                .toList(),
                            valueKey: 'ItemCategoryID',
                            displayKey: 'ItemCategoryName',
                            selectedValues: controller
                                .formState.selectedItemCategoryIds
                                .toList(),
                            onChanged: (values) {
                              controller.formState.selectedItemCategoryIds
                                  .assignAll(values);
                              // Mirror the primary selection for legacy readers.
                              controller.formState.itemCategoryController.text =
                                  values.isNotEmpty ? values.first : '';
                            },
                            validator: (values) =>
                                (values == null || values.isEmpty)
                                    ? 'Please select at least one item category'
                                    : null,
                          )),
                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// Pick-Up Date (date only)
                      ReadOnlyDateFormField(
                        controller: controller.formState.datePickUpController,
                        label: 'Pick-Up Date',
                        includeTime: false,
                        icon: Iconsax.calendar,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please pick a pick-up date'
                            : null,
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: BSizes.sm,
              right: BSizes.sm,
              bottom: BSizes.sm,
            ),
            child: Obx(() {
              final isSaving = controller.isSaving.value;
              return BSubmitButton(
                isLoading: isSaving,
                label: 'Create Request',
                onPressed: () async {
                  if (isSaving) return;
                  if (controller.formState.formKey.currentState?.validate() ??
                      false) {
                    await onSave();
                  }
                },
              );
            }),
          ),
        ),
      );
  }
}
