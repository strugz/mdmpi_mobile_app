import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_dynamic_list.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_autocomplete_text_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_client_validation_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_list.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/mobile_controller.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_initial_controller.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_mdmpi_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/scanner/scanned_items_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_client_information.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_document_reference.dart';
import 'package:mdmpi_mobile_app/features/logistics/widgets/trip_ticket_input.dart';

import '../../../../../base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/read_only_date_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_text_form_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/b_submit_button.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

class PullOutForm extends StatelessWidget {
  const PullOutForm({super.key});

  @override
  Widget build(BuildContext context) {
    final PullOutController controller = Get.find();
    final StandardDeliveryController stdController = Get.find();
    final UserMdmpiController userController = Get.find();
    final RequestController requestController = Get.find();
    final UserInitialController userInitialController = Get.find();
    final MobileController mobileController = Get.find();

    userController.filterUserFromLocal();

    final stdFormRefs = stdController.formState.documentReferenceControllers;
    if (stdFormRefs.isEmpty) {
      stdController.addDocumentReferenceField();
    }

    // Pre-select form category from RequestController if available
    bool isStockReceive = false;
    try {
      final selectedCategory = requestController.currentSelectedCategory.value;
      isStockReceive = FormCategoryConstants.fromCategoryName(
              selectedCategory?.name ?? '') ==
          FormCategoryType.stockReceive;

      if (selectedCategory != null) {
        // Set form category based on selected tab
        controller.formState.formCategoryController.text = selectedCategory.id;
        logDebug(
            'Pre-selected form category from RequestController: ${selectedCategory.name} (ID: ${selectedCategory.id})');
      }
    } catch (e) {
      logDebug('RequestController not found or error reading category: $e');
    }

    Future<void> onSave() async {
      // Save contact person name for autocomplete before clearing
      final contactPersonName =
          controller.formState.clientContactPersonController.text.trim();

      await controller.submitFromForm();

      if ((controller.errorMessage.value ?? '').isEmpty) {
        // Save contact person to database for future autocomplete
        if (contactPersonName.isNotEmpty) {
          await saveClientContactPerson(contactPersonName);
        }

        controller.formState.clientContactPersonController.clear();
        controller.formState.irrfNumberController.clear();
        controller.formState.irrfDateController.clear();
        controller.formState.reasonController.clear();
        controller.formState.pullOutDateController.clear();
        controller.formState.tripTicketController.clear();
        controller.formState.commute.reset();
        controller.formState.driverController.clear();
        controller.formState.helperController.clear();
        controller.formState.mobile.clear();

        stdController.formState.requestedBy.clear();

        await controller.loadCategories();

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
                          clientInformation:
                              stdController.formState.clientInformation,
                        ),

                        const Divider(),
                        const SizedBox(height: BSizes.sm),

                        /// Document Reference — optional for Stock Receive,
                        /// required for Pull Out / Return.
                        BDocumentReference(isRequired: !isStockReceive),
                        const SizedBox(height: BSizes.sm),

                        /// Add Item (scanner) — Pull Out only; Stock Receive
                        /// shares this form but has no item list.
                        if (!isStockReceive)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Obx(() {
                              final count = stdController
                                  .formState.scannedInventoryItems.length;
                              return TextButton.icon(
                                onPressed: () => Get.to(() =>
                                    ScannedItemsScreen(
                                        controller: stdController)),
                                icon: const Icon(Iconsax.add, size: 16),
                                label: Text(count > 0
                                    ? 'Add Item ($count)'
                                    : 'Add Item'),
                              );
                            }),
                          ),
                        if (!isStockReceive)
                          const SizedBox(height: BSizes.sm),
                      ],
                    ),

                    const SizedBox(height: BSizes.spaceBtwItems),

                    /// Form Category (display name, store ID)
                    Obx(() => BDropDownDynamicList(
                          controller:
                              controller.formState.formCategoryController,
                          label: 'Form Category',
                          icon: null,
                          dropdownList: controller.formState.formCategories
                              .map((e) => e.toJson())
                              .toList(),
                          valueKey: 'FormCategoryID',
                          displayKey: 'FormCategoryName',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please select a form category'
                              : null,
                          readOnly: true,
                        )),
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

                    /// Client Contact Person
                    BAutocompleteTextField(
                      controller:
                          controller.formState.clientContactPersonController,
                      autocompleteController:
                          controller.formState.clientContactPersonAutocomplete,
                      label: 'Client Contact Person',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter client contact person'
                          : null,
                    ),
                    const SizedBox(height: BSizes.spaceBtwItems),

                    /// IRRF Number
                    BTextFormField(
                      controller: controller.formState.irrfNumberController,
                      label: 'IRRF Number',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: BSizes.spaceBtwItems),

                    /// IRRF Date
                    ReadOnlyDateFormField(
                      controller: controller.formState.irrfDateController,
                      label: 'IRRF Date',
                      includeTime: false,
                      icon: Iconsax.calendar,
                    ),
                    const SizedBox(height: BSizes.spaceBtwItems),

                    /// Reason for Return
                    BTextFormField(
                      controller: controller.formState.reasonController,
                      label: 'Reason for Return',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Reason for Return is required';
                        }
                        if (value.trim().length < 10) {
                          return 'Reason must be at least 10 characters long';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: BSizes.spaceBtwItems),

                    /// Pull Out Date (date only)
                    ReadOnlyDateFormField(
                      controller: controller.formState.pullOutDateController,
                      label: isStockReceive
                          ? 'Stock Receive Date'
                          : 'Pull Out Date',
                      includeTime: false,
                      icon: Iconsax.clock,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? (isStockReceive
                              ? 'Please pick a stock receive date'
                              : 'Please pick a pull out date')
                          : null,
                    ),
                    const SizedBox(height: BSizes.spaceBtwItems),

                    /// Delivery Info — Stock Receive is dispatched at
                    /// creation, so the assigned driver sees it right away.
                    if (isStockReceive) ...[
                      const BTextDivider(text: 'Delivery Info'),
                      const SizedBox(height: BSizes.spaceBtwItems),
                      TripTicketInput(
                        tripTicket: controller.formState.tripTicketController,
                        commute: controller.formState.commute,
                        vehicle: controller.formState.mobile,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter Trip Ticket Number'
                            : null,
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),
                      Obx(() {
                        final users = userInitialController.userList.toList();
                        if (users.isEmpty) {
                          return const SizedBox(
                              height: 24,
                              width: 24,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2));
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: DropdownList<UserModel>(
                                label: 'Driver',
                                dropdownList: users,
                                controller:
                                    controller.formState.driverController,
                                getValue: (u) => u.initial,
                                getDisplay: (u) => u.initial,
                                onChanged: (_) {},
                              ),
                            ),
                            const SizedBox(width: BSizes.spaceBtwItems),
                            Expanded(
                              child: DropdownList<UserModel>(
                                label: 'Helper',
                                dropdownList: users,
                                controller:
                                    controller.formState.helperController,
                                getValue: (u) => u.initial,
                                getDisplay: (u) => u.initial,
                                onChanged: (_) {},
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: BSizes.spaceBtwItems),
                      // A commuting driver has no vehicle to pick (hidden, so
                      // its validator does not run either).
                      Obx(() => controller.formState.commute.isOn.value
                          ? const SizedBox.shrink()
                          : BDropDownDynamicList(
                              icon: Iconsax.truck,
                              label: 'Vehicle',
                              dropdownList: mobileController.mobile
                                  .map((m) => m.toJson())
                                  .toList(),
                              controller: controller.formState.mobile,
                              valueKey: 'MobileID',
                              displayKey: 'MobileName',
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Please select Vehicle'
                                      : null,
                            )),
                      const SizedBox(height: BSizes.spaceBtwItems),
                    ],

                    /// Requested By
                    Center(
                      child: Obx(
                        () => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            BDropDownDynamicList(
                              controller: stdController.formState.requestedBy,
                              icon: Iconsax.personalcard,
                              label: 'Requested By',
                              dropdownList: userController.userList
                                  .map((user) => user.toJson())
                                  .toList(),
                              onChanged: (String? newId) {},
                              valueKey: 'CNTMNN',
                              displayKey: 'CNTMCN',
                              enableSearch: true,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Please select requestor'
                                  : null,
                            ),
                          ],
                        ),
                      ),
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
