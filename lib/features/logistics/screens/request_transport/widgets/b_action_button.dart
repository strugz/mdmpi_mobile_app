import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

import '../../../../../base/utils/helpers/helper_functions.dart';
import '../../../controllers/request_controller.dart';
import '../../../controllers/request_transport_controller.dart';

class BActionButton extends StatelessWidget {
  const BActionButton(
      {super.key,
      required this.requestController,
      required this.requestTransportController});

  final RequestController requestController;
  final RequestTransportController requestTransportController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Obx(() {
        bool isLoading = requestTransportController.isLoadingAction.value;
        final String currentStatus =
            requestController.currentSelectedRequest.value!.status;
        // Get the signature state
        final bool hasSignature =
            requestController.formState.receiverSignatureBytes.value != null;
        final userController = Get.find<UserController>();

        return ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  // VALIDATION START
                  if (currentStatus == BTexts.statusForDelivery) {
                    if (requestController.formState.receiver.text.trim().isEmpty) {
                      BHelperFunctions.showSnackBar(
                          "Please enter the receiver's name.");
                      return;
                    }
                    // New: Validate signature
                    if (!hasSignature) {
                      BHelperFunctions.showSnackBar(
                          "Please capture the receiver's signature.");
                      return;
                    }
                  }
                  await requestTransportController
                      .processRequestDispatchOrDropOff(
                          requestController.currentSelectedRequest.value!,
                          userController.user.value.initial);
                },
          style: ElevatedButton.styleFrom(),
          child: isLoading
              ? const SizedBox(
                  height: 24.0,
                  width: 24.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  currentStatus == BTexts.statusItemPrepared
                      ? 'Dispatch'
                      : currentStatus == BTexts.statusForDelivery
                          ? 'Drop Off'
                          : 'Processing...',
                ),
        );
      }),
    );
  }
}
