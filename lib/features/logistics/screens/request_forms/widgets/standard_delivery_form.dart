import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
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

class StandardDelivery extends StatelessWidget {
  const StandardDelivery({super.key});

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<StandardDeliveryController>();
    final userCNTMSTController = Get.find<UserMdmpiController>();
    final itemCategoryRepo = Get.find<ItemCategoryRepository>();
    final formCategoryRepo = Get.find<FormCategoryRepository>();

    userCNTMSTController.filterUserFromLocal();

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
                key: requestController.formState.formKey,
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
                          const Divider(),
                          const SizedBox(height: BSizes.sm),

                          /// Document Reference
                          const BDocumentReference(),
                          const SizedBox(height: BSizes.sm),

                          /// Item Category dropdown
                          FutureBuilder(
                            future: itemCategoryRepo.getAll(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                                return BDropdown(
                                  controller: requestController.formState.itemCategory,
                                  label: 'Item Category',
                                  dropdownList: const [],
                                );
                              }
                              return BDropDownDynamicList(
                                controller: requestController.formState.itemCategory,
                                icon: Iconsax.box,
                                label: 'Item Category',
                                dropdownList: snapshot.data!.map((cat) => cat.toJson()).toList(),
                                valueKey: 'ItemCategoryID',
                                displayKey: 'ItemCategoryName',
                              );
                            },
                          ),
                          const SizedBox(height: BSizes.spaceBtwItems),

                          /// Form Category dropdown
                          FutureBuilder(
                            future: formCategoryRepo.getAll(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                                return BDropdown(
                                  controller: requestController.formState.formCategory,
                                  label: 'Form Category',
                                  dropdownList: const [],
                                );
                              }
                              return BDropDownDynamicList(
                                controller: requestController.formState.formCategory,
                                icon: Iconsax.document,
                                label: 'Form Category',
                                dropdownList: snapshot.data!.map((cat) => cat.toJson()).toList(),
                                valueKey: 'FormCategoryID',
                                displayKey: 'FormCategoryName',
                              );
                            },
                          ),
                          const SizedBox(height: BSizes.sm),
                        ],
                      ),

                      /// Shipping Method dropdown
                      BDropdown(
                        controller: requestController.formState.shippingMethod,
                        label: 'Shipping Method',
                        dropdownList: ['Land', 'Air', 'Sea'],
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// Delivery Terms dropdown
                      BDropdown(
                          controller: requestController.formState.deliveryTerms,
                          icon: Iconsax.truck,
                          label: 'Delivery Terms',
                          dropdownList: ['Partial', 'Full']),
                      const SizedBox(height: BSizes.spaceBtwItems),

                      /// Target date
                      ReadOnlyDateFormField(
                        controller: requestController.formState.targetDate,
                        label: 'Delivery Date',
                        includeTime: false,
                        icon: Iconsax.calendar,
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            BDropdown(
                                controller: requestController.formState.preference,
                                icon: Iconsax.status_up,
                                label: 'Priority',
                                dropdownList: ['High', 'Medium', 'Low']),
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
                                controller: requestController.formState.requestedBy,
                                icon: Iconsax.personalcard,
                                label: 'Requested By',
                                dropdownList: userCNTMSTController.userList
                                    .map((user) => user.toJson())
                                    .toList(),
                                onChanged: (String? newId) {},
                                valueKey: 'CNTMNN',
                                displayKey: 'CNTMCN',
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
              onPressed: () => requestController.saveRequest(),
              child: Text('Create Request')),
        ),
      ),
    );
  }
}
