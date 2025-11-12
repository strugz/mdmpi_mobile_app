import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_action_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_prepared_by_and_dispatcher_information.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_request_details.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/constants/sizes.dart';
import '../../../../personalization/controller/user_controller.dart';
import '../../../controllers/standard_delivery_controller.dart';
import '../../../controllers/request_transport_controller.dart';

class BDispatcher extends StatelessWidget {
  const BDispatcher({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final requestController = Get.find<StandardDeliveryController>();
    final userController = Get.find<UserController>();
    final requestTransportController = Get.find<RequestTransportController>();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.45,
      maxChildSize: 0.45,
      minChildSize: 0.45,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: dark ? BColors.black : BColors.light,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Column(
            children: [
              _buildDragHandle(dark),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: BSizes.defaultSpace),
                      child: BRequestDetails(
                        requestController: requestController,
                        userController: userController,
                        requestTransportController: requestTransportController,
                      )),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
                child: BPreparedByAndDispatcherInformation(
                    request: requestController.currentSelectedRequest.value!,
                    userController: userController),
              ),
              Padding(
                padding: const EdgeInsets.all(
                    BSizes.defaultSpace), // Adjust padding as needed
                child: BActionButton(
                  requestController: requestController,
                  requestTransportController: requestTransportController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle(bool dark) {
    return SizedBox(
      height: 30,
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: dark ? BColors.light : BColors.black,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
