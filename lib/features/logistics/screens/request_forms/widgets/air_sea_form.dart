import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_dynamic_list.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_client_validation_field.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/shipping_methods.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_hd_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_client_information.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_document_reference.dart';

import '../../../../../base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/read_only_date_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/b_submit_button.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

class AirSeaForm extends StatelessWidget {
  const AirSeaForm({super.key});

  @override
  Widget build(BuildContext context) {
    final StandardDeliveryController stdController = Get.find();
    final RequestController requestController = Get.find();

    // This form is shared by the base 'Air / Sea / Land' tab and its urgent
    // 'Air / Sea / Land HD' variant — bind to the controller matching the tab
    // so the request is created (and the list refreshed) under the right
    // category, mirroring how the Standard Delivery form serves Hotline Direct.
    final selectedCategoryName =
        requestController.currentSelectedCategory.value?.name ?? '';
    final selectedType =
        FormCategoryConstants.fromCategoryName(selectedCategoryName);
    final AirSeaController controller =
        selectedType == FormCategoryType.airSeaHd
            ? Get.find<AirSeaHdController>()
            : Get.find<AirSeaController>();

    final stdFormRefs = stdController.formState.documentReferenceControllers;
    if (stdFormRefs.isEmpty) {
      stdController.addDocumentReferenceField();
    }

    Future<void> onSave() async {
      await controller.submitFromForm();

      if ((controller.errorMessage.value ?? '').isEmpty) {
        controller.formState.preparedByController.clear();
        controller.formState.itemPreparedAtController.clear();
        controller.formState.itemPreparedEndAtController.clear();
        controller.formState.datePickUpController.clear();
        controller.formState.remarksController.clear();

        await controller.loadCategories();

        stdController.formState.reset();
        stdController.addDocumentReferenceField();

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

                      /// Item Category (display name, store ID)
                      Obx(() => BDropDownDynamicList(
                            controller:
                                controller.formState.itemCategoryController,
                            label: 'Item Category',
                            dropdownList: controller.formState.itemCategories
                                .map((e) => e.toJson())
                                .toList(),
                            valueKey: 'ItemCategoryID',
                            displayKey: 'ItemCategoryName',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please select an item category'
                                : null,
                          )),
                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// Form Category (read-only, driven by the selected tab)
                      TextFormField(
                        readOnly: true,
                        enabled: false,
                        initialValue: selectedCategoryName.isNotEmpty
                            ? selectedCategoryName
                            : FormCategoryType.airSea.categoryName,
                        decoration: const InputDecoration(
                          labelText: 'Form Category',
                          prefixIcon: Icon(Iconsax.document),
                        ),
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// Mode of Shipment (required, create-only)
                      BDropdown(
                        controller:
                            controller.formState.shippingMethodController,
                        label: 'Mode of Shipment',
                        icon: Iconsax.ship,
                        dropdownList: ShippingMethods.all,
                        validator: (v) =>
                            (v == null || v.toString().trim().isEmpty)
                                ? 'Please select the mode of shipment'
                                : null,
                      ),
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
              bottom: BSizes.sm + MediaQuery.of(context).viewInsets.bottom,
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
