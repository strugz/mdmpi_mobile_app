import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

import '../../../../../base/utils/helpers/helper_functions.dart';
import '../../../../../base/utils/image_utils/image_conversion_base_64_to_string.dart';
import '../../../controllers/request_transport_controller.dart';
import '../../../models/standard_delivery_model.dart';

class BActionButton extends StatelessWidget {
  const BActionButton({
    super.key,
    required this.requestController,
    required this.requestTransportController,
  });

  final IDeliveryRequestController requestController;
  final RequestTransportController requestTransportController;

  @override
  Widget build(BuildContext context) {
    print('BActionButton build - requestController instance: ${requestController.hashCode}');

    return SizedBox(
      width: double.infinity,
      child: Obx(() {
        bool isLoading = requestTransportController.isLoadingAction.value;
        // Watch currentSelectedRequest for reactive status updates
        final updatedRequest = requestController.currentSelectedRequest.value;

        print('BActionButton rebuild - updatedRequest: ${updatedRequest?.status ?? "NULL"}');
        print('BActionButton rebuild - controller instance: ${requestController.hashCode}');

        // If somehow null, use the static request as absolute fallback
        if (updatedRequest == null) {
          return const Text('Error: Request not found');
        }

        final String currentStatus = updatedRequest.status;
        print('BActionButton currentStatus: $currentStatus');
        // Get the signature state
        final bool hasSignature =
            requestController.formState.receiverSignatureBytes.value != null;
        final bool hasReceiverName =
            requestController.formState.receiver.text.trim().isNotEmpty;
        final String proofImage =
            BImageHelperFunctions.getDeliveryImageAsBase64(
                    currentStatus, updatedRequest.id)
                .toString();

        final userController = Get.find<UserController>();


        return ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  // VALIDATION START
                  if (currentStatus == BTexts.statusForDelivery) {
                    if (!hasReceiverName) {
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
                    // Validate proof of delivery

                    if (proofImage.isEmpty) {
                      BHelperFunctions.showSnackBar(
                          "Please capture the delivery proof image.");
                      return;
                    }
                  }
                  await requestTransportController
                      .processRequestDispatchOrDropOff(
                          updatedRequest,
                          userController.user.value.initial,
                          requestController,
                      );
                  await requestController.loadRequests();
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
