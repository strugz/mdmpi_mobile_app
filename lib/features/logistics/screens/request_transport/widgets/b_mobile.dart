import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_dynamic_list.dart';

import '../../../../../data/controllers/app_data/mobile_controller.dart';

class BMobile extends StatelessWidget {
  const BMobile({
    super.key,
    required this.requestController,
  });

  final IDeliveryRequestController requestController;

  @override
  Widget build(BuildContext context) {
    final mobileController = Get.find<MobileController>();
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Obx(
        () => BDropDownDynamicList(
            icon: Iconsax.truck,
            label: 'Vehicle',
            dropdownList:
                mobileController.mobile.map((mobile) => mobile.toJson()).toList(),
            controller: requestController.formState.mobile,
            valueKey: 'MobileID',
            displayKey: 'MobileName',
            onChanged: (String? newID) {
              if (newID != null) {
                mobileController.mobile.firstWhere(
                    // This line finds an item but doesn't do anything with it
                    (item) => item.mobileID == newID);
              }
            }),
      ),
    );
  }
}
