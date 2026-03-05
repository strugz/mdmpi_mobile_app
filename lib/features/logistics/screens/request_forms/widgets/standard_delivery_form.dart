import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_client_validation_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/read_only_date_field.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_mdmpi_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_client_information.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_document_reference.dart';

import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../common/widgets/dropdown/dropdown_dynamic_list.dart';
import '../../../controllers/standard_delivery_controller.dart';
import '../../../controllers/request_controller.dart';

class StandardDelivery extends StatelessWidget {
  const StandardDelivery({super.key});

  @override
  Widget build(BuildContext context) {
    final stdDeliveryController = Get.find<StandardDeliveryController>();
    final userCNTMSTController = Get.find<UserMdmpiController>();
    final requestController = Get.find<RequestController>();

    userCNTMSTController.filterUserFromLocal();

    // Pre-select form category from RequestController if available
    try {
      final selectedCategory = requestController.currentSelectedCategory.value;

      if (selectedCategory != null) {
        // Set form category based on selected tab
        stdDeliveryController.formState.formCategory.text = selectedCategory.id;
      }
    } catch (e) {
      logDebug('RequestController not found or error reading category: $e');
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
                key: stdDeliveryController.formState.formKey,
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
                            clientInformation: stdDeliveryController.formState.clientInformation,
                          ),

                          const Divider(),
                          const SizedBox(height: BSizes.sm),

                          /// Document Reference
                          const BDocumentReference(),
                          const SizedBox(height: BSizes.sm),

                          /// Item Category dropdown
                          Obx(() {
                            final categories = stdDeliveryController.formState.itemCategories;
                            if (categories.isEmpty) {
                              return BDropdown(
                                controller: stdDeliveryController
                                    .formState.itemCategory,
                                label: 'Item Category',
                                dropdownList: const [],
                              );
                            }
                            return BDropDownDynamicList(
                              controller: stdDeliveryController
                                  .formState.itemCategory,
                              icon: Iconsax.box,
                              label: 'Item Category',
                              dropdownList: categories
                                  .map((cat) => cat.toJson())
                                  .toList(),
                              valueKey: 'ItemCategoryID',
                              displayKey: 'ItemCategoryName',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Please select an item category'
                                  : null,
                            );
                          }),
                          const SizedBox(height: BSizes.spaceBtwItems),

                          /// Form Category dropdown
                          Obx(() {
                            final categories = stdDeliveryController.formState.formCategories;
                            if (categories.isEmpty) {
                              return BDropdown(
                                controller: stdDeliveryController
                                    .formState.formCategory,
                                label: 'Form Category',
                                dropdownList: const [],
                              );
                            }
                            return BDropDownDynamicList(
                              controller: stdDeliveryController
                                  .formState.formCategory,
                              icon: Iconsax.document,
                              label: 'Form Category',
                              dropdownList: categories
                                  .map((cat) => cat.toJson())
                                  .toList(),
                              valueKey: 'FormCategoryID',
                              displayKey: 'FormCategoryName',
                              readOnly: true,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Please select a form category'
                                  : null,
                            );
                          }),
                          const SizedBox(height: BSizes.sm),
                        ],
                      ),

                      /// Shipping Method dropdown
                      BDropdown(
                        controller:
                            stdDeliveryController.formState.shippingMethod,
                        label: 'Shipping Method',
                        dropdownList: ['Land', 'Air', 'Sea'],
                        validator: (v) => (v == null || v.toString().trim().isEmpty)
                            ? 'Please select a shipping method'
                            : null,
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// Delivery Terms dropdown
                      BDropdown(
                          controller:
                              stdDeliveryController.formState.deliveryTerms,
                          icon: Iconsax.truck,
                          label: 'Delivery Terms',
                          dropdownList: ['Partial', 'Full'],
                          validator: (v) => (v == null || v.toString().trim().isEmpty)
                              ? 'Please select delivery terms'
                              : null,
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// Target date
                      ReadOnlyDateFormField(
                        controller: stdDeliveryController.formState.targetDate,
                        label: 'Delivery Date',
                        includeTime: false,
                        icon: Iconsax.calendar,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please select a delivery date'
                            : null,
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            BDropdown(
                                controller:
                                    stdDeliveryController.formState.preference,
                                icon: Iconsax.status_up,
                                label: 'Priority',
                                dropdownList: ['Rush','High', 'Medium', 'Low'],
                                validator: (v) => (v == null || v.toString().trim().isEmpty)
                                    ? 'Please select a priority level'
                                    : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// Requested By
                      Center(
                        child: Obx(
                          () => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              BDropDownDynamicList(
                                controller:
                                    stdDeliveryController.formState.requestedBy,
                                icon: Iconsax.personalcard,
                                label: 'Requested By',
                                dropdownList: userCNTMSTController.userList
                                    .map((user) => user.toJson())
                                    .toList(),
                                onChanged: (String? newId) {},
                                valueKey: 'CNTMNN',
                                displayKey: 'CNTMCN',
                                enableSearch: true,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Please select who requested this'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
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
          child: ElevatedButton(
              onPressed: () {
                // Validate form before submission
                if (stdDeliveryController.formState.formKey.currentState?.validate() ?? false) {
                  stdDeliveryController.saveRequest();
                }
              },
              child: const Text('Create Request')),
        ),
      ),
    );
  }
}
