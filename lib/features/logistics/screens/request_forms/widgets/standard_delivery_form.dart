import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/read_only_date_field.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_mdmpi_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_client_information.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_document_reference.dart';

import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../common/widgets/dropdown/dropdown_dynamic_list.dart';
import '../../../../../data/repositories/common/item_category_repository.dart';
import '../../../../../data/repositories/common/form_category_repository.dart';
import '../../../controllers/standard_delivery_controller.dart';
import '../../../controllers/request_controller.dart';

class StandardDelivery extends StatelessWidget {
  const StandardDelivery({super.key});

  @override
  Widget build(BuildContext context) {
    final stdDeliveryController = Get.find<StandardDeliveryController>();
    final userCNTMSTController = Get.find<UserMdmpiController>();
    final itemCategoryRepo = Get.find<ItemCategoryRepository>();
    final formCategoryRepo = Get.find<FormCategoryRepository>();
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

    // Get the bottom padding of the device
    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final bool isGestureNavigation = bottomPadding > 0.0;

    return SafeArea(
      bottom: !isGestureNavigation,
      child: Scaffold(
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
                          FormField<String>(
                            validator: (_) {
                              final client = stdDeliveryController.formState.clientInformation.value;
                              if (client == null || client.id.isEmpty) {
                                return 'Please select a client';
                              }
                              return null;
                            },
                            builder: (formFieldState) {
                              return formFieldState.hasError
                                  ? Padding(
                                      padding: const EdgeInsets.only(left: BSizes.sm, top: 4.0),
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

                          const Divider(),
                          const SizedBox(height: BSizes.sm),

                          /// Document Reference
                          const BDocumentReference(),
                          const SizedBox(height: BSizes.sm),

                          /// Item Category dropdown
                          FutureBuilder(
                            future: itemCategoryRepo.getAll(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError ||
                                  !snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
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
                                dropdownList: snapshot.data!
                                    .map((cat) => cat.toJson())
                                    .toList(),
                                valueKey: 'ItemCategoryID',
                                displayKey: 'ItemCategoryName',
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Please select an item category'
                                    : null,
                              );
                            },
                          ),
                          const SizedBox(height: BSizes.spaceBtwItems),

                          /// Form Category dropdown
                          FutureBuilder(
                            future: formCategoryRepo.getAll(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError ||
                                  !snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
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
                                dropdownList: snapshot.data!
                                    .map((cat) => cat.toJson())
                                    .toList(),
                                valueKey: 'FormCategoryID',
                                displayKey: 'FormCategoryName',
                                readOnly: true,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Please select a form category'
                                    : null,
                              );
                            },
                          ),
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
                                dropdownList: ['High', 'Medium', 'Low'],
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
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(BSizes.sm),
          child: ElevatedButton(
              onPressed: () {
                // Validate form before submission
                if (stdDeliveryController.formState.formKey.currentState?.validate() ?? false) {
                  stdDeliveryController.saveRequest();
                }
              },
              child: Text('Create Request')),
        ),
      ),
    );
  }
}
