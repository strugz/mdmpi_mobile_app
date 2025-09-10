import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_mdmpi_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request/request_controller_components.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_client_information.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_document_reference.dart';

import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../common/widgets/dropdown/dropdown_dynamic_list.dart';
import '../../../controllers/request_controller.dart';

class HotlineDirectForm extends StatelessWidget {
  const HotlineDirectForm({super.key});

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<RequestController>();
    final userCNTMSTController = Get.find<UserMdmpiController>();
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
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            TextFormField(
                              onTap: () => RequestControllerComponents
                                  .showDateTimerPicker(
                                  context, requestController.formState.targetDate),
                              controller: requestController.formState.targetDate,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Iconsax.clock),
                                labelText: 'Delivery Date',
                                labelStyle: TextStyle(color: BColors.darkGrey),
                              ),
                            )
                          ],
                        ),
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
