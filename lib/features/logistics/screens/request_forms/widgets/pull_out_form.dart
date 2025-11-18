import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_dynamic_list.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_mdmpi_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_client_information.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_document_reference.dart';

import '../../../../../base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/text_formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/read_only_date_field.dart';

class PullOutForm extends StatelessWidget {
  const PullOutForm({super.key});

  @override
  Widget build(BuildContext context) {
    final PullOutController controller = Get.find();
    final StandardDeliveryController stdController = Get.find();
    final UserMdmpiController userController = Get.find();

    userController.filterUserFromLocal();

    // Ensure there's at least one document reference field when opening the form
    final stdFormRefs = stdController.formState.documentReferenceControllers;
    if (stdFormRefs.isEmpty) {
      stdController.addDocumentReferenceField();
    }

    Future<void> onSave() async {
      await controller.submitFromForm();
      Get.back();
    }

    // Get the bottom padding of the device
    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final bool isGestureNavigation = bottomPadding > 0.0;

    return SafeArea(
      bottom: !isGestureNavigation,
      child: Scaffold(
        appBar: BAppBar(
          title: Text(BTexts.requestFormTitle,
              style: Theme.of(context).textTheme.bodyLarge),
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
                        children: const [
                          /// Search Client
                          BClientInformation(),
                          Divider(),
                          SizedBox(height: BSizes.sm),

                          /// Document Reference
                          BDocumentReference(),
                          SizedBox(height: BSizes.sm),
                        ],
                      ),

                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// Form Category
                      Obx(() => BDropdown(
                            controller: controller.formCategoryController,
                            label: 'Form Category',
                            dropdownList: controller.formCategories
                                    .map((e) => e.name)
                                    .toList()
                                    .isEmpty
                                ? ['']
                                : controller.formCategories
                                    .map((e) => e.name)
                                    .toList(),
                            validator: (v) =>
                                (v == null || v.toString().trim().isEmpty)
                                    ? 'Please select a form category'
                                    : null,
                          )),
                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// Item Category
                      Obx(() => BDropdown(
                            controller: controller.itemCategoryController,
                            label: 'Item Category',
                            dropdownList: controller.itemCategories
                                    .map((e) => e.name)
                                    .toList()
                                    .isEmpty
                                ? ['']
                                : controller.itemCategories
                                    .map((e) => e.name)
                                    .toList(),
                            validator: (v) =>
                                (v == null || v.toString().trim().isEmpty)
                                    ? 'Please select an item category'
                                    : null,
                          )),
                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// Slip No
                      TextFormField(
                        controller: controller.slipNoController,
                        decoration: const InputDecoration(labelText: 'Slip No'),
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [UpperCaseTextFormatter()],
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// Client Contact Person
                      TextFormField(
                        controller: controller.clientContactPersonController,
                        decoration: const InputDecoration(
                            labelText: 'Client Contact Person'),
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// IRRF Number
                      TextFormField(
                        controller: controller.irrfNumberController,
                        decoration:
                            const InputDecoration(labelText: 'IRRF Number'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// IRRF Date
                      ReadOnlyDateFormField(
                        controller: controller.irrfDateController,
                        label: 'IRRF Date',
                        includeTime: false,
                        icon: Iconsax.calendar,
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// Reason for Return
                      TextFormField(
                        controller: controller.reasonController,
                        decoration: const InputDecoration(
                            labelText: 'Reason for Return'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// Pull Out Date (date only)
                      ReadOnlyDateFormField(
                        controller: controller.pullOutDateController,
                        label: 'Pull Out Date',
                        includeTime: false,
                        icon: Iconsax.clock,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please pick a pull out date'
                            : null,
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),

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
                                valueKey: 'CNTMNN',
                                displayKey: 'CNTMCN',
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
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(BSizes.sm),
          child: Obx(() {
            final isSaving = controller.isSaving.value;
            return ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      // Trigger form validation and submit
                      if (controller.formState.formKey.currentState
                              ?.validate() ??
                          false) {
                        await onSave();
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Request'),
            );
          }),
        ),
      ),
    );
  }
}
